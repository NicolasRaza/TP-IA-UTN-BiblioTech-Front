import 'package:equatable/equatable.dart';

enum EstadoReserva {
  /// En cola, esperando que se libere un ejemplar.
  pendiente('pendiente', 'En cola'),

  /// Ejemplar retenido en mostrador, corriendo el plazo de retiro (§7).
  lista('lista', 'Lista para retirar'),

  /// Se convirtió en préstamo.
  completada('completada', 'Completada'),
  cancelada('cancelada', 'Cancelada'),

  /// Venció el plazo de retiro sin que el lector la retirara.
  vencida('vencida', 'Vencida');

  const EstadoReserva(this.code, this.label);
  final String code;
  final String label;

  static EstadoReserva fromCode(String? code) =>
      EstadoReserva.values.firstWhere(
        (e) => e.code == code,
        orElse: () => EstadoReserva.pendiente,
      );

  bool get esActiva =>
      this == EstadoReserva.pendiente || this == EstadoReserva.lista;
}

/// Reserva de un título.
///
/// La cola se resuelve por `fechaReserva` en orden estrictamente cronológico
/// (spec v2 §7). Igual que el préstamo, congela el plazo de retiro vigente al
/// momento de generarse.
class Reserva extends Equatable {
  const Reserva({
    required this.id,
    required this.lectorId,
    required this.libroId,
    required this.fechaReserva,
    this.fechaVencimientoRetiro,
    required this.estado,
    this.ejemplarAsignadoId,
    required this.plazoRetiroHorasAlReservar,
  });

  final String id;
  final String lectorId;
  final String libroId;
  final DateTime fechaReserva;

  /// Se completa recién cuando la reserva pasa a `lista`.
  final DateTime? fechaVencimientoRetiro;
  final EstadoReserva estado;
  final String? ejemplarAsignadoId;
  final int plazoRetiroHorasAlReservar;

  bool get esActiva => estado.esActiva;

  bool get estaRetenida => estado == EstadoReserva.lista;

  /// ¿Se venció el plazo de retiro sin que el lector pasara a buscarlo?
  bool venceRetiroA(DateTime momento) {
    final limite = fechaVencimientoRetiro;
    if (!estaRetenida || limite == null) return false;
    return momento.isAfter(limite);
  }

  Reserva copyWith({
    DateTime? fechaVencimientoRetiro,
    EstadoReserva? estado,
    String? ejemplarAsignadoId,
  }) =>
      Reserva(
        id: id,
        lectorId: lectorId,
        libroId: libroId,
        fechaReserva: fechaReserva,
        fechaVencimientoRetiro:
            fechaVencimientoRetiro ?? this.fechaVencimientoRetiro,
        estado: estado ?? this.estado,
        ejemplarAsignadoId: ejemplarAsignadoId ?? this.ejemplarAsignadoId,
        plazoRetiroHorasAlReservar: plazoRetiroHorasAlReservar,
      );

  @override
  List<Object?> get props => [
        id,
        lectorId,
        libroId,
        fechaReserva,
        fechaVencimientoRetiro,
        estado,
        ejemplarAsignadoId,
        plazoRetiroHorasAlReservar,
      ];
}
