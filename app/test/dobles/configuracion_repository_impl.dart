import 'package:bibliotech/core/error/result.dart';
import 'package:bibliotech/features/administracion/domain/entities/configuracion_biblioteca.dart';
import 'package:bibliotech/features/administracion/domain/repositories/configuracion_repository.dart';
import 'administracion_local_datasource.dart';

/// Implementación del [ConfiguracionRepository] sobre el almacenamiento local.
class ConfiguracionRepositoryImpl implements ConfiguracionRepository {
  const ConfiguracionRepositoryImpl(this._local);

  final AdministracionLocalDataSource _local;

  @override
  Future<Result<ConfiguracionBiblioteca>> obtener() async =>
      _local.leerConfiguracion();

  @override
  Future<Result<ConfiguracionBiblioteca>> guardar(
      ConfiguracionBiblioteca configuracion) async {
    final guardado = _local.guardarConfiguracion(configuracion);
    if (guardado case Fallo(:final failure)) return Fallo(failure);
    return Exito(configuracion);
  }
}
