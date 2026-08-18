import '../../../../core/error/result.dart';
import '../entities/configuracion_biblioteca.dart';

/// Contrato de acceso a los parámetros de la biblioteca.
abstract interface class ConfiguracionRepository {
  Future<Result<ConfiguracionBiblioteca>> obtener();

  Future<Result<ConfiguracionBiblioteca>> guardar(
      ConfiguracionBiblioteca configuracion);
}
