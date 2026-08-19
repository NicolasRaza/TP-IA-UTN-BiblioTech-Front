import 'dart:convert';

import 'package:bibliotech/core/api/cliente_api.dart';
import 'package:bibliotech/features/catalogo/data/datasources/catalogo_api_datasource.dart';
import 'package:bibliotech/features/catalogo/data/repositories/catalogo_repository_api.dart';
import 'package:bibliotech/features/catalogo/domain/entities/ejemplar.dart';
import 'package:bibliotech/features/catalogo/domain/usecases/agregar_ejemplar.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// El alta de un ejemplar desde la UI tiene que terminar en
/// `POST /api/v1/catalogo/ejemplares`, la misma ruta que funciona por Postman.
///
/// Antes el caso de uso armaba el ejemplar en memoria y guardaba el título
/// entero con la lista ampliada: contra la API eso caía en `PATCH /titulos`,
/// que no da de alta ejemplares, así que el alta fallaba o no hacía nada.
void main() {
  const baseUrl = 'https://backend.test';

  test('el alta de un ejemplar va por POST /ejemplares con el título y la '
      'condición', () async {
    final peticiones = <http.Request>[];
    final cliente = MockClient((peticion) async {
      peticiones.add(peticion);
      return http.Response(
        jsonEncode({
          'id': 12,
          'titulo_id': 7,
          'codigo_qr': 'SGB-000012',
          'condicion': 'regular',
          'estado': 'disponible',
          'ubicacion_fisica': null,
          'activo': true,
          'fecha_ingreso': '2026-03-02T09:00:00',
        }),
        201,
      );
    });

    final usecase = AgregarEjemplar(
      catalogoRepository: CatalogoRepositoryApi(
        CatalogoApiDataSourceHttp(ClienteApi(
          baseUrl: baseUrl,
          token: () => 'jwt',
          cliente: cliente,
        )),
      ),
    );

    final resultado = await usecase(const AgregarEjemplarParams(
      libroId: '7',
      condicion: CondicionEjemplar.regular,
    ));

    expect(peticiones, hasLength(1),
        reason: 'el alta es un solo request, no una relectura del título');
    final enviado = peticiones.single;
    expect(enviado.method, 'POST');
    expect(enviado.url.path, '/api/v1/catalogo/ejemplares');
    expect(jsonDecode(enviado.body), {'titulo_id': 7, 'condicion': 'regular'});

    final ejemplar = resultado.valorONull!;
    expect(ejemplar.id, '12',
        reason: 'el id lo asigna el backend, no la app');
    expect(ejemplar.qr, 'SGB-000012',
        reason: 'la etiqueta que se imprime es la que devolvió el backend');
    expect(ejemplar.condicion, CondicionEjemplar.regular);
    expect(ejemplar.estado, EstadoEjemplar.disponible);
  });

  test('un rechazo del backend llega como fallo al caso de uso', () async {
    final usecase = AgregarEjemplar(
      catalogoRepository: CatalogoRepositoryApi(
        CatalogoApiDataSourceHttp(ClienteApi(
          baseUrl: baseUrl,
          token: () => 'jwt',
          cliente: MockClient((_) async => http.Response(
                jsonEncode({'detail': 'El título no existe'}),
                404,
              )),
        )),
      ),
    );

    final resultado = await usecase(const AgregarEjemplarParams(
      libroId: '999',
      condicion: CondicionEjemplar.bueno,
    ));

    expect(resultado.esExito, isFalse);
  });
}
