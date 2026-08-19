import 'dart:convert';

import 'package:bibliotech/core/api/cliente_api.dart';
import 'package:bibliotech/features/lectores/data/datasources/lector_api_datasource.dart';
import 'package:bibliotech/features/lectores/domain/entities/lector.dart';
import 'package:bibliotech/features/lectores/domain/entities/solicitud_de_registro.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// Contrato contra `/api/v1/lectores` (`LectorResponse` y
/// `LectorFichaResponse` del OpenAPI).
void main() {
  LectorApiDataSourceHttp construir(MockClient cliente) =>
      LectorApiDataSourceHttp(ClienteApi(
        baseUrl: 'https://backend.test',
        token: () => 'jwt',
        cliente: cliente,
      ));

  Map<String, Object?> lectorJson({
    String categoria = 'adulto',
    String estado = 'activo',
    int multas = 0,
  }) =>
      {
        'id': 3,
        'nombre': 'Laura',
        'apellido': 'Gómez',
        'documento': '30123456',
        'fecha_nacimiento': '1990-07-14',
        'categoria': categoria,
        'estado': estado,
        'tutor_nombre': null,
        'tutor_telefono': null,
        'consentimiento_datos': true,
        'fecha_alta': '2026-01-10T09:00:00',
        'usuario_id': 5,
        'prestamos_activos': 1,
        'multas_pendientes': multas,
      };

  test('traduce la ficha del backend', () async {
    final datasource = construir(MockClient(
      (_) async => http.Response(jsonEncode(lectorJson(multas: 2)), 200),
    ));

    final lector = (await datasource.obtener('3')).valorONull!;

    expect(lector.id, '3');
    expect(lector.nombreCompleto, 'Laura Gómez');
    expect(lector.dni, '30123456');
    expect(lector.categoria, CategoriaLector.adulto);
    expect(lector.activo, isTrue);
    expect(lector.fechaNacimiento, DateTime(1990, 7, 14));
    expect(lector.multasPendientes, 2);
    // Ninguno de los dos viaja en la respuesta del backend.
    expect(lector.email, isEmpty);
    expect(lector.pin, isEmpty);
  });

  group('categorías', () {
    test('infantil y adolescente colapsan en menor', () async {
      for (final code in ['infantil', 'adolescente']) {
        final datasource = construir(MockClient(
          (_) async =>
              http.Response(jsonEncode(lectorJson(categoria: code)), 200),
        ));
        expect((await datasource.obtener('3')).valorONull!.categoria,
            CategoriaLector.menor,
            reason: code);
      }
    });

    test('institucional se lee como personal', () async {
      final datasource = construir(MockClient(
        (_) async => http.Response(
            jsonEncode(lectorJson(categoria: 'institucional')), 200),
      ));

      expect((await datasource.obtener('3')).valorONull!.categoria,
          CategoriaLector.personal);
    });

    test('senior viaja como adulto, que es el plazo que le daría el backend',
        () async {
      late http.Request enviado;
      final datasource = construir(MockClient((peticion) async {
        enviado = peticion;
        return http.Response(jsonEncode(lectorJson()), 200);
      }));

      await datasource.actualizar(Lector(
        id: '3',
        nombre: 'Laura',
        apellido: 'Gómez',
        email: 'laura@demo.com',
        categoria: CategoriaLector.senior,
        fechaAlta: DateTime(2026, 1, 10),
      ));

      expect((jsonDecode(enviado.body) as Map)['categoria'], 'adulto');
    });
  });

  test('pendiente se distingue de activo y de baja', () async {
    final esperado = {
      'pendiente': EstadoLector.pendiente,
      'activo': EstadoLector.activo,
      'suspendido': EstadoLector.suspendido,
      'baja': EstadoLector.baja,
    };

    for (final entrada in esperado.entries) {
      final datasource = construir(MockClient(
        (_) async =>
            http.Response(jsonEncode(lectorJson(estado: entrada.key)), 200),
      ));
      expect((await datasource.obtener('3')).valorONull!.estado, entrada.value,
          reason: entrada.key);
    }
  });

  test('la edición manda el estado tal cual, no un booleano', () async {
    late http.Request enviado;
    final datasource = construir(MockClient((peticion) async {
      enviado = peticion;
      return http.Response(jsonEncode(lectorJson()), 200);
    }));

    await datasource.actualizar(Lector(
      id: '3',
      nombre: 'Laura',
      apellido: 'Gómez',
      email: 'laura@demo.com',
      categoria: CategoriaLector.adulto,
      fechaAlta: DateTime(2026, 1, 10),
      estado: EstadoLector.suspendido,
    ));

    expect((jsonDecode(enviado.body) as Map)['estado'], 'suspendido');
  });

  test('el autorregistro manda todo lo que declara la persona', () async {
    late http.Request enviado;
    final datasource = construir(MockClient((peticion) async {
      enviado = peticion;
      return http.Response(jsonEncode(lectorJson(estado: 'pendiente')), 201);
    }));

    final registrado = await datasource.registrar(SolicitudDeRegistro(
      nombre: 'Nadia',
      apellido: 'Ferreyra',
      documento: '44111222',
      email: 'nadia@demo.com',
      fechaNacimiento: DateTime(2012, 3, 9),
      telefono: '11-5555-0000',
      domicilio: 'Mitre 440',
      categoria: CategoriaLector.menor,
      tutorNombre: 'Marta Ferreyra',
      tutorTelefono: '11-4444-1111',
      consentimientoDatos: true,
    ));

    final cuerpo = jsonDecode(enviado.body) as Map<String, Object?>;
    expect(enviado.method, 'POST');
    expect(enviado.url.path, '/api/v1/lectores/');
    expect(cuerpo['documento'], '44111222');
    expect(cuerpo['fecha_nacimiento'], '2012-03-09');
    expect(cuerpo['domicilio'], 'Mitre 440');
    expect(cuerpo['categoria'], 'infantil');
    expect(cuerpo['tutor_nombre'], 'Marta Ferreyra');
    expect(cuerpo['tutor_telefono'], '11-4444-1111');
    expect(cuerpo['consentimiento_datos'], isTrue);
    // Lo que vuelve del backend es un lector que todavía no opera.
    expect(registrado.valorONull!.estado, EstadoLector.pendiente);
  });

  test('suspendido y baja dejan al lector sin operar', () async {
    for (final estado in ['suspendido', 'baja']) {
      final datasource = construir(MockClient(
        (_) async => http.Response(jsonEncode(lectorJson(estado: estado)), 200),
      ));
      expect((await datasource.obtener('3')).valorONull!.activo, isFalse,
          reason: estado);
    }
  });

  test('el alta manda documento, nacimiento y consentimiento', () async {
    late http.Request enviado;
    final datasource = construir(MockClient((peticion) async {
      enviado = peticion;
      return http.Response(jsonEncode(lectorJson()), 201);
    }));

    await datasource.crear(Lector(
      id: '',
      nombre: 'Laura',
      apellido: 'Gómez',
      email: 'laura@demo.com',
      dni: '30123456',
      categoria: CategoriaLector.adulto,
      fechaAlta: DateTime(2026, 1, 10),
      fechaNacimiento: DateTime(1990, 7, 14),
    ));

    final cuerpo = jsonDecode(enviado.body) as Map<String, Object?>;
    expect(enviado.url.path, '/api/v1/lectores/');
    expect(cuerpo['documento'], '30123456');
    // FastAPI parsea un campo `date` como YYYY-MM-DD, sin hora.
    expect(cuerpo['fecha_nacimiento'], '1990-07-14');
    expect(cuerpo['consentimiento_datos'], isTrue);
  });

  test('filtra por nombre y documento con la query del backend', () async {
    late http.Request enviado;
    final datasource = construir(MockClient((peticion) async {
      enviado = peticion;
      return http.Response('[]', 200);
    }));

    await datasource.listar(nombre: 'gómez', documento: '301');

    expect(
        enviado.url.queryParameters, {'nombre': 'gómez', 'documento': '301'});
  });
}
