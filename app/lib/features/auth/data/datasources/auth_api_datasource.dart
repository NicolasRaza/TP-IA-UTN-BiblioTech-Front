import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../core/config/entorno.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/error/result.dart';
import '../../domain/entities/credenciales_api.dart';

/// Acceso a las rutas de autenticación del backend (SGB API v1).
///
/// Devuelve [Result] igual que los datasources locales: la capa de datos
/// traduce acá los errores técnicos —status HTTP, JSON inesperado, timeout— a
/// una [Failure], y hacia arriba nunca viaja una excepción.
abstract interface class AuthApiDataSource {
  /// `POST /api/v1/auth/login` → JWT de la sesión del backend.
  Future<Result<String>> login(CredencialesApi credenciales);

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
    this.espera = const Duration(seconds: 20),
  })  : _cliente = cliente ?? http.Client(),
        _baseUrl = baseUrl;

  final http.Client _cliente;
  final String _baseUrl;

  /// Railway duerme las instancias inactivas: el primer request de la demo
  /// puede tardar varios segundos en despertar el contenedor.
  final Duration espera;

  @override
  Future<Result<String>> login(CredencialesApi credenciales) => _pedir<String>(
        ruta: '/api/v1/auth/login',
        cuerpo: {
          'email': credenciales.email,
          'password': credenciales.password,
        },
        alFallarAutenticacion: 'Usuario o contraseña incorrectos',
        leerRespuesta: (json) => switch (json) {
          {'access_token': final String token} when token.isNotEmpty =>
            Exito(token),
          _ => const Fallo(
              RedFailure('El servidor no devolvió un token de sesión')),
        },
      );

  @override
  Future<Result<void>> registrarFirebaseToken({
    required String jwt,
    required String tokenFirebase,
  }) =>
      _pedir<void>(
        ruta: '/api/v1/auth/firebase-token',
        cuerpo: {'firebase_token': tokenFirebase},
        jwt: jwt,
        alFallarAutenticacion: 'La sesión del backend expiró',
        leerRespuesta: (_) => const Exito(null),
      );

  /// Un único POST con el manejo de errores compartido.
  Future<Result<T>> _pedir<T>({
    required String ruta,
    required Map<String, Object?> cuerpo,
    required String alFallarAutenticacion,
    required Result<T> Function(Object? json) leerRespuesta,
    String? jwt,
  }) async {
    try {
      final respuesta = await _cliente
          .post(
            Uri.parse('$_baseUrl$ruta'),
            headers: {
              'Content-Type': 'application/json',
              if (jwt != null) 'Authorization': 'Bearer $jwt',
            },
            body: jsonEncode(cuerpo),
          )
          .timeout(espera);

      return switch (respuesta.statusCode) {
        >= 200 && < 300 => leerRespuesta(_decodificar(respuesta.body)),
        401 || 403 => Fallo(AutenticacionFailure(alFallarAutenticacion)),
        422 => Fallo(ValidacionFailure(_detalle(respuesta.body))),
        final codigo => Fallo(RedFailure('El servidor respondió $codigo')),
      };
    } on FormatException {
      return const Fallo(
          RedFailure('El servidor devolvió una respuesta ilegible'));
    } catch (_) {
      // Timeout, DNS, CORS, TLS: para el usuario final son todos lo mismo.
      return const Fallo(RedFailure());
    }
  }

  Object? _decodificar(String cuerpo) =>
      cuerpo.isEmpty ? null : jsonDecode(cuerpo);

  /// FastAPI devuelve los errores de validación en `detail`, que puede ser un
  /// texto suelto o la lista de campos que no pasaron.
  String _detalle(String cuerpo) {
    try {
      final json = jsonDecode(cuerpo);
      return switch (json) {
        {'detail': final String texto} => texto,
        {'detail': final List<Object?> errores} when errores.isNotEmpty =>
          errores
              .map((e) =>
                  e is Map && e['msg'] is String ? e['msg'] as String : '$e')
              .join(' · '),
        _ => 'El servidor rechazó los datos enviados',
      };
    } on FormatException {
      return 'El servidor rechazó los datos enviados';
    }
  }
}
