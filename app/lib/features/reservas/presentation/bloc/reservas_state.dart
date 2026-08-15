part of 'reservas_bloc.dart';

class ReservasState extends Equatable {
  const ReservasState({
    this.estado = EstadoCarga.inicial,
    this.propias = const [],
    this.todas = const [],
    this.operando = false,
    this.mensajeError,
    this.mensajeExito,
  });

  final EstadoCarga estado;

  /// Reservas del lector consultado, de la más reciente a la más vieja.
  final List<Reserva> propias;

  /// Todas las reservas del sistema, para los paneles de gestión.
  final List<Reserva> todas;

  final bool operando;
  final String? mensajeError;
  final String? mensajeExito;

  List<Reserva> get activas => propias.where((r) => r.esActiva).toList();

  /// Reservas con ejemplar retenido esperando que el lector pase a buscarlo.
  List<Reserva> get listasParaRetirar =>
      propias.where((r) => r.estaRetenida).toList();

  /// Cola de un título, ordenada cronológicamente.
  List<Reserva> colaDe(String libroId) {
    final cola = todas
        .where((r) => r.libroId == libroId && r.esActiva)
        .toList()
      ..sort((a, b) => a.fechaReserva.compareTo(b.fechaReserva));
    return cola;
  }

  ReservasState copyWith({
    EstadoCarga? estado,
    List<Reserva>? propias,
    List<Reserva>? todas,
    bool? operando,
    String? mensajeError,
    String? mensajeExito,
    bool limpiarMensajes = false,
  }) =>
      ReservasState(
        estado: estado ?? this.estado,
        propias: propias ?? this.propias,
        todas: todas ?? this.todas,
        operando: operando ?? this.operando,
        mensajeError: limpiarMensajes ? null : mensajeError,
        mensajeExito: limpiarMensajes ? null : mensajeExito,
      );

  @override
  List<Object?> get props =>
      [estado, propias, todas, operando, mensajeError, mensajeExito];
}
