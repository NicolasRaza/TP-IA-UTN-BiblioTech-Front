import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'opciones_firebase.dart';
import 'servicio_push.dart';

ServicioPush crearServicioPush() => ServicioPushFirebase();

/// Implementación sobre el plugin nativo `firebase_messaging`.
///
/// Se compila para todo lo que no sea web, pero sólo se activa en Android:
/// iOS necesita además una clave APNs y una cuenta paga de Apple, y en
/// escritorio el plugin no existe.
class ServicioPushFirebase implements ServicioPush {
  bool _listo = false;

  static bool get _plataformaConPlugin =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  @override
  bool get soportado => _listo;

  @override
  Future<void> inicializar() async {
    if (_listo || !_plataformaConPlugin) return;
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(options: OpcionesFirebase.android);
      }
      _listo = true;
    } catch (_) {
      // Un APK compilado sin google-services.json, o sin Google Play Services
      // en el dispositivo: la app sigue andando, sólo que sin push.
      _listo = false;
    }
  }

  @override
  Future<String> obtenerToken() async {
    await inicializar();
    if (!_listo) {
      throw const ExcepcionPush(
          'Este dispositivo no tiene disponible el servicio de notificaciones');
    }

    final permiso = await FirebaseMessaging.instance.requestPermission();
    if (permiso.authorizationStatus == AuthorizationStatus.denied) {
      throw const ExcepcionPush(
          'Rechazaste el permiso de notificaciones. Habilitalo desde los '
          'ajustes del sistema para recibir los avisos.');
    }

    final token = await FirebaseMessaging.instance.getToken();
    if (token == null || token.isEmpty) {
      throw const ExcepcionPush(
          'Firebase no devolvió un token para este dispositivo');
    }
    return token;
  }

  @override
  Stream<MensajePush> get mensajesRecibidos => _listo
      ? FirebaseMessaging.onMessage.map((mensaje) => MensajePush(
            titulo: mensaje.notification?.title,
            cuerpo: mensaje.notification?.body,
          ))
      : const Stream.empty();
}
