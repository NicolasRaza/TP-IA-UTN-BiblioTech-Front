/// Consultas que exponen el trabajo de los agentes a la capa de presentación.
library;

import 'package:equatable/equatable.dart';

import '../../../../core/error/result.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../catalogo/domain/repositories/catalogo_repository.dart';
import '../entities/decision.dart';
import '../entities/recomendacion.dart';
import '../repositories/aprendizaje_repository.dart';
import '../services/agente_aprendizaje.dart';
import '../services/agente_evaluador.dart';
import '../services/observador_del_sistema.dart';

class RecomendacionesParams extends Equatable {
  const RecomendacionesParams({required this.lectorId, this.limite = 8});

  final String lectorId;
  final int limite;

  @override
  List<Object?> get props => [lectorId, limite];
}

/// Recomendaciones de lectura para un lector (spec v2 §2).
class ObtenerRecomendaciones
    implements UseCase<List<Recomendacion>, RecomendacionesParams> {
  const ObtenerRecomendaciones({
    required ObservadorDelSistema observador,
    required AgenteEvaluador evaluador,
  })  : _observador = observador,
        _evaluador = evaluador;

  final ObservadorDelSistema _observador;
  final AgenteEvaluador _evaluador;

  @override
  Future<Result<List<Recomendacion>>> call(
      RecomendacionesParams params) async {
    final estado = await _observador.observar();
    return estado.map((e) => _evaluador.recomendarPara(
          e,
          params.lectorId,
          limite: params.limite,
        ));
  }
}

/// Indicadores de negocio del dashboard (spec v2 §6).
class ObtenerIndicadores implements UseCase<Indicadores, SinParametros> {
  const ObtenerIndicadores({
    required ObservadorDelSistema observador,
    required AgenteEvaluador evaluador,
  })  : _observador = observador,
        _evaluador = evaluador;

  final ObservadorDelSistema _observador;
  final AgenteEvaluador _evaluador;

  @override
  Future<Result<Indicadores>> call(SinParametros params) async {
    final estado = await _observador.observar();
    return estado.map(_evaluador.calcularIndicadores);
  }
}

/// Sugerencias estratégicas para la biblioteca (spec v2 §2).
class ObtenerSugerencias implements UseCase<List<Sugerencia>, SinParametros> {
  const ObtenerSugerencias({
    required ObservadorDelSistema observador,
    required AgenteEvaluador evaluador,
  })  : _observador = observador,
        _evaluador = evaluador;

  final ObservadorDelSistema _observador;
  final AgenteEvaluador _evaluador;

  @override
  Future<Result<List<Sugerencia>>> call(SinParametros params) async {
    final estado = await _observador.observar();
    return estado.map(_evaluador.generarSugerencias);
  }
}

/// Decisiones pendientes sin ejecutarlas: es la vista de alertas del panel
/// del bibliotecario, que muestra qué ve el Evaluador en este momento.
class ObtenerDecisionesPendientes
    implements UseCase<List<Decision>, SinParametros> {
  const ObtenerDecisionesPendientes({
    required ObservadorDelSistema observador,
    required AgenteEvaluador evaluador,
  })  : _observador = observador,
        _evaluador = evaluador;

  final ObservadorDelSistema _observador;
  final AgenteEvaluador _evaluador;

  @override
  Future<Result<List<Decision>>> call(SinParametros params) async {
    final estado = await _observador.observar();
    return estado.map(_evaluador.decidir);
  }
}

/// Reporte del Agente de Aprendizaje para el panel de administración.
class ObtenerReporteAprendizaje
    implements UseCase<ReporteAprendizaje, SinParametros> {
  const ObtenerReporteAprendizaje({
    required AprendizajeRepository aprendizajeRepository,
    required CatalogoRepository catalogoRepository,
    AgenteAprendizaje agente = const AgenteAprendizaje(),
  })  : _aprendizaje = aprendizajeRepository,
        _catalogo = catalogoRepository,
        _agente = agente;

  final AprendizajeRepository _aprendizaje;
  final CatalogoRepository _catalogo;
  final AgenteAprendizaje _agente;

  @override
  Future<Result<ReporteAprendizaje>> call(SinParametros params) async {
    final correcciones = await _aprendizaje.obtenerCorrecciones();
    if (correcciones case Fallo(:final failure)) return Fallo(failure);

    final interacciones = await _aprendizaje.obtenerInteracciones();
    if (interacciones case Fallo(:final failure)) return Fallo(failure);

    final libros = await _catalogo.obtenerTodos();
    if (libros case Fallo(:final failure)) return Fallo(failure);

    return Exito(_agente.generarReporte(
      correcciones: correcciones.valorONull!,
      interacciones: interacciones.valorONull!,
      libros: libros.valorONull!,
    ));
  }
}

class RegistrarCorreccionParams extends Equatable {
  const RegistrarCorreccionParams({
    required this.campo,
    required this.valorSugerido,
    required this.valorFinal,
  });

  final String campo;
  final String valorSugerido;
  final String valorFinal;

  @override
  List<Object?> get props => [campo, valorSugerido, valorFinal];
}

/// Asienta una corrección del bibliotecario sobre un campo sugerido.
///
/// Es la señal que alimenta al Agente de Aprendizaje: sin esto, el ciclo de
/// la spec v2 §5 quedaría abierto.
class RegistrarCorreccion implements UseCase<void, RegistrarCorreccionParams> {
  const RegistrarCorreccion({
    required AprendizajeRepository aprendizajeRepository,
    required this.ahora,
  }) : _aprendizaje = aprendizajeRepository;

  final AprendizajeRepository _aprendizaje;
  final DateTime Function() ahora;

  @override
  Future<Result<void>> call(RegistrarCorreccionParams params) =>
      _aprendizaje.registrarCorreccion(
        Correccion(
          campo: params.campo,
          valorSugerido: params.valorSugerido,
          valorFinal: params.valorFinal,
          fecha: ahora(),
        ),
      );
}
