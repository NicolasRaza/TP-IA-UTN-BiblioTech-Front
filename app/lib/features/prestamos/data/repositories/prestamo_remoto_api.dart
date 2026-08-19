import '../../../../core/error/result.dart';
import '../../domain/entities/prestamo.dart';
import '../../domain/repositories/prestamo_remoto.dart';
import '../datasources/prestamo_api_datasource.dart';

/// Implementación del [PrestamoRemoto] sobre la API del backend.
class PrestamoRemotoApi implements PrestamoRemoto {
  const PrestamoRemotoApi(this._api);

  final PrestamoApiDataSource _api;

  @override
  Future<Result<Prestamo>> prestar({
    required String lectorId,
    required String qrEjemplar,
  }) =>
      _api.prestar(lectorId: lectorId, qrEjemplar: qrEjemplar);

  @override
  Future<Result<Prestamo>> devolver(String qrEjemplar) =>
      _api.devolver(qrEjemplar);
}
