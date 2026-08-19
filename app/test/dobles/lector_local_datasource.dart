import 'package:bibliotech/core/error/result.dart';
import 'coleccion_json.dart';
import 'package:bibliotech/core/storage/key_value_store.dart';
import 'package:bibliotech/features/lectores/domain/entities/lector.dart';
import 'package:bibliotech/features/lectores/data/models/lector_model.dart';

/// Acceso al almacenamiento local del padrón de personas.
abstract interface class LectorLocalDataSource {
  Result<List<LectorModel>> leer();
  Result<void> guardar(List<Lector> usuarios);
}

class LectorLocalDataSourceImpl implements LectorLocalDataSource {
  LectorLocalDataSourceImpl(KeyValueStore store)
      : _coleccion = ColeccionJson<LectorModel>(
          store: store,
          clave: ClavesAlmacenamiento.lectores,
          desdeJson: LectorModel.fromJson,
          aJson: (l) => l.toJson(),
        );

  final ColeccionJson<LectorModel> _coleccion;

  @override
  Result<List<LectorModel>> leer() => _coleccion.leer();

  @override
  Result<void> guardar(List<Lector> usuarios) =>
      _coleccion.escribir(usuarios.map(LectorModel.fromEntity).toList());
}
