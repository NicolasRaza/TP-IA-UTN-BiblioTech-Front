import '../../../../core/error/failures.dart';
import '../../../../core/error/result.dart';
import '../../../agentes/domain/entities/ficha_sugerida.dart';
import '../../domain/entities/ejemplar.dart';
import '../../domain/entities/libro.dart';
import '../../domain/repositories/catalogo_repository.dart';
import '../datasources/catalogo_api_datasource.dart';

/// Implementación del [CatalogoRepository] contra la API del backend.
///
/// El contrato de dominio es el mismo que cumple `CatalogoRepositoryImpl`
/// sobre el almacenamiento local: los casos de uso no distinguen cuál de las
/// dos está montada. Lo que cambia es dónde vive la verdad —acá, en el
/// servidor— y qué operaciones existen.
///
/// El listado y el detalle traen distinto nivel de detalle, a propósito:
///
/// - `GET /titulos` informa `total_ejemplares` y `ejemplares_disponibles`,
///   que es todo lo que necesita una grilla de catálogo. Los `Libro` del
///   listado llegan con esos conteos y `ejemplares` vacía: pedir la lista de
///   cada título sería un request por fila para un dato que la grilla no usa.
/// - `obtenerPorId` sí completa los ejemplares con
///   `GET /titulos/{id}/ejemplares`, que es de donde salen los códigos QR
///   reales para la ficha y el inventario.
///
/// Queda un hueco de la API: `GET /titulos` devuelve únicamente títulos
/// validados, así que el backend no expone los pendientes de revisión.
/// `obtenerPendientesValidacion` devuelve vacío en vez de simular una bandeja
/// de entrada.
class CatalogoRepositoryApi implements CatalogoRepository {
  const CatalogoRepositoryApi(this._api);

  final CatalogoApiDataSource _api;

  @override
  Future<Result<List<Libro>>> obtenerTodos() => _api.buscarTitulos();

  @override
  Future<Result<List<Libro>>> obtenerCatalogoPublico() => _api.buscarTitulos();

  @override
  Future<Result<List<Libro>>> obtenerPendientesValidacion() async =>
      const Exito([]);

  @override
  Future<Result<Libro>> obtenerPorId(String libroId) async {
    final tituloResult = await _api.obtenerTitulo(libroId);
    if (tituloResult case Fallo(:final failure)) return Fallo(failure);

    final ejemplaresResult = await _api.listarEjemplares(libroId);
    if (ejemplaresResult case Fallo(:final failure)) return Fallo(failure);

    return Exito(
      tituloResult.valorONull!.copyWith(
        ejemplares: ejemplaresResult.valorONull!,
      ),
    );
  }

  @override
  Future<Result<List<Libro>>> buscar({
    String texto = '',
    String genero = 'Todos',
  }) =>
      // El filtrado lo hace el servidor: es su índice el que decide qué
      // coincide, y así la búsqueda no depende de cuánto catálogo bajó la app.
      _api.buscarTitulos(texto: texto, genero: genero);

  @override
  Future<Result<List<String>>> obtenerGeneros() async {
    // La API no expone los géneros por separado, pero sí vienen en cada
    // título: se derivan del catálogo en lugar de hardcodear una lista.
    final catalogo = await _api.buscarTitulos();
    if (catalogo case Fallo(:final failure)) return Fallo(failure);

    final generos = catalogo.valorONull!
        .map((l) => l.genero)
        .where((g) => g.isNotEmpty)
        .toSet()
        .toList()
      ..sort();

    return Exito(generos);
  }

  @override
  Future<Result<EjemplarLocalizado>> buscarPorQr(String qr) async {
    final ejemplarResult = await _api.buscarEjemplarPorQr(qr);
    if (ejemplarResult case Fallo(:final failure)) return Fallo(failure);
    final ejemplar = ejemplarResult.valorONull!;

    // El ejemplar sólo trae el id de su título; el mostrador necesita también
    // la ficha para poder mostrar de qué libro se trata.
    final libroResult = await obtenerPorId(ejemplar.libroId);
    if (libroResult case Fallo(:final failure)) return Fallo(failure);

    return Exito((libro: libroResult.valorONull!, ejemplar: ejemplar));
  }

  @override
  Future<Result<Libro>> crear(Libro libro) => _api.crearTitulo(libro);

  @override
  Future<Result<Libro>> actualizar(Libro libro) async {
    // `validado` no es un campo editable del título: se cambia con la ruta de
    // validación, que es la que publica el libro en el catálogo.
    if (libro.validado) {
      final validado = await _api.validarTitulo(libro);
      if (validado.esExito) return validado;
      // Si el título ya estaba publicado, validarlo otra vez es un 409; la
      // edición común sigue siendo válida y se intenta igual.
      if (validado.failureONull is! ReglaDeNegocioFailure) return validado;
    }
    return _api.editarTitulo(libro);
  }

  @override
  Future<Result<FichaSugerida>> capturarOcr({
    required List<int> fotoTapa,
    required List<int> fotoContratapa,
    required List<int> fotoFicha,
    String? extensionTapa,
    String? extensionContratapa,
    String? extensionFicha,
  }) {
    return _api.capturarOcr(
      fotoTapa: fotoTapa,
      fotoContratapa: fotoContratapa,
      fotoFicha: fotoFicha,
      extensionTapa: extensionTapa,
      extensionContratapa: extensionContratapa,
      extensionFicha: extensionFicha,
    );
  }

  @override
  Future<Result<void>> eliminar(String libroId) async => const Fallo(
        ReglaDeNegocioFailure(
          'La API no permite borrar títulos: se dan de baja sus ejemplares',
        ),
      );

  @override
  Future<Result<Ejemplar>> agregarEjemplar(
    String libroId,
    CondicionEjemplar condicion,
  ) =>
      // El alta va por su propia ruta: el backend asigna el id y el código QR
      // de la etiqueta. Mandar el título entero con un ejemplar más no daría
      // de alta nada, porque `PATCH /titulos/{id}` no toca los ejemplares.
      _api.crearEjemplar(libroId: libroId, condicion: condicion);

  @override
  Future<Result<Ejemplar>> cambiarEstadoEjemplar(
    String libroId,
    String ejemplarId,
    EstadoEjemplar estado,
  ) async {
    // El estado del ejemplar lo mueve el propio backend al registrar un
    // préstamo o una devolución; la única transición que expone como ruta
    // propia es la baja. Forzar las otras desde la app duplicaría la lógica
    // que el servidor ya aplica dentro de la misma transacción.
    if (estado != EstadoEjemplar.baja) {
      return const Fallo(ReglaDeNegocioFailure(
        'El estado del ejemplar lo administra el servidor al prestar o '
        'devolver',
      ));
    }

    final baja = await _api.darDeBajaEjemplar(ejemplarId);
    if (baja case Fallo(:final failure)) return Fallo(failure);

    return Exito(Ejemplar(
      id: ejemplarId,
      libroId: libroId,
      condicion: CondicionEjemplar.malo,
      estado: EstadoEjemplar.baja,
    ));
  }
}
