/// Parámetros que cambian según dónde se compile la app.
///
/// Se leen con `String.fromEnvironment`, así que se fijan en el build y no en
/// el código: `flutter build web --dart-define=SGB_API_URL=...`. El default
/// apunta al backend publicado en Railway, que es contra el que corre la demo.
abstract final class Entorno {
  /// Si la app trabaja contra el backend o contra su almacenamiento local.
  ///
  /// Con `true` —el valor por defecto— el catálogo, el padrón y la circulación
  /// son los del servidor, y la sesión se abre con `POST /auth/login`. Con
  /// `false` la app corre entera sobre los datos sembrados en el dispositivo,
  /// que es lo que permite mostrarla sin conexión:
  /// `flutter build web --dart-define=SGB_USAR_BACKEND=false`.
  static const usarBackend =
      bool.fromEnvironment('SGB_USAR_BACKEND', defaultValue: true);

  /// Raíz de la API del backend, sin barra final.
  static const apiBaseUrl = String.fromEnvironment(
    'SGB_API_URL',
    defaultValue: 'https://tp-ia-utn-bibliotech-back-production.up.railway.app',
  );

  /// Credenciales del backend precargadas en el build.
  ///
  /// Vacías a propósito: el repositorio es público y una contraseña commiteada
  /// es una contraseña filtrada. Si se compila con
  /// `--dart-define=SGB_API_EMAIL=... --dart-define=SGB_API_PASSWORD=...`,
  /// el formulario de activación aparece prellenado; si no, el lector escribe
  /// las suyas una vez.
  static const apiEmail = String.fromEnvironment('SGB_API_EMAIL');
  static const apiPassword = String.fromEnvironment('SGB_API_PASSWORD');
}
