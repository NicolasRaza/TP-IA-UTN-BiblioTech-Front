import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/presentation/estado_carga.dart';
import '../../../../core/services/reloj.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/entities/decision.dart';
import '../../domain/usecases/consultas_agentes.dart';
import '../../domain/usecases/correr_ciclo_de_agentes.dart';

part 'agentes_event.dart';
part 'agentes_state.dart';

/// Ciclo de agentes (spec v2 §5) y bitácora de la sesión.
///
/// Va como Bloc: cada corrida del ciclo es un evento explícito, y el registro
/// de eventos del bloc es en sí mismo parte de lo que el TP pide mostrar —el
/// "log de sesión real de uso".
class AgentesBloc extends Bloc<AgentesEvent, AgentesState> {
  AgentesBloc({
    required CorrerCicloDeAgentes correrCiclo,
    required ObtenerDecisionesPendientes obtenerDecisiones,
    required Reloj reloj,
  })  : _correrCiclo = correrCiclo,
        _obtenerDecisiones = obtenerDecisiones,
        _reloj = reloj,
        super(const AgentesState()) {
    on<CicloDeAgentesSolicitado>(_alCorrerCiclo);
    on<DecisionesPendientesSolicitadas>(_alSolicitarDecisiones);
    on<BitacoraLimpiada>((_, emit) => emit(state.copyWith(bitacora: const [])));
  }

  final CorrerCicloDeAgentes _correrCiclo;
  final ObtenerDecisionesPendientes _obtenerDecisiones;
  final Reloj _reloj;

  Future<void> _alCorrerCiclo(
    CicloDeAgentesSolicitado event,
    Emitter<AgentesState> emit,
  ) async {
    emit(state.copyWith(estado: EstadoCarga.cargando));

    final resultado = await _correrCiclo(const SinParametros());

    resultado.fold(
      (failure) => emit(state.copyWith(
        estado: EstadoCarga.error,
        mensajeError: failure.mensaje,
      )),
      (ciclo) => emit(state.copyWith(
        estado: EstadoCarga.exito,
        ultimoCiclo: ciclo,
        decisiones: ciclo.decisiones,
        bitacora: [...state.bitacora, _entradaDeBitacora(ciclo)],
      )),
    );
  }

  Future<void> _alSolicitarDecisiones(
    DecisionesPendientesSolicitadas event,
    Emitter<AgentesState> emit,
  ) async {
    final resultado = await _obtenerDecisiones(const SinParametros());

    resultado.fold(
      (failure) => emit(state.copyWith(
        estado: EstadoCarga.error,
        mensajeError: failure.mensaje,
      )),
      (decisiones) => emit(state.copyWith(
        estado: EstadoCarga.exito,
        decisiones: decisiones,
      )),
    );
  }

  String _entradaDeBitacora(CicloDeAgentes ciclo) =>
      '[${_reloj.ahora.toIso8601String()}] Ciclo de agentes: '
      '${ciclo.decisiones.length} decisiones del Evaluador, '
      '${ciclo.ejecutadas} ejecutadas por el Planificador '
      '(${ciclo.prestamosVencidos} préstamos vencidos, '
      '${ciclo.reservasLiberadas} reservas liberadas).';
}
