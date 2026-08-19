import '../../../../core/api/cliente_api.dart';
import '../../../../core/api/mapeo_api.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/error/result.dart';
import '../../domain/entities/notificacion.dart';

/// Acceso a los avisos del backend SGB (`/api/v1/notificaciones`).
///
/// El backend decide de quién son: un lector autenticado siempre opera sobre
/// los suyos y pedir los de otro es 403, no una lista vacía. Por eso [listar]
/// acepta el id pero el servidor puede ignorarlo cuando quien pregunta es el
/// propio destinatario.
abstract interface class NotificacionApiDataSource {
  Future<Result<List<Notificacion>>> listar(String lectorId);

  Future<Result<Notificacion>> crear(Notificacion notificacion);

  Future<Result<void>> marcarLeida(String notificacionId);

  Future<Result<void>> marcarTodasLeidas(String lectorId);
}

class NotificacionApiDataSourceHttp implements NotificacionApiDataSource {
  const NotificacionApiDataSourceHttp(this._api);

  final ClienteApi _api;

  @override
  Future<Result<List<Notificacion>>> listar(String lectorId) {
    final id = idHaciaApi(lectorId);
    if (id == null) return _sinIdRemoto();
    return _api.get<List<Notificacion>>(
      '/api/v1/notificaciones',
      query: {'lector_id': '$id'},
      leer: (json) => (json as List<Object?>? ?? const [])
          .map((e) => _notificacionDesdeApi(e as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  Future<Result<Notificacion>> crear(Notificacion notificacion) {
    final id = idHaciaApi(notificacion.lectorId);
    if (id == null) return _sinIdRemoto();
    return _api.post<Notificacion>(
      '/api/v1/notificaciones',
      cuerpo: {
        'lector_id': id,
        'tipo': notificacion.tipo.code,
        'titulo': notificacion.titulo,
        'descripcion': notificacion.descripcion,
      },
      leer: (json) => _notificacionDesdeApi(json as Map<String, dynamic>),
    );
  }

  @override
  Future<Result<void>> marcarLeida(String notificacionId) {
    final id = idHaciaApi(notificacionId);
    if (id == null) return _sinIdRemoto();
    return _api.patch<void>(
      '/api/v1/notificaciones/$id/leida',
      leer: (_) {},
    );
  }

  @override
  Future<Result<void>> marcarTodasLeidas(String lectorId) {
    final id = idHaciaApi(lectorId);
    if (id == null) return _sinIdRemoto();
    return _api.post<void>(
      '/api/v1/notificaciones/marcar-leidas?lector_id=$id',
      leer: (_) {},
    );
  }

  static Future<Result<T>> _sinIdRemoto<T>() => Future.value(
        const Fallo(
            NoEncontradoFailure('Ese registro no existe en el servidor')),
      );
}

Notificacion _notificacionDesdeApi(Map<String, dynamic> json) => Notificacion(
      id: idDesdeApi(json['id']),
      lectorId: idDesdeApi(json['lector_id']),
      tipo: TipoNotificacion.fromCode(json['tipo'] as String?),
      titulo: (json['titulo'] as String?) ?? '',
      descripcion: (json['descripcion'] as String?) ?? '',
      fecha: fechaDesdeApi(json['creado_en'], DateTime.now()),
      leida: (json['leida'] as bool?) ?? false,
    );
