import 'dart:convert';

import 'package:bibliotech/core/error/failures.dart';
import 'package:bibliotech/core/error/result.dart';
import 'package:bibliotech/core/storage/key_value_store.dart';

/// Lectura y escritura de una lista de entidades serializada como JSON bajo
/// una clave del [KeyValueStore].
///
/// Todos los datasources locales comparten exactamente el mismo mecanismo, así
/// que vive una sola vez acá. Además concentra el manejo de errores: un JSON
/// corrupto se traduce a [CacheFailure] en lugar de propagar un
/// `FormatException` hacia el dominio.
class ColeccionJson<T> {
  const ColeccionJson({
    required KeyValueStore store,
    required this.clave,
    required this.desdeJson,
    required this.aJson,
  }) : _store = store;

  final KeyValueStore _store;
  final String clave;
  final T Function(Map<String, dynamic>) desdeJson;
  final Map<String, dynamic> Function(T) aJson;

  Result<List<T>> leer() {
    try {
      final raw = _store.read(clave);
      if (raw == null || raw.isEmpty) return const Exito([]);
      final data = jsonDecode(raw) as List<dynamic>;
      return Exito(
        data.map((e) => desdeJson(e as Map<String, dynamic>)).toList(),
      );
    } on Object {
      return Fallo(CacheFailure('No se pudieron leer los datos de "$clave"'));
    }
  }

  Result<void> escribir(List<T> lista) {
    try {
      _store.write(clave, jsonEncode(lista.map(aJson).toList()));
      return const Exito(null);
    } on Object {
      return Fallo(
          CacheFailure('No se pudieron guardar los datos de "$clave"'));
    }
  }
}

/// Igual que [ColeccionJson] pero para un único objeto, no una lista.
class DocumentoJson<T> {
  const DocumentoJson({
    required KeyValueStore store,
    required this.clave,
    required this.desdeJson,
    required this.aJson,
  }) : _store = store;

  final KeyValueStore _store;
  final String clave;
  final T Function(Map<String, dynamic>) desdeJson;
  final Map<String, dynamic> Function(T) aJson;

  /// Devuelve [porDefecto] si todavía no se guardó nada.
  Result<T> leer(T porDefecto) {
    try {
      final raw = _store.read(clave);
      if (raw == null || raw.isEmpty) return Exito(porDefecto);
      return Exito(desdeJson(jsonDecode(raw) as Map<String, dynamic>));
    } on Object {
      return Fallo(CacheFailure('No se pudo leer "$clave"'));
    }
  }

  Result<void> escribir(T valor) {
    try {
      _store.write(clave, jsonEncode(aJson(valor)));
      return const Exito(null);
    } on Object {
      return Fallo(CacheFailure('No se pudo guardar "$clave"'));
    }
  }
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
