import 'dart:convert';

import 'package:bibliotech/core/api/cliente_api.dart';
import 'package:bibliotech/core/api/sesion_api.dart';
import 'package:bibliotech/core/storage/key_value_store.dart';
import 'package:bibliotech/features/reservas/data/datasources/reserva_api_datasource.dart';
import 'package:bibliotech/features/reservas/data/repositories/reserva_repository_api.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// Permisos del repositorio de reservas.
///
/// `GET /reservas` pide rol bibliotecario, así que un lector sólo llega a las
/// suyas. Buscar una reserva por id tiene que empezar por ahí: si arrancara
/// por el listado global, cancelar la propia reserva daría 403.
void main() {
  Map<String, Object?> reservaJson(int id) => {
        'id': id,
        'titulo_id': 7,
        'lector_id': 3,
        'posicion_cola': 1,
        'estado': 'en_cola',
        'fecha_solicitud': '2026-03-05T14:00:00',
        'fecha_disponible': null,
        'fecha_limite_retiro': null,
      };

  SesionApi sesionDeLector() {
    final sesion = SesionApi(MemoryStore());
    sesion.abrir(
      token: 'jwt',
      usuario: const UsuarioApi(
        id: 5,
        email: 'laura@demo.com',
        rol: 'lector',
        lectorId: 3,
      ),
    );
    return sesion;
  }

  test('un lector encuentra su reserva sin tocar el listado global', () async {
    final rutas = <String>[];
    final repo = ReservaRepositoryApi(
      api: ReservaApiDataSourceHttp(ClienteApi(
        baseUrl: 'https://backend.test',
        token: () => 'jwt',
        cliente: MockClient((peticion) async {
          rutas.add(peticion.url.path);
          // El listado global le está vedado a un lector.
          if (peticion.url.path == '/api/v1/reservas') {
            return http.Response('{"detail":"Se requiere rol"}', 403);
          }
          return http.Response(jsonEncode([reservaJson(9)]), 200);
        }),
      )),
      sesion: sesionDeLector(),
    );

    final reserva = await repo.obtenerPorId('9');

    expect(reserva.valorONull!.id, '9');
    expect(rutas, ['/api/v1/reservas/lector/3']);
  });

  test('si no es una reserva propia, cae al listado global', () async {
    final rutas = <String>[];
    final repo = ReservaRepositoryApi(
      api: ReservaApiDataSourceHttp(ClienteApi(
        baseUrl: 'https://backend.test',
        token: () => 'jwt',
        cliente: MockClient((peticion) async {
          rutas.add(peticion.url.path);
          if (peticion.url.path == '/api/v1/reservas') {
            return http.Response(jsonEncode([reservaJson(11)]), 200);
          }
          return http.Response('[]', 200);
        }),
      )),
      sesion: sesionDeLector(),
    );

    final reserva = await repo.obtenerPorId('11');

    expect(reserva.valorONull!.id, '11');
    expect(rutas, ['/api/v1/reservas/lector/3', '/api/v1/reservas']);
  });
}
