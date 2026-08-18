import 'dart:convert';

import 'package:bibliotech/core/error/failures.dart';
import 'package:bibliotech/features/auth/data/datasources/auth_api_datasource.dart';
import 'package:bibliotech/features/auth/domain/entities/credenciales_api.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// Contrato contra el backend SGB (`/api/v1/auth`), verificado con un cliente
/// HTTP falso: los tests describen exactamente el JSON que la API documenta en
/// su OpenAPI, así que si el backend cambia el contrato, esto se rompe acá y
/// no en la demo.
void main() {
  const baseUrl = 'https://backend.test';
  const credenciales =
      CredencialesApi(email: 'admin@biblioteca.com', password: 'secreta');

  AuthApiDataSourceHttp construir(MockClient cliente) =>
      AuthApiDataSourceHttp(cliente: cliente, baseUrl: baseUrl);

  group('login', () {
    test('manda email y password y devuelve el access_token', () async {
      late http.Request enviado;

      final datasource = construir(MockClient((peticion) async {
        enviado = peticion;
        return http.Response(
          jsonEncode({
            'access_token': 'jwt-de-prueba',
            'token_type': 'bearer',
            'rol': 'administrador',
          }),
          200,
        );
      }));

      final resultado = await datasource.login(credenciales);

      expect(resultado.valorONull, 'jwt-de-prueba');
      expect(enviado.url.toString(), '$baseUrl/api/v1/auth/login');
      expect(jsonDecode(enviado.body), {
        'email': 'admin@biblioteca.com',
        'password': 'secreta',
      });
    });

    test('traduce el 401 a una falla de autenticación', () async {
      final datasource = construir(
        MockClient(
            (_) async => http.Response('{"detail":"unauthorized"}', 401)),
      );

      final resultado = await datasource.login(credenciales);

      expect(resultado.failureONull, isA<AutenticacionFailure>());
    });

    test('un 200 sin access_token no se toma por bueno', () async {
      final datasource = construir(
        MockClient((_) async => http.Response('{"rol":"lector"}', 200)),
      );

      expect((await datasource.login(credenciales)).failureONull,
          isA<RedFailure>());
    });

    test('un servidor caído no propaga la excepción hacia arriba', () async {
      final datasource = construir(
        MockClient((_) async => throw const SocketExceptionFalsa()),
      );

      expect((await datasource.login(credenciales)).failureONull,
          isA<RedFailure>());
    });
  });

  group('registrarFirebaseToken', () {
    test('manda el token con el JWT en el header Authorization', () async {
      late http.Request enviado;

      final datasource = construir(MockClient((peticion) async {
        enviado = peticion;
        return http.Response('{"ok":true}', 200);
      }));

      final resultado = await datasource.registrarFirebaseToken(
        jwt: 'jwt-de-prueba',
        tokenFirebase: 'fcm-abc123',
      );

      expect(resultado.esExito, isTrue);
      expect(enviado.url.toString(), '$baseUrl/api/v1/auth/firebase-token');
      expect(enviado.headers['Authorization'], 'Bearer jwt-de-prueba');
      expect(jsonDecode(enviado.body), {'firebase_token': 'fcm-abc123'});
    });

    test('el 422 de FastAPI llega con el detalle del campo rechazado',
        () async {
      final datasource = construir(MockClient((_) async => http.Response(
            jsonEncode({
              'detail': [
                {
                  'loc': ['body', 'firebase_token'],
                  'msg': 'field required'
                },
              ],
            }),
            422,
          )));

      final resultado = await datasource.registrarFirebaseToken(
        jwt: 'jwt-de-prueba',
        tokenFirebase: '',
      );

      final failure = resultado.failureONull;
      expect(failure, isA<ValidacionFailure>());
      expect(failure!.mensaje, contains('field required'));
    });
  });
}

/// Un corte de red cualquiera: lo que importa es que no sea una excepción que
/// el datasource conozca.
class SocketExceptionFalsa implements Exception {
  const SocketExceptionFalsa();
}
