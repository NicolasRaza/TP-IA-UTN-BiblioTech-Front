import 'dart:convert';

import 'package:bibliotech/core/api/cliente_api.dart';
import 'package:bibliotech/features/reservas/data/datasources/reserva_api_datasource.dart';
import 'package:bibliotech/features/reservas/domain/entities/reserva.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// Contrato contra `/api/v1/reservas` (`ReservaResponse` del OpenAPI).
void main() {
  ReservaApiDataSourceHttp construir(MockClient cliente) =>
      ReservaApiDataSourceHttp(ClienteApi(
        baseUrl: 'https://backend.test',
        token: () => 'jwt',
        cliente: cliente,
      ));

  Map<String, Object?> reservaJson({
    String estado = 'en_cola',
    String? disponible,
    String? limite,
  }) =>
      {
        'id': 9,
        'titulo_id': 7,
        'lector_id': 3,
        'posicion_cola': 2,
        'estado': estado,
        'fecha_solicitud': '2026-03-05T14:00:00',
        'fecha_disponible': disponible,
        'fecha_limite_retiro': limite,
      };

  test('una reserva en cola todavía no tiene plazo corriendo', () async {
    final datasource = construir(MockClient(
      (_) async => http.Response(jsonEncode([reservaJson()]), 200),
    ));

    final reserva = (await datasource.deLector('3')).valorONull!.single;

    expect(reserva.id, '9');
    expect(reserva.libroId, '7');
    expect(reserva.lectorId, '3');
    expect(reserva.estado, EstadoReserva.pendiente);
    expect(reserva.fechaVencimientoRetiro, isNull);
    expect(reserva.plazoRetiroHorasAlReservar, horasDeRetiroPorDefecto);
  });

  test('una reserva retenida deriva su plazo de las fechas del servidor',
      () async {
    final datasource = construir(MockClient(
      (_) async => http.Response(
        jsonEncode([
          reservaJson(
            estado: 'disponible_para_retiro',
            disponible: '2026-03-06T10:00:00',
            limite: '2026-03-08T10:00:00',
          ),
        ]),
        200,
      ),
    ));

    final reserva = (await datasource.deLector('3')).valorONull!.single;

    expect(reserva.estado, EstadoReserva.lista);
    expect(reserva.estaRetenida, isTrue);
    expect(reserva.fechaVencimientoRetiro, DateTime(2026, 3, 8, 10));
    expect(reserva.plazoRetiroHorasAlReservar, 48);
  });

  test('cada estado del backend cae en el del dominio que le corresponde',
      () async {
    final esperados = {
      'en_cola': EstadoReserva.pendiente,
      'disponible_para_retiro': EstadoReserva.lista,
      'retirada': EstadoReserva.completada,
      'cancelada': EstadoReserva.cancelada,
      'vencida': EstadoReserva.vencida,
    };

    for (final entrada in esperados.entries) {
      final datasource = construir(MockClient(
        (_) async =>
            http.Response(jsonEncode([reservaJson(estado: entrada.key)]), 200),
      ));

      expect((await datasource.deLector('3')).valorONull!.single.estado,
          entrada.value,
          reason: entrada.key);
    }
  });

  test('la reserva sólo manda el título: el lector sale del JWT', () async {
    late http.Request enviado;
    final datasource = construir(MockClient((peticion) async {
      enviado = peticion;
      return http.Response(jsonEncode(reservaJson()), 201);
    }));

    await datasource.reservar('7');

    expect(enviado.url.path, '/api/v1/reservas');
    expect(jsonDecode(enviado.body), {'titulo_id': 7});
  });

  test('cancelar usa DELETE sobre la reserva', () async {
    late http.Request enviado;
    final datasource = construir(MockClient((peticion) async {
      enviado = peticion;
      return http.Response('{"mensaje":"Reserva cancelada"}', 200);
    }));

    final resultado = await datasource.cancelar('9');

    expect(enviado.method, 'DELETE');
    expect(enviado.url.path, '/api/v1/reservas/9');
    expect(resultado.esExito, isTrue);
  });
}
