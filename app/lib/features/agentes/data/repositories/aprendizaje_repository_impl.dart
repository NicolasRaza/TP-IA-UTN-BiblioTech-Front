import '../../../../core/error/result.dart';
import '../../domain/entities/recomendacion.dart';
import '../../domain/repositories/aprendizaje_repository.dart';
import '../datasources/aprendizaje_local_datasource.dart';

/// Implementación del [AprendizajeRepository] sobre el almacenamiento local.
class AprendizajeRepositoryImpl implements AprendizajeRepository {
  const AprendizajeRepositoryImpl(this._local);

  final AprendizajeLocalDataSource _local;

  @override
  Future<Result<List<Correccion>>> obtenerCorrecciones() async =>
      _local.leerCorrecciones().map((c) => c.cast<Correccion>());

  @override
  Future<Result<void>> registrarCorreccion(Correccion correccion) async {
    final leidas = _local.leerCorrecciones();
    if (leidas case Fallo(:final failure)) return Fallo(failure);

    return _local.guardarCorrecciones([...leidas.valorONull!, correccion]);
  }

  @override
  Future<Result<List<InteraccionLector>>> obtenerInteracciones() async =>
      _local.leerInteracciones().map((i) => i.cast<InteraccionLector>());

  @override
  Future<Result<void>> registrarInteraccion(
      InteraccionLector interaccion) async {
    final leidas = _local.leerInteracciones();
    if (leidas case Fallo(:final failure)) return Fallo(failure);

    return _local.guardarInteracciones([...leidas.valorONull!, interaccion]);
  }
}
