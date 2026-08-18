import 'package:equatable/equatable.dart';

import '../../../catalogo/domain/entities/libro.dart';
import '../../../lectores/domain/entities/lector.dart';
import '../../../prestamos/domain/entities/prestamo.dart';
import '../../../reservas/domain/entities/reserva.dart';

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
class Decision extends Equatable {
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

  @override
  List<Object?> get props =>
      [tipo, motivo, prestamo, reserva, lector, libro, dias];
}

/// Resultado de ejecutar una decisión.
class ResultadoEjecucion extends Equatable {
  const ResultadoEjecucion({
    required this.decision,
    required this.ejecutada,
    this.detalle = '',
  });

  final Decision decision;
  final bool ejecutada;
  final String detalle;

  @override
  List<Object?> get props => [decision, ejecutada, detalle];
}

/// Salida de una corrida completa del ciclo de agentes.
class CicloDeAgentes extends Equatable {
  const CicloDeAgentes({
    required this.decisiones,
    required this.resultados,
    required this.prestamosVencidos,
    required this.reservasLiberadas,
  });

  final List<Decision> decisiones;
  final List<ResultadoEjecucion> resultados;
  final int prestamosVencidos;
  final int reservasLiberadas;

  int get ejecutadas => resultados.where((r) => r.ejecutada).length;

  @override
  List<Object?> get props =>
      [decisiones, resultados, prestamosVencidos, reservasLiberadas];
}
