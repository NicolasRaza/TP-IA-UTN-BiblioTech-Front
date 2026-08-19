import 'dart:convert';

import 'package:bibliotech/core/api/cliente_api.dart';
import 'package:bibliotech/features/administracion/data/datasources/auditoria_api_datasource.dart';
import 'package:bibliotech/features/administracion/data/datasources/configuracion_api_datasource.dart';
import 'package:bibliotech/features/administracion/domain/entities/configuracion_biblioteca.dart';
import 'package:bibliotech/features/administracion/domain/entities/evento_auditoria.dart';
import 'package:bibliotech/features/agentes/data/datasources/aprendizaje_api_datasource.dart';
import 'package:bibliotech/features/agentes/domain/entities/recomendacion.dart';
import 'package:bibliotech/features/lectores/domain/entities/lector.dart';
import 'package:bibliotech/features/notificaciones/data/datasources/notificacion_api_datasource.dart';
import 'package:bibliotech/features/notificaciones/domain/entities/notificacion.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// Contrato con `/api/v1` para notificaciones, auditoría, configuración y
/// aprendizaje, verificado con un cliente HTTP falso.
///
/// Los cuerpos que se responden acá no están inventados: son las respuestas
/// que devuelve el backend, capturadas corriéndolo. Si el servidor cambia el
/// contrato, esto se rompe en CI y no en la demo.
void main() {
  const baseUrl = 'https://backend.test';

  ClienteApi construir(MockClient cliente) => ClienteApi(
        baseUrl: baseUrl,
        token: () => 'jwt',
        cliente: cliente,
      );

  ClienteApi queResponde(Object? json, {int status = 200}) =>
      construir(MockClient((_) async => http.Response(
            jsonEncode(json),
            status,
            headers: {'content-type': 'application/json; charset=utf-8'},
          )));

  // ── Notificaciones ─────────────────────────────────────────────────────────

  group('notificaciones', () {
    Map<String, Object?> avisoJson({bool leida = false}) => {
          'id': 1,
          'lector_id': 7,
          'tipo': 'vencimiento_proximo',
          'titulo': 'Vence pronto',
          'descripcion': 'Tu préstamo vence en 3 días',
          'leida': leida,
          'creado_en': '2026-08-19T22:15:37.080910',
        };

    test('traduce el aviso al vocabulario del dominio', () async {
      final datasource =
          NotificacionApiDataSourceHttp(queResponde([avisoJson()]));

      final aviso = (await datasource.listar('7')).valorONull!.single;

      expect(aviso.id, '1');
      expect(aviso.lectorId, '7');
      expect(aviso.tipo, TipoNotificacion.vencimientoProximo);
      expect(aviso.titulo, 'Vence pronto');
      expect(aviso.leida, isFalse);
      expect(aviso.fecha, DateTime.parse('2026-08-19T22:15:37.080910'));
    });

    test('el alta manda el lector como número y el tipo como código', () async {
      late http.Request enviado;
      final datasource = NotificacionApiDataSourceHttp(construir(
        MockClient((p) async {
          enviado = p;
          return http.Response(jsonEncode(avisoJson()), 201);
        }),
      ));

      await datasource.crear(Notificacion(
        id: '',
        lectorId: '7',
        tipo: TipoNotificacion.reservaDisponible,
        titulo: 'Tu reserva está lista',
        descripcion: 'Pasá a retirarla',
        fecha: DateTime(2026, 8, 19),
      ));

      expect(enviado.url.path, '/api/v1/notificaciones');
      expect(jsonDecode(enviado.body), {
        'lector_id': 7,
        'tipo': 'reserva_disponible',
        'titulo': 'Tu reserva está lista',
        'descripcion': 'Pasá a retirarla',
      });
    });

    test('marcar leída va por la ruta del aviso', () async {
      late http.Request enviado;
      final datasource = NotificacionApiDataSourceHttp(construir(
        MockClient((p) async {
          enviado = p;
          return http.Response(jsonEncode(avisoJson(leida: true)), 200);
        }),
      ));

      await datasource.marcarLeida('1');

      expect(enviado.method, 'PATCH');
      expect(enviado.url.path, '/api/v1/notificaciones/1/leida');
    });
  });

  // ── Auditoría ──────────────────────────────────────────────────────────────

  group('auditoría', () {
    Map<String, Object?> eventoJson({Object? usuarioId = 1}) => {
          'id': 1,
          'tipo': 'alta_libro',
          'descripcion': 'Se dio de alta Rayuela',
          'usuario_id': usuarioId,
          'creado_en': '2026-08-19T22:15:37.105628',
        };

    test('traduce el evento al vocabulario del dominio', () async {
      final datasource =
          AuditoriaApiDataSourceHttp(queResponde([eventoJson()]));

      final evento = (await datasource.listar()).valorONull!.single;

      expect(evento.id, '1');
      expect(evento.tipo, TipoEventoAuditoria.altaLibro);
      expect(evento.descripcion, 'Se dio de alta Rayuela');
      expect(evento.usuarioId, '1');
    });

    test('un evento que escribió el servidor no tiene autor', () async {
      // Es el caso del autorregistro: la traza la asienta el backend porque el
      // cliente no tiene token con el cual hacerlo.
      final datasource = AuditoriaApiDataSourceHttp(
          queResponde([eventoJson(usuarioId: null)]));

      final evento = (await datasource.listar()).valorONull!.single;

      expect(evento.usuarioId, isEmpty);
    });

    test('el alta no manda el autor: lo pone el servidor desde el token',
        () async {
      late http.Request enviado;
      final datasource = AuditoriaApiDataSourceHttp(construir(
        MockClient((p) async {
          enviado = p;
          return http.Response(jsonEncode(eventoJson()), 201);
        }),
      ));

      await datasource.registrar(
        tipo: TipoEventoAuditoria.reimpresionQr,
        descripcion: 'Se reimprimió la etiqueta SGB-000012',
      );

      expect(jsonDecode(enviado.body), {
        'tipo': 'reimpresion_qr',
        'descripcion': 'Se reimprimió la etiqueta SGB-000012',
      });
    });
  });

  // ── Configuración ──────────────────────────────────────────────────────────

  group('configuración', () {
    final configJson = {
      'plazo_prestamo_dias': {
        'infantil': 7,
        'adolescente': 7,
        'adulto': 14,
        'docente': 21,
        'institucional': 30,
      },
      'limite_ejemplares': {
        'infantil': 2,
        'adolescente': 2,
        'adulto': 3,
        'docente': 5,
        'institucional': 5,
      },
      'limite_reservas': {
        'infantil': 2,
        'adolescente': 2,
        'adulto': 3,
        'docente': 5,
        'institucional': 5,
      },
      'plazo_retiro_reserva_horas': 48,
      'multa_por_dia_demora': 100,
      'recordatorio_antes_dias': 3,
      'peso_historial_recomendacion': 0.7,
      'min_prestamos_para_historial': 5,
      'edad_mayoria_edad': 18,
      'actualizado_en': '2026-08-19T22:15:37.122931',
    };

    test('las categorías del backend se traducen a las del dominio', () async {
      final datasource =
          ConfiguracionApiDataSourceHttp(queResponde(configJson));

      final cfg = (await datasource.obtener()).valorONull!;

      expect(cfg.plazoPara(CategoriaLector.menor), 7,
          reason: '`infantil` del backend es `menor` acá');
      expect(cfg.plazoPara(CategoriaLector.adulto), 14);
      expect(cfg.plazoPara(CategoriaLector.docente), 21);
      expect(cfg.plazoPara(CategoriaLector.personal), 30,
          reason: '`institucional` del backend es `personal` acá');
      expect(cfg.plazoPara(CategoriaLector.senior), 14,
          reason: 'el backend no tiene senior: se le aplica lo del adulto');
      expect(cfg.limiteEjemplaresPara(CategoriaLector.docente), 5);
      expect(cfg.multaPorDiaDemora, 100);
      expect(cfg.pesoHistorialRecomendacion, 0.7);
    });

    test('si el backend deja de informar un parámetro rige el de la spec',
        () async {
      final datasource = ConfiguracionApiDataSourceHttp(queResponde({
        'plazo_prestamo_dias': configJson['plazo_prestamo_dias'],
        'actualizado_en': '2026-08-19T22:15:37.122931',
      }));

      final cfg = (await datasource.obtener()).valorONull!;

      expect(cfg.plazoRetiroReservaHoras, 48,
          reason: 'un cero acá negaría toda operación');
      expect(cfg.multaPorDiaDemora, 100);
    });

    test('guardar manda el mapa entero por PUT', () async {
      late http.Request enviado;
      final datasource = ConfiguracionApiDataSourceHttp(construir(
        MockClient((p) async {
          enviado = p;
          return http.Response(jsonEncode(configJson), 200);
        }),
      ));

      await datasource.guardar(const ConfiguracionBiblioteca());

      expect(enviado.method, 'PUT');
      expect(enviado.url.path, '/api/v1/configuracion');
      final cuerpo = jsonDecode(enviado.body) as Map<String, Object?>;
      expect(cuerpo['plazo_prestamo_dias'], {
        'infantil': 7,
        'adolescente': 7,
        'adulto': 14,
        'docente': 21,
        'institucional': 30,
      });
      expect(cuerpo['multa_por_dia_demora'], 100);
    });
  });

  // ── Aprendizaje ────────────────────────────────────────────────────────────

  group('aprendizaje', () {
    test('traduce interacciones y correcciones', () async {
      final interacciones = AprendizajeApiDataSourceHttp(queResponde([
        {
          'id': 1,
          'lector_id': 7,
          'titulo_id': 3,
          'tipo': 'vista',
          'creado_en': '2026-08-19T22:15:37.139005',
        }
      ]));
      final leida =
          (await interacciones.listarInteracciones()).valorONull!.single;
      expect(leida.lectorId, '7');
      expect(leida.libroId, '3', reason: 'el título del backend es el libro');
      expect(leida.tipo, 'vista');

      final correcciones = AprendizajeApiDataSourceHttp(queResponde([
        {
          'id': 1,
          'campo': 'autor',
          'valor_sugerido': 'J. Cortazar',
          'valor_final': 'Julio Cortázar',
          'usuario_id': 1,
          'creado_en': '2026-08-19T22:15:37.153271',
        }
      ]));
      final correccion =
          (await correcciones.listarCorrecciones()).valorONull!.single;
      expect(correccion.campo, 'autor');
      expect(correccion.valorFinal, 'Julio Cortázar');
    });

    test('registrar una interacción manda los ids como números', () async {
      late http.Request enviado;
      final datasource = AprendizajeApiDataSourceHttp(construir(
        MockClient((p) async {
          enviado = p;
          return http.Response('{}', 201);
        }),
      ));

      await datasource.registrarInteraccion(InteraccionLector(
        lectorId: '7',
        libroId: '3',
        tipo: 'reserva',
        fecha: DateTime(2026, 8, 19),
      ));

      expect(jsonDecode(enviado.body),
          {'lector_id': 7, 'titulo_id': 3, 'tipo': 'reserva'});
    });
  });
}
