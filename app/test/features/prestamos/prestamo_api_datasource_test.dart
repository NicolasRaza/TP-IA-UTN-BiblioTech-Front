import 'dart:convert';

import 'package:bibliotech/core/api/cliente_api.dart';
import 'package:bibliotech/features/prestamos/data/datasources/prestamo_api_datasource.dart';
import 'package:bibliotech/features/prestamos/domain/entities/prestamo.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// Contrato contra `/api/v1/prestamos` (`PrestamoResponse` del OpenAPI).
void main() {
  PrestamoApiDataSourceHttp construir(MockClient cliente) =>
      PrestamoApiDataSourceHttp(ClienteApi(
        baseUrl: 'https://backend.test',
        token: () => 'jwt',
        cliente: cliente,
      ));

  Map<String, Object?> prestamoJson({
    int id = 15,
    Object? tituloId = 7,
    String estado = 'activo',
    String? devolucionReal,
  }) =>
      {
        'id': id,
        'ejemplar_id': 42,
        'titulo_id': tituloId,
        'lector_id': 3,
        'fecha_inicio': '2026-03-01',
        'fecha_devolucion_pactada': '2026-03-15',
        'fecha_devolucion_real': devolucionReal,
        'estado': estado,
        'dias_restantes': 6,
        'creado_en': '2026-03-01T11:00:00',
      };

  test('traduce un préstamo activo', () async {
    final datasource = construir(MockClient(
      (_) async => http.Response(jsonEncode([prestamoJson()]), 200),
    ));

    final prestamo = (await datasource.deLector('3')).valorONull!.single;

    expect(prestamo.id, '15');
    expect(prestamo.lectorId, '3');
    expect(prestamo.ejemplarId, '42');
    expect(prestamo.libroId, '7');
    expect(prestamo.estado, EstadoPrestamo.activo);
    expect(prestamo.fechaPrestamo, DateTime(2026, 3, 1));
    expect(prestamo.fechaVencimiento, DateTime(2026, 3, 15));
    // El backend no guarda el plazo con el que nació el préstamo, pero es
    // exactamente la distancia entre las dos fechas que sí devuelve.
    expect(prestamo.plazoDiasAlPrestar, 14);
    expect(prestamo.fechaDevolucion, isNull);
    expect(prestamo.tardio, isFalse);
  });

  test('una devolución fuera de plazo queda marcada como tardía', () async {
    final datasource = construir(MockClient(
      (_) async => http.Response(
        jsonEncode([
          prestamoJson(estado: 'devuelto', devolucionReal: '2026-03-20'),
        ]),
        200,
      ),
    ));

    final prestamo = (await datasource.deLector('3')).valorONull!.single;

    expect(prestamo.estado, EstadoPrestamo.devuelto);
    expect(prestamo.fechaDevolucion, DateTime(2026, 3, 20));
    expect(prestamo.tardio, isTrue);
  });

  test('sin titulo_id el préstamo no apunta a ningún libro', () async {
    // `GET /prestamos/lector/{id}` todavía no completa `titulo_id`. Dejarlo
    // vacío es preferible a apuntar a un título equivocado.
    final datasource = construir(MockClient(
      (_) async =>
          http.Response(jsonEncode([prestamoJson(tituloId: null)]), 200),
    ));

    expect((await datasource.deLector('3')).valorONull!.single.libroId, '');
  });

  test('el préstamo identifica el ejemplar por su etiqueta', () async {
    late http.Request enviado;
    final datasource = construir(MockClient((peticion) async {
      enviado = peticion;
      return http.Response(jsonEncode(prestamoJson()), 201);
    }));

    await datasource.prestar(qrEjemplar: 'SGB-A1B2C3', lectorId: '3');

    expect(enviado.url.path, '/api/v1/prestamos');
    expect(jsonDecode(enviado.body),
        {'qr_ejemplar': 'SGB-A1B2C3', 'lector_id': 3});
  });

  test('la devolución va por su propia ruta, sólo con el QR', () async {
    late http.Request enviado;
    final datasource = construir(MockClient((peticion) async {
      enviado = peticion;
      return http.Response(jsonEncode(prestamoJson(estado: 'devuelto')), 200);
    }));

    await datasource.devolver('SGB-A1B2C3');

    expect(enviado.url.path, '/api/v1/prestamos/devolucion');
    expect(jsonDecode(enviado.body), {'qr_ejemplar': 'SGB-A1B2C3'});
  });

  test('la circulación completa se pide en una sola llamada', () async {
    late http.Request enviado;
    final datasource = construir(MockClient((peticion) async {
      enviado = peticion;
      return http.Response(jsonEncode([prestamoJson()]), 200);
    }));

    final todos = await datasource.todos();

    expect(enviado.url.path, '/api/v1/prestamos');
    expect(todos.valorONull, hasLength(1));
  });
}
