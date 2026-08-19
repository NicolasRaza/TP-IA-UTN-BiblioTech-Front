import '../../../../core/api/cliente_api.dart';
import '../../../../core/api/mapeo_api.dart';
import '../../../../core/error/result.dart';
import '../../domain/entities/evento_auditoria.dart';

/// Acceso al registro de auditoría del backend (`/api/v1/auditoria`).
///
/// Es de sólo lectura y alta: la traza es append-only, así que no hay `PATCH`
/// ni `DELETE` que exponer. Las dos rutas exigen rol bibliotecario o
/// administrador.
abstract interface class AuditoriaApiDataSource {
  Future<Result<List<EventoAuditoria>>> listar({int limite});

  /// `POST /auditoria` — el autor no viaja en el cuerpo: lo toma el servidor
  /// del token, porque quién hizo qué no es algo que el cliente pueda declarar
  /// sobre sí mismo.
  Future<Result<EventoAuditoria>> registrar({
    required TipoEventoAuditoria tipo,
    required String descripcion,
  });
}

class AuditoriaApiDataSourceHttp implements AuditoriaApiDataSource {
  const AuditoriaApiDataSourceHttp(this._api);

  final ClienteApi _api;

  @override
  Future<Result<List<EventoAuditoria>>> listar({
    int limite = EventoAuditoria.maximoRetenido,
  }) =>
      _api.get<List<EventoAuditoria>>(
        '/api/v1/auditoria',
        query: {'limite': '$limite'},
        leer: (json) => (json as List<Object?>? ?? const [])
            .map((e) => _eventoDesdeApi(e as Map<String, dynamic>))
            .toList(),
      );

  @override
  Future<Result<EventoAuditoria>> registrar({
    required TipoEventoAuditoria tipo,
    required String descripcion,
  }) =>
      _api.post<EventoAuditoria>(
        '/api/v1/auditoria',
        cuerpo: {'tipo': tipo.code, 'descripcion': descripcion},
        leer: (json) => _eventoDesdeApi(json as Map<String, dynamic>),
      );
}

EventoAuditoria _eventoDesdeApi(Map<String, dynamic> json) => EventoAuditoria(
      id: idDesdeApi(json['id']),
      tipo: TipoEventoAuditoria.fromCode(json['tipo'] as String?),
      descripcion: (json['descripcion'] as String?) ?? '',
      // El backend admite eventos sin autor —los que escribe él mismo, como la
      // traza del autorregistro público—, y el dominio los representa con el
      // id vacío en vez de inventar un usuario.
      usuarioId:
          json['usuario_id'] == null ? '' : idDesdeApi(json['usuario_id']),
      fecha: fechaDesdeApi(json['creado_en'], DateTime.now()),
    );
