import '../../../../core/error/result.dart';
import '../../../lectores/domain/entities/lector.dart';

/// Contrato de la sesión del usuario.
abstract interface class SesionRepository {
  /// Usuario logueado, o `null` si no hay sesión abierta.
  Future<Result<Lector?>> obtenerSesionActiva();

  /// Valida las credenciales y persiste la sesión.
  ///
  /// [clave] es el secreto que escribió la persona: el PIN del padrón cuando
  /// la app corre sobre su almacenamiento local, y la contraseña de la cuenta
  /// cuando corre contra el backend. El contrato no distingue cuál de los dos
  /// es; eso lo sabe la implementación que esté montada.
  ///
  /// Falla con [AutenticacionFailure] si las credenciales no coinciden o la
  /// cuenta está dada de baja.
  Future<Result<Lector>> iniciarSesion({
    required String email,
    required String clave,
  });

  Future<Result<void>> cerrarSesion();
}
