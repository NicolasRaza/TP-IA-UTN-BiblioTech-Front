import 'package:bibliotech/core/error/failures.dart';
import 'package:bibliotech/core/error/result.dart';
import 'package:bibliotech/core/services/reloj.dart';
import 'package:bibliotech/features/agentes/domain/entities/ficha_sugerida.dart';
import 'package:bibliotech/features/catalogo/domain/entities/ejemplar.dart';
import 'package:bibliotech/features/catalogo/domain/entities/libro.dart';
import 'package:bibliotech/features/catalogo/domain/repositories/catalogo_repository.dart';
import 'catalogo_local_datasource.dart';

/// Implementación del [CatalogoRepository] sobre el almacenamiento local.
///
/// Sólo traduce entre el contrato de dominio y el datasource: no toma
/// decisiones de negocio. La Regla de Validación Estricta, por ejemplo, se
/// aplica en el caso de uso `RegistrarLibro`; acá sólo se filtra por el flag
/// `validado`, que es una consulta, no una regla.
class CatalogoRepositoryImpl implements CatalogoRepository {
  const CatalogoRepositoryImpl({
    required CatalogoLocalDataSource localDataSource,
    required GeneradorId generadorId,
  })  : _local = localDataSource,
        _generadorId = generadorId;

  final CatalogoLocalDataSource _local;
  final GeneradorId _generadorId;

  @override
  Future<Result<List<Libro>>> obtenerTodos() async =>
      _local.leer().map((libros) => libros.cast<Libro>());

  @override
  Future<Result<List<Libro>>> obtenerCatalogoPublico() async =>
      _local.leer().map(
            (libros) => libros.where((l) => l.validado).cast<Libro>().toList(),
          );

  @override
  Future<Result<List<Libro>>> obtenerPendientesValidacion() async =>
      _local.leer().map(
            (libros) => libros.where((l) => !l.validado).cast<Libro>().toList(),
          );

  @override
  Future<Result<Libro>> obtenerPorId(String libroId) async {
    final leidos = _local.leer();
    if (leidos case Fallo(:final failure)) return Fallo(failure);

    for (final l in leidos.valorONull!) {
      if (l.id == libroId) return Exito(l);
    }
    return const Fallo(NoEncontradoFailure('El libro no existe'));
  }

  @override
  Future<Result<List<Libro>>> buscar({
    String texto = '',
    String genero = 'Todos',
  }) async {
    final leidos = _local.leer();
    if (leidos case Fallo(:final failure)) return Fallo(failure);

    var lista = leidos.valorONull!.where((l) => l.validado).cast<Libro>();

    if (texto.trim().isNotEmpty) {
      lista = lista.where((l) => l.coincideCon(texto));
    }
    if (genero != 'Todos' && genero.isNotEmpty) {
      lista = lista.where((l) => l.genero == genero);
    }

    return Exito(lista.toList());
  }

  @override
  Future<Result<List<String>>> obtenerGeneros() async {
    final leidos = _local.leer();
    if (leidos case Fallo(:final failure)) return Fallo(failure);

    final generos = leidos.valorONull!
        .where((l) => l.validado)
        .map((l) => l.genero)
        .where((g) => g.isNotEmpty)
        .toSet()
        .toList()
      ..sort();

    return Exito(generos);
  }

  @override
  Future<Result<EjemplarLocalizado>> buscarPorQr(String qr) async {
    final leidos = _local.leer();
    if (leidos case Fallo(:final failure)) return Fallo(failure);

    for (final libro in leidos.valorONull!) {
      for (final ejemplar in libro.ejemplares) {
        if (ejemplar.qr == qr) {
          return Exito((libro: libro as Libro, ejemplar: ejemplar));
        }
      }
    }
    return const Fallo(
        NoEncontradoFailure('Ninguna etiqueta coincide con ese código'));
  }

  @override
  Future<Result<Libro>> crear(Libro libro) async {
    final leidos = _local.leer();
    if (leidos case Fallo(:final failure)) return Fallo(failure);

    // Un id vacío significa "asigname uno": así el dominio construye la
    // entidad sin depender de cómo se generan los identificadores.
    final nuevo = libro.id.isEmpty
        ? _conId(libro, 'lib-${_generadorId.generar()}')
        : libro;

    final lista = [...leidos.valorONull!, nuevo];
    final guardado = _local.guardar(lista);
    if (guardado case Fallo(:final failure)) return Fallo(failure);

    return Exito(nuevo);
  }

  @override
  Future<Result<Libro>> actualizar(Libro libro) async {
    final leidos = _local.leer();
    if (leidos case Fallo(:final failure)) return Fallo(failure);

    final lista = leidos.valorONull!.cast<Libro>().toList();
    final i = lista.indexWhere((l) => l.id == libro.id);
    if (i < 0) return const Fallo(NoEncontradoFailure('El libro no existe'));

    lista[i] = libro;
    final guardado = _local.guardar(lista);
    if (guardado case Fallo(:final failure)) return Fallo(failure);

    return Exito(libro);
  }

  @override
  Future<Result<FichaSugerida>> capturarOcr({
    required List<int> fotoTapa,
    required List<int> fotoContratapa,
    required List<int> fotoFicha,
    String? extensionTapa,
    String? extensionContratapa,
    String? extensionFicha,
  }) async {
    throw UnimplementedError(
      'El doble local no soporta OCR: es una capacidad exclusiva del backend',
    );
  }

  @override
  Future<Result<void>> eliminar(String libroId) async {
    final leidos = _local.leer();
    if (leidos case Fallo(:final failure)) return Fallo(failure);

    final lista = leidos.valorONull!.cast<Libro>().toList()
      ..removeWhere((l) => l.id == libroId);

    return _local.guardar(lista);
  }

  @override
  Future<Result<Ejemplar>> agregarEjemplar(
    String libroId,
    CondicionEjemplar condicion,
  ) async {
    final libroResult = await obtenerPorId(libroId);
    if (libroResult case Fallo(:final failure)) return Fallo(failure);
    final libro = libroResult.valorONull!;

    final nuevo = Ejemplar(
      id: 'ej-${_generadorId.generar()}',
      libroId: libroId,
      condicion: condicion,
      estado: EstadoEjemplar.disponible,
    );

    final guardado = await actualizar(
      libro.copyWith(ejemplares: [...libro.ejemplares, nuevo]),
    );
    if (guardado case Fallo(:final failure)) return Fallo(failure);

    return Exito(nuevo);
  }

  @override
  Future<Result<Ejemplar>> cambiarEstadoEjemplar(
    String libroId,
    String ejemplarId,
    EstadoEjemplar estado,
  ) async {
    final libroResult = await obtenerPorId(libroId);
    if (libroResult case Fallo(:final failure)) return Fallo(failure);

    final libro = libroResult.valorONull!;
    if (libro.ejemplar(ejemplarId) == null) {
      return const Fallo(NoEncontradoFailure('El ejemplar no existe'));
    }

    final actualizado = libro.conEjemplarActualizado(
      ejemplarId,
      (e) => e.copyWith(estado: estado),
    );

    final guardado = await actualizar(actualizado);
    if (guardado case Fallo(:final failure)) return Fallo(failure);

    return Exito(actualizado.ejemplar(ejemplarId)!);
  }

  Libro _conId(Libro libro, String id) => Libro(
        id: id,
        titulo: libro.titulo,
        autor: libro.autor,
        editorial: libro.editorial,
        anio: libro.anio,
        isbn: libro.isbn,
        sinopsis: libro.sinopsis,
        genero: libro.genero,
        paginas: libro.paginas,
        portada: libro.portada,
        validado: libro.validado,
        fechaAlta: libro.fechaAlta,
        // Los ejemplares cargados junto con el alta apuntan al id provisorio;
        // se reapuntan al definitivo para no romper el QR, que se deriva de él.
        ejemplares: libro.ejemplares
            .map((e) => Ejemplar(
                  id: e.id,
                  libroId: id,
                  condicion: e.condicion,
                  estado: e.estado,
                  reimpresionesQr: e.reimpresionesQr,
                ))
            .toList(),
        camposPendientes: libro.camposPendientes,
      );
}
