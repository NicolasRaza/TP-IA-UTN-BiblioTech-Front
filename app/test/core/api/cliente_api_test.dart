import 'dart:convert';

import 'package:bibliotech/core/api/cliente_api.dart';
import 'package:bibliotech/core/error/failures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// El borde HTTP de la app. Lo que se fija acá es cómo se traduce cada
/// respuesta del backend a una `Failure` del dominio: es la tabla que usan
/// todos los datasources remotos, así que conviene tenerla escrita una vez.
void main() {
  const baseUrl = 'https://backend.test';

  ClienteApi construir(MockClient cliente, {String? token}) => ClienteApi(
        baseUrl: baseUrl,
        token: () => token,
        cliente: cliente,
      );

  ClienteApi conStatus(int status, {String cuerpo = '{}'}) => construir(
        MockClient((_) async => http.Response(cuerpo, status)),
      );

  test('arma la URL con la query y decodifica el JSON', () async {
    late http.Request enviado;
    final api = construir(MockClient((peticion) async {
      enviado = peticion;
      return http.Response(jsonEncode([1, 2, 3]), 200);
    }));

    final resultado = await api.get<int>(
      '/api/v1/catalogo/titulos',
      query: {'q': 'borges', 'genero': 'Ficción'},
      leer: (json) => (json as List).length,
    );

    expect(resultado.valorONull, 3);
    expect(enviado.url.path, '/api/v1/catalogo/titulos');
    expect(enviado.url.queryParameters, {'q': 'borges', 'genero': 'Ficción'});
  });

  test('adjunta el token de la sesión en cada request', () async {
    late http.Request enviado;
    final api = construir(
      MockClient((peticion) async {
        enviado = peticion;
        return http.Response('{}', 200);
      }),
      token: 'jwt-vigente',
    );

    await api.get<void>('/api/v1/auth/me', leer: (_) {});

    expect(enviado.headers['Authorization'], 'Bearer jwt-vigente');
  });

  test('el token explícito le gana al de la sesión', () async {
    late http.Request enviado;
    final api = construir(
      MockClient((peticion) async {
        enviado = peticion;
        return http.Response('{}', 200);
      }),
      token: 'el-de-la-sesion',
    );

    await api.get<void>('/x', token: 'el-explicito', leer: (_) {});

    expect(enviado.headers['Authorization'], 'Bearer el-explicito');
  });

  test('sin sesión no manda header de autorización', () async {
    late http.Request enviado;
    final api = construir(MockClient((peticion) async {
      enviado = peticion;
      return http.Response('{}', 200);
    }));

    await api.get<void>('/x', leer: (_) {});

    expect(enviado.headers.containsKey('Authorization'), isFalse);
  });

  group('traducción de errores', () {
    test('401 y 403 son fallas de autenticación', () async {
      expect((await conStatus(401).get<void>('/x', leer: (_) {})).failureONull,
          isA<AutenticacionFailure>());
      expect((await conStatus(403).get<void>('/x', leer: (_) {})).failureONull,
          isA<AutenticacionFailure>());
    });

    test('404 es no encontrado', () async {
      expect((await conStatus(404).get<void>('/x', leer: (_) {})).failureONull,
          isA<NoEncontradoFailure>());
    });

    test('409 es una regla de negocio, no un error técnico', () async {
      // El backend usa 409 para el cupo lleno, la reserva duplicada y el
      // ejemplar ya prestado: son cosas que hay que explicarle al usuario.
      final resultado = await conStatus(
        409,
        cuerpo: jsonEncode({'detail': 'Lector con multas impagas'}),
      ).post<void>('/prestamos', leer: (_) {});

      expect(resultado.failureONull, isA<ReglaDeNegocioFailure>());
      expect(resultado.failureONull!.mensaje, 'Lector con multas impagas');
    });

    test('422 es validación, con el detalle de FastAPI', () async {
      final resultado = await conStatus(
        422,
        cuerpo: jsonEncode({
          'detail': [
            {
              'loc': ['body', 'email'],
              'msg': 'value is not a valid email'
            },
          ],
        }),
      ).post<void>('/lectores/', leer: (_) {});

      expect(resultado.failureONull, isA<ValidacionFailure>());
      expect(resultado.failureONull!.mensaje,
          contains('value is not a valid email'));
    });

    test('un 500 no se confunde con nada del dominio', () async {
      expect((await conStatus(500).get<void>('/x', leer: (_) {})).failureONull,
          isA<RedFailure>());
    });

    test('un servidor caído no propaga la excepción hacia arriba', () async {
      final api = construir(
        MockClient((_) async => throw const _CorteDeRed()),
      );

      expect((await api.get<void>('/x', leer: (_) {})).failureONull,
          isA<RedFailure>());
    });

    test('un cuerpo que no es JSON queda como falla de red', () async {
      final api = construir(
        MockClient((_) async => http.Response('<html>502</html>', 200)),
      );

      expect((await api.get<void>('/x', leer: (_) {})).failureONull,
          isA<RedFailure>());
    });

    test('un 200 al que le falta lo que el contrato promete se rechaza',
        () async {
      final api = construir(
        MockClient((_) async => http.Response('{"otra_cosa":1}', 200)),
      );

      final resultado = await api.get<String>(
        '/x',
        leer: (json) => switch (json) {
          {'lo_que_hace_falta': final String v} => v,
          _ => throw const FormatException('falta el campo'),
        },
      );

      expect(resultado.failureONull, isA<RedFailure>());
    });
  });
}

class _CorteDeRed implements Exception {
  const _CorteDeRed();
}
