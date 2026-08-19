import '../../../../core/error/result.dart';
import '../../domain/entities/reserva.dart';
import '../../domain/repositories/reserva_remota.dart';
import '../datasources/reserva_api_datasource.dart';

/// Implementación de [ReservaRemota] sobre la API del backend.
class ReservaRemotaApi implements ReservaRemota {
  const ReservaRemotaApi(this._api);

  final ReservaApiDataSource _api;

  @override
  Future<Result<Reserva>> reservar(String libroId) => _api.reservar(libroId);

  @override
  Future<Result<void>> cancelar(String reservaId) => _api.cancelar(reservaId);
}
