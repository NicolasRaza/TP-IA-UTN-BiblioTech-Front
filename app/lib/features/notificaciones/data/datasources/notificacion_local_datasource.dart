import '../../../../core/error/result.dart';
import '../../../../core/storage/coleccion_json.dart';
import '../../../../core/storage/key_value_store.dart';
import '../../domain/entities/notificacion.dart';
import '../models/notificacion_model.dart';

/// Acceso al almacenamiento local de las notificaciones.
abstract interface class NotificacionLocalDataSource {
  Result<List<NotificacionModel>> leer();
  Result<void> guardar(List<Notificacion> notificaciones);
}

class NotificacionLocalDataSourceImpl implements NotificacionLocalDataSource {
  NotificacionLocalDataSourceImpl(KeyValueStore store)
      : _coleccion = ColeccionJson<NotificacionModel>(
          store: store,
          clave: ClavesAlmacenamiento.notificaciones,
          desdeJson: NotificacionModel.fromJson,
          aJson: (n) => n.toJson(),
        );

  final ColeccionJson<NotificacionModel> _coleccion;

  @override
  Result<List<NotificacionModel>> leer() => _coleccion.leer();

  @override
  Result<void> guardar(List<Notificacion> notificaciones) => _coleccion
      .escribir(notificaciones.map(NotificacionModel.fromEntity).toList());
}
