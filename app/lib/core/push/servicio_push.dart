/// Aviso push recibido con la app abierta.
///
/// Cuando la app está en segundo plano el push lo dibuja el sistema operativo
/// (o el service worker, en la web) y este objeto nunca se construye.
class MensajePush {
  const MensajePush({this.titulo, this.cuerpo});

  final String? titulo;
  final String? cuerpo;
}

/// Falla del servicio de mensajería del dispositivo.
class ExcepcionPush implements Exception {
  const ExcepcionPush(this.mensaje);

  final String mensaje;

  @override
  String toString() => 'ExcepcionPush: $mensaje';
}

/// Acceso a Firebase Cloud Messaging desde el dispositivo.
///
/// La implementación cambia por plataforma y se elige con un import
/// condicional, no con un `if (kIsWeb)`: así el build de Android no arrastra
/// `dart:js_interop` ni el de web arrastra el plugin nativo.
///
/// **Por qué hay dos.** En Android alcanza con el plugin `firebase_messaging`.
/// En la web no: `firebase_messaging_web` no permite pasarle un
/// `ServiceWorkerRegistration` propio al SDK de Firebase (está anotado como
/// TODO en su código), así que el SDK registra `/firebase-messaging-sw.js` en
/// la raíz del dominio. GitHub Pages sirve el sitio bajo `/<repo>/`, donde esa
/// ruta no existe y `getToken()` falla. La implementación web habla entonces
/// con el SDK de JavaScript a través de un shim propio —`web/firebase-push.js`—
/// que sí registra el service worker en el scope correcto.
abstract interface class ServicioPush {
  /// `true` si esta plataforma puede recibir push. En un navegador sin
  /// `PushManager` o en un escritorio Linux, es `false`.
  bool get soportado;

  /// Deja el SDK listo. Nunca lanza: si Firebase no arranca, la app sigue
  /// funcionando y [soportado] pasa a `false`.
  Future<void> inicializar();

  /// Pide permiso al usuario y devuelve el token FCM de este dispositivo.
  ///
  /// Lanza [ExcepcionPush] si el usuario rechaza el permiso o el SDK falla.
  Future<String> obtenerToken();

  /// Avisos que llegan con la app en primer plano.
  Stream<MensajePush> get mensajesRecibidos;
}
