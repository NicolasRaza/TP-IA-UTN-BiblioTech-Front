import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/presentation/estado_carga.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/entities/lector.dart';
import '../../domain/usecases/cambiar_categoria.dart';
import '../../domain/usecases/gestionar_lectores.dart';

part 'lectores_event.dart';
part 'lectores_state.dart';

/// Padrón de lectores del panel del bibliotecario.
class LectoresBloc extends Bloc<LectoresEvent, LectoresState> {
  LectoresBloc({
    required ObtenerLectores obtenerLectores,
    required RegistrarLector registrarLector,
    required ActualizarLector actualizarLector,
    required CambiarCategoria cambiarCategoria,
    required ObtenerLectoresConCategoriaDesactualizada obtenerDesactualizados,
    required BuscarLectorPorQr buscarPorQr,
    required String? Function() usuarioActualId,
  })  : _obtenerLectores = obtenerLectores,
        _registrarLector = registrarLector,
        _actualizarLector = actualizarLector,
        _cambiarCategoria = cambiarCategoria,
        _obtenerDesactualizados = obtenerDesactualizados,
        _buscarPorQr = buscarPorQr,
        _usuarioActualId = usuarioActualId,
        super(const LectoresState()) {
    on<LectoresSolicitados>(_alSolicitarLectores);
    on<LectorRegistrado>(_alRegistrarLector);
    on<LectorActualizado>(_alActualizarLector);
    on<CategoriaCambiada>(_alCambiarCategoria);
    on<LectorBuscadoPorQr>(_alBuscarPorQr);
    on<SeleccionDeLectorLimpiada>(
      (_, emit) => emit(state.copyWith(limpiarSeleccionado: true)),
    );
    on<MensajeLectoresDescartado>(
      (_, emit) => emit(state.copyWith(limpiarMensajes: true)),
    );
  }

  final ObtenerLectores _obtenerLectores;
  final RegistrarLector _registrarLector;
  final ActualizarLector _actualizarLector;
  final CambiarCategoria _cambiarCategoria;
  final ObtenerLectoresConCategoriaDesactualizada _obtenerDesactualizados;
  final BuscarLectorPorQr _buscarPorQr;
  final String? Function() _usuarioActualId;

  Future<void> _alSolicitarLectores(
    LectoresSolicitados event,
    Emitter<LectoresState> emit,
  ) async {
    emit(state.copyWith(estado: EstadoCarga.cargando, limpiarMensajes: true));
    await _recargar(emit);
  }

  Future<void> _alRegistrarLector(
    LectorRegistrado event,
    Emitter<LectoresState> emit,
  ) async {
    final resultado = await _registrarLector(RegistrarLectorParams(
      lector: event.lector,
      usuarioId: _usuarioActualId(),
    ));

    await resultado.fold(
      (failure) async => emit(state.copyWith(mensajeError: failure.mensaje)),
      (lector) async {
        await _recargar(emit);
        emit(state.copyWith(
          mensajeExito: '${lector.nombreCompleto} quedó registrado. '
              'Su credencial es ${lector.qr}.',
        ));
      },
    );
  }

  Future<void> _alActualizarLector(
    LectorActualizado event,
    Emitter<LectoresState> emit,
  ) async {
    final resultado = await _actualizarLector(ActualizarLectorParams(
      lector: event.lector,
      usuarioId: _usuarioActualId(),
    ));

    await resultado.fold(
      (failure) async => emit(state.copyWith(mensajeError: failure.mensaje)),
      (_) async {
        await _recargar(emit);
        emit(state.copyWith(mensajeExito: 'Datos actualizados'));
      },
    );
  }

  Future<void> _alCambiarCategoria(
    CategoriaCambiada event,
    Emitter<LectoresState> emit,
  ) async {
    final resultado = await _cambiarCategoria(CambiarCategoriaParams(
      lectorId: event.lectorId,
      nueva: event.categoria,
      usuarioId: _usuarioActualId(),
    ));

    await resultado.fold(
      (failure) async => emit(state.copyWith(mensajeError: failure.mensaje)),
      (lector) async {
        await _recargar(emit);
        emit(state.copyWith(
          mensajeExito: '${lector.nombreCompleto} pasó a '
              '${lector.categoria.label}. Los préstamos vigentes conservan '
              'sus condiciones originales.',
        ));
      },
    );
  }

  Future<void> _alBuscarPorQr(
    LectorBuscadoPorQr event,
    Emitter<LectoresState> emit,
  ) async {
    final resultado = await _buscarPorQr(BuscarLectorPorQrParams(event.qr));

    resultado.fold(
      (failure) => emit(state.copyWith(
        mensajeError: failure.mensaje,
        limpiarSeleccionado: true,
      )),
      (lector) => emit(state.copyWith(seleccionado: lector)),
    );
  }

  Future<void> _recargar(Emitter<LectoresState> emit) async {
    final lectores = await _obtenerLectores(const SinParametros());
    final desactualizados =
        await _obtenerDesactualizados(const SinParametros());

    lectores.fold(
      (failure) => emit(state.copyWith(
        estado: EstadoCarga.error,
        mensajeError: failure.mensaje,
      )),
      (lista) => emit(state.copyWith(
        estado: EstadoCarga.exito,
        lectores: lista,
        categoriasDesactualizadas: desactualizados.valorONull ?? const [],
      )),
    );
  }
}
