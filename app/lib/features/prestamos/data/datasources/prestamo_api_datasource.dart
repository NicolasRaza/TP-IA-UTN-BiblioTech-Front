import '../../../../core/api/cliente_api.dart';
import '../../../../core/api/mapeo_api.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/error/result.dart';
import '../../../lectores/domain/entities/lector.dart';
import '../../domain/entities/prestamo.dart';

/// Acceso a la circulación del backend SGB (`/api/v1/prestamos`).
///
/// El préstamo y la devolución son transacciones del servidor: verifica cupo,
/// multas y disponibilidad, mueve el estado del ejemplar y calcula el plazo
/// según la categoría del lector, todo dentro del mismo commit. La app no
/// reproduce nada de eso; manda el QR y el lector, y guarda lo que vuelve.
abstract interface class PrestamoApiDataSource {
  /// `POST /prestamos` — el ejemplar se identifica por su etiqueta.
  Future<Result<Prestamo>> prestar({
    required String qrEjemplar,
    required String lectorId,
  });

  /// `POST /prestamos/devolucion`.
  Future<Result<Prestamo>> devolver(String qrEjemplar);

  /// `GET /prestamos/lector/{id}`.
  Future<Result<List<Prestamo>>> deLector(String lectorId);

  /// `GET /prestamos` — la circulación completa. Pide rol bibliotecario.
  Future<Result<List<Prestamo>>> todos();
}

class PrestamoApiDataSourceHttp implements PrestamoApiDataSource {
  const PrestamoApiDataSourceHttp(this._api);

  final ClienteApi _api;

  @override
  Future<Result<Prestamo>> prestar({
    required String qrEjemplar,
    required String lectorId,
  }) {
    final id = idHaciaApi(lectorId);
    if (id == null) {
      return Future.value(const Fallo(
        NoEncontradoFailure('Ese lector no existe en el servidor'),
      ));
    }
    return _api.post<Prestamo>(
      '/api/v1/prestamos',
      cuerpo: {'qr_ejemplar': qrEjemplar, 'lector_id': id},
      leer: _leerPrestamo,
    );
  }

  @override
  Future<Result<Prestamo>> devolver(String qrEjemplar) => _api.post<Prestamo>(
        '/api/v1/prestamos/devolucion',
        cuerpo: {'qr_ejemplar': qrEjemplar},
        leer: _leerPrestamo,
      );

  @override
  Future<Result<List<Prestamo>>> deLector(String lectorId) {
    final id = idHaciaApi(lectorId);
    if (id == null) return Future.value(const Exito([]));
    return _api.get<List<Prestamo>>(
      '/api/v1/prestamos/lector/$id',
      leer: _leerLista,
    );
  }

  @override
  Future<Result<List<Prestamo>>> todos() => _api.get<List<Prestamo>>(
        '/api/v1/prestamos',
        leer: _leerLista,
      );

  static Prestamo _leerPrestamo(Object? json) =>
      prestamoDesdeApi(json as Map<String, dynamic>);

  static List<Prestamo> _leerLista(Object? json) =>
      (json as List<Object?>? ?? const [])
          .map((e) => prestamoDesdeApi(e as Map<String, dynamic>))
          .toList();
}

/// Traduce un `PrestamoResponse` del backend.
///
/// Dos campos del dominio no tienen equivalente en esa respuesta:
///
/// - **categoriaAlPrestar / plazoDiasAlPrestar**: el backend aplica el plazo
///   de la categoría pero no lo guarda en el préstamo, así que la regla de
///   transición de categoría (spec §7) queda del lado del servidor. Se
///   reconstruye el plazo restando las dos fechas, que es exactamente el que
///   se aplicó, y la categoría se deja en la de por defecto.
/// - **multaAplicada**: las multas del backend son registros aparte
///   (`/api/v1/multas`), no un acumulado dentro del préstamo.
///
/// `titulo_id` es parte del contrato —está en `PrestamoResponse` y aparece en
/// el OpenAPI—, pero hoy sólo lo completan `POST /prestamos` y
/// `GET /prestamos`; `GET /prestamos/lector/{id}` y la devolución lo dejan en
/// `null`, porque devuelven el `model_validate` sin asignarlo.
///
/// Por eso el campo se lee siempre que traiga valor y sólo se cae a vacío
/// cuando llega nulo: apuntar a un título equivocado sería peor que no
/// apuntar a ninguno. El día que el backend lo complete en las cuatro rutas,
/// esto empieza a funcionar sin tocar una línea de la app.
Prestamo prestamoDesdeApi(Map<String, dynamic> json) {
  final inicio = fechaDesdeApi(json['fecha_inicio'], DateTime.now());
  final vencimiento = fechaDesdeApi(json['fecha_devolucion_pactada'], inicio);
  final devolucion = fechaOpcionalDesdeApi(json['fecha_devolucion_real']);

  return Prestamo(
    id: idDesdeApi(json['id']),
    lectorId: idDesdeApi(json['lector_id']),
    ejemplarId: idDesdeApi(json['ejemplar_id']),
    libroId: json['titulo_id'] == null ? '' : idDesdeApi(json['titulo_id']),
    fechaPrestamo: inicio,
    fechaVencimiento: vencimiento,
    fechaDevolucion: devolucion,
    estado: estadoPrestamoDesdeApi(json['estado'] as String?),
    tardio: devolucion != null && devolucion.isAfter(vencimiento),
    categoriaAlPrestar: CategoriaLector.adulto,
    plazoDiasAlPrestar: vencimiento.difference(inicio).inDays,
  );
}
