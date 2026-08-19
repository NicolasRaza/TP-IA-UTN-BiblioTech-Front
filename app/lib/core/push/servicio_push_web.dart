import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'servicio_push.dart';

ServicioPush crearServicioPush() => ServicioPushWeb();

/// Contrato del shim `window.sgbPush` que define `web/firebase-push.js`.
extension type _ShimPush._(JSObject _) implements JSObject {
  external bool soportado();

  /// Pide permiso, registra el service worker y resuelve con el token FCM.
  external JSPromise<JSString> activar();
}

/// Implementación web: delega en el SDK de JavaScript de Firebase.
///
/// No usa `firebase_messaging`. El plugin oficial no expone el
/// `serviceWorkerRegistration` del SDK, así que registra
/// `/firebase-messaging-sw.js` en la raíz del dominio; como GitHub Pages sirve
/// la app bajo `/<repo>/`, esa ruta no existe y `getToken()` falla. El shim
/// registra el mismo service worker con la ruta relativa al `<base href>` y
/// con un scope propio, para no pisar al `flutter_service_worker.js`.
class ServicioPushWeb implements ServicioPush {
  final _mensajes = StreamController<MensajePush>.broadcast();
  bool _escuchando = false;

  _ShimPush? get _shim => globalContext.has('sgbPush')
      ? globalContext.getProperty<_ShimPush>('sgbPush'.toJS)
      : null;

  @override
  bool get soportado => _shim?.soportado() ?? false;

  /// El shim se carga desde `web/index.html`, así que no hay nada que
  /// inicializar.
  @override
  Future<void> inicializar() async {}

  @override
  Future<String> obtenerToken() async {
    final shim = _shim;
    if (shim == null) {
      throw const ExcepcionPush(
          'No se cargó el módulo de notificaciones de la página');
    }
    if (!shim.soportado()) {
      throw const ExcepcionPush(
          'Este navegador no soporta notificaciones push. En iPhone hay que '
          'agregar el sitio a la pantalla de inicio primero.');
    }

    try {
      final token = (await shim.activar().toDart).toDart;
      _escucharPrimerPlano();
      return token;
    } catch (error) {
      throw ExcepcionPush(_mensajeDe(error));
    }
  }

  @override
  Stream<MensajePush> get mensajesRecibidos => _mensajes.stream;

  /// El shim publica cada aviso recibido con la pestaña abierta como un
  /// `CustomEvent` en `window`.
  void _escucharPrimerPlano() {
    if (_escuchando) return;
    _escuchando = true;

    globalContext.callMethod<JSAny?>(
      'addEventListener'.toJS,
      'sgb-push'.toJS,
      ((JSObject evento) {
        final detalle = evento.getProperty<JSObject?>('detail'.toJS);
        _mensajes.add(MensajePush(
          titulo: detalle?.getProperty<JSString?>('titulo'.toJS)?.toDart,
          cuerpo: detalle?.getProperty<JSString?>('cuerpo'.toJS)?.toDart,
        ));
      }).toJS,
    );
  }

  /// Los `Error` de JavaScript llegan como objetos opacos: el texto útil está
  /// en `message`, y el shim ya lo escribe pensando en el usuario final.
  String _mensajeDe(Object error) {
    if (error is JSObject) {
      final mensaje = error.getProperty<JSString?>('message'.toJS);
      if (mensaje != null && mensaje.toDart.isNotEmpty) return mensaje.toDart;
    }
    return 'No se pudo activar el servicio de notificaciones';
  }
}
