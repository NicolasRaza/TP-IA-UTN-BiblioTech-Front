import 'package:equatable/equatable.dart';

import 'ejemplar.dart';

/// Título del catálogo, junto con sus ejemplares físicos.
///
/// `Libro` es la raíz del agregado: los [Ejemplar] no se manipulan por fuera
/// del libro que los contiene, y toda la persistencia del agregado ocurre en
/// una sola escritura.
class Libro extends Equatable {
  const Libro({
    required this.id,
    required this.titulo,
    required this.autor,
    this.editorial = '',
    this.anio,
    this.isbn = '',
    this.sinopsis = '',
    this.genero = '',
    this.paginas,
    this.portada = '',
    this.validado = false,
    required this.fechaAlta,
    this.ejemplares = const [],
    this.camposPendientes = const [],
  });

  final String id;
  final String titulo;
  final String autor;
  final String editorial;
  final int? anio;
  final String isbn;
  final String sinopsis;
  final String genero;
  final int? paginas;
  final String portada;

  /// Regla de Validación Estricta (spec v2 §7): mientras sea `false` el libro
  /// no aparece en el catálogo público, sin importar la confianza de la IA.
  final bool validado;

  final DateTime fechaAlta;
  final List<Ejemplar> ejemplares;

  /// Campos que ninguna fuente externa pudo resolver y que quedaron
  /// marcados para carga manual (spec v2 §4.2).
  final List<String> camposPendientes;

  int get totalEjemplares => ejemplares.length;
  int get ejemplaresDisponibles =>
      ejemplares.where((e) => e.estaDisponible).length;
  bool get hayDisponible => ejemplaresDisponibles > 0;

  Ejemplar? get primerEjemplarDisponible {
    for (final e in ejemplares) {
      if (e.estaDisponible) return e;
    }
    return null;
  }

  Ejemplar? ejemplar(String ejemplarId) {
    for (final e in ejemplares) {
      if (e.id == ejemplarId) return e;
    }
    return null;
  }

  String get portadaUrl {
    if (portada.isNotEmpty) return portada;
    if (isbn.isNotEmpty) {
      return 'https://covers.openlibrary.org/b/isbn/$isbn-L.jpg';
    }
    return '';
  }

  /// ¿El texto de búsqueda aparece en alguno de los campos indexados?
  bool coincideCon(String consulta) {
    final q = consulta.toLowerCase().trim();
    if (q.isEmpty) return true;
    return titulo.toLowerCase().contains(q) ||
        autor.toLowerCase().contains(q) ||
        isbn.contains(q) ||
        genero.toLowerCase().contains(q);
  }

  Libro copyWith({
    String? titulo,
    String? autor,
    String? editorial,
    int? anio,
    String? isbn,
    String? sinopsis,
    String? genero,
    int? paginas,
    String? portada,
    bool? validado,
    List<Ejemplar>? ejemplares,
    List<String>? camposPendientes,
  }) =>
      Libro(
        id: id,
        titulo: titulo ?? this.titulo,
        autor: autor ?? this.autor,
        editorial: editorial ?? this.editorial,
        anio: anio ?? this.anio,
        isbn: isbn ?? this.isbn,
        sinopsis: sinopsis ?? this.sinopsis,
        genero: genero ?? this.genero,
        paginas: paginas ?? this.paginas,
        portada: portada ?? this.portada,
        validado: validado ?? this.validado,
        fechaAlta: fechaAlta,
        ejemplares: ejemplares ?? this.ejemplares,
        camposPendientes: camposPendientes ?? this.camposPendientes,
      );

  /// Devuelve una copia con un ejemplar reemplazado por su versión modificada.
  Libro conEjemplarActualizado(
    String ejemplarId,
    Ejemplar Function(Ejemplar) cambio,
  ) =>
      copyWith(
        ejemplares:
            ejemplares.map((e) => e.id == ejemplarId ? cambio(e) : e).toList(),
      );

  @override
  List<Object?> get props => [
        id,
        titulo,
        autor,
        editorial,
        anio,
        isbn,
        sinopsis,
        genero,
        paginas,
        portada,
        validado,
        fechaAlta,
        ejemplares,
        camposPendientes,
      ];
}
