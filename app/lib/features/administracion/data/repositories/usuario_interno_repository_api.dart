import '../../../../core/error/result.dart';
import '../../../lectores/domain/entities/lector.dart';
import '../../domain/entities/usuario_interno.dart';
import '../../domain/repositories/usuario_interno_repository.dart';
import '../datasources/usuario_interno_api_datasource.dart';

/// Implementación del [UsuarioInternoRepository] contra la API del backend.
class UsuarioInternoRepositoryApi implements UsuarioInternoRepository {
  const UsuarioInternoRepositoryApi(this._api);

  final UsuarioInternoApiDataSource _api;

  @override
  Future<Result<List<UsuarioInterno>>> obtenerTodos() => _api.listar();

  @override
  Future<Result<UsuarioInterno>> crear({
    required String email,
    required String password,
    required RolUsuario rol,
  }) =>
      _api.crear(email: email, password: password, rol: rol);

  @override
  Future<Result<void>> darDeBaja(String usuarioId) => _api.darDeBaja(usuarioId);

  @override
  Future<Result<void>> reactivar(String usuarioId) => _api.reactivar(usuarioId);
}
