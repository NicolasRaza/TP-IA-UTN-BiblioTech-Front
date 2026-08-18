// Configuración del proyecto de Firebase `sgb-biblioteca-2a7b4` (app web).
//
// Se carga con `self.` y no con `window.` a propósito: este mismo archivo lo
// importa el service worker con importScripts(), donde `window` no existe.
//
// Ninguno de estos valores es secreto — son los que Firebase publica en la
// consola para cualquier app web —, y el par de claves VAPID sólo identifica
// al remitente ante el navegador. La clave privada del proyecto vive en el
// backend y no aparece acá.
self.sgbFirebaseConfig = {
  apiKey: 'AIzaSyBVo3QfiUZRrzm0daPJRXLX2PyPDup4Jp8',
  authDomain: 'sgb-biblioteca-2a7b4.firebaseapp.com',
  projectId: 'sgb-biblioteca-2a7b4',
  storageBucket: 'sgb-biblioteca-2a7b4.firebasestorage.app',
  messagingSenderId: '926046783593',
  appId: '1:926046783593:web:eaf23b99a3389cb07a3af8',
};

// Clave pública VAPID (Cloud Messaging → Certificados push web).
self.sgbVapidKey =
  'BM1PIkbr3puMFLzSkE3Oalt-qRgdC0raWamQz1Ex0uBruU8kuHmtjvVRgDexdFdAkM3LSsMr-ztO-67vU0MdPcc';

// Versión del SDK de Firebase para JavaScript. La comparten el service worker
// y el shim de la página: si se desincronizan, el SDK tira un error de
// versiones incompatibles al pedir el token.
self.sgbFirebaseSdk = '10.14.1';
