import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/presentation/estado_carga.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../administracion/domain/entities/configuracion_biblioteca.dart';
import '../../../administracion/domain/usecases/gestionar_configuracion.dart';
import '../../domain/entities/recomendacion.dart';
import '../../domain/usecases/consultas_agentes.dart';

part 'recomendaciones_state.dart';

/// Recomendaciones de lectura del Agente Evaluador (spec v2 §2).
class RecomendacionesCubit extends Cubit<RecomendacionesState> {
  RecomendacionesCubit({
    required ObtenerRecomendaciones obtenerRecomendaciones,
    required ObtenerConfiguracion obtenerConfiguracion,
  })  : _obtener = obtenerRecomendaciones,
        _obtenerConfiguracion = obtenerConfiguracion,
        super(const RecomendacionesState());

  final ObtenerRecomendaciones _obtener;
  final ObtenerConfiguracion _obtenerConfiguracion;

  Future<void> cargar(String lectorId, {int limite = 8}) async {
    emit(state.copyWith(estado: EstadoCarga.cargando));

    final resultado = await _obtener(
      RecomendacionesParams(lectorId: lectorId, limite: limite),
    );
    final configuracion = await _obtenerConfiguracion(const SinParametros());

    resultado.fold(
      (failure) => emit(state.copyWith(
        estado: EstadoCarga.error,
        mensajeError: failure.mensaje,
      )),
      (recomendaciones) => emit(state.copyWith(
        estado: EstadoCarga.exito,
        recomendaciones: recomendaciones,
        configuracion: configuracion.valorONull,
      )),
    );
  }
}
