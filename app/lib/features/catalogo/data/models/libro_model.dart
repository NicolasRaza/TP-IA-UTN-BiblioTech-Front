import '../../domain/entities/libro.dart';
import 'ejemplar_model.dart';

/// [Libro] con serialización, ejemplares incluidos.
class LibroModel extends Libro {
  const LibroModel({
    required super.id,
    required super.titulo,
    required super.autor,
    super.editorial,
    super.anio,
    super.isbn,
    super.sinopsis,
    super.genero,
    super.paginas,
    super.portada,
    super.validado,
    required super.fechaAlta,
    super.ejemplares,
    super.camposPendientes,
  });

  factory LibroModel.fromEntity(Libro l) => LibroModel(
        id: l.id,
        titulo: l.titulo,
        autor: l.autor,
        editorial: l.editorial,
        anio: l.anio,
        isbn: l.isbn,
        sinopsis: l.sinopsis,
        genero: l.genero,
        paginas: l.paginas,
        portada: l.portada,
        validado: l.validado,
        fechaAlta: l.fechaAlta,
        ejemplares: l.ejemplares,
        camposPendientes: l.camposPendientes,
      );

  factory LibroModel.fromJson(Map<String, dynamic> json) => LibroModel(
        id: json['id'] as String,
        titulo: json['titulo'] as String? ?? '',
        autor: json['autor'] as String? ?? '',
        editorial: json['editorial'] as String? ?? '',
        anio: (json['anio'] as num?)?.toInt(),
        isbn: json['isbn'] as String? ?? '',
        sinopsis: json['sinopsis'] as String? ?? '',
        genero: json['genero'] as String? ?? '',
        paginas: (json['paginas'] as num?)?.toInt(),
        portada: json['portada'] as String? ?? '',
        validado: json['validado'] as bool? ?? false,
        fechaAlta: DateTime.parse(json['fechaAlta'] as String),
        ejemplares: (json['ejemplares'] as List<dynamic>? ?? [])
            .map((e) => EjemplarModel.fromJson(e as Map<String, dynamic>))
            .toList(),
        camposPendientes:
            (json['camposPendientes'] as List<dynamic>? ?? []).cast<String>(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'titulo': titulo,
        'autor': autor,
        'editorial': editorial,
        'anio': anio,
        'isbn': isbn,
        'sinopsis': sinopsis,
        'genero': genero,
        'paginas': paginas,
        'portada': portada,
        'validado': validado,
        'fechaAlta': fechaAlta.toIso8601String(),
        'ejemplares': ejemplares
            .map((e) => EjemplarModel.fromEntity(e).toJson())
            .toList(),
        'camposPendientes': camposPendientes,
      };
}
