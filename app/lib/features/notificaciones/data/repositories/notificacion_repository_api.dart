import '../../../../core/error/result.dart';
import '../../domain/entities/notificacion.dart';
import '../../domain/repositories/notificacion_repository.dart';
import '../datasources/notificacion_api_datasource.dart';

/// Los avisos de un lector, servidos por el backend.
///
/// El contrato de dominio pide tres cosas que la API no expone como rutas
/// propias —contar los no leídos y detectar un aviso repetido—; las dos se
/// resuelven sobre el listado del lector, que es corto por naturaleza. Sumar
/// endpoints para eso habría sido más superficie de API para ahorrar un
/// recuento sobre una lista de decenas de filas.
class NotificacionRepositoryApi implements NotificacionRepository {
  const NotificacionRepositoryApi(this._api);

  final NotificacionApiDataSource _api;

  @override
  Future<Result<List<Notificacion>>> obtenerDeLector(String lectorId) =>
      _api.listar(lectorId);

  @override
  Future<Result<int>> contarNoLeidas(String lectorId) async {
    final avisos = await _api.listar(lectorId);
    if (avisos case Fallo(:final failure)) return Fallo(failure);
    return Exito(avisos.valorONull!.where((n) => !n.leida).length);
  }

  @override
  Future<Result<Notificacion>> crear(Notificacion notificacion) =>
      _api.crear(notificacion);

  @override
  Future<Result<bool>> existeSimilar(
    String lectorId,
    TipoNotificacion tipo,
    String textoClave,
  ) async {
    final avisos = await _api.listar(lectorId);
    if (avisos case Fallo(:final failure)) return Fallo(failure);

    return Exito(avisos.valorONull!.any(
      (n) => n.tipo == tipo && n.descripcion.contains(textoClave),
    ));
  }

  @override
  Future<Result<void>> marcarLeida(String notificacionId) =>
      _api.marcarLeida(notificacionId);

  @override
  Future<Result<void>> marcarTodasLeidas(String lectorId) =>
      _api.marcarTodasLeidas(lectorId);
}
