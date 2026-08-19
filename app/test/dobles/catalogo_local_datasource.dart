import 'package:bibliotech/core/error/result.dart';
import 'coleccion_json.dart';
import 'package:bibliotech/core/storage/key_value_store.dart';
import 'package:bibliotech/features/catalogo/domain/entities/libro.dart';
import 'package:bibliotech/features/catalogo/data/models/libro_model.dart';

/// Acceso al almacenamiento local del catálogo.
///
/// Es la única clase de todo el feature que sabe que los libros viven en un
/// `KeyValueStore` serializados como JSON.
abstract interface class CatalogoLocalDataSource {
  Result<List<LibroModel>> leer();
  Result<void> guardar(List<Libro> libros);
}

class CatalogoLocalDataSourceImpl implements CatalogoLocalDataSource {
  CatalogoLocalDataSourceImpl(KeyValueStore store)
      : _coleccion = ColeccionJson<LibroModel>(
          store: store,
          clave: ClavesAlmacenamiento.libros,
          desdeJson: LibroModel.fromJson,
          aJson: (l) => l.toJson(),
        );

  final ColeccionJson<LibroModel> _coleccion;

  @override
  Result<List<LibroModel>> leer() => _coleccion.leer();

  @override
  Result<void> guardar(List<Libro> libros) =>
      _coleccion.escribir(libros.map(LibroModel.fromEntity).toList());
}
