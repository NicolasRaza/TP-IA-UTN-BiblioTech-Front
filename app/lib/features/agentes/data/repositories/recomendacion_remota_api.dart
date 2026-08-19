import '../../../../core/api/cliente_api.dart';
import '../../../../core/api/mapeo_api.dart';
import '../../../../core/error/result.dart';
import '../../../catalogo/domain/entities/libro.dart';
import '../../../prestamos/domain/repositories/prestamo_repository.dart';
import '../../domain/entities/recomendacion.dart';
import '../../domain/repositories/recomendacion_remota.dart';

/// Implementación de [RecomendacionRemota] sobre `GET /api/v1/recomendaciones`.
///
/// El backend devuelve los libros ya ordenados por puntaje, pero no el puntaje
/// ni el motivo de cada uno. En vez de inventar una explicación, se informa lo
/// que sí se sabe: la posición en el ranking y de dónde salió la lista.
///
/// El *cold start* sí se puede afirmar con certeza, y es lo que la spec §2
/// pide avisarle al lector: se cuenta su propio historial —que su rol sí puede
/// leer— contra el mismo umbral que usa el servidor.
class RecomendacionRemotaApi implements RecomendacionRemota {
  const RecomendacionRemotaApi({
    required ClienteApi api,
    required PrestamoRepository prestamos,
  })  : _api = api,
        _prestamos = prestamos;

  final ClienteApi _api;
  final PrestamoRepository _prestamos;

  /// `UMBRAL_COLD_START` del backend, que es también el de la spec §2.
  static const umbralColdStart = 5;

  @override
  Future<Result<List<Recomendacion>>> para(
    String lectorId, {
    int limite = 6,
  }) async {
    final historial = await _prestamos.obtenerDeLector(lectorId);
    // Si el historial no se pudo leer, se sigue igual: perder la advertencia de
    // cold start es mejor que quedarse sin recomendaciones.
    final leidos = historial.valorONull?.length ?? 0;
    final esColdStart = leidos <= umbralColdStart;

    final libros = await _api.get<List<Libro>>(
      '/api/v1/recomendaciones',
      leer: (json) => (json as List<Object?>? ?? const [])
          .map((e) => _libroDesdeAgente(e as Map<String, dynamic>))
          .toList(),
    );
    if (libros case Fallo(:final failure)) return Fallo(failure);

    final lista = libros.valorONull!.take(limite).toList();
    return Exito([
      for (var i = 0; i < lista.length; i++)
        Recomendacion(
          libro: lista[i],
          // El servidor no publica el puntaje: se usa la posición, que es la
          // información de orden que sí devuelve.
          puntaje: (lista.length - i).toDouble(),
          motivo: esColdStart
              ? 'Entre lo más pedido de la biblioteca'
              : 'Por lo que venís leyendo y lo más pedido',
          esColdStart: esColdStart,
        ),
    ]);
  }

  /// El endpoint de recomendaciones no devuelve un `TituloResponse` sino el
  /// shape con el que trabajan los agentes del backend, que ya usa el
  /// vocabulario del dominio (`autor`, `anio`, `portada`, `validado`).
  static Libro _libroDesdeAgente(Map<String, dynamic> json) => Libro(
        id: '${json['id']}',
        titulo: json['titulo'] as String? ?? '',
        autor: json['autor'] as String? ?? '',
        editorial: json['editorial'] as String? ?? '',
        anio: int.tryParse('${json['anio'] ?? ''}'),
        isbn: json['isbn'] as String? ?? '',
        sinopsis: json['sinopsis'] as String? ?? '',
        genero: json['genero'] as String? ?? '',
        paginas: int.tryParse('${json['paginas'] ?? ''}'),
        portada: json['portada'] as String? ?? '',
        validado: json['validado'] as bool? ?? true,
        fechaAlta: fechaDesdeApi(json['fechaAlta'], DateTime.now()),
      );
}
