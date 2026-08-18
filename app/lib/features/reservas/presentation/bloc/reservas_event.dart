part of 'reservas_bloc.dart';

sealed class ReservasEvent extends Equatable {
  const ReservasEvent();

  @override
  List<Object?> get props => const [];
}

class ReservasDeLectorSolicitadas extends ReservasEvent {
  const ReservasDeLectorSolicitadas(this.lectorId);

  final String lectorId;

  @override
  List<Object?> get props => [lectorId];
}

class TodasLasReservasSolicitadas extends ReservasEvent {
  const TodasLasReservasSolicitadas();
}

class ReservaCreada extends ReservasEvent {
  const ReservaCreada({required this.lectorId, required this.libroId});

  final String lectorId;
  final String libroId;

  @override
  List<Object?> get props => [lectorId, libroId];
}

class ReservaCancelada extends ReservasEvent {
  const ReservaCancelada(this.reservaId);

  final String reservaId;

  @override
  List<Object?> get props => [reservaId];
}

class MensajeReservasDescartado extends ReservasEvent {
  const MensajeReservasDescartado();
}
