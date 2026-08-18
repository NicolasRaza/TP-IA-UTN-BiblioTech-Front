import '../../../../core/error/result.dart';
import '../../../lectores/domain/entities/lector.dart';

/// Contrato de la sesión del usuario.
abstract interface class SesionRepository {
  /// Usuario logueado, o `null` si no hay sesión abierta.
  Future<Result<Lector?>> obtenerSesionActiva();

  /// Valida las credenciales y persiste la sesión.
  ///
  /// Falla con [AutenticacionFailure] si el email no existe, el PIN no
  /// coincide, o la cuenta de un lector está dada de baja.
  Future<Result<Lector>> iniciarSesion({
    required String email,
    required String pin,
  });

  Future<Result<void>> cerrarSesion();
}
