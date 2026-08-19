import 'dart:convert';

import 'package:http/http.dart' as http;

import '../error/failures.dart';
import '../error/result.dart';

/// Cliente HTTP contra la API del backend SGB.
///
/// Es el único lugar de la app que arma URLs, adjunta el JWT y traduce el
/// borde técnico —status HTTP, JSON inesperado, timeout, CORS— a una
/// [Failure]. Los datasources de cada feature reciben este cliente y sólo
/// describen qué ruta piden y cómo mapear el JSON a sus models; ninguno vuelve
/// a escribir el manejo de errores.
///
/// Hacia arriba nunca viaja una excepción: todo sale como [Result].
class ClienteApi {
  ClienteApi({
    required String baseUrl,
    required TokenDeSesion token,
    http.Client? cliente,
    this.espera = const Duration(seconds: 20),
  })  : _baseUrl = baseUrl,
        _token = token,
        _cliente = cliente ?? http.Client();

  final String _baseUrl;
  final http.Client _cliente;

  /// De dónde sale el `Authorization: Bearer`. Es una función y no un String
  /// porque el token cambia con cada login y el cliente vive todo el proceso.
  final TokenDeSesion _token;

  /// Railway duerme las instancias inactivas: el primer request de la demo
  /// puede tardar varios segundos en despertar el contenedor.
  final Duration espera;

  Future<Result<T>> get<T>(
    String ruta, {
    Map<String, String> query = const {},
    required T Function(Object? json) leer,
  }) =>
      _pedir(
        metodo: _Metodo.get,
        ruta: ruta,
        query: query,
        leer: leer,
      );

  Future<Result<T>> post<T>(
    String ruta, {
    Object? cuerpo,
    required T Function(Object? json) leer,
  }) =>
      _pedir(
        metodo: _Metodo.post,
        ruta: ruta,
        cuerpo: cuerpo,
        leer: leer,
      );

  Future<Result<T>> patch<T>(
    String ruta, {
    Object? cuerpo,
    required T Function(Object? json) leer,
  }) =>
      _pedir(
        metodo: _Metodo.patch,
        ruta: ruta,
        cuerpo: cuerpo,
        leer: leer,
      );

  Future<Result<T>> delete<T>(
    String ruta, {
    required T Function(Object? json) leer,
  }) =>
      _pedir(
        metodo: _Metodo.delete,
        ruta: ruta,
        leer: leer,
      );

  Future<Result<T>> _pedir<T>({
    required _Metodo metodo,
    required String ruta,
    Map<String, String> query = const {},
    Object? cuerpo,
    required T Function(Object? json) leer,
  }) async {
    final uri = Uri.parse('$_baseUrl$ruta').replace(
      queryParameters: query.isEmpty ? null : query,
    );

    final jwt = _token();
    final headers = {
      'Accept': 'application/json',
      if (cuerpo != null) 'Content-Type': 'application/json',
      if (jwt != null && jwt.isNotEmpty) 'Authorization': 'Bearer $jwt',
    };
    final body = cuerpo == null ? null : jsonEncode(cuerpo);

    try {
      final respuesta = await switch (metodo) {
        _Metodo.get => _cliente.get(uri, headers: headers),
        _Metodo.post => _cliente.post(uri, headers: headers, body: body),
        _Metodo.patch => _cliente.patch(uri, headers: headers, body: body),
        _Metodo.delete => _cliente.delete(uri, headers: headers, body: body),
      }
          .timeout(espera);

      return switch (respuesta.statusCode) {
        >= 200 && < 300 => Exito(leer(_decodificar(respuesta.body))),
        401 => Fallo(AutenticacionFailure(
            _detalle(respuesta.body, 'La sesión del backend expiró'))),
        403 => Fallo(AutenticacionFailure(
            _detalle(respuesta.body, 'La cuenta no tiene permiso para esto'))),
        404 => Fallo(NoEncontradoFailure(
            _detalle(respuesta.body, 'El servidor no encontró ese registro'))),
        // El backend usa 409 para los choques con una regla de negocio
        // —cupo lleno, reserva duplicada, ejemplar prestado— y 422 para los
        // datos mal formados. Distinguirlos importa: el primero se le explica
        // al usuario, el segundo es un formulario a corregir.
        409 => Fallo(ReglaDeNegocioFailure(
            _detalle(respuesta.body, 'La operación no está permitida'))),
        422 => Fallo(ValidacionFailure(
            _detalle(respuesta.body, 'El servidor rechazó los datos'))),
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

  static Object? _decodificar(String cuerpo) =>
      cuerpo.isEmpty ? null : jsonDecode(cuerpo);

  /// FastAPI devuelve el motivo del error en `detail`, que puede ser un texto
  /// suelto o la lista de campos que no pasaron la validación.
  static String _detalle(String cuerpo, String porDefecto) {
    try {
      return switch (jsonDecode(cuerpo)) {
        {'detail': final String texto} when texto.isNotEmpty => texto,
        {'detail': final List<Object?> errores} when errores.isNotEmpty =>
          errores
              .map((e) =>
                  e is Map && e['msg'] is String ? e['msg'] as String : '$e')
              .join(' · '),
        _ => porDefecto,
      };
    } on FormatException {
      return porDefecto;
    }
  }
}

/// Devuelve el JWT vigente, o `null` si todavía no hay sesión abierta.
typedef TokenDeSesion = String? Function();

enum _Metodo { get, post, patch, delete }
