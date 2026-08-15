part of 'notificaciones_cubit.dart';

class NotificacionesState extends Equatable {
  const NotificacionesState({
    this.estado = EstadoCarga.inicial,
    this.notificaciones = const [],
    this.noLeidas = 0,
    this.mensajeError,
  });

  final EstadoCarga estado;
  final List<Notificacion> notificaciones;

  /// Alimenta el globo del ícono de campana en la navegación.
  final int noLeidas;

  final String? mensajeError;

  NotificacionesState copyWith({
    EstadoCarga? estado,
    List<Notificacion>? notificaciones,
    int? noLeidas,
    String? mensajeError,
  }) =>
      NotificacionesState(
        estado: estado ?? this.estado,
        notificaciones: notificaciones ?? this.notificaciones,
        noLeidas: noLeidas ?? this.noLeidas,
        mensajeError: mensajeError,
      );

  @override
  List<Object?> get props => [estado, notificaciones, noLeidas, mensajeError];
}
