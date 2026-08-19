import 'package:bibliotech/core/error/result.dart';
import 'coleccion_json.dart';
import 'package:bibliotech/core/storage/key_value_store.dart';
import 'package:bibliotech/features/prestamos/domain/entities/prestamo.dart';
import 'package:bibliotech/features/prestamos/data/models/prestamo_model.dart';

/// Acceso al almacenamiento local de los préstamos.
abstract interface class PrestamoLocalDataSource {
  Result<List<PrestamoModel>> leer();
  Result<void> guardar(List<Prestamo> prestamos);
}

class PrestamoLocalDataSourceImpl implements PrestamoLocalDataSource {
  PrestamoLocalDataSourceImpl(KeyValueStore store)
      : _coleccion = ColeccionJson<PrestamoModel>(
          store: store,
          clave: ClavesAlmacenamiento.prestamos,
          desdeJson: PrestamoModel.fromJson,
          aJson: (p) => p.toJson(),
        );

  final ColeccionJson<PrestamoModel> _coleccion;

  @override
  Result<List<PrestamoModel>> leer() => _coleccion.leer();

  @override
  Result<void> guardar(List<Prestamo> prestamos) =>
      _coleccion.escribir(prestamos.map(PrestamoModel.fromEntity).toList());
}
