part of 'catalogo_bloc.dart';

/// Estado del catálogo, compartido por la vista del lector y el inventario
/// del bibliotecario.
class CatalogoState extends Equatable {
  const CatalogoState({
    this.estado = EstadoCarga.inicial,
    this.libros = const [],
    this.todosLosLibros = const [],
    this.pendientesValidacion = const [],
    this.generos = const [],
    this.texto = '',
    this.genero = 'Todos',
    this.mensajeError,
    this.mensajeExito,
  });

  final EstadoCarga estado;

  /// Catálogo público ya filtrado por texto y género.
  final List<Libro> libros;

  /// Inventario completo, validado o no. Es la vista del bibliotecario.
  final List<Libro> todosLosLibros;

  /// Altas que esperan confirmación (spec v2 §7).
  final List<Libro> pendientesValidacion;

  final List<String> generos;
  final String texto;
  final String genero;

  final String? mensajeError;
  final String? mensajeExito;

  bool get hayFiltroActivo => texto.isNotEmpty || genero != 'Todos';

  CatalogoState copyWith({
    EstadoCarga? estado,
    List<Libro>? libros,
    List<Libro>? todosLosLibros,
    List<Libro>? pendientesValidacion,
    List<String>? generos,
    String? texto,
    String? genero,
    String? mensajeError,
    String? mensajeExito,
    bool limpiarMensajes = false,
  }) =>
      CatalogoState(
        estado: estado ?? this.estado,
        libros: libros ?? this.libros,
        todosLosLibros: todosLosLibros ?? this.todosLosLibros,
        pendientesValidacion: pendientesValidacion ?? this.pendientesValidacion,
        generos: generos ?? this.generos,
        texto: texto ?? this.texto,
        genero: genero ?? this.genero,
        mensajeError: limpiarMensajes ? null : mensajeError,
        mensajeExito: limpiarMensajes ? null : mensajeExito,
      );

  @override
  List<Object?> get props => [
        estado,
        libros,
        todosLosLibros,
        pendientesValidacion,
        generos,
        texto,
        genero,
        mensajeError,
        mensajeExito,
      ];
}
