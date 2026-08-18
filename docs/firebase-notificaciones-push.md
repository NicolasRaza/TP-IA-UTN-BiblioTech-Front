# Notificaciones push con Firebase Cloud Messaging

Cómo está conectada la app Flutter con Firebase, qué hay que saber para
demostrarlo y dónde están los límites de lo que quedó implementado.

Proyecto de Firebase: **`sgb-biblioteca-2a7b4`** · Backend:
`https://tp-ia-utn-bibliotech-back-production.up.railway.app`

## El flujo completo

```
Vence un préstamo
      ↓
Agente Planificador (backend en Railway)
      ↓  usa usuarios.firebase_token
Firebase Cloud Messaging
      ↓
Navegador o celular del lector
      ↓
BiblioTech muestra el aviso
```

El backend nunca le habla al dispositivo: le habla a Firebase, que es quien
sabe cómo llegar a cada uno. Lo único que tiene que hacer la app es conseguir
su token y dejárselo al backend.

## Qué pasa cuando el lector activa los avisos

En **Portal del Lector → Avisos** hay una tarjeta con un botón. Al apretarlo:

1. se pide el permiso de notificaciones del sistema o del navegador;
2. Firebase devuelve el token FCM de ese dispositivo;
3. la app hace `POST /api/v1/auth/login` con las credenciales que el lector
   escribió, y con el JWT que recibe llama a
   `POST /api/v1/auth/firebase-token` con `{"firebase_token": "..."}`.

El token queda a la vista en la tarjeta, para poder compararlo contra la
consola de Firebase durante la demo.

**Por qué se piden credenciales ahí.** El login de la app es local —el padrón
de lectores vive en el dispositivo— y el endpoint que guarda el token exige un
JWT del backend. El token se guarda contra la cuenta que se autenticó, así que
tiene que ser la del lector que va a recibir los avisos, no una cuenta genérica.

Si se compila con las credenciales precargadas, el formulario aparece lleno:

```bash
flutter build web --release \
  --base-href /TP-IA-UTN-BiblioTech-Front/ \
  --dart-define=SGB_API_EMAIL=admin@biblioteca.com \
  --dart-define=SGB_API_PASSWORD=...
```

No están hardcodeadas en el repositorio a propósito: es público. También se
puede apuntar a otro backend con `--dart-define=SGB_API_URL=...`.

## El problema de la web, y cómo está resuelto

`firebase_messaging` **no funciona tal cual en GitHub Pages**, y esto es lo
menos obvio de todo el asunto.

El plugin `firebase_messaging_web` no expone la opción
`serviceWorkerRegistration` de `getToken()` — está marcada como TODO en su
propio código—, así que el SDK de Firebase cae en su default y registra
`/firebase-messaging-sw.js` en la **raíz del dominio**. GitHub Pages sirve el
sitio bajo `https://<usuario>.github.io/<repo>/`, donde esa ruta devuelve 404 y
el pedido del token falla.

Por eso en web no se usa el plugin. Hay un shim propio:

| Archivo | Qué hace |
|---|---|
| `app/web/firebase-config.js` | Config del proyecto y clave VAPID. Lo comparten la página y el service worker. |
| `app/web/firebase-messaging-sw.js` | Service worker: muestra el aviso cuando la pestaña está cerrada. |
| `app/web/firebase-push.js` | Publica `window.sgbPush`: pide permiso, registra el SW con ruta **relativa al `<base href>`** y llama a `getToken()` con esa registración. |
| `app/lib/core/push/servicio_push_web.dart` | Lo consume desde Dart con `dart:js_interop`. |

El service worker se registra en el scope
`<base href>firebase-cloud-messaging-push-scope`, separado del
`flutter_service_worker.js` que Flutter registra en `<base href>`, así que
conviven sin pisarse. Verificado en Chromium sobre una copia del build servida
bajo `/TP-IA-UTN-BiblioTech-Front/`: quedan las dos registraciones y
`getToken()` resuelve.

En Android sí se usa el plugin nativo, que no tiene este problema
(`app/lib/core/push/servicio_push_movil.dart`). El import condicional de
`fabrica_push.dart` elige uno u otro en tiempo de compilación.

## Dónde está cada cosa

| Ruta | Qué es |
|---|---|
| `app/lib/core/push/servicio_push.dart` | Contrato del servicio de push. Sin dependencias de plataforma. |
| `app/lib/core/push/fabrica_push.dart` | Import condicional: elige implementación web o móvil. |
| `app/lib/core/push/opciones_firebase.dart` | Config del proyecto para Android (equivale a `firebase_options.dart`). |
| `app/lib/core/config/entorno.dart` | URL del backend y credenciales por `--dart-define`. |
| `app/lib/features/auth/data/datasources/auth_api_datasource.dart` | Cliente de `/api/v1/auth`. |
| `app/lib/features/notificaciones/domain/usecases/activar_notificaciones_push.dart` | Los tres pasos del flujo, en orden y sin saltearse ninguno. |
| `app/lib/features/notificaciones/presentation/widgets/tarjeta_push.dart` | La tarjeta de activación. |
| `app/android/app/google-services.json` | Config de la app Android, descargada de la consola. |

## Cómo probarlo

**En la web (Chrome, Edge o Firefox de escritorio).** Entrar al portal del
lector, ir a *Avisos*, completar email y contraseña de una cuenta del backend y
apretar *Activar notificaciones*. Aceptar el permiso del navegador. Debería
aparecer el token. Después, desde la consola de Firebase →
*Messaging* → *Nueva campaña* → *Enviar mensaje de prueba*, pegar ese token.

**En Android.** Instalar el APK del release y hacer lo mismo. En Android 13+ el
sistema pide el permiso al activar.

Con la app abierta el aviso aparece dentro de la tarjeta; con la app cerrada lo
dibuja el sistema operativo o el service worker.

## Límites conocidos

- **iOS no está soportado.** Necesita una clave APNs y una cuenta paga del
  Apple Developer Program. En Safari de iPhone la web sólo puede recibir push
  si el sitio se agrega a la pantalla de inicio (iOS 16.4+).
- **El token no se re-registra solo.** FCM puede rotar el token del
  dispositivo; hoy hay que volver a activar desde la tarjeta. Registrar
  `onTokenRefresh` sería el siguiente paso.
- **La primera activación puede tardar.** Railway duerme las instancias
  inactivas: el `login` inicial despierta el contenedor y puede tomar varios
  segundos. El cliente espera hasta 20.
- **El SDK de Firebase se baja de `gstatic.com`** cuando el lector activa los
  avisos. Sin internet no hay push, pero la app sigue funcionando igual: todo
  lo demás es local.

## Alternativa si se quisiera simplificar

Publicar el build web en **Firebase Hosting** en vez de GitHub Pages lo dejaría
servido desde la raíz de un dominio, y ahí `firebase_messaging` funcionaría sin
el shim. Se descartó para no sumar una credencial de deploy más al CI y para
conservar el link de Pages que ya cita el informe.
