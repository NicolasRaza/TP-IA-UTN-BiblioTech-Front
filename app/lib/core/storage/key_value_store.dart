import 'package:shared_preferences/shared_preferences.dart';

/// Almacén clave-valor sincrónico.
///
/// Es el detalle de infraestructura más bajo de la app. Los datasources
/// trabajan contra esta interfaz en lugar de contra `SharedPreferences`
/// directamente: en la app corre [SharedPrefsStore] (localStorage en web,
/// SharedPreferences en mobile) y en los tests [MemoryStore], que no necesita
/// binding de Flutter ni plugins.
abstract interface class KeyValueStore {
  String? read(String key);
  void write(String key, String value);
  void remove(String key);
  Iterable<String> get keys;
}

class MemoryStore implements KeyValueStore {
  MemoryStore([Map<String, String>? inicial]) : _data = {...?inicial};

  final Map<String, String> _data;

  @override
  String? read(String key) => _data[key];

  @override
  void write(String key, String value) => _data[key] = value;

  @override
  void remove(String key) => _data.remove(key);

  @override
  Iterable<String> get keys => _data.keys;
}

/// Adaptador sobre SharedPreferences.
///
/// Mantiene una copia en memoria para poder ofrecer lecturas sincrónicas; las
/// escrituras se propagan al plugin sin bloquear a quien llama.
class SharedPrefsStore implements KeyValueStore {
  SharedPrefsStore._(this._prefs, this._cache);

  final SharedPreferences _prefs;
  final Map<String, String> _cache;

  static Future<SharedPrefsStore> abrir() async {
    final prefs = await SharedPreferences.getInstance();
    final cache = <String, String>{};
    for (final k in prefs.getKeys()) {
      final v = prefs.get(k);
      if (v is String) cache[k] = v;
    }
    return SharedPrefsStore._(prefs, cache);
  }

  @override
  String? read(String key) => _cache[key];

  @override
  void write(String key, String value) {
    _cache[key] = value;
    // Escritura en background: la fuente de verdad para la UI es la caché.
    _prefs.setString(key, value);
  }

  @override
  void remove(String key) {
    _cache.remove(key);
    _prefs.remove(key);
  }

  @override
  Iterable<String> get keys => _cache.keys;
}

/// Claves de persistencia. Los nombres (`bt_*`) vienen del prototipo
/// HTML/JS original y se conservan para que los datos ya guardados en un
/// navegador sigan siendo legibles.
abstract final class ClavesAlmacenamiento {
  static const libros = 'bt_libros';
  static const lectores = 'bt_lectores';
  static const prestamos = 'bt_prestamos';
  static const reservas = 'bt_reservas';
  static const notificaciones = 'bt_notificaciones';
  static const config = 'bt_config';
  static const auditoria = 'bt_auditoria';
  static const aprendizaje = 'bt_aprendizaje';
  static const sesion = 'bt_sesion';
  static const inicializado = 'bt_initialized';

  static const todas = [
    libros,
    lectores,
    prestamos,
    reservas,
    notificaciones,
    config,
    auditoria,
    aprendizaje,
    sesion,
    inicializado,
  ];
}
