import '../../../../core/error/result.dart';
import '../../../lectores/domain/entities/lector.dart';
import '../entities/usuario_interno.dart';

/// Contrato del ABM de cuentas del personal.
///
/// Todas sus operaciones exigen rol administrador del otro lado: es el propio
/// backend el que define que dar de alta a un bibliotecario no es tarea de un
/// bibliotecario.
abstract interface class UsuarioInternoRepository {
  /// Bibliotecarios y administradores, activos y dados de baja.
  Future<Result<List<UsuarioInterno>>> obtenerTodos();

  Future<Result<UsuarioInterno>> crear({
    required String email,
    required String password,
    required RolUsuario rol,
  });

  /// Baja lógica: la cuenta deja de poder iniciar sesión.
  Future<Result<void>> darDeBaja(String usuarioId);

  Future<Result<void>> reactivar(String usuarioId);
}
