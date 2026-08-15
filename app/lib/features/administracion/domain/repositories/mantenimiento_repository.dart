import '../../../../core/error/result.dart';

/// Contrato del ciclo de vida de los datos de demostración.
abstract interface class MantenimientoRepository {
  /// Carga los datos de ejemplo la primera vez que se abre la app.
  /// Es idempotente: si ya se sembró, no hace nada.
  Future<Result<void>> inicializarSiHaceFalta();

  /// Borra todo y vuelve al estado de demostración original.
  Future<Result<void>> reiniciar();
}
