// Puente entre la app Flutter y el SDK de Firebase para JavaScript.
//
// ¿Por qué no se usa el plugin `firebase_messaging` en web? Porque
// `firebase_messaging_web` no expone la opción `serviceWorkerRegistration` de
// `getToken()` (está marcada como TODO en su código), y sin ella el SDK
// registra `/firebase-messaging-sw.js` en la RAÍZ del dominio. GitHub Pages
// sirve el sitio bajo `/<repo>/`, así que esa ruta devuelve 404 y el pedido
// del token falla. Acá el service worker se registra con ruta relativa al
// <base href> y con un scope propio, para no pisar al flutter_service_worker.
//
// Del lado de Dart esto lo consume `lib/core/push/servicio_push_web.dart`.
(function () {
  'use strict';

  const SCOPE = 'firebase-cloud-messaging-push-scope';
  const cdn = (archivo) =>
    `https://www.gstatic.com/firebasejs/${self.sgbFirebaseSdk}/${archivo}`;

  let sdkCargado = null;

  function cargarScript(url) {
    return new Promise((resolver, rechazar) => {
      const etiqueta = document.createElement('script');
      etiqueta.src = url;
      etiqueta.onload = resolver;
      etiqueta.onerror = () =>
        rechazar(new Error('No se pudo descargar el SDK de Firebase'));
      document.head.appendChild(etiqueta);
    });
  }

  // Los scripts van en orden: `messaging-compat` necesita que `firebase` ya
  // exista. Se descargan la primera vez que se activan los avisos y no al
  // cargar la página, para no sumarle peso al arranque de la app.
  function cargarSdk() {
    sdkCargado =
      sdkCargado ||
      cargarScript(cdn('firebase-app-compat.js')).then(() =>
        cargarScript(cdn('firebase-messaging-compat.js')),
      );
    return sdkCargado;
  }

  function soportado() {
    return (
      'serviceWorker' in navigator &&
      'PushManager' in window &&
      'Notification' in window
    );
  }

  async function pedirPermiso() {
    if (Notification.permission === 'denied') {
      throw new Error(
        'El navegador tiene bloqueadas las notificaciones para este sitio. ' +
          'Habilitalas desde el candado de la barra de direcciones.',
      );
    }
    const permiso = await Notification.requestPermission();
    if (permiso !== 'granted') {
      throw new Error('Hace falta permitir las notificaciones para activarlas');
    }
  }

  async function activar() {
    if (!soportado()) {
      throw new Error('Este navegador no soporta notificaciones push');
    }

    await pedirPermiso();
    await cargarSdk();

    const app = firebase.apps.length
      ? firebase.app()
      : firebase.initializeApp(self.sgbFirebaseConfig);
    const messaging = firebase.messaging(app);

    // Ruta relativa: el navegador la resuelve contra el <base href> que
    // escribe `flutter build web --base-href`, que es lo que hace que esto
    // funcione igual en la raíz de un dominio y en /<repo>/ de GitHub Pages.
    const registro = await navigator.serviceWorker.register(
      'firebase-messaging-sw.js',
      { scope: SCOPE },
    );
    await navigator.serviceWorker.ready;

    const token = await messaging.getToken({
      vapidKey: self.sgbVapidKey,
      serviceWorkerRegistration: registro,
    });

    if (!token) {
      throw new Error('Firebase no devolvió un token para este navegador');
    }

    escucharPrimerPlano(messaging);
    return token;
  }

  let escuchando = false;

  // Con la pestaña abierta el service worker no dibuja nada: el aviso llega
  // acá y la app Flutter lo muestra dentro de la interfaz.
  function escucharPrimerPlano(messaging) {
    if (escuchando) return;
    escuchando = true;

    messaging.onMessage((payload) => {
      const notificacion = payload.notification || {};
      const datos = payload.data || {};

      window.dispatchEvent(
        new CustomEvent('sgb-push', {
          detail: {
            titulo: notificacion.title || datos.titulo || datos.title || null,
            cuerpo: notificacion.body || datos.cuerpo || datos.body || null,
          },
        }),
      );
    });
  }

  window.sgbPush = { soportado, activar };
})();
