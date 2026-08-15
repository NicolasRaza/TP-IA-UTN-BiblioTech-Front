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
import '../../../reservas/domain/services/asignador_de_cola.dart';
import '../entities/prestamo.dart';
import '../repositories/prestamo_repository.dart';

class RegistrarDevolucionParams extends Equatable {
  const RegistrarDevolucionParams({required this.prestamoId, this.usuarioId});

  final String prestamoId;
  final String? usuarioId;

  @override
  List<Object?> get props => [prestamoId, usuarioId];
}

/// Registra la devolución, aplica la multa que corresponda y libera el
/// ejemplar.
///
/// Al liberarlo, el primero de la cola de reservas pasa a "lista para retirar"
/// con el plazo de 48 hs corriendo (spec v2 §7). Esa consecuencia la produce
/// el [AsignadorDeCola], compartido con los otros dos flujos que liberan
/// ejemplares.
class RegistrarDevolucion
    implements UseCase<Prestamo, RegistrarDevolucionParams> {
  const RegistrarDevolucion({
    required PrestamoRepository prestamoRepository,
    required LectorRepository lectorRepository,
    required CatalogoRepository catalogoRepository,
    required ConfiguracionRepository configuracionRepository,
    required AuditoriaRepository auditoriaRepository,
    required AsignadorDeCola asignadorDeCola,
    required Reloj reloj,
  })  : _prestamos = prestamoRepository,
        _lectores = lectorRepository,
        _catalogo = catalogoRepository,
        _configuracion = configuracionRepository,
        _auditoria = auditoriaRepository,
        _asignador = asignadorDeCola,
        _reloj = reloj;

  final PrestamoRepository _prestamos;
  final LectorRepository _lectores;
  final CatalogoRepository _catalogo;
  final ConfiguracionRepository _configuracion;
  final AuditoriaRepository _auditoria;
  final AsignadorDeCola _asignador;
  final Reloj _reloj;

  @override
  Future<Result<Prestamo>> call(RegistrarDevolucionParams params) async {
    final prestamoResult = await _prestamos.obtenerPorId(params.prestamoId);
    if (prestamoResult case Fallo(:final failure)) return Fallo(failure);
    final prestamo = prestamoResult.valorONull!;

    if (prestamo.estado == EstadoPrestamo.devuelto) {
      return const Fallo(
          ReglaDeNegocioFailure('El préstamo ya fue devuelto'));
    }

    final configResult = await _configuracion.obtener();
    if (configResult case Fallo(:final failure)) return Fallo(failure);
    final configuracion = configResult.valorONull!;

    final momento = _reloj.ahora;
    final tardio = momento.isAfter(prestamo.fechaVencimiento);

    // Sólo se cobra lo que todavía no se había cargado por este préstamo, así
    // devolver un libro ya marcado como vencido no duplica la multa.
    final multaNueva = tardio
        ? prestamo.multaPendienteA(momento, configuracion.multaPorDiaDemora)
        : 0;

    final devuelto = prestamo.copyWith(
      fechaDevolucion: momento,
      estado: EstadoPrestamo.devuelto,
      tardio: tardio,
      multaAplicada: prestamo.multaAplicada + multaNueva,
    );

    final guardado = await _prestamos.actualizar(devuelto);
    if (guardado case Fallo(:final failure)) return Fallo(failure);

    if (multaNueva > 0) {
      await _lectores.ajustarMultas(prestamo.lectorId, multaNueva);
    }

    await _catalogo.cambiarEstadoEjemplar(
      prestamo.libroId,
      prestamo.ejemplarId,
      EstadoEjemplar.disponible,
    );

    final lector = (await _lectores.obtenerPorId(prestamo.lectorId)).valorONull;
    final libro = (await _catalogo.obtenerPorId(prestamo.libroId)).valorONull;

    await _auditoria.registrar(
      tipo: TipoEventoAuditoria.devolucion,
      descripcion: 'Devolución: "${libro?.titulo ?? prestamo.libroId}" de '
          '${lector?.nombreCompleto ?? prestamo.lectorId}'
          '${tardio ? ' (tardía)' : ''}',
      usuarioId: params.usuarioId,
    );

    // El ejemplar liberado se le ofrece al primero de la cola.
    await _asignador.asignarSiguiente(prestamo.libroId);

    return Exito(guardado.valorONull!);
  }
}
