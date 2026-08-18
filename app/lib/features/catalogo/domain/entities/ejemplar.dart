import 'package:equatable/equatable.dart';

enum EstadoEjemplar {
  disponible('disponible', 'Disponible'),
  prestado('prestado', 'Prestado'),
  reservado('reservado', 'Reservado'),
  baja('baja', 'De baja');

  const EstadoEjemplar(this.code, this.label);
  final String code;
  final String label;

  static EstadoEjemplar fromCode(String? code) =>
      EstadoEjemplar.values.firstWhere(
        (e) => e.code == code,
        orElse: () => EstadoEjemplar.disponible,
      );
}

enum CondicionEjemplar {
  bueno('bueno', 'Bueno'),
  regular('regular', 'Regular'),
  malo('malo', 'Malo');

  const CondicionEjemplar(this.code, this.label);
  final String code;
  final String label;

  static CondicionEjemplar fromCode(String? code) =>
      CondicionEjemplar.values.firstWhere(
        (c) => c.code == code,
        orElse: () => CondicionEjemplar.bueno,
      );
}

/// Ejemplar físico de un libro.
///
/// El `id` es el identificador interno e inmutable: la spec v2 §7 prohíbe
/// generar uno nuevo al reimprimir la etiqueta, porque eso rompería la
/// trazabilidad del historial de préstamos.
class Ejemplar extends Equatable {
  const Ejemplar({
    required this.id,
    required this.libroId,
    required this.condicion,
    required this.estado,
    this.reimpresionesQr = 0,
  });

  final String id;
  final String libroId;
  final CondicionEjemplar condicion;
  final EstadoEjemplar estado;

  /// Cuántas veces se reimprimió la etiqueta. El QR en sí nunca cambia.
  final int reimpresionesQr;

  /// El contenido del QR se deriva del ID interno, nunca se almacena aparte.
  /// Así una reimpresión produce siempre exactamente la misma etiqueta.
  String get qr => 'BT-$libroId-$id';

  bool get estaDisponible => estado == EstadoEjemplar.disponible;

  Ejemplar copyWith({
    CondicionEjemplar? condicion,
    EstadoEjemplar? estado,
    int? reimpresionesQr,
  }) =>
      Ejemplar(
        id: id,
        libroId: libroId,
        condicion: condicion ?? this.condicion,
        estado: estado ?? this.estado,
        reimpresionesQr: reimpresionesQr ?? this.reimpresionesQr,
      );

  @override
  List<Object?> get props => [id, libroId, condicion, estado, reimpresionesQr];
}
