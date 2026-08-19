import '../../../../core/error/failures.dart';
import '../../../../core/error/result.dart';
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
/// **Dos huecos de la API v1**, resueltos sin inventar datos:
///
/// - `GET /titulos` devuelve únicamente títulos validados, así que el backend
///   no tiene forma de listar los pendientes de revisión. `obtenerTodos` y
///   `obtenerPendientesValidacion` devuelven, respectivamente, el catálogo
///   público y una lista vacía, en lugar de simular una bandeja de entrada.
/// - No hay ruta que liste los ejemplares de un título; sólo el conteo y la
///   búsqueda por QR. Los `Libro` que salen de acá traen los totales
///   informados por el servidor y `ejemplares` vacía.
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
  Future<Result<Libro>> obtenerPorId(String libroId) =>
      _api.obtenerTitulo(libroId);

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
    final libroResult = await _api.obtenerTitulo(ejemplar.libroId);
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
  Future<Result<void>> eliminar(String libroId) async => const Fallo(
        ReglaDeNegocioFailure(
          'La API no permite borrar títulos: se dan de baja sus ejemplares',
        ),
      );

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
