// Service worker de Firebase Cloud Messaging.
//
// Es el que muestra la notificación cuando el aviso llega con la pestaña
// cerrada o en segundo plano. Corre fuera de la página, así que no puede usar
// los módulos ES del SDK: van las versiones `compat`, que exponen el global
// `firebase`.
//
// Ojo con las rutas: importScripts() resuelve relativo a la ubicación de este
// archivo, que en GitHub Pages es `/<repo>/firebase-messaging-sw.js`. Por eso
// `./firebase-config.js` y no `/firebase-config.js`.
importScripts('./firebase-config.js');
importScripts(
  `https://www.gstatic.com/firebasejs/${self.sgbFirebaseSdk}/firebase-app-compat.js`,
);
importScripts(
  `https://www.gstatic.com/firebasejs/${self.sgbFirebaseSdk}/firebase-messaging-compat.js`,
);

firebase.initializeApp(self.sgbFirebaseConfig);

const messaging = firebase.messaging();

// Sólo se dispara con mensajes de datos puros. Si el backend manda el bloque
// `notification`, el navegador ya dibuja el aviso solo y este handler no
// corre: no hay que duplicarlo.
messaging.onBackgroundMessage((payload) => {
  const datos = payload.data || {};
  const titulo = datos.titulo || datos.title || 'BiblioTech';

  self.registration.showNotification(titulo, {
    body: datos.cuerpo || datos.body || '',
    icon: './icons/Icon-192.png',
    badge: './icons/Icon-192.png',
    tag: datos.tag || 'bibliotech',
    data: datos,
  });
});

// Al tocar la notificación: si ya hay una pestaña de BiblioTech abierta se
// enfoca esa, y si no se abre una nueva.
self.addEventListener('notificationclick', (evento) => {
  evento.notification.close();

  const destino = new URL('./', self.location.href).href;

  evento.waitUntil(
    self.clients
      .matchAll({ type: 'window', includeUncontrolled: true })
      .then((pestanias) => {
        for (const pestania of pestanias) {
          if (pestania.url.startsWith(destino) && 'focus' in pestania) {
            return pestania.focus();
          }
        }
        return self.clients.openWindow(destino);
      }),
  );
});
