import 'package:http/http.dart' as http;

import '../../../../core/api/cliente_api.dart';
import '../../../../core/api/sesion_api.dart';
import '../../../../core/config/entorno.dart';
import '../../../../core/error/result.dart';
import '../../domain/entities/credenciales_api.dart';

/// Acceso a las rutas de autenticación del backend (SGB API v1).
///
/// Devuelve [Result] igual que los datasources locales: el [ClienteApi]
/// traduce acá los errores técnicos —status HTTP, JSON inesperado, timeout— a
/// una `Failure`, y hacia arriba nunca viaja una excepción.
abstract interface class AuthApiDataSource {
  /// `POST /api/v1/auth/login` → JWT de la sesión del backend.
  Future<Result<String>> login(CredencialesApi credenciales);

  /// `GET /api/v1/auth/me` → quién es el dueño del [jwt] y con qué rol.
  Future<Result<UsuarioApi>> perfil(String jwt);

  /// `POST /api/v1/auth/firebase-token` → asocia el token FCM del dispositivo
  /// al usuario dueño del [jwt].
  Future<Result<void>> registrarFirebaseToken({
    required String jwt,
    required String tokenFirebase,
  });
}

class AuthApiDataSourceHttp implements AuthApiDataSource {
  AuthApiDataSourceHttp({
    http.Client? cliente,
    String baseUrl = Entorno.apiBaseUrl,
    Duration espera = const Duration(seconds: 20),
  }) : _api = ClienteApi(
          baseUrl: baseUrl,
          // Ninguna de estas tres rutas usa la sesión guardada: el login es
          // previo a que exista, y las otras dos reciben el JWT por parámetro.
          token: _sinSesion,
          cliente: cliente,
          espera: espera,
        );

  final ClienteApi _api;

  static String? _sinSesion() => null;

  @override
  Future<Result<String>> login(CredencialesApi credenciales) =>
      _api.post<String>(
        '/api/v1/auth/login',
        cuerpo: {
          'email': credenciales.email,
          'password': credenciales.password,
        },
        leer: (json) => switch (json) {
          {'access_token': final String token} when token.isNotEmpty => token,
          // Un 200 sin token no es una sesión: se rechaza en vez de dar por
          // buena una respuesta que no cumple el contrato.
          _ => throw const FormatException('La respuesta no trae access_token'),
        },
      );

  @override
  Future<Result<UsuarioApi>> perfil(String jwt) => _api.get<UsuarioApi>(
        '/api/v1/auth/me',
        token: jwt,
        leer: (json) => UsuarioApi.fromJson(json as Map<String, dynamic>),
      );

  @override
  Future<Result<void>> registrarFirebaseToken({
    required String jwt,
    required String tokenFirebase,
  }) =>
      _api.post<void>(
        '/api/v1/auth/firebase-token',
        cuerpo: {'firebase_token': tokenFirebase},
        token: jwt,
        leer: (_) {},
      );
}
