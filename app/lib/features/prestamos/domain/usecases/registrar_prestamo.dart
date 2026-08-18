import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/error/result.dart';
import '../../../../core/services/reloj.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../administracion/domain/entities/evento_auditoria.dart';
import '../../../administracion/domain/repositories/auditoria_repository.dart';
import '../../../administracion/domain/repositories/configuracion_repository.dart';
import '../../../catalogo/domain/entities/ejemplar.dart';
import '../../../catalogo/domain/repositories/catalogo_repository.dart';
import '../../../lectores/domain/repositories/lector_repository.dart';
import '../../../notificaciones/domain/entities/notificacion.dart';
import '../../../notificaciones/domain/repositories/notificacion_repository.dart';
import '../../../reservas/domain/entities/reserva.dart';
import '../../../reservas/domain/repositories/reserva_repository.dart';
import '../entities/prestamo.dart';
import '../repositories/prestamo_repository.dart';
import '../services/politica_de_prestamo.dart';

class RegistrarPrestamoParams extends Equatable {
  const RegistrarPrestamoParams({
    required this.lectorId,
    required this.libroId,
    this.ejemplarId,
    this.usuarioId,
  });

  final String lectorId;
  final String libroId;

  /// Ejemplar puntual. Si es `null` se toma el primero disponible.
  final String? ejemplarId;

  /// Quién opera el mostrador, para la traza de auditoría.
  final String? usuarioId;

  @override
  List<Object?> get props => [lectorId, libroId, ejemplarId, usuarioId];
}

/// Registra un préstamo, congelando plazo y categoría vigentes.
///
/// Este caso de uso es el que más repositorios coordina, y eso es fiel al
/// negocio: prestar un libro toca al lector, al ejemplar, a la cola de
/// reservas, a las notificaciones y a la auditoría. La diferencia con el
/// diseño anterior es que ahora esa coordinación está explícita en un solo
/// lugar y contra interfaces, en vez de escondida como efecto secundario
/// dentro de un repositorio de 946 líneas.
class RegistrarPrestamo implements UseCase<Prestamo, RegistrarPrestamoParams> {
  const RegistrarPrestamo({
    required PrestamoRepository prestamoRepository,
    required LectorRepository lectorRepository,
    required CatalogoRepository catalogoRepository,
    required ReservaRepository reservaRepository,
    required NotificacionRepository notificacionRepository,
    required ConfiguracionRepository configuracionRepository,
    required AuditoriaRepository auditoriaRepository,
    required Reloj reloj,
    PoliticaDePrestamo politica = const PoliticaDePrestamo(),
  })  : _prestamos = prestamoRepository,
        _lectores = lectorRepository,
        _catalogo = catalogoRepository,
        _reservas = reservaRepository,
        _notificaciones = notificacionRepository,
        _configuracion = configuracionRepository,
        _auditoria = auditoriaRepository,
        _reloj = reloj,
        _politica = politica;

  final PrestamoRepository _prestamos;
  final LectorRepository _lectores;
  final CatalogoRepository _catalogo;
  final ReservaRepository _reservas;
  final NotificacionRepository _notificaciones;
  final ConfiguracionRepository _configuracion;
  final AuditoriaRepository _auditoria;
  final Reloj _reloj;
  final PoliticaDePrestamo _politica;

  @override
  Future<Result<Prestamo>> call(RegistrarPrestamoParams params) async {
    final lectorResult = await _lectores.obtenerPorId(params.lectorId);
    if (lectorResult case Fallo(:final failure)) return Fallo(failure);
    final lector = lectorResult.valorONull!;

    final prestamosResult = await _prestamos.obtenerDeLector(params.lectorId);
    if (prestamosResult case Fallo(:final failure)) return Fallo(failure);

    final configResult = await _configuracion.obtener();
    if (configResult case Fallo(:final failure)) return Fallo(failure);
    final configuracion = configResult.valorONull!;

    final habilitado = _politica.verificar(
      lector: lector,
      prestamosDelLector: prestamosResult.valorONull!,
      configuracion: configuracion,
    );
    if (habilitado case Fallo(:final failure)) return Fallo(failure);

    final libroResult = await _catalogo.obtenerPorId(params.libroId);
    if (libroResult case Fallo(:final failure)) return Fallo(failure);
    final libro = libroResult.valorONull!;

    final ejemplar = params.ejemplarId != null
        ? libro.ejemplar(params.ejemplarId!)
        : libro.primerEjemplarDisponible;

    if (ejemplar == null) {
      return const Fallo(
          ReglaDeNegocioFailure('No hay ejemplares disponibles'));
    }
    if (!ejemplar.estaDisponible &&
        ejemplar.estado != EstadoEjemplar.reservado) {
      return const Fallo(
          ReglaDeNegocioFailure('El ejemplar no está disponible'));
    }

    final ahora = _reloj.ahora;
    final plazo = configuracion.plazoPara(lector.categoria);

    final creado = await _prestamos.crear(
      Prestamo(
        id: '',
        lectorId: params.lectorId,
        ejemplarId: ejemplar.id,
        libroId: params.libroId,
        fechaPrestamo: ahora,
        fechaVencimiento: ahora.add(Duration(days: plazo)),
        estado: EstadoPrestamo.activo,
        categoriaAlPrestar: lector.categoria,
        plazoDiasAlPrestar: plazo,
      ),
    );
    if (creado case Fallo(:final failure)) return Fallo(failure);
    final prestamo = creado.valorONull!;

    await _catalogo.cambiarEstadoEjemplar(
      params.libroId,
      ejemplar.id,
      EstadoEjemplar.prestado,
    );

    await _cerrarReservaQueSatisface(params.lectorId, params.libroId);

    await _notificaciones.crear(
      Notificacion(
        id: '',
        lectorId: params.lectorId,
        tipo: TipoNotificacion.reservaConfirmada,
        titulo: 'Préstamo confirmado',
        descripcion: 'Te llevaste "${libro.titulo}". '
            'Vence el ${_fechaCorta(prestamo.fechaVencimiento)}.',
        fecha: ahora,
      ),
    );

    await _auditoria.registrar(
      tipo: TipoEventoAuditoria.prestamo,
      descripcion: 'Préstamo otorgado: "${libro.titulo}" a '
          '${lector.nombreCompleto} (DNI ${lector.dni}), plazo $plazo días',
      usuarioId: params.usuarioId,
    );

    return Exito(prestamo);
  }

  /// Si el lector tenía una reserva activa sobre este título, el préstamo la
  /// satisface y la cierra.
  Future<void> _cerrarReservaQueSatisface(
      String lectorId, String libroId) async {
    final reservasResult = await _reservas.obtenerDeLector(lectorId);
    final reservas = reservasResult.valorONull;
    if (reservas == null) return;

    for (final r in reservas) {
      if (r.libroId == libroId && r.esActiva) {
        await _reservas.actualizar(
          r.copyWith(estado: EstadoReserva.completada),
        );
        return;
      }
    }
  }

  static String _fechaCorta(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/${d.year}';
}
