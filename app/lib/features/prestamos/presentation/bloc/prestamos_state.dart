part of 'prestamos_bloc.dart';

class PrestamosState extends Equatable {
  const PrestamosState({
    this.estado = EstadoCarga.inicial,
    this.activos = const [],
    this.historial = const [],
    this.todos = const [],
    this.estadisticas,
    this.operando = false,
    this.mensajeError,
    this.mensajeExito,
  });

  final EstadoCarga estado;

  /// Préstamos abiertos del lector consultado, del que vence antes al que
  /// vence después.
  final List<Prestamo> activos;

  /// Préstamos ya devueltos del lector consultado.
  final List<Prestamo> historial;

  /// Toda la circulación, para los paneles de gestión.
  final List<Prestamo> todos;

  final EstadisticasPrestamos? estadisticas;

  /// `true` mientras corre un préstamo o una devolución. La UI lo usa para
  /// deshabilitar el botón y evitar el doble clic.
  final bool operando;

  final String? mensajeError;
  final String? mensajeExito;

  PrestamosState copyWith({
    EstadoCarga? estado,
    List<Prestamo>? activos,
    List<Prestamo>? historial,
    List<Prestamo>? todos,
    EstadisticasPrestamos? estadisticas,
    bool? operando,
    String? mensajeError,
    String? mensajeExito,
    bool limpiarMensajes = false,
  }) =>
      PrestamosState(
        estado: estado ?? this.estado,
        activos: activos ?? this.activos,
        historial: historial ?? this.historial,
        todos: todos ?? this.todos,
        estadisticas: estadisticas ?? this.estadisticas,
        operando: operando ?? this.operando,
        mensajeError: limpiarMensajes ? null : mensajeError,
        mensajeExito: limpiarMensajes ? null : mensajeExito,
      );

  @override
  List<Object?> get props => [
        estado,
        activos,
        historial,
        todos,
        estadisticas,
        operando,
        mensajeError,
        mensajeExito,
      ];
}
