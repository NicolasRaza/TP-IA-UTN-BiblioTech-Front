# Estado de la migración a Flutter

Seguimiento de la migración del prototipo HTML/JS a Flutter (web + mobile).
Rama de trabajo: `claude/flutter-architecture-structure-2grzfz`.

**Última actualización:** sesión del 15/08/2026 — refactor a Clean
Architecture + BLoC.

## Dónde está cada cosa

| Ruta | Qué es |
|---|---|
| `app/` | Proyecto Flutter (web, android, ios) |
| `.github/workflows/ci.yml` | CI: formato, análisis, tests y builds |
| `index.html`, `lector.html`, `bibliotecario.html`, `admin.html`, `js/`, `css/` | Prototipo original, se conserva como referencia |
| `docs/tp1-sistema-gestion-bibliotecas-v2.md` | Especificación funcional canónica |

El prototipo no se tocó: la app Flutter vive en `app/` y se puede comparar
pantalla por pantalla contra el HTML.

## Conexión con el backend

La app corre contra la API del backend SGB
(`https://tp-ia-utn-bibliotech-back-production.up.railway.app`). El
interruptor es uno solo, `Entorno.usarBackend`, y vive en el composition
root: decide qué implementación queda atada a cada contrato de dominio. Ni
los casos de uso, ni los blocs, ni las pantallas se enteran de cuál está
montada.

```bash
flutter run -d chrome                                    # contra el backend
flutter run -d chrome --dart-define=SGB_USAR_BACKEND=false   # modo local
```

El modo local sigue existiendo a propósito: sirve para mostrar la app sin
conexión y es el que usan los tests de reglas de negocio, que describen el
dominio y no deben depender de la red.

### Qué viene del servidor

| Feature | Rutas |
|---|---|
| Sesión | `POST /auth/login`, `GET /auth/me` |
| Catálogo | `GET/POST/PATCH /catalogo/titulos`, `/titulos/{id}/validar`, `/titulos/{id}/ejemplares`, `/ejemplares`, `/ejemplares/qr/{qr}` |
| Padrón | `GET/POST/PATCH /lectores` |
| Préstamos | `GET/POST /prestamos`, `/prestamos/devolucion`, `/prestamos/lector/{id}` |
| Reservas | `GET/POST/DELETE /reservas`, `/reservas/lector/{id}` |
| Recomendaciones | `GET /recomendaciones` |

Siguen siendo locales las features que la API no cubre: notificaciones,
auditoría, configuración de parámetros y registro de aprendizaje.

### Permisos: qué cambia según quién esté logueado

El backend le reserva `/lectores`, `GET /prestamos` y `GET /reservas` al rol
bibliotecario. Eso no es un detalle de implementación, define qué puede hacer
cada pantalla, y hubo que respetarlo en tres lugares:

- **Recomendaciones.** El motor local necesita ver toda la circulación para
  ponderar historial contra popularidad, y un lector no puede leerla. Contra
  el backend se usa `GET /recomendaciones`, que corre la misma ponderación de
  la spec §2 —70/30, cold start con 5 préstamos o menos— sobre datos
  completos. El aviso de cold start se afirma contando el historial propio
  del lector, que su rol sí puede leer.
- **Buscar una reserva por id.** Se empieza por las del dueño de la sesión y
  recién después por el listado global: al revés, cancelar la propia reserva
  daría 403.
- **Ciclo de agentes.** Los pasos que escriben —procesar vencimientos y
  ejecutar decisiones— son del servidor, que corre su propio planificador en
  un scheduler desde que arranca. La app observa y decide, así que el
  bibliotecario sigue viendo qué propone el Evaluador sobre datos reales,
  pero no duplica acciones ya ejecutadas del otro lado.

### Cómo está armado

- `core/api/cliente_api.dart` — el único lugar que arma URLs, adjunta el JWT
  y traduce el borde técnico a una `Failure`. La tabla de traducción
  (401/403 → autenticación, 404 → no encontrado, 409 → regla de negocio,
  422 → validación) está fijada por tests.
- `core/api/sesion_api.dart` — el JWT y su dueño, persistidos. El cliente le
  pide el token en cada request, así que un login o un logout se reflejan
  solos en todos los datasources.
- `core/api/mapeo_api.dart` — la traducción entre los dos vocabularios, con
  la pérdida de información de cada conversión documentada.
- Un datasource y un repositorio API por agregado, implementando los mismos
  contratos que las versiones locales.
- `PrestamoRemoto` y `ReservaRemota` — puertos para las operaciones que el
  backend resuelve en una sola transacción. Prestar, devolver, reservar y
  cancelar no son "guardar una fila": el servidor verifica cupo, multas y
  disponibilidad, mueve el estado del ejemplar y calcula el plazo, todo
  dentro del mismo commit. Los casos de uso delegan en esos puertos cuando
  están registrados, en vez de repetir del lado de la app reglas que el
  servidor ya aplica.

### Decisiones sobre datos que la API no da

- **Ejemplares en el listado.** `GET /titulos` informa los conteos pero no
  lista los ejemplares. El listado guarda esos conteos y deja `ejemplares`
  vacía; el detalle sí los pide. Rellenar con ejemplares de relleno mostraría
  etiquetas QR que no resuelven contra el servidor.
- **Códigos QR.** Los emite el backend y no se pueden derivar del id, así que
  `Ejemplar.qrAsignado` los conserva tal cual. La regla de continuidad de
  identidad ante reimpresión (§7) vale igual: el código se conserva, no se
  recalcula.
- **Títulos pendientes de validación.** `GET /titulos` sólo devuelve los
  validados, así que en modo backend la bandeja de pendientes queda vacía.
- **Multas.** Del lado del backend son registros propios con su motivo y su
  estado, no un saldo acumulado en el lector: se pagan o condonan de a una.

### Pendiente del lado del backend

`titulo_id` se completa en `POST /prestamos` y en `GET /prestamos`, pero no
en `GET /prestamos/lector/{id}` ni en la devolución. Mientras falte, la
sección "Mi actividad" del lector no puede mostrar de qué libro es cada
préstamo. Se arregla con la misma línea que ya usan las otras dos rutas.

## Estado: la migración funcional está completa

Las tres interfaces de la spec v2 §9 están portadas y operativas. Verificado
con Flutter 3.24.5: `dart format` y `flutter analyze` limpios, **43 tests en
verde** y build de web exitoso.

## Arquitectura: Clean Architecture + BLoC

El proyecto pasó de un diseño por capas con `AppState` único y un
`Repositorio` de 946 líneas a Clean Architecture organizada por features.

```
app/lib/
├── core/            error/ · usecases/ · services/ · storage/ · di/ · theme/
├── features/<f>/
│   ├── domain/      entities · repositories (abstractas) · services · usecases
│   ├── data/        models · datasources · repositories (impl)
│   └── presentation/bloc|cubit · pages · widgets
├── app/             MaterialApp, ruteo por rol y los tres shells
└── main.dart        composition root
```

Regla de dependencia estricta: `presentation → domain ← data`. El dominio no
importa Flutter ni conoce `data`.

**Piezas clave**

- `Result<T>` sellado (`Exito` / `Fallo`) en vez de `ResultadoOperacion`: el
  `switch` es exhaustivo y lo verifica el compilador.
- Jerarquía `Failure`: la UI nunca ve una excepción de `data`.
- Servicios de dominio para las reglas compartidas — `PoliticaDePrestamo`,
  `PoliticaDeReserva`, `PoliticaDeCategoria`, `AsignadorDeCola` —, que
  centralizan lo que antes estaba repetido en tres flujos distintos.
- Casos de uso, uno por operación. La auditoría es explícita en el caso de
  uso en lugar de un efecto secundario oculto del repositorio.
- Un datasource local por agregado, sobre el mismo `KeyValueStore`.
- Inyección con `get_it` en `core/di/inyeccion.dart`: único lugar donde una
  interfaz se ata a su implementación. Acepta store, reloj y generador de
  ids inyectados, que es lo que usan los tests.

**Estado con BLoC** — Cubit donde el estado es simple y Bloc con eventos
donde hay varias intenciones que conviene dejar registradas:

| Bloc (eventos) | Cubit |
|---|---|
| `CatalogoBloc`, `PrestamosBloc`, `ReservasBloc`, `LectoresBloc`, `AgentesBloc` | `SesionCubit`, `NotificacionesCubit`, `RecomendacionesCubit`, `AdministracionCubit`, `AltaLibroCubit` |

Cada shell de rol provee los blocs de su panel y los descarta al cerrar
sesión. Los mensajes de resultado viajan en el estado y un `BlocListener`
por shell los muestra: ningún bloc necesita un `BuildContext`.

### Base del proyecto
- Scaffold con los tres targets: `web`, `android`, `ios`.
- Tema portado de `css/main.css` (misma paleta, radios y tipografía).
- Shell adaptativo: barra inferior en celular, riel lateral en tablet,
  sidebar expandido en escritorio. Un solo árbol de widgets para las tres.

### Dominio y persistencia (portado de `js/db.js`)
- Entidades inmutables con `Equatable`, sin serialización: el JSON vive en
  los models de `data`, que extienden a la entidad.
- `KeyValueStore` abstrae el almacenamiento: `SharedPrefsStore` en la app,
  `MemoryStore` en los tests. `ColeccionJson` concentra el patrón
  leer-decodificar-escribir que antes se repetía en cada operación.
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

La separación Evaluador-decide / Planificador-ejecuta de la §4.3 quedó
garantizada por construcción:

- `ObservadorDelSistema` es el único que habla con repositorios y congela un
  `EstadoDelSistema` inmutable.
- `AgenteEvaluador` es **puro**: recibe ese estado y devuelve decisiones. No
  tiene acceso a nada que pueda modificar.
- `AgentePlanificador` sólo ve decisiones, nunca el estado, así que tampoco
  podría re-evaluar aunque quisiera.
- `CorrerCicloDeAgentes` fija el orden Observación → Análisis → Decisión →
  Acción en un solo lugar.

Como el Evaluador es puro, sus tests se escriben armando un
`EstadoDelSistema` a mano, sin almacenamiento ni dobles de prueba.

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

### Tests — 115, todos en verde

`test/helpers/entorno_de_prueba.dart` levanta el grafo real de la app sobre
`MemoryStore`, `RelojFijo` y `GeneradorIdSecuencial`. Los tests usan los
mismos casos de uso y repositorios que corren en producción: lo único que
cambia son las tres piezas de infraestructura del borde.

| Archivo | Qué cubre |
|---|---|
| `features/reglas_negocio_test.dart` | Reglas de la §7 sobre los casos de uso: validación estricta, límites, bloqueos, transición de categoría, reimpresión de QR, cola de reservas con 48 hs, multas idempotentes |
| `features/agentes/agente_evaluador_test.dart` | El Evaluador como función pura: decisiones sobre préstamos, reservas y lectores, y ponderación de recomendaciones |
| `features/auth/sesion_cubit_test.dart` | Login válido, PIN incorrecto, email inexistente, cierre de sesión y validación de campos |
| `features/reservas/reservas_bloc_test.dart` | Reserva lista vs. en espera, duplicados, cancelación, bloqueo por multa y orden de la cola |
| `app/arranque_test.dart` | Arranque del composition root, ruteo por rol y tema |
| `core/api/cliente_api_test.dart` | El borde HTTP: query, JWT y la traducción de cada status a su `Failure` |
| `features/*/​*_api_datasource_test.dart` | El contrato con la API, con cliente HTTP falso: los cuerpos son los que documenta el OpenAPI, así que un cambio del backend rompe en CI y no en la demo |
| `features/auth/sesion_repository_api_test.dart` | Login, revalidación del JWT al arrancar, token vencido vs. corte de red |

### CI/CD

`.github/workflows/ci.yml` corre en push a `main`, `develop` y `claude/**`, y
en PR a `main` y `develop`:

1. **Calidad** — `dart format --set-exit-if-changed`, `flutter analyze`,
   `flutter test --coverage` (sube el `lcov.info` como artefacto).
2. **Build web** — sube `build/web` como artefacto.
3. **Build APK** — compila el APK de release y lo sube como artefacto.
4. **Publicar en Pages** — solo desde `main`.
5. **Etiquetar y publicar el release** — en cada push a `main`: calcula la
   versión siguiente, empuja el tag `vX.Y.Z` y crea un release de GitHub con
   el APK y el build web adjuntos.

### Ramas y publicación

Cada disparador tiene un significado distinto:

| Evento | Qué pasa |
|---|---|
| push a `develop` | Corre CI (calidad y builds). No publica nada |
| push a `main` | Publica en GitHub Pages, etiqueta la versión y crea el release con el APK |
| tag `vX.Y.Z` a mano | Crea el release con esa versión exacta (única forma de subir la mayor) |

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
permanente.

### Versionado automático

No hace falta etiquetar a mano: cada push a `main` calcula la versión, empuja
el tag y publica el release. El número sale del último tag `vX.Y.Z` y de la
rama que se mergeó:

| Rama mergeada a `main` | Sube | Ejemplo |
|---|---|---|
| `fix/…`, `hotfix/…`, `bugfix/…` | parche (Z) | `v1.2.3` → `v1.2.4` |
| `develop` o cualquier otra | menor (Y), resetea Z | `v1.2.3` → `v1.3.0` |
| — sin ningún tag previo | primera publicación | `v1.0.0` |

La rama se resuelve por la API a partir del PR del commit, así que funciona
igual con merge commit, squash o rebase; si el commit no tiene PR asociado
—un commit suelto empujado a `main`— se lee del mensaje del merge commit y,
si tampoco está, cuenta como versión menor.

La versión **mayor** (X) nunca sube sola: un cambio que rompe compatibilidad
es una decisión, no algo que se deduzca del nombre de una rama. Para eso se
empuja el tag a mano y el workflow respeta ese nombre exacto:

```bash
git tag v2.0.0
git push origin v2.0.0
```

El tag automático se empuja con el `GITHUB_TOKEN`, que a propósito **no**
dispara otro run del workflow —GitHub lo bloquea para evitar loops infinitos—.
Por eso el release se crea en la misma corrida que empuja el tag, en vez de
esperar a que el push del tag levante un run nuevo.

## Pendiente

1. **Escaneo real de QR con cámara.** Hoy el QR se resuelve por texto, igual
   que en el prototipo. Haría falta `mobile_scanner` y permisos en Android/iOS.
2. **Enriquecimiento contra Open Library.** `AgenteAnalizador.resolverFuentes`
   ya acepta varias fuentes con su autoridad y resuelve conflictos, pero falta
   el cliente HTTP que consulte la API y arme esos resultados. Hoy la ficha se
   arma solo con el texto del OCR. `http` ya está en `pubspec.yaml`.
3. **Alta de lectores desde la UI.** El caso de uso `RegistrarLector` y el
   `LectoresBloc` ya la soportan; falta el formulario en la sección de
   lectores.
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

Contra el backend, las cuentas son las del servidor y el formulario pide
email y **contraseña**. La pantalla no prellena nada: las credenciales de la
demo local no existen del otro lado.

En modo local (`--dart-define=SGB_USAR_BACKEND=false`) valen los usuarios de
demostración, precargados en cada tarjeta de rol:

| Rol | Email | PIN |
|---|---|---|
| Lector | laura@demo.com | 1234 |
| Bibliotecario | bibliotecario@demo.com | 0000 |
| Administrador | admin@demo.com | 9999 |

Probado con Flutter 3.24.5 / Dart 3.5.4, la versión fijada en el CI. Ojo al
subir de versión: el código usa `withOpacity`, que 3.27+ reemplaza por
`withValues`.
