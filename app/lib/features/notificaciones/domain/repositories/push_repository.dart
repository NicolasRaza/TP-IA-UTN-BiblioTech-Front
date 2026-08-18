import '../../../../core/error/result.dart';
import '../../../../core/push/servicio_push.dart';
import '../../../auth/domain/entities/credenciales_api.dart';

/// Canal de notificaciones push del lector.
///
/// Separa las dos mitades del flujo que describe la spec: el dispositivo pide
/// su token a Firebase, y el backend lo guarda en `usuarios.firebase_token`
/// para que el Agente Planificador sepa a dónde mandar el aviso cuando vence
/// un préstamo.
abstract interface class PushRepository {
  /// `true` si esta plataforma puede recibir push.
  bool get soportado;

  /// Pide permiso al usuario y devuelve el token FCM de este dispositivo.
  Future<Result<String>> obtenerTokenDelDispositivo();

  /// Asocia el [token] a la cuenta del backend de [credenciales].
  Future<Result<void>> registrarTokenEnServidor({
    required String token,
    required CredencialesApi credenciales,
  });

  /// Avisos que llegan con la app abierta.
  Stream<MensajePush> get mensajesRecibidos;
}
