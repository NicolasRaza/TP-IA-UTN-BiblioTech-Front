import 'package:equatable/equatable.dart';

import '../../../../core/error/result.dart';
import '../../../../core/services/reloj.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../administracion/domain/repositories/configuracion_repository.dart';
import '../../../catalogo/domain/entities/ejemplar.dart';
import '../../../catalogo/domain/repositories/catalogo_repository.dart';
import '../../../lectores/domain/repositories/lector_repository.dart';
import '../../../notificaciones/domain/entities/notificacion.dart';
import '../../../notificaciones/domain/repositories/notificacion_repository.dart';
import '../../../prestamos/domain/entities/prestamo.dart';
import '../../../prestamos/domain/repositories/prestamo_repository.dart';
import '../../../reservas/domain/entities/reserva.dart';
import '../../../reservas/domain/repositories/reserva_repository.dart';
import '../../../reservas/domain/services/asignador_de_cola.dart';

/// Cuánto movió el calendario en esta corrida.
class ResumenVencimientos extends Equatable {
  const ResumenVencimientos({
    required this.prestamosVencidos,
    required this.reservasLiberadas,
  });

  final int prestamosVencidos;
  final int reservasLiberadas;

  @override
  List<Object?> get props => [prestamosVencidos, reservasLiberadas];
}

/// Pone al sistema al día respecto del calendario.
///
/// Marca los préstamos vencidos con su multa acumulada y libera las reservas
/// que superaron el plazo de retiro, pasando el ejemplar al siguiente de la
/// cola. Es la fase de **Observación** del ciclo de la spec v2 §5: corre antes
/// de que el Evaluador decida, para que decida sobre datos actualizados.
///
/// Es idempotente: correrla dos veces seguidas no duplica multas ni avisos.
class ProcesarVencimientos
    implements UseCase<ResumenVencimientos, SinParametros> {
  const ProcesarVencimientos({
    required PrestamoRepository prestamoRepository,
    required ReservaRepository reservaRepository,
    required LectorRepository lectorRepository,
    required CatalogoRepository catalogoRepository,
    required NotificacionRepository notificacionRepository,
    required ConfiguracionRepository configuracionRepository,
    required AsignadorDeCola asignadorDeCola,
    required Reloj reloj,
  })  : _prestamos = prestamoRepository,
        _reservas = reservaRepository,
        _lectores = lectorRepository,
        _catalogo = catalogoRepository,
        _notificaciones = notificacionRepository,
        _configuracion = configuracionRepository,
        _asignador = asignadorDeCola,
        _reloj = reloj;

  final PrestamoRepository _prestamos;
  final ReservaRepository _reservas;
  final LectorRepository _lectores;
  final CatalogoRepository _catalogo;
  final NotificacionRepository _notificaciones;
  final ConfiguracionRepository _configuracion;
  final AsignadorDeCola _asignador;
  final Reloj _reloj;

  @override
  Future<Result<ResumenVencimientos>> call(SinParametros params) async {
    final configResult = await _configuracion.obtener();
    if (configResult case Fallo(:final failure)) return Fallo(failure);
    final configuracion = configResult.valorONull!;

    final momento = _reloj.ahora;

    final vencidos = await _vencerPrestamos(
      momento: momento,
      multaPorDia: configuracion.multaPorDiaDemora,
    );
    if (vencidos case Fallo(:final failure)) return Fallo(failure);

    final liberadas = await _liberarReservasNoRetiradas(momento);
    if (liberadas case Fallo(:final failure)) return Fallo(failure);

    return Exito(ResumenVencimientos(
      prestamosVencidos: vencidos.valorONull!,
      reservasLiberadas: liberadas.valorONull!,
    ));
  }

  /// Marca como vencidos los préstamos pasados de fecha y carga la multa que
  /// falte. Devuelve cuántos préstamos están vencidos en total.
  Future<Result<int>> _vencerPrestamos({
    required DateTime momento,
    required int multaPorDia,
  }) async {
    final todosResult = await _prestamos.obtenerTodos();
    if (todosResult case Fallo(:final failure)) return Fallo(failure);

    final modificados = <Prestamo>[];
    final multasPorLector = <String, int>{};
    var vencidos = 0;

    for (final p in todosResult.valorONull!) {
      if (!p.estaVencido(momento)) continue;
      vencidos++;

      final delta = p.multaPendienteA(momento, multaPorDia);
      if (p.estado == EstadoPrestamo.vencido && delta == 0) continue;

      modificados.add(p.copyWith(
        estado: EstadoPrestamo.vencido,
        tardio: true,
        multaAplicada: p.multaAplicada + delta,
      ));

      if (delta > 0) {
        multasPorLector.update(
          p.lectorId,
          (acumulado) => acumulado + delta,
          ifAbsent: () => delta,
        );
      }
    }

    if (modificados.isNotEmpty) {
      final guardado = await _prestamos.actualizarVarios(modificados);
      if (guardado case Fallo(:final failure)) return Fallo(failure);
    }

    // Un lector con varios préstamos atrasados recibe un único ajuste de
    // saldo, no uno por préstamo.
    for (final entrada in multasPorLector.entries) {
      await _lectores.ajustarMultas(entrada.key, entrada.value);
    }

    return Exito(vencidos);
  }

  /// Vence las reservas retenidas que nadie retiró y ofrece el ejemplar al
  /// siguiente de cada cola afectada.
  Future<Result<int>> _liberarReservasNoRetiradas(DateTime momento) async {
    final todasResult = await _reservas.obtenerTodas();
    if (todasResult case Fallo(:final failure)) return Fallo(failure);

    final modificadas = <Reserva>[];
    final librosAfectados = <String>{};

    for (final r in todasResult.valorONull!) {
      if (!r.venceRetiroA(momento)) continue;

      modificadas.add(r.copyWith(estado: EstadoReserva.vencida));
      librosAfectados.add(r.libroId);

      if (r.ejemplarAsignadoId != null) {
        await _catalogo.cambiarEstadoEjemplar(
          r.libroId,
          r.ejemplarAsignadoId!,
          EstadoEjemplar.disponible,
        );
      }

      final libro = (await _catalogo.obtenerPorId(r.libroId)).valorONull;
      await _notificaciones.crear(
        Notificacion(
          id: '',
          lectorId: r.lectorId,
          tipo: TipoNotificacion.reservaVencida,
          titulo: 'Reserva vencida',
          descripcion: 'Se venció el plazo para retirar '
              '"${libro?.titulo ?? ''}". La reserva pasó al siguiente lector '
              'en la lista.',
          fecha: momento,
        ),
      );
    }

    if (modificadas.isNotEmpty) {
      final guardado = await _reservas.actualizarVarias(modificadas);
      if (guardado case Fallo(:final failure)) return Fallo(failure);
    }

    for (final libroId in librosAfectados) {
      await _asignador.asignarSiguiente(libroId);
    }

    return Exito(modificadas.length);
  }
}
