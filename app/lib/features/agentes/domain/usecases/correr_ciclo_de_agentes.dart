import '../../../../core/error/result.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/decision.dart';
import '../services/agente_evaluador.dart';
import '../services/agente_planificador.dart';
import '../services/observador_del_sistema.dart';
import 'procesar_vencimientos.dart';

/// Corre el ciclo completo de la spec v2 §5:
/// **Observación → Análisis → Decisión → Acción**.
///
/// El orden importa y está fijado acá, no repartido entre los agentes:
///
/// 1. [ProcesarVencimientos] pone el calendario al día.
/// 2. [ObservadorDelSistema] congela una fotografía consistente.
/// 3. [AgenteEvaluador] decide sobre esa fotografía, sin tocar nada.
/// 4. [AgentePlanificador] ejecuta las decisiones, sin volver a evaluarlas.
///
/// Que el Evaluador reciba un estado inmutable y el Planificador reciba sólo
/// decisiones es lo que hace imposible, por construcción, que se invierta la
/// separación de roles que pide la spec.
///
/// Contra el backend, los pasos que **escriben** —1 y 4— son del servidor: su
/// propio planificador corre en un scheduler desde que arranca. La app se
/// queda con la observación y la decisión, así que el bibliotecario sigue
/// viendo qué propone el Evaluador sobre datos reales, pero no duplica
/// acciones que del otro lado ya se ejecutaron.
class CorrerCicloDeAgentes implements UseCase<CicloDeAgentes, SinParametros> {
  const CorrerCicloDeAgentes({
    required ProcesarVencimientos procesarVencimientos,
    required ObservadorDelSistema observador,
    required AgenteEvaluador evaluador,
    required AgentePlanificador planificador,
    bool ejecutarAcciones = true,
  })  : _ejecutarAcciones = ejecutarAcciones,
        _procesarVencimientos = procesarVencimientos,
        _observador = observador,
        _evaluador = evaluador,
        _planificador = planificador;

  final ProcesarVencimientos _procesarVencimientos;
  final ObservadorDelSistema _observador;
  final AgenteEvaluador _evaluador;
  final AgentePlanificador _planificador;

  /// Si los pasos que escriben corren del lado de la app.
  final bool _ejecutarAcciones;

  @override
  Future<Result<CicloDeAgentes>> call(SinParametros params) async {
    // 1 · Observación: primero el calendario.
    var resumen =
        const ResumenVencimientos(prestamosVencidos: 0, reservasLiberadas: 0);
    if (_ejecutarAcciones) {
      final vencimientos = await _procesarVencimientos(const SinParametros());
      if (vencimientos case Fallo(:final failure)) return Fallo(failure);
      resumen = vencimientos.valorONull!;
    }

    // 2 · Observación: fotografía del sistema ya actualizado.
    final estadoResult = await _observador.observar();
    if (estadoResult case Fallo(:final failure)) return Fallo(failure);

    // 3 · Análisis y decisión.
    final decisiones = _evaluador.decidir(estadoResult.valorONull!);

    // 4 · Acción.
    final resultados = _ejecutarAcciones
        ? await _planificador.ejecutar(decisiones)
        : const <ResultadoEjecucion>[];

    return Exito(CicloDeAgentes(
      decisiones: decisiones,
      resultados: resultados,
      prestamosVencidos: resumen.prestamosVencidos,
      reservasLiberadas: resumen.reservasLiberadas,
    ));
  }
}
