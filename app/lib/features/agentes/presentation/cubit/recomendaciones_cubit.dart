import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/presentation/estado_carga.dart';
import '../../domain/entities/recomendacion.dart';
import '../../domain/usecases/consultas_agentes.dart';

part 'recomendaciones_state.dart';

/// Recomendaciones de lectura del Agente Evaluador (spec v2 §2).
class RecomendacionesCubit extends Cubit<RecomendacionesState> {
  RecomendacionesCubit({
    required ObtenerRecomendaciones obtenerRecomendaciones,
  })  : _obtener = obtenerRecomendaciones,
        super(const RecomendacionesState());

  final ObtenerRecomendaciones _obtener;

  Future<void> cargar(String lectorId, {int limite = 8}) async {
    emit(state.copyWith(estado: EstadoCarga.cargando));

    final resultado = await _obtener(
      RecomendacionesParams(lectorId: lectorId, limite: limite),
    );

    resultado.fold(
      (failure) => emit(state.copyWith(
        estado: EstadoCarga.error,
        mensajeError: failure.mensaje,
      )),
      (recomendaciones) => emit(state.copyWith(
        estado: EstadoCarga.exito,
        recomendaciones: recomendaciones,
      )),
    );
  }
}
