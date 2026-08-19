import '../../../../core/error/result.dart';
import '../entities/prestamo.dart';

/// Puerto para la circulación que resuelve el backend en una transacción.
///
/// Existe porque prestar y devolver no son "guardar una fila": el servidor
/// verifica cupo, multas y disponibilidad, mueve el estado del ejemplar y
/// calcula el plazo, todo junto. Modelarlo como un `crear()` del
/// [PrestamoRepository] obligaría a la app a repetir esas reglas y a mandar
/// varias escrituras que podrían quedar a medias.
///
/// Cuando está registrado, los casos de uso de préstamo y devolución delegan
/// acá en lugar de coordinar los repositorios locales. Cuando no lo está —la
/// app corriendo sobre su almacenamiento local—, valen las reglas de dominio
/// implementadas en la propia app.
abstract interface class PrestamoRemoto {
  Future<Result<Prestamo>> prestar({
    required String lectorId,
    required String qrEjemplar,
  });

  Future<Result<Prestamo>> devolver(String qrEjemplar);
}
