import '../../domain/entities/reserva.dart';

/// [Reserva] con serialización.
class ReservaModel extends Reserva {
  const ReservaModel({
    required super.id,
    required super.lectorId,
    required super.libroId,
    required super.fechaReserva,
    super.fechaVencimientoRetiro,
    required super.estado,
    super.ejemplarAsignadoId,
    required super.plazoRetiroHorasAlReservar,
  });

  factory ReservaModel.fromEntity(Reserva r) => ReservaModel(
        id: r.id,
        lectorId: r.lectorId,
        libroId: r.libroId,
        fechaReserva: r.fechaReserva,
        fechaVencimientoRetiro: r.fechaVencimientoRetiro,
        estado: r.estado,
        ejemplarAsignadoId: r.ejemplarAsignadoId,
        plazoRetiroHorasAlReservar: r.plazoRetiroHorasAlReservar,
      );

  factory ReservaModel.fromJson(Map<String, dynamic> json) => ReservaModel(
        id: json['id'] as String,
        lectorId: json['lectorId'] as String,
        libroId: json['libroId'] as String,
        fechaReserva: DateTime.parse(json['fechaReserva'] as String),
        fechaVencimientoRetiro: json['fechaVencimientoRetiro'] == null
            ? null
            : DateTime.parse(json['fechaVencimientoRetiro'] as String),
        estado: EstadoReserva.fromCode(json['estado'] as String?),
        ejemplarAsignadoId: json['ejemplarAsignadoId'] as String?,
        plazoRetiroHorasAlReservar:
            (json['plazoRetiroHorasAlReservar'] as num?)?.toInt() ?? 48,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'lectorId': lectorId,
        'libroId': libroId,
        'fechaReserva': fechaReserva.toIso8601String(),
        'fechaVencimientoRetiro': fechaVencimientoRetiro?.toIso8601String(),
        'estado': estado.code,
        'ejemplarAsignadoId': ejemplarAsignadoId,
        'plazoRetiroHorasAlReservar': plazoRetiroHorasAlReservar,
      };
}
