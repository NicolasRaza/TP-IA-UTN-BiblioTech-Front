import '../../../../core/error/result.dart';
import '../entities/prestamo.dart';

/// Contrato de acceso a los préstamos.
abstract interface class PrestamoRepository {
  Future<Result<List<Prestamo>>> obtenerTodos();

  Future<Result<List<Prestamo>>> obtenerDeLector(String lectorId);

  Future<Result<Prestamo>> obtenerPorId(String prestamoId);

  Future<Result<Prestamo>> crear(Prestamo prestamo);

  Future<Result<Prestamo>> actualizar(Prestamo prestamo);

  /// Persiste varios préstamos en una sola escritura.
  ///
  /// El procesamiento de vencimientos recorre toda la tabla y puede tocar
  /// muchos préstamos a la vez; guardarlos de a uno multiplicaría las
  /// escrituras sobre el almacenamiento local.
  Future<Result<void>> actualizarVarios(List<Prestamo> prestamos);
}
