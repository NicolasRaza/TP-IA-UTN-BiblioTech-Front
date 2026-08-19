import '../../../../core/error/result.dart';
import '../entities/reserva.dart';

/// Puerto para las reservas que resuelve el backend en una transacción.
///
/// El servidor verifica el estado del lector, su cupo y sus multas, descarta
/// las reservas duplicadas y asigna la posición en la cola. Igual que
/// `PrestamoRemoto`, cuando está registrado los casos de uso delegan acá en
/// vez de aplicar esas reglas del lado de la app.
abstract interface class ReservaRemota {
  /// La reserva es siempre del lector dueño de la sesión: el backend lo
  /// resuelve desde el JWT y no acepta reservar en nombre de otro.
  Future<Result<Reserva>> reservar(String libroId);

  Future<Result<void>> cancelar(String reservaId);
}
