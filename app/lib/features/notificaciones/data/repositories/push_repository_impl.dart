import '../../../../core/error/failures.dart';
import '../../../../core/error/result.dart';
import '../../../../core/push/servicio_push.dart';
import '../../../auth/data/datasources/auth_api_datasource.dart';
import '../../../auth/domain/entities/credenciales_api.dart';
import '../../domain/repositories/push_repository.dart';

/// Une las dos mitades del canal push: el SDK de Firebase en el dispositivo y
/// la API del backend que guarda el token.
class PushRepositoryImpl implements PushRepository {
  const PushRepositoryImpl({
    required ServicioPush servicio,
    required AuthApiDataSource api,
  })  : _servicio = servicio,
        _api = api;

  final ServicioPush _servicio;
  final AuthApiDataSource _api;

  @override
  bool get soportado => _servicio.soportado;

  @override
  Stream<MensajePush> get mensajesRecibidos => _servicio.mensajesRecibidos;

  @override
  Future<Result<String>> obtenerTokenDelDispositivo() async {
    try {
      return Exito(await _servicio.obtenerToken());
    } on ExcepcionPush catch (e) {
      return Fallo(PushFailure(e.mensaje));
    } catch (_) {
      return const Fallo(
          PushFailure('No se pudo obtener el token de notificaciones'));
    }
  }

  @override
  Future<Result<void>> registrarTokenEnServidor({
    required String token,
    required CredencialesApi credenciales,
  }) async {
    // El endpoint que guarda el token exige un JWT, así que primero hay que
    // autenticarse contra el backend: el token queda asociado a esa cuenta.
    final sesion = await _api.login(credenciales);

    return switch (sesion) {
      Fallo(:final failure) => Fallo(failure),
      Exito(valor: final jwt) =>
        await _api.registrarFirebaseToken(jwt: jwt, tokenFirebase: token),
    };
  }
}
