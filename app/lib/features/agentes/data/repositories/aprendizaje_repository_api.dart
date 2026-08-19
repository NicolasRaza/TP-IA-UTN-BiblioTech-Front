import '../../../../core/error/result.dart';
import '../../domain/entities/recomendacion.dart';
import '../../domain/repositories/aprendizaje_repository.dart';
import '../datasources/aprendizaje_api_datasource.dart';

/// La memoria del Agente de Aprendizaje, servida por el backend.
///
/// Es la feature que más gana con la mudanza: en el dispositivo, cada lector
/// alimentaba una señal que sólo él veía, así que el ciclo de
/// retroalimentación de la spec §5 nunca llegaba a cerrarse sobre el conjunto.
class AprendizajeRepositoryApi implements AprendizajeRepository {
  const AprendizajeRepositoryApi(this._api);

  final AprendizajeApiDataSource _api;

  @override
  Future<Result<List<Correccion>>> obtenerCorrecciones() =>
      _api.listarCorrecciones();

  @override
  Future<Result<void>> registrarCorreccion(Correccion correccion) =>
      _api.registrarCorreccion(correccion);

  @override
  Future<Result<List<InteraccionLector>>> obtenerInteracciones() =>
      _api.listarInteracciones();

  @override
  Future<Result<void>> registrarInteraccion(InteraccionLector interaccion) =>
      _api.registrarInteraccion(interaccion);
}
