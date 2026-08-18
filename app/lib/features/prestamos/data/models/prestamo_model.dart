import '../../../lectores/domain/entities/lector.dart';
import '../../domain/entities/prestamo.dart';

/// [Prestamo] con serialización.
///
/// `categoriaAlPrestar` y `plazoDiasAlPrestar` se persisten con el préstamo:
/// son la materialización de la regla de transición de categoría (spec v2 §7).
class PrestamoModel extends Prestamo {
  const PrestamoModel({
    required super.id,
    required super.lectorId,
    required super.ejemplarId,
    required super.libroId,
    required super.fechaPrestamo,
    required super.fechaVencimiento,
    super.fechaDevolucion,
    required super.estado,
    super.tardio,
    required super.categoriaAlPrestar,
    required super.plazoDiasAlPrestar,
    super.multaAplicada,
  });

  factory PrestamoModel.fromEntity(Prestamo p) => PrestamoModel(
        id: p.id,
        lectorId: p.lectorId,
        ejemplarId: p.ejemplarId,
        libroId: p.libroId,
        fechaPrestamo: p.fechaPrestamo,
        fechaVencimiento: p.fechaVencimiento,
        fechaDevolucion: p.fechaDevolucion,
        estado: p.estado,
        tardio: p.tardio,
        categoriaAlPrestar: p.categoriaAlPrestar,
        plazoDiasAlPrestar: p.plazoDiasAlPrestar,
        multaAplicada: p.multaAplicada,
      );

  factory PrestamoModel.fromJson(Map<String, dynamic> json) => PrestamoModel(
        id: json['id'] as String,
        lectorId: json['lectorId'] as String,
        ejemplarId: json['ejemplarId'] as String,
        libroId: json['libroId'] as String,
        fechaPrestamo: DateTime.parse(json['fechaPrestamo'] as String),
        fechaVencimiento: DateTime.parse(json['fechaVencimiento'] as String),
        fechaDevolucion: json['fechaDevolucion'] == null
            ? null
            : DateTime.parse(json['fechaDevolucion'] as String),
        estado: EstadoPrestamo.fromCode(json['estado'] as String?),
        tardio: json['tardio'] as bool? ?? false,
        categoriaAlPrestar:
            CategoriaLector.fromCode(json['categoriaAlPrestar'] as String?),
        plazoDiasAlPrestar: (json['plazoDiasAlPrestar'] as num?)?.toInt() ?? 14,
        multaAplicada: (json['multaAplicada'] as num?)?.toInt() ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'lectorId': lectorId,
        'ejemplarId': ejemplarId,
        'libroId': libroId,
        'fechaPrestamo': fechaPrestamo.toIso8601String(),
        'fechaVencimiento': fechaVencimiento.toIso8601String(),
        'fechaDevolucion': fechaDevolucion?.toIso8601String(),
        'estado': estado.code,
        'tardio': tardio,
        'categoriaAlPrestar': categoriaAlPrestar.code,
        'plazoDiasAlPrestar': plazoDiasAlPrestar,
        'multaAplicada': multaAplicada,
      };
}
