import '../domain/models.dart';

/// Tipos de acción que el Agente Evaluador puede decidir.
enum TipoDecision {
  notificarVencimientoProximo,
  notificarPrestamoVencido,
  liberarReservaNoRetirada,
  asignarReservaAlSiguiente,
  alertarMultaPendiente,
  sugerirRevisionCategoria,
}

/// Una acción decidida por el Agente Evaluador y pendiente de ejecución.
///
/// La spec v2 §4.3 separa los roles: el Evaluador *decide* qué corresponde
/// hacer a partir de las métricas, y el Planificador *ejecuta* esa decisión.
/// Esta clase es el contrato entre ambos: el Evaluador la produce sin tocar el
/// sistema, y el Planificador la consume sin volver a evaluar criterios.
class Decision {
  const Decision({
    required this.tipo,
    required this.motivo,
    this.prestamo,
    this.reserva,
    this.lector,
    this.libro,
    this.dias = 0,
  });

  final TipoDecision tipo;

  /// Explicación legible de por qué el Evaluador tomó esta decisión.
  /// Se muestra en el panel del bibliotecario y queda en el log de la sesión.
  final String motivo;

  final Prestamo? prestamo;
  final Reserva? reserva;
  final Lector? lector;
  final Libro? libro;

  /// Días de atraso o días restantes, según el tipo de decisión.
  final int dias;
}

/// Resultado de ejecutar una decisión.
class ResultadoEjecucion {
  const ResultadoEjecucion({
    required this.decision,
    required this.ejecutada,
    this.detalle = '',
  });

  final Decision decision;
  final bool ejecutada;
  final String detalle;
}
