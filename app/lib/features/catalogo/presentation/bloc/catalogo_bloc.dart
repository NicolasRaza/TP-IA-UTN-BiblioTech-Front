import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/result.dart';
import '../../../../core/presentation/estado_carga.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/entities/ejemplar.dart';
import '../../domain/entities/libro.dart';
import '../../domain/usecases/agregar_ejemplar.dart';
import '../../domain/usecases/buscar_libros.dart';
import '../../domain/usecases/consultas_catalogo.dart';
import '../../domain/usecases/obtener_catalogo.dart';
import '../../domain/usecases/registrar_libro.dart';
import '../../domain/usecases/reimprimir_etiqueta.dart';
import '../../domain/usecases/validar_libro.dart';

part 'catalogo_event.dart';
part 'catalogo_state.dart';

/// Catálogo e inventario.
///
/// Va como Bloc y no como Cubit porque concentra intenciones bien distintas
/// —buscar, filtrar, dar de alta, validar, reimprimir— y el registro de
/// eventos deja la trazabilidad de qué disparó cada cambio.
class CatalogoBloc extends Bloc<CatalogoEvent, CatalogoState> {
  CatalogoBloc({
    required ObtenerCatalogo obtenerCatalogo,
    required BuscarLibros buscarLibros,
    required ObtenerGeneros obtenerGeneros,
    required ObtenerPendientesValidacion obtenerPendientesValidacion,
    required RegistrarLibro registrarLibro,
    required ValidarLibro validarLibro,
    required AgregarEjemplar agregarEjemplar,
    required ReimprimirEtiqueta reimprimirEtiqueta,
    required String? Function() usuarioActualId,
  })  : _obtenerCatalogo = obtenerCatalogo,
        _buscarLibros = buscarLibros,
        _obtenerGeneros = obtenerGeneros,
        _obtenerPendientes = obtenerPendientesValidacion,
        _registrarLibro = registrarLibro,
        _validarLibro = validarLibro,
        _agregarEjemplar = agregarEjemplar,
        _reimprimirEtiqueta = reimprimirEtiqueta,
        _usuarioActualId = usuarioActualId,
        super(const CatalogoState()) {
    on<CatalogoSolicitado>(_alSolicitarCatalogo);
    // restartable: si el usuario sigue tecleando, la búsqueda anterior se
    // cancela y sólo sobrevive la última.
    on<BusquedaCambiada>(_alCambiarBusqueda, transformer: restartable());
    on<GeneroCambiado>(_alCambiarGenero, transformer: restartable());
    on<LibroRegistrado>(_alRegistrarLibro);
    on<LibroValidado>(_alValidarLibro);
    on<EjemplarAgregado>(_alAgregarEjemplar);
    on<EtiquetaReimpresa>(_alReimprimirEtiqueta);
    on<MensajeCatalogoDescartado>(
      (_, emit) => emit(state.copyWith(limpiarMensajes: true)),
    );
  }

  final ObtenerCatalogo _obtenerCatalogo;
  final BuscarLibros _buscarLibros;
  final ObtenerGeneros _obtenerGeneros;
  final ObtenerPendientesValidacion _obtenerPendientes;
  final RegistrarLibro _registrarLibro;
  final ValidarLibro _validarLibro;
  final AgregarEjemplar _agregarEjemplar;
  final ReimprimirEtiqueta _reimprimirEtiqueta;

  /// Quién está operando, para la traza de auditoría. Se inyecta como función
  /// para no acoplar este bloc al de sesión.
  final String? Function() _usuarioActualId;

  Future<void> _alSolicitarCatalogo(
    CatalogoSolicitado event,
    Emitter<CatalogoState> emit,
  ) async {
    emit(state.copyWith(estado: EstadoCarga.cargando, limpiarMensajes: true));
    await _recargar(emit);
  }

  Future<void> _alCambiarBusqueda(
    BusquedaCambiada event,
    Emitter<CatalogoState> emit,
  ) async {
    emit(state.copyWith(texto: event.texto));
    await _aplicarFiltros(emit, texto: event.texto, genero: state.genero);
  }

  Future<void> _alCambiarGenero(
    GeneroCambiado event,
    Emitter<CatalogoState> emit,
  ) async {
    emit(state.copyWith(genero: event.genero));
    await _aplicarFiltros(emit, texto: state.texto, genero: event.genero);
  }

  Future<void> _alRegistrarLibro(
    LibroRegistrado event,
    Emitter<CatalogoState> emit,
  ) async {
    final resultado = await _registrarLibro(RegistrarLibroParams(
      libro: event.libro,
      usuarioId: _usuarioActualId(),
    ));

    await resultado.fold(
      (failure) async => emit(state.copyWith(mensajeError: failure.mensaje)),
      (libro) async {
        await _recargar(emit);
        emit(state.copyWith(
          mensajeExito: '"${libro.titulo}" quedó pendiente de validación',
        ));
      },
    );
  }

  Future<void> _alValidarLibro(
    LibroValidado event,
    Emitter<CatalogoState> emit,
  ) async {
    final resultado = await _validarLibro(ValidarLibroParams(
      libroId: event.libroId,
      usuarioId: _usuarioActualId(),
    ));

    await resultado.fold(
      (failure) async => emit(state.copyWith(mensajeError: failure.mensaje)),
      (libro) async {
        await _recargar(emit);
        emit(state.copyWith(
          mensajeExito: '"${libro.titulo}" ya está en el catálogo público',
        ));
      },
    );
  }

  Future<void> _alAgregarEjemplar(
    EjemplarAgregado event,
    Emitter<CatalogoState> emit,
  ) async {
    final resultado = await _agregarEjemplar(AgregarEjemplarParams(
      libroId: event.libroId,
      condicion: event.condicion,
    ));

    await resultado.fold(
      (failure) async => emit(state.copyWith(mensajeError: failure.mensaje)),
      (ejemplar) async {
        await _recargar(emit);
        emit(state.copyWith(mensajeExito: 'Ejemplar ${ejemplar.qr} agregado'));
      },
    );
  }

  Future<void> _alReimprimirEtiqueta(
    EtiquetaReimpresa event,
    Emitter<CatalogoState> emit,
  ) async {
    final resultado = await _reimprimirEtiqueta(ReimprimirEtiquetaParams(
      libroId: event.libroId,
      ejemplarId: event.ejemplarId,
      motivo: event.motivo,
      usuarioId: _usuarioActualId(),
    ));

    await resultado.fold(
      (failure) async => emit(state.copyWith(mensajeError: failure.mensaje)),
      (ejemplar) async {
        await _recargar(emit);
        emit(state.copyWith(
          mensajeExito: 'Etiqueta ${ejemplar.qr} reimpresa. '
              'El código es el mismo de siempre.',
        ));
      },
    );
  }

  /// Relee catálogo, inventario, pendientes y géneros, y reaplica el filtro
  /// vigente para que la vista no se resetee después de una operación.
  Future<void> _recargar(Emitter<CatalogoState> emit) async {
    final todos = await _obtenerCatalogo(
        const ObtenerCatalogoParams(soloValidados: false));
    if (todos case Fallo(:final failure)) {
      emit(state.copyWith(
        estado: EstadoCarga.error,
        mensajeError: failure.mensaje,
      ));
      return;
    }

    final generos = await _obtenerGeneros(const SinParametros());
    final pendientes = await _obtenerPendientes(const SinParametros());
    final filtrados = await _buscarLibros(
      BuscarLibrosParams(texto: state.texto, genero: state.genero),
    );

    emit(state.copyWith(
      estado: EstadoCarga.exito,
      todosLosLibros: todos.valorONull,
      generos: generos.valorONull ?? const [],
      pendientesValidacion: pendientes.valorONull ?? const [],
      libros: filtrados.valorONull ?? const [],
    ));
  }

  Future<void> _aplicarFiltros(
    Emitter<CatalogoState> emit, {
    required String texto,
    required String genero,
  }) async {
    final resultado =
        await _buscarLibros(BuscarLibrosParams(texto: texto, genero: genero));

    resultado.fold(
      (failure) => emit(state.copyWith(
        estado: EstadoCarga.error,
        mensajeError: failure.mensaje,
      )),
      (libros) => emit(state.copyWith(
        estado: EstadoCarga.exito,
        libros: libros,
      )),
    );
  }
}
