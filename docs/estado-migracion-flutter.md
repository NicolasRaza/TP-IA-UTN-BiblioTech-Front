# Estado de la migración a Flutter

Seguimiento de la migración del prototipo HTML/JS a Flutter (web + mobile).
Rama de trabajo: `claude/flutter-migration`.

**Última actualización:** sesión del 14/08/2026.

## Dónde está cada cosa

| Ruta | Qué es |
|---|---|
| `app/` | Proyecto Flutter (web, android, ios) |
| `.github/workflows/ci.yml` | CI: formato, análisis, tests y builds |
| `index.html`, `lector.html`, `bibliotecario.html`, `admin.html`, `js/`, `css/` | Prototipo original, se conserva como referencia |
| `docs/tp1-sistema-gestion-bibliotecas-v2.md` | Especificación funcional canónica |

El prototipo no se tocó: la app Flutter vive en `app/` y se puede comparar
pantalla por pantalla contra el HTML.

## Estado: la migración funcional está completa

Las tres interfaces de la spec v2 §9 están portadas y operativas. Verificado
con Flutter 3.24.5: `dart format` y `flutter analyze` limpios, **39 tests en
verde** y build de web exitoso.

### Base del proyecto
- Scaffold con los tres targets: `web`, `android`, `ios`.
- Tema portado de `css/main.css` (misma paleta, radios y tipografía).
- Shell adaptativo: barra inferior en celular, riel lateral en tablet,
  sidebar expandido en escritorio. Un solo árbol de widgets para las tres.

### Dominio y persistencia (portado de `js/db.js`)
- Modelos inmutables con serialización JSON manual, sin codegen.
- `KeyValueStore` abstrae el almacenamiento: `SharedPrefsStore` en la app,
  `MemoryStore` en los tests.
- Reloj y generador de IDs inyectables, para fijar el tiempo en los tests.
- Datos semilla completos: 21 libros, 5 lectores, bibliotecario, administrador,
  préstamos, reservas y auditoría.

### Reglas de la spec v2 que el prototipo no cubría

Implementadas de cero durante la migración:

- **Transición de categoría (§7).** Préstamos y reservas congelan plazo y
  categoría al crearse. Si el lector cambia de categoría, lo ya generado
  conserva sus condiciones y solo lo nuevo usa las nuevas.
- **Continuidad de identidad ante reimpresión de QR (§7).** El QR se deriva del
  ID interno, así que reimprimir da una etiqueta idéntica. Nunca se genera un
  ID nuevo; queda registro en auditoría con el motivo.
- **Priorización de reservas (§7).** Cola cronológica estricta, retención de
  48 hs configurable, y pase automático al siguiente al vencer o cancelarse.
- **Resolución de fuentes externas (§4.2).** Sin resultados el campo queda
  `pendiente`; ante discrepancia desempata la autoridad editorial; si empatan,
  queda `enConflicto` y decide el bibliotecario. Ningún campo de baja confianza
  se completa sin quedar marcado.
- **Ponderación de recomendaciones (§2).** 70% historial / 30% popularidad, con
  inversión a 100% popularidad en *cold start*.

### Agentes (portado de `js/agents.js`)
- **Analizador:** parser OCR y resolución de fuentes externas.
- **Evaluador:** decide y devuelve una lista de `Decision` sin tocar el sistema.
  Produce además recomendaciones e indicadores.
- **Planificador:** solo ejecuta las decisiones que recibe.
- **Aprendizaje:** patrones de corrección y conversión de recomendaciones.

La separación Evaluador-decide / Planificador-ejecuta de la §4.3 está
implementada en serio: `Decision` es el contrato entre ambos, y la UI del
dashboard permite disparar el ciclo y ver qué se ejecutó.

### Pantallas

**Lector** (`lector.html`) — las siete secciones del prototipo agrupadas en
cinco destinos, para que la barra inferior siga siendo usable en un celular:
- Catálogo con búsqueda por título, autor, ISBN o género, filtro por género y
  por disponibilidad, y ficha con reserva.
- Recomendaciones que explican el criterio y avisan del cold start.
- Mi actividad: solapas de préstamos, reservas e historial. Cada préstamo
  muestra el plazo y la categoría con la que se generó; cada reserva, su
  posición en la cola o el plazo de retiro corriendo.
- Notificaciones y perfil con límites de la categoría y QR de credencial.

**Bibliotecario** (`bibliotecario.html`) — las siete secciones:
- Dashboard con métricas y las decisiones abiertas del Evaluador, con botón
  para que el Planificador ejecute el lote.
- Alta de libro: se pega el texto reconocido, el Analizador propone la ficha
  con el nivel de confianza por campo, y hay que confirmar explícitamente para
  publicar. "Guardar sin publicar" deja el libro fuera del catálogo.
- Catálogo e inventario: ejemplares por título, alta de ejemplares y etiqueta
  QR con reimpresión.
- Préstamo y devolución, con identificación del lector y del ejemplar.
- Lectores con cambio de categoría y registro de pago de multas.
- Alertas agrupadas por tipo, con el motivo de cada decisión.

**Admin** (`admin.html`) — las seis secciones:
- Reportes con gráfico de préstamos por mes y rankings.
- Parámetros: plazos y límites por categoría, retención de reservas, multa
  diaria y ponderación del motor de recomendaciones.
- Auditoría filtrable por tipo de evento.
- Aprendizaje, sugerencias estratégicas y "acerca de" con la bitácora de la
  sesión y el reinicio de datos.

### Tests — 39, todos en verde

| Archivo | Qué cubre |
|---|---|
| `reglas_negocio_test.dart` | Reglas de la §7: validación estricta, límites, bloqueos, transición de categoría, reimpresión de QR, cola de reservas con 48 hs, multas idempotentes |
| `portal_lector_test.dart` | Catálogo, filtro de búsqueda, alta de reserva, cold start, préstamos vigentes, límites del perfil, avisos |
| `paneles_gestion_test.dart` | Decisiones del Evaluador, análisis de ficha, publicar vs. guardar sin publicar, devolución, alertas, parámetros, auditoría |
| `widget_test.dart` | Arranque sin sesión e ingreso al portal |

### CI/CD

`.github/workflows/ci.yml` corre en push a `main`, `develop` y `claude/**`, y
en PR a `main` y `develop`:

1. **Calidad** — `dart format --set-exit-if-changed`, `flutter analyze`,
   `flutter test --coverage` (sube el `lcov.info` como artefacto).
2. **Build web** — sube `build/web` como artefacto.
3. **Build APK** — compila el APK de release y lo sube como artefacto.
4. **Publicar en Pages** — solo desde `main`.
5. **Publicar release** — solo al empujar un tag `vX.Y.Z`: crea un release de
   GitHub con el APK y el build web adjuntos.

### Ramas y publicación

Cada disparador tiene un significado distinto:

| Evento | Qué pasa |
|---|---|
| push a `develop` | Corre CI (calidad y builds). No publica nada |
| push a `main` | Publica la app en GitHub Pages |
| tag `vX.Y.Z` | Crea el release con el APK descargable |

`develop` es la rama de integración y `main` es lo que está publicado. Se
promueve con un PR `develop` → `main` cuando la versión está lista para que
la vean desde afuera; así un merge a medias nunca queda en vivo.

La URL es `https://nicolasraza.github.io/TP-IA-UTN-BiblioTech-Front/`. El job
de Pages compila aparte del job `build-web` porque necesita
`--base-href /<repo>/`: Pages sirve el sitio en un subdirectorio y sin eso la
página carga en blanco. El artefacto de `build-web` se deja sin `base-href`
para que sirva en cualquier hosting.

### Distribución del APK

El APK de release se firma con las claves de debug que trae el template de
Flutter (`android/app/build.gradle` deja `signingConfig = signingConfigs.debug`).
Eso alcanza para instalarlo de costado en un teléfono habilitando orígenes
desconocidos, pero no para publicarlo en Play Store: para eso haría falta
generar un keystore propio y guardarlo como secret del repositorio.

Los artefactos de Actions caducan y exigen estar logueado en GitHub, así que
para el informe conviene citar el link del **release**, que es público y
permanente. Para generarlo:

```bash
git tag v1.0.0
git push origin v1.0.0
```

## Pendiente

1. **Escaneo real de QR con cámara.** Hoy el QR se resuelve por texto, igual
   que en el prototipo. Haría falta `mobile_scanner` y permisos en Android/iOS.
2. **Enriquecimiento contra Open Library.** `AgenteAnalizador.resolverFuentes`
   ya acepta varias fuentes con su autoridad y resuelve conflictos, pero falta
   el cliente HTTP que consulte la API y arme esos resultados. Hoy la ficha se
   arma solo con el texto del OCR. `http` ya está en `pubspec.yaml`.
3. **Alta de lectores desde la UI.** El repositorio y `AppState` ya la
   soportan; falta el formulario en la sección de lectores.
4. **Publicación.** El TP pide la app publicada con links en vivo.
   `flutter build web` genera `app/build/web` y el CI ya lo sube como
   artefacto; falta decidir dónde alojarlo (GitHub Pages es lo más directo).
5. **Captura de fotos.** La spec v2 §3 habla de tres fotos por libro. La UI
   trabaja sobre el texto reconocido; falta la captura en sí.

## Cómo levantar el proyecto

```bash
cd app
flutter pub get
flutter run -d chrome        # web
flutter run                  # mobile con dispositivo conectado
flutter test                 # 39 tests
flutter analyze
```

Usuarios de demostración (precargados en cada tarjeta de rol):

| Rol | Email | PIN |
|---|---|---|
| Lector | laura@demo.com | 1234 |
| Bibliotecario | bibliotecario@demo.com | 0000 |
| Administrador | admin@demo.com | 9999 |

Probado con Flutter 3.24.5 / Dart 3.5.4, la versión fijada en el CI. Ojo al
subir de versión: el código usa `withOpacity`, que 3.27+ reemplaza por
`withValues`.
