part of 'recomendaciones_cubit.dart';

class RecomendacionesState extends Equatable {
  const RecomendacionesState({
    this.estado = EstadoCarga.inicial,
    this.recomendaciones = const [],
    this.mensajeError,
  });

  final EstadoCarga estado;
  final List<Recomendacion> recomendaciones;
  final String? mensajeError;

  /// `true` cuando el lector todavía no tiene historial suficiente y las
  /// recomendaciones salen sólo de la popularidad general.
  bool get esColdStart =>
      recomendaciones.isNotEmpty && recomendaciones.first.esColdStart;

  RecomendacionesState copyWith({
    EstadoCarga? estado,
    List<Recomendacion>? recomendaciones,
    String? mensajeError,
  }) =>
      RecomendacionesState(
        estado: estado ?? this.estado,
        recomendaciones: recomendaciones ?? this.recomendaciones,
        mensajeError: mensajeError,
      );

  @override
  List<Object?> get props => [estado, recomendaciones, mensajeError];
}
