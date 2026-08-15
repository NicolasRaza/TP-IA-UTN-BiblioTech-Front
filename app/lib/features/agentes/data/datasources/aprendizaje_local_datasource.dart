import 'dart:convert';

import '../../../../core/error/failures.dart';
import '../../../../core/error/result.dart';
import '../../../../core/storage/key_value_store.dart';
import '../../domain/entities/recomendacion.dart';
import '../models/aprendizaje_models.dart';

/// Acceso al almacenamiento local de la memoria del Agente de Aprendizaje.
///
/// Correcciones e interacciones comparten una única clave (`bt_aprendizaje`)
/// con la forma `{correcciones: [...], clics: [...]}`, heredada del prototipo
/// HTML. El datasource preserva ese formato para no invalidar datos ya
/// guardados, y expone las dos colecciones por separado.
abstract interface class AprendizajeLocalDataSource {
  Result<List<CorreccionModel>> leerCorrecciones();
  Result<void> guardarCorrecciones(List<Correccion> correcciones);

  Result<List<InteraccionLectorModel>> leerInteracciones();
  Result<void> guardarInteracciones(List<InteraccionLector> interacciones);
}

class AprendizajeLocalDataSourceImpl implements AprendizajeLocalDataSource {
  const AprendizajeLocalDataSourceImpl(this._store);

  final KeyValueStore _store;

  static const _claveCorrecciones = 'correcciones';

  /// Se llamaba 'clics' en el prototipo; se conserva el nombre en disco.
  static const _claveInteracciones = 'clics';

  @override
  Result<List<CorreccionModel>> leerCorrecciones() => _leerLista(
        _claveCorrecciones,
        CorreccionModel.fromJson,
      );

  @override
  Result<void> guardarCorrecciones(List<Correccion> correcciones) =>
      _guardarLista(
        _claveCorrecciones,
        correcciones.map((c) => CorreccionModel.fromEntity(c).toJson()).toList(),
      );

  @override
  Result<List<InteraccionLectorModel>> leerInteracciones() => _leerLista(
        _claveInteracciones,
        InteraccionLectorModel.fromJson,
      );

  @override
  Result<void> guardarInteracciones(List<InteraccionLector> interacciones) =>
      _guardarLista(
        _claveInteracciones,
        interacciones
            .map((i) => InteraccionLectorModel.fromEntity(i).toJson())
            .toList(),
      );

  Result<Map<String, dynamic>> _leerDocumento() {
    try {
      final raw = _store.read(ClavesAlmacenamiento.aprendizaje);
      if (raw == null || raw.isEmpty) {
        return const Exito({_claveCorrecciones: [], _claveInteracciones: []});
      }
      return Exito(jsonDecode(raw) as Map<String, dynamic>);
    } on Object {
      return const Fallo(
          CacheFailure('No se pudo leer la memoria de aprendizaje'));
    }
  }

  Result<List<T>> _leerLista<T>(
    String clave,
    T Function(Map<String, dynamic>) desdeJson,
  ) {
    final documento = _leerDocumento();
    if (documento case Fallo(:final failure)) return Fallo(failure);

    try {
      final lista = documento.valorONull![clave] as List<dynamic>? ?? [];
      return Exito(
        lista.map((e) => desdeJson(e as Map<String, dynamic>)).toList(),
      );
    } on Object {
      return Fallo(CacheFailure('No se pudo leer "$clave"'));
    }
  }

  Result<void> _guardarLista(String clave, List<Map<String, dynamic>> lista) {
    final documento = _leerDocumento();
    if (documento case Fallo(:final failure)) return Fallo(failure);

    try {
      final data = {...documento.valorONull!, clave: lista};
      _store.write(ClavesAlmacenamiento.aprendizaje, jsonEncode(data));
      return const Exito(null);
    } on Object {
      return Fallo(CacheFailure('No se pudo guardar "$clave"'));
    }
  }
}
