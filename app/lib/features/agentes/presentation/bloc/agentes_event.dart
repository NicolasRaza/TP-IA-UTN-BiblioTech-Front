part of 'agentes_bloc.dart';

sealed class AgentesEvent extends Equatable {
  const AgentesEvent();

  @override
  List<Object?> get props => const [];
}

/// Dispara el ciclo Observación → Análisis → Decisión → Acción.
class CicloDeAgentesSolicitado extends AgentesEvent {
  const CicloDeAgentesSolicitado();
}

/// Relee qué decidiría el Evaluador ahora mismo, sin ejecutar nada.
/// Es la vista de alertas del panel del bibliotecario.
class DecisionesPendientesSolicitadas extends AgentesEvent {
  const DecisionesPendientesSolicitadas();
}

class BitacoraLimpiada extends AgentesEvent {
  const BitacoraLimpiada();
}
