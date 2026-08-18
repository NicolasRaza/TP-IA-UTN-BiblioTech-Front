import '../../../../core/error/result.dart';
import '../entities/reserva.dart';

/// Contrato de acceso a las reservas.
abstract interface class ReservaRepository {
  Future<Result<List<Reserva>>> obtenerTodas();

  Future<Result<List<Reserva>>> obtenerDeLector(String lectorId);

  /// Cola de espera de un título, en orden estrictamente cronológico (§7).
  Future<Result<List<Reserva>>> obtenerCola(String libroId);

  Future<Result<Reserva>> obtenerPorId(String reservaId);

  Future<Result<Reserva>> crear(Reserva reserva);

  Future<Result<Reserva>> actualizar(Reserva reserva);

  Future<Result<void>> actualizarVarias(List<Reserva> reservas);
}
