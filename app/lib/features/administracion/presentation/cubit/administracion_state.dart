part of 'administracion_cubit.dart';

class AdministracionState extends Equatable {
  const AdministracionState({
    this.estado = EstadoCarga.inicial,
    this.configuracion = const ConfiguracionBiblioteca(),
    this.auditoria = const [],
    this.indicadores,
    this.sugerencias = const [],
    this.reporteAprendizaje,
    this.mensajeError,
    this.mensajeExito,
  });

  final EstadoCarga estado;
  final ConfiguracionBiblioteca configuracion;
  final List<EventoAuditoria> auditoria;

  /// Indicadores de negocio del Agente Evaluador (spec v2 §6).
  final Indicadores? indicadores;

  /// Sugerencias estratégicas para la biblioteca (spec v2 §2).
  final List<Sugerencia> sugerencias;

  /// Reporte del Agente de Aprendizaje (spec v2 §5).
  final ReporteAprendizaje? reporteAprendizaje;

  final String? mensajeError;
  final String? mensajeExito;

  AdministracionState copyWith({
    EstadoCarga? estado,
    ConfiguracionBiblioteca? configuracion,
    List<EventoAuditoria>? auditoria,
    Indicadores? indicadores,
    List<Sugerencia>? sugerencias,
    ReporteAprendizaje? reporteAprendizaje,
    String? mensajeError,
    String? mensajeExito,
    bool limpiarMensajes = false,
  }) =>
      AdministracionState(
        estado: estado ?? this.estado,
        configuracion: configuracion ?? this.configuracion,
        auditoria: auditoria ?? this.auditoria,
        indicadores: indicadores ?? this.indicadores,
        sugerencias: sugerencias ?? this.sugerencias,
        reporteAprendizaje: reporteAprendizaje ?? this.reporteAprendizaje,
        mensajeError: limpiarMensajes ? null : mensajeError,
        mensajeExito: limpiarMensajes ? null : mensajeExito,
      );

  @override
  List<Object?> get props => [
        estado,
        configuracion,
        auditoria,
        indicadores,
        sugerencias,
        reporteAprendizaje,
        mensajeError,
        mensajeExito,
      ];
}
