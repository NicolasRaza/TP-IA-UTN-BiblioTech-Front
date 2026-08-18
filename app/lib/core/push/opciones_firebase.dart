import 'package:firebase_core/firebase_core.dart';

/// Configuración del proyecto de Firebase `sgb-biblioteca-2a7b4`.
///
/// Equivale al `firebase_options.dart` que genera `flutterfire configure`,
/// escrito a mano a partir del `google-services.json` de la consola. Sólo
/// tiene la app Android: la web no pasa por acá porque el SDK de JavaScript se
/// inicializa desde `web/firebase-config.js` (ver `servicio_push_web.dart`).
///
/// Estas claves no son secretas. La `apiKey` de una app Android sólo sirve
/// junto con el package name y la firma del APK; lo que nunca sale del backend
/// es la clave privada de la cuenta de servicio.
abstract final class OpcionesFirebase {
  static const android = FirebaseOptions(
    apiKey: 'AIzaSyBKIOOp8x5peVWemkH6M_lG2ndi_MUXgLo',
    appId: '1:926046783593:android:b4c5cf81e7f2b9cd7a3af8',
    messagingSenderId: '926046783593',
    projectId: 'sgb-biblioteca-2a7b4',
    storageBucket: 'sgb-biblioteca-2a7b4.firebasestorage.app',
  );
}
