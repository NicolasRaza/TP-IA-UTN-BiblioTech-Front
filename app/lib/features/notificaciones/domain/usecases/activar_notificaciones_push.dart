import '../../../../core/error/failures.dart';
import '../../../../core/error/result.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../auth/domain/entities/credenciales_api.dart';
import '../repositories/push_repository.dart';

/// Activa los avisos push en este dispositivo (spec v2 §4.3).
///
/// Encadena los tres pasos del flujo y devuelve el token FCM obtenido, que la
/// pantalla muestra para poder verificarlo contra la consola de Firebase
/// durante la demo:
///
/// 1. verifica que la plataforma soporte push;
/// 2. pide permiso al usuario y le pide el token a Firebase;
/// 3. registra ese token contra la cuenta del backend.
///
/// Si cualquiera de los pasos falla, no se avanza al siguiente: un token que
/// el backend no llegó a guardar no sirve para nada.
class ActivarNotificacionesPush implements UseCase<String, CredencialesApi> {
  const ActivarNotificacionesPush(this._repository);

  final PushRepository _repository;

  @override
  Future<Result<String>> call(CredencialesApi params) async {
    if (!_repository.soportado) {
      return const Fallo(
          PushFailure('Esta plataforma no soporta notificaciones push'));
    }
    if (!params.completas) {
      return const Fallo(ValidacionFailure(
          'Ingresá el email y la contraseña de tu cuenta del sistema'));
    }

    final token = await _repository.obtenerTokenDelDispositivo();

    return switch (token) {
      Fallo(:final failure) => Fallo(failure),
      Exito(valor: final fcm) => (await _repository.registrarTokenEnServidor(
          token: fcm,
          credenciales: params,
        ))
            .map((_) => fcm),
    };
  }
}
