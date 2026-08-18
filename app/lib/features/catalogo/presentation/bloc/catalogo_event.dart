part of 'catalogo_bloc.dart';

sealed class CatalogoEvent extends Equatable {
  const CatalogoEvent();

  @override
  List<Object?> get props => const [];
}

/// Carga inicial del catálogo y de los géneros disponibles.
class CatalogoSolicitado extends CatalogoEvent {
  const CatalogoSolicitado();
}

/// El lector escribió en el buscador.
class BusquedaCambiada extends CatalogoEvent {
  const BusquedaCambiada(this.texto);

  final String texto;

  @override
  List<Object?> get props => [texto];
}

/// El lector eligió un género en el filtro.
class GeneroCambiado extends CatalogoEvent {
  const GeneroCambiado(this.genero);

  final String genero;

  @override
  List<Object?> get props => [genero];
}

/// El bibliotecario da de alta un título nuevo.
class LibroRegistrado extends CatalogoEvent {
  const LibroRegistrado(this.libro);

  final Libro libro;

  @override
  List<Object?> get props => [libro];
}

/// El bibliotecario confirma un alta y la publica en el catálogo público.
class LibroValidado extends CatalogoEvent {
  const LibroValidado(this.libroId);

  final String libroId;

  @override
  List<Object?> get props => [libroId];
}

/// Se suma una copia física a un título existente.
class EjemplarAgregado extends CatalogoEvent {
  const EjemplarAgregado({required this.libroId, required this.condicion});

  final String libroId;
  final CondicionEjemplar condicion;

  @override
  List<Object?> get props => [libroId, condicion];
}

/// Reimpresión de una etiqueta QR, con su motivo para la auditoría.
class EtiquetaReimpresa extends CatalogoEvent {
  const EtiquetaReimpresa({
    required this.libroId,
    required this.ejemplarId,
    required this.motivo,
  });

  final String libroId;
  final String ejemplarId;
  final String motivo;

  @override
  List<Object?> get props => [libroId, ejemplarId, motivo];
}

/// Limpia el mensaje de resultado ya mostrado en pantalla.
class MensajeCatalogoDescartado extends CatalogoEvent {
  const MensajeCatalogoDescartado();
}
