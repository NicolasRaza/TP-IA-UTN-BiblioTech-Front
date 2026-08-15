import 'package:equatable/equatable.dart';

import '../../../../core/error/result.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../catalogo/domain/entities/ejemplar.dart';
import '../../../catalogo/domain/repositories/catalogo_repository.dart';
import '../entities/reserva.dart';
import '../repositories/reserva_repository.dart';
import '../services/asignador_de_cola.dart';

class CancelarReservaParams extends Equatable {
  const CancelarReservaParams(this.reservaId);

  final String reservaId;

  @override
  List<Object?> get props => [reservaId];
}

/// Da de baja una reserva.
///
/// Si estaba retenida, el ejemplar que tenía asignado vuelve a estar
/// disponible y se le ofrece al siguiente de la cola.
class CancelarReserva implements UseCase<Reserva, CancelarReservaParams> {
  const CancelarReserva({
    required ReservaRepository reservaRepository,
    required CatalogoRepository catalogoRepository,
    required AsignadorDeCola asignadorDeCola,
  })  : _reservas = reservaRepository,
        _catalogo = catalogoRepository,
        _asignador = asignadorDeCola;

  final ReservaRepository _reservas;
  final CatalogoRepository _catalogo;
  final AsignadorDeCola _asignador;

  @override
  Future<Result<Reserva>> call(CancelarReservaParams params) async {
    final reservaResult = await _reservas.obtenerPorId(params.reservaId);
    if (reservaResult case Fallo(:final failure)) return Fallo(failure);
    final reserva = reservaResult.valorONull!;

    final estabaRetenida = reserva.estaRetenida;
    final ejemplarId = reserva.ejemplarAsignadoId;

    final cancelada = await _reservas.actualizar(
      reserva.copyWith(estado: EstadoReserva.cancelada),
    );
    if (cancelada case Fallo(:final failure)) return Fallo(failure);

    if (estabaRetenida && ejemplarId != null) {
      await _catalogo.cambiarEstadoEjemplar(
        reserva.libroId,
        ejemplarId,
        EstadoEjemplar.disponible,
      );
    }

    await _asignador.asignarSiguiente(reserva.libroId);

    return Exito(cancelada.valorONull!);
  }
}
