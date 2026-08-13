# Estado de la migración a Flutter

Seguimiento de la migración del prototipo HTML/JS a Flutter (web + mobile).
Rama de trabajo: `claude/flutter-migration`.

**Última actualización:** sesión del 13/08/2026.

## Dónde está cada cosa

| Ruta | Qué es |
|---|---|
| `app/` | Proyecto Flutter (web, android, ios) |
| `index.html`, `lector.html`, `bibliotecario.html`, `admin.html`, `js/`, `css/` | Prototipo original, se conserva como referencia de la migración |
| `docs/tp1-sistema-gestion-bibliotecas-v2.md` | Especificación funcional canónica |

El prototipo no se tocó: la app Flutter vive en `app/` y se puede comparar
pantalla por pantalla contra el HTML mientras dure la migración.

## Hecho

### Base del proyecto
- Scaffold Flutter con los tres targets: `web`, `android`, `ios`.
- Tema portado de `css/main.css` (misma paleta, radios y tipografía).
- Shell adaptativo: barra inferior en celular, riel lateral en tablet,
  sidebar expandido en escritorio. Un solo árbol de widgets para las tres.
- Build de web verificado; `flutter analyze` sin issues.

### Dominio y persistencia (portado de `js/db.js`)
- Modelos inmutables con serialización JSON manual, sin codegen.
- `KeyValueStore` abstrae el almacenamiento: `SharedPrefsStore` en la app,
  `MemoryStore` en los tests.
- Reloj y generador de IDs inyectables en el repositorio, para que los tests
  fijen el tiempo y obtengan identificadores predecibles.
- Datos semilla completos: 21 libros con sus ejemplares, 5 lectores, un
  bibliotecario, un administrador, préstamos, reservas y auditoría.

### Reglas de la spec v2 §7 que el prototipo no cubría

Estas son las que se implementaron de cero durante la migración:

- **Transición de categoría.** Préstamos y reservas congelan el plazo y la
  categoría vigentes al momento de crearse. Si el lector cambia de categoría,
  lo ya generado conserva sus condiciones y solo lo nuevo usa las nuevas.
- **Continuidad de identidad ante reimpresión de QR.** El contenido del QR se
  deriva del ID interno, así que reimprimir produce una etiqueta idéntica.
  Nunca se genera un ID nuevo; queda registro en auditoría con el motivo.
- **Priorización de reservas.** Cola por orden cronológico estricto, retención
  de 48 hs configurable, y pase automático al siguiente cuando vence el plazo
  o se cancela.
- **Resolución de fuentes externas (§4.2).** Sin resultados el campo queda
  `pendiente` de carga manual; ante discrepancia desempata la autoridad
  editorial; si empatan, el campo queda `enConflicto` y decide el bibliotecario.
  Ningún campo de baja confianza se completa sin quedar marcado.
- **Ponderación de recomendaciones (§2).** 70% historial / 30% popularidad,
  con inversión a 100% popularidad para lectores sin historial suficiente.

### Agentes (portado de `js/agents.js`)
- **Analizador:** parser OCR (ISBN, año, páginas, editorial, autor, título) y
  resolución de fuentes externas.
- **Evaluador:** decide y devuelve una lista de `Decision` sin tocar el sistema.
  Produce además recomendaciones e indicadores de negocio.
- **Planificador:** solo ejecuta las decisiones que recibe.
- **Aprendizaje:** patrones de corrección y conversión de recomendaciones.

La separación Evaluador-decide / Planificador-ejecuta de la §4.3 está
implementada en serio: `Decision` es el contrato entre ambos.

### Tests — 19, todos en verde
`app/test/reglas_negocio_test.dart` cubre validación estricta, límites y
bloqueos por multa o vencimiento, transición de categoría, reimpresión de QR,
cola de reservas con el plazo de 48 hs, y cálculo idempotente de multas.
`app/test/widget_test.dart` cubre el arranque sin sesión y el ingreso al portal.

## Pendiente

### 1. Cuerpo de las pantallas (lo más grande)

El esqueleto de navegación de los tres roles está armado y refleja las
secciones del prototipo, pero **cada sección muestra hoy un marcador**
(`SeccionPendiente`) en lugar de su contenido. Falta portar:

**Lector** — `lector.html`
- Catálogo: búsqueda, filtro por género, ficha del libro, botón de reserva.
- Recomendaciones: tarjetas con el motivo y el aviso de cold start.
- Mi actividad: solapas de préstamos, reservas e historial.
- Notificaciones: lista, marcar leída, contador.
- Perfil: datos, categoría y límites, multas, géneros de interés, QR propio.

**Bibliotecario** — `bibliotecario.html`
- Dashboard con métricas y decisiones abiertas del Evaluador.
- Alta de libro: las tres fotos, ficha sugerida con confianza por campo,
  resolución de conflictos entre fuentes y confirmación explícita.
- Catálogo e inventario: ejemplares, alta y reimpresión de etiquetas.
- Préstamo y devolución con identificación por QR.
- Lectores: alta, edición y cambio de categoría.
- Alertas operativas.

**Admin** — `admin.html`
- Reportes con gráficos (`fl_chart` ya está en `pubspec.yaml`).
- Parámetros de la biblioteca.
- Auditoría, aprendizaje, sugerencias y "acerca de".

La lógica que alimenta todas estas pantallas ya existe y está testeada: falta
la capa visual. `AppState` expone las operaciones y consultas necesarias.

### 2. CI/CD
No se llegó a configurar. La idea era `.github/workflows/ci.yml` con:
`flutter format --set-exit-if-changed`, `flutter analyze`,
`flutter test --coverage` y `flutter build web`, más un job de APK.
Los tres comandos ya corren limpios en local, así que el workflow debería
pasar en verde apenas se agregue.

### 3. Escaneo de QR con cámara
Hoy el QR se resuelve por texto, igual que en el prototipo. Para escaneo real
haría falta `mobile_scanner` y permisos de cámara en Android e iOS.

### 4. Enriquecimiento contra Open Library
`AgenteAnalizador.resolverFuentes` ya acepta varias fuentes con su autoridad,
pero falta el cliente HTTP que consulte Open Library y arme esos resultados.
`http` ya está en `pubspec.yaml`.

### 5. Publicación
El TP pide la app publicada con links en vivo. `flutter build web` genera
`app/build/web`, listo para GitHub Pages o similar. Falta decidir dónde.

## Cómo levantar el proyecto

```bash
cd app
flutter pub get
flutter run -d chrome        # web
flutter run                  # mobile con dispositivo conectado
flutter test                 # 19 tests
flutter analyze
```

Usuarios de demostración (precargados en cada tarjeta de rol):

| Rol | Email | PIN |
|---|---|---|
| Lector | laura@demo.com | 1234 |
| Bibliotecario | bibliotecario@demo.com | 0000 |
| Administrador | admin@demo.com | 9999 |

Se probó con Flutter 3.24.5 / Dart 3.5.4. Ojo con la versión: el código usa
`withOpacity`, no `withValues`, que recién existe desde 3.27.
