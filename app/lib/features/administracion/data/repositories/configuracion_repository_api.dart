import '../../../../core/error/result.dart';
import '../../domain/entities/configuracion_biblioteca.dart';
import '../../domain/repositories/configuracion_repository.dart';
import '../datasources/configuracion_api_datasource.dart';

/// Los parámetros de la biblioteca, servidos por el backend.
///
/// Que vivan en el servidor es lo que hace que un cambio de plazo valga para
/// toda la biblioteca y no sólo para el navegador donde se tocó.
class ConfiguracionRepositoryApi implements ConfiguracionRepository {
  const ConfiguracionRepositoryApi(this._api);

  final ConfiguracionApiDataSource _api;

  @override
  Future<Result<ConfiguracionBiblioteca>> obtener() => _api.obtener();

  @override
  Future<Result<ConfiguracionBiblioteca>> guardar(
    ConfiguracionBiblioteca configuracion,
  ) =>
      _api.guardar(configuracion);
}
