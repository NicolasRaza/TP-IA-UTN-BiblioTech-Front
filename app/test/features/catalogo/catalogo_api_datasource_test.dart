import 'dart:convert';

import 'package:bibliotech/core/api/cliente_api.dart';
import 'package:bibliotech/features/catalogo/data/datasources/catalogo_api_datasource.dart';
import 'package:bibliotech/features/catalogo/domain/entities/ejemplar.dart';
import 'package:bibliotech/features/catalogo/domain/entities/libro.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// Contrato contra `/api/v1/catalogo`, verificado con un cliente HTTP falso.
///
/// Los cuerpos que se responden acá son los que documenta el OpenAPI del
/// backend (`TituloResponse`, `EjemplarResponse`), así que si el servidor
/// cambia el contrato esto se rompe en CI y no en la demo.
void main() {
  const baseUrl = 'https://backend.test';

  CatalogoApiDataSourceHttp construir(MockClient cliente) =>
      CatalogoApiDataSourceHttp(ClienteApi(
        baseUrl: baseUrl,
        token: () => 'jwt',
        cliente: cliente,
      ));

  CatalogoApiDataSourceHttp queResponde(Object? json, {int status = 200}) =>
      construir(
          MockClient((_) async => http.Response(jsonEncode(json), status)));

  Map<String, Object?> tituloJson({
    int id = 7,
    String estado = 'validado',
    int total = 3,
    int disponibles = 2,
  }) =>
      {
        'id': id,
        'isbn': '9788437604947',
        'titulo': 'Rayuela',
        'autores': 'Julio Cortázar',
        'editorial': 'Sudamericana',
        'anio_edicion': '1963',
        'lugar_edicion': 'Buenos Aires',
        'idioma': 'es',
        'genero': 'Novela',
        'sinopsis': 'Una novela para leer de muchas maneras.',
        'portada_url': '',
        'paginas': 736,
        'estado_validacion': estado,
        'total_ejemplares': total,
        'ejemplares_disponibles': disponibles,
        'creado_en': '2026-03-01T10:30:00',
      };

  group('buscarTitulos', () {
    test('traduce el vocabulario de la API al del dominio', () async {
      final resultado = await queResponde([tituloJson()]).buscarTitulos();

      final libro = resultado.valorONull!.single;
      expect(libro.id, '7');
      expect(libro.titulo, 'Rayuela');
      // La API lo llama `autores`; el dominio, `autor`.
      expect(libro.autor, 'Julio Cortázar');
      // Y guarda el año como texto libre.
      expect(libro.anio, 1963);
      expect(libro.validado, isTrue);
      expect(libro.fechaAlta, DateTime(2026, 3, 1, 10, 30));
    });

    test('guarda los conteos del servidor sin inventar ejemplares', () async {
      // La ruta de listado no trae los ejemplares. Rellenarlos con objetos de
      // relleno mostraría etiquetas QR que no existen del otro lado.
      final resultado =
          await queResponde([tituloJson(total: 5, disponibles: 2)])
              .buscarTitulos();

      final libro = resultado.valorONull!.single;
      expect(libro.ejemplares, isEmpty);
      expect(libro.totalEjemplares, 5);
      expect(libro.ejemplaresDisponibles, 2);
      expect(libro.hayDisponible, isTrue);
    });

    test('sin ejemplares libres el título no figura como disponible', () async {
      final resultado =
          await queResponde([tituloJson(total: 4, disponibles: 0)])
              .buscarTitulos();

      expect(resultado.valorONull!.single.hayDisponible, isFalse);
    });

    test('manda texto y género como query, y omite el género "Todos"',
        () async {
      late http.Request enviado;
      final datasource = construir(MockClient((peticion) async {
        enviado = peticion;
        return http.Response('[]', 200);
      }));

      await datasource.buscarTitulos(texto: ' borges ', genero: 'Todos');

      expect(enviado.url.path, '/api/v1/catalogo/titulos');
      expect(enviado.url.queryParameters, {'q': 'borges'});
    });
  });

  group('ejemplares', () {
    test('conserva el código QR que emitió el servidor', () async {
      // El QR local se deriva del id; el del backend no se puede derivar y es
      // lo único que resuelve contra GET /ejemplares/qr/{codigo}.
      final resultado = await queResponde({
        'id': 42,
        'titulo_id': 7,
        'codigo_qr': 'SGB-A1B2C3D4E5F6',
        'condicion': 'nuevo',
        'estado': 'prestado',
        'ubicacion_fisica': 'Estante 3',
        'activo': true,
        'fecha_ingreso': '2026-03-02T09:00:00',
      }).buscarEjemplarPorQr('SGB-A1B2C3D4E5F6');

      final ejemplar = resultado.valorONull!;
      expect(ejemplar.qr, 'SGB-A1B2C3D4E5F6');
      expect(ejemplar.id, '42');
      expect(ejemplar.libroId, '7');
      expect(ejemplar.estado, EstadoEjemplar.prestado);
      // El backend tiene cuatro condiciones y el dominio tres.
      expect(ejemplar.condicion, CondicionEjemplar.bueno);
    });

    test('pide la lista por la ruta del título', () async {
      late http.Request enviado;
      final datasource = construir(MockClient((peticion) async {
        enviado = peticion;
        return http.Response('[]', 200);
      }));

      await datasource.listarEjemplares('7');

      expect(enviado.url.path, '/api/v1/catalogo/titulos/7/ejemplares');
    });

    test('el alta manda la condición en el vocabulario del backend', () async {
      late http.Request enviado;
      final datasource = construir(MockClient((peticion) async {
        enviado = peticion;
        return http.Response(
          jsonEncode({
            'id': 1,
            'titulo_id': 7,
            'codigo_qr': 'SGB-X',
            'condicion': 'deteriorado',
            'estado': 'disponible',
            'ubicacion_fisica': null,
            'activo': true,
            'fecha_ingreso': '2026-03-02T09:00:00',
          }),
          201,
        );
      }));

      await datasource.crearEjemplar(
        libroId: '7',
        condicion: CondicionEjemplar.malo,
      );

      expect(jsonDecode(enviado.body),
          {'titulo_id': 7, 'condicion': 'deteriorado'});
    });
  });

  group('alta y validación de títulos', () {
    test('el alta manda el ISBN; la edición no, porque el backend no lo cambia',
        () async {
      final cuerpos = <Map<String, Object?>>[];
      final datasource = construir(MockClient((peticion) async {
        cuerpos.add(jsonDecode(peticion.body) as Map<String, Object?>);
        return http.Response(jsonEncode(tituloJson()), 200);
      }));

      final libro = Libro(
        id: '7',
        titulo: 'Rayuela',
        autor: 'Julio Cortázar',
        isbn: '9788437604947',
        anio: 1963,
        fechaAlta: DateTime(2026, 3, 1),
      );

      await datasource.crearTitulo(libro);
      await datasource.editarTitulo(libro);

      expect(cuerpos.first['isbn'], '9788437604947');
      expect(cuerpos.last.containsKey('isbn'), isFalse);
      // El año viaja como texto, que es como lo guarda el backend.
      expect(cuerpos.first['anio_edicion'], '1963');
      expect(cuerpos.first['autores'], 'Julio Cortázar');
    });

    test('un id que no es del backend se corta antes de salir a la red',
        () async {
      var huboPeticion = false;
      final datasource = construir(MockClient((_) async {
        huboPeticion = true;
        return http.Response('{}', 200);
      }));

      // `lib-abc` es un id de la semilla local: del otro lado no existe.
      final resultado = await datasource.obtenerTitulo('lib-abc');

      expect(huboPeticion, isFalse);
      expect(resultado.esFallo, isTrue);
    });
  });
}
