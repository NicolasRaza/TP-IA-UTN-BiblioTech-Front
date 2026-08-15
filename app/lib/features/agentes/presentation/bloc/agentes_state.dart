part of 'agentes_bloc.dart';

class AgentesState extends Equatable {
  const AgentesState({
    this.estado = EstadoCarga.inicial,
    this.decisiones = const [],
    this.ultimoCiclo,
    this.bitacora = const [],
    this.mensajeError,
  });

  final EstadoCarga estado;

  /// Lo que el Evaluador decidió en la última corrida.
  final List<Decision> decisiones;

  final CicloDeAgentes? ultimoCiclo;

  /// Registro legible de lo que hicieron los agentes en esta sesión.
  /// Alimenta el "log de sesión real de uso" que pide el TP.
  final List<String> bitacora;

  final String? mensajeError;

  int decisionesDeTipo(TipoDecision tipo) =>
      decisiones.where((d) => d.tipo == tipo).length;

  int get prestamosVencidos =>
      decisionesDeTipo(TipoDecision.notificarPrestamoVencido);
  int get vencimientosProximos =>
      decisionesDeTipo(TipoDecision.notificarVencimientoProximo);
  int get reservasPorLiberar =>
      decisionesDeTipo(TipoDecision.liberarReservaNoRetirada);
  int get multasPendientes =>
      decisionesDeTipo(TipoDecision.alertarMultaPendiente);
  int get categoriasARevisar =>
      decisionesDeTipo(TipoDecision.sugerirRevisionCategoria);

  AgentesState copyWith({
    EstadoCarga? estado,
    List<Decision>? decisiones,
    CicloDeAgentes? ultimoCiclo,
    List<String>? bitacora,
    String? mensajeError,
  }) =>
      AgentesState(
        estado: estado ?? this.estado,
        decisiones: decisiones ?? this.decisiones,
        ultimoCiclo: ultimoCiclo ?? this.ultimoCiclo,
        bitacora: bitacora ?? this.bitacora,
        mensajeError: mensajeError,
      );

  @override
  List<Object?> get props =>
      [estado, decisiones, ultimoCiclo, bitacora, mensajeError];
}
