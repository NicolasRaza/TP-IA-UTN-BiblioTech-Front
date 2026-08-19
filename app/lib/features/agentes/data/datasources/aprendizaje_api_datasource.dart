import '../../../../core/api/cliente_api.dart';
import '../../../../core/api/mapeo_api.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/error/result.dart';
import '../../domain/entities/recomendacion.dart';

/// Memoria del Agente de Aprendizaje en el backend (`/api/v1/aprendizaje`).
///
/// Las lecturas son del personal: la señal sirve agregada sobre todos los
/// lectores, y es el reporte del panel de administración el único que la
/// consume. Registrar una interacción, en cambio, lo hace el propio lector
/// mientras navega, y el backend verifica que sea sobre sí mismo.
abstract interface class AprendizajeApiDataSource {
  Future<Result<List<InteraccionLector>>> listarInteracciones();

  Future<Result<void>> registrarInteraccion(InteraccionLector interaccion);

  Future<Result<List<Correccion>>> listarCorrecciones();

  Future<Result<void>> registrarCorreccion(Correccion correccion);
}

class AprendizajeApiDataSourceHttp implements AprendizajeApiDataSource {
  const AprendizajeApiDataSourceHttp(this._api);

  final ClienteApi _api;

  @override
  Future<Result<List<InteraccionLector>>> listarInteracciones() =>
      _api.get<List<InteraccionLector>>(
        '/api/v1/aprendizaje/interacciones',
        leer: (json) => (json as List<Object?>? ?? const [])
            .map((e) => _interaccionDesdeApi(e as Map<String, dynamic>))
            .toList(),
      );

  @override
  Future<Result<void>> registrarInteraccion(InteraccionLector interaccion) {
    final lectorId = idHaciaApi(interaccion.lectorId);
    final libroId = idHaciaApi(interaccion.libroId);
    if (lectorId == null || libroId == null) {
      return Future.value(const Fallo(
        NoEncontradoFailure('Ese registro no existe en el servidor'),
      ));
    }

    return _api.post<void>(
      '/api/v1/aprendizaje/interacciones',
      cuerpo: {
        'lector_id': lectorId,
        'titulo_id': libroId,
        'tipo': interaccion.tipo,
      },
      leer: (_) {},
    );
  }

  @override
  Future<Result<List<Correccion>>> listarCorrecciones() =>
      _api.get<List<Correccion>>(
        '/api/v1/aprendizaje/correcciones',
        leer: (json) => (json as List<Object?>? ?? const [])
            .map((e) => _correccionDesdeApi(e as Map<String, dynamic>))
            .toList(),
      );

  @override
  Future<Result<void>> registrarCorreccion(Correccion correccion) =>
      _api.post<void>(
        '/api/v1/aprendizaje/correcciones',
        cuerpo: {
          'campo': correccion.campo,
          'valor_sugerido': correccion.valorSugerido,
          'valor_final': correccion.valorFinal,
        },
        leer: (_) {},
      );
}

InteraccionLector _interaccionDesdeApi(Map<String, dynamic> json) =>
    InteraccionLector(
      lectorId: idDesdeApi(json['lector_id']),
      libroId: idDesdeApi(json['titulo_id']),
      tipo: (json['tipo'] as String?) ?? '',
      fecha: fechaDesdeApi(json['creado_en'], DateTime.now()),
    );

Correccion _correccionDesdeApi(Map<String, dynamic> json) => Correccion(
      campo: (json['campo'] as String?) ?? '',
      valorSugerido: (json['valor_sugerido'] as String?) ?? '',
      valorFinal: (json['valor_final'] as String?) ?? '',
      fecha: fechaDesdeApi(json['creado_en'], DateTime.now()),
    );
