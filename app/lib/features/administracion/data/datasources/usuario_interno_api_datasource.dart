import '../../../../core/api/cliente_api.dart';
import '../../../../core/api/mapeo_api.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/error/result.dart';
import '../../../lectores/domain/entities/lector.dart';
import '../../domain/entities/usuario_interno.dart';

/// Acceso al ABM de usuarios internos del backend (`/api/v1/usuarios`).
///
/// Las cuatro rutas piden rol administrador: con un JWT de bibliotecario el
/// backend responde 403, que el [ClienteApi] traduce a
/// [AutenticacionFailure].
abstract interface class UsuarioInternoApiDataSource {
  /// `GET /usuarios/` — bibliotecarios y administradores.
  Future<Result<List<UsuarioInterno>>> listar();

  /// `POST /usuarios/` — alta de una cuenta de personal.
  Future<Result<UsuarioInterno>> crear({
    required String email,
    required String password,
    required RolUsuario rol,
  });

  /// `DELETE /usuarios/{id}` — baja lógica.
  Future<Result<void>> darDeBaja(String usuarioId);

  /// `POST /usuarios/{id}/reactivar`.
  Future<Result<void>> reactivar(String usuarioId);
}

class UsuarioInternoApiDataSourceHttp implements UsuarioInternoApiDataSource {
  const UsuarioInternoApiDataSourceHttp(this._api);

  final ClienteApi _api;

  @override
  Future<Result<List<UsuarioInterno>>> listar() =>
      _api.get<List<UsuarioInterno>>(
        '/api/v1/usuarios/',
        leer: (json) => (json as List<Object?>? ?? const [])
            .map((e) => usuarioInternoDesdeApi(e as Map<String, dynamic>))
            .toList(),
      );

  @override
  Future<Result<UsuarioInterno>> crear({
    required String email,
    required String password,
    required RolUsuario rol,
  }) =>
      _api.post<UsuarioInterno>(
        '/api/v1/usuarios/',
        cuerpo: {
          'email': email,
          'password': password,
          'rol': rol.code,
        },
        leer: _leerUsuario,
      );

  @override
  Future<Result<void>> darDeBaja(String usuarioId) {
    final id = idHaciaApi(usuarioId);
    if (id == null) return _sinIdRemoto();
    return _api.delete<void>('/api/v1/usuarios/$id', leer: (_) {});
  }

  @override
  Future<Result<void>> reactivar(String usuarioId) {
    final id = idHaciaApi(usuarioId);
    if (id == null) return _sinIdRemoto();
    return _api.post<void>('/api/v1/usuarios/$id/reactivar', leer: (_) {});
  }

  static UsuarioInterno _leerUsuario(Object? json) =>
      usuarioInternoDesdeApi(json as Map<String, dynamic>);

  static Future<Result<void>> _sinIdRemoto() async => const Fallo(
        NoEncontradoFailure('Esa cuenta no existe en el servidor'),
      );
}

/// Traduce un `BibliotecarioResponse` del backend.
UsuarioInterno usuarioInternoDesdeApi(Map<String, dynamic> json) =>
    UsuarioInterno(
      id: idDesdeApi(json['id']),
      email: json['email'] as String? ?? '',
      rol: rolDesdeApi(json['rol'] as String?),
      creadoEn: fechaDesdeApi(json['creado_en'], DateTime.now()),
      activo: json['activo'] as bool? ?? true,
    );
