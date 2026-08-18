import 'dart:convert';

import '../error/failures.dart';
import '../error/result.dart';
import 'key_value_store.dart';

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
