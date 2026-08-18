import '../../../../core/error/result.dart';
import '../../../../core/storage/coleccion_json.dart';
import '../../../../core/storage/key_value_store.dart';
import '../../domain/entities/reserva.dart';
import '../models/reserva_model.dart';

/// Acceso al almacenamiento local de las reservas.
abstract interface class ReservaLocalDataSource {
  Result<List<ReservaModel>> leer();
  Result<void> guardar(List<Reserva> reservas);
}

class ReservaLocalDataSourceImpl implements ReservaLocalDataSource {
  ReservaLocalDataSourceImpl(KeyValueStore store)
      : _coleccion = ColeccionJson<ReservaModel>(
          store: store,
          clave: ClavesAlmacenamiento.reservas,
          desdeJson: ReservaModel.fromJson,
          aJson: (r) => r.toJson(),
        );

  final ColeccionJson<ReservaModel> _coleccion;

  @override
  Result<List<ReservaModel>> leer() => _coleccion.leer();

  @override
  Result<void> guardar(List<Reserva> reservas) =>
      _coleccion.escribir(reservas.map(ReservaModel.fromEntity).toList());
}
