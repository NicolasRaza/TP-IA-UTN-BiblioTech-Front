part of 'recomendaciones_cubit.dart';

class RecomendacionesState extends Equatable {
  const RecomendacionesState({
    this.estado = EstadoCarga.inicial,
    this.recomendaciones = const [],
    this.configuracion = const ConfiguracionBiblioteca(),
    this.mensajeError,
  });

  final EstadoCarga estado;
  final List<Recomendacion> recomendaciones;

  /// Parámetros vigentes, para poder explicar en pantalla con qué
  /// ponderación se armaron las sugerencias (spec v2 §2).
  final ConfiguracionBiblioteca configuracion;

  final String? mensajeError;

  /// `true` cuando el lector todavía no tiene historial suficiente y las
  /// recomendaciones salen sólo de la popularidad general.
  bool get esColdStart =>
      recomendaciones.isNotEmpty && recomendaciones.first.esColdStart;

  RecomendacionesState copyWith({
    EstadoCarga? estado,
    List<Recomendacion>? recomendaciones,
    ConfiguracionBiblioteca? configuracion,
    String? mensajeError,
  }) =>
      RecomendacionesState(
        estado: estado ?? this.estado,
        recomendaciones: recomendaciones ?? this.recomendaciones,
        configuracion: configuracion ?? this.configuracion,
        mensajeError: mensajeError,
      );

  @override
  List<Object?> get props =>
      [estado, recomendaciones, configuracion, mensajeError];
}
