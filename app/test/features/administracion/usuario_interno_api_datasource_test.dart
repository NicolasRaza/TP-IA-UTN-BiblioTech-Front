import 'dart:convert';

import 'package:bibliotech/core/api/cliente_api.dart';
import 'package:bibliotech/features/administracion/data/datasources/usuario_interno_api_datasource.dart';
import 'package:bibliotech/features/lectores/domain/entities/lector.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// Contrato contra `/api/v1/usuarios` (`BibliotecarioResponse` del OpenAPI).
void main() {
  UsuarioInternoApiDataSourceHttp construir(MockClient cliente) =>
      UsuarioInternoApiDataSourceHttp(ClienteApi(
        baseUrl: 'https://backend.test',
        token: () => 'jwt',
        cliente: cliente,
      ));

  Map<String, Object?> usuarioJson({
    int id = 7,
    String rol = 'bibliotecario',
    bool activo = true,
  }) =>
      {
        'id': id,
        'email': 'ana@biblioteca.test',
        'rol': rol,
        'activo': activo,
        'creado_en': '2026-02-03T10:15:00',
      };

  test('traduce la respuesta del backend', () async {
    final datasource = construir(MockClient(
      (_) async => http.Response(jsonEncode([usuarioJson()]), 200),
    ));

    final usuarios = (await datasource.listar()).valorONull!;

    expect(usuarios, hasLength(1));
    expect(usuarios.single.id, '7');
    expect(usuarios.single.email, 'ana@biblioteca.test');
    expect(usuarios.single.rol, RolUsuario.bibliotecario);
    expect(usuarios.single.activo, isTrue);
    expect(usuarios.single.creadoEn, DateTime(2026, 2, 3, 10, 15));
  });

  test('el alta manda email, contraseña y rol', () async {
    late http.Request enviado;
    final datasource = construir(MockClient((peticion) async {
      enviado = peticion;
      return http.Response(jsonEncode(usuarioJson(rol: 'administrador')), 201);
    }));

    final creado = await datasource.crear(
      email: 'ana@biblioteca.test',
      password: 'secreta123',
      rol: RolUsuario.administrador,
    );

    final cuerpo = jsonDecode(enviado.body) as Map<String, Object?>;
    expect(enviado.method, 'POST');
    expect(enviado.url.path, '/api/v1/usuarios/');
    expect(cuerpo, {
      'email': 'ana@biblioteca.test',
      'password': 'secreta123',
      'rol': 'administrador',
    });
    expect(creado.valorONull!.rol, RolUsuario.administrador);
  });

  test('la baja es un DELETE y la reactivación un POST', () async {
    final rutas = <String>[];
    final metodos = <String>[];
    final datasource = construir(MockClient((peticion) async {
      rutas.add(peticion.url.path);
      metodos.add(peticion.method);
      return http.Response(jsonEncode({'mensaje': 'ok'}), 200);
    }));

    await datasource.darDeBaja('7');
    await datasource.reactivar('7');

    expect(rutas, ['/api/v1/usuarios/7', '/api/v1/usuarios/7/reactivar']);
    expect(metodos, ['DELETE', 'POST']);
  });

  test('un id que no es del backend no llega a pegarle', () async {
    var pegoAlServidor = false;
    final datasource = construir(MockClient((_) async {
      pegoAlServidor = true;
      return http.Response('{}', 200);
    }));

    final resultado = await datasource.darDeBaja('lec-local-1');

    expect(resultado.esExito, isFalse);
    expect(pegoAlServidor, isFalse);
  });
}
