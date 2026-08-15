import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/presentation/estado_carga.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/entities/reserva.dart';
import '../../domain/usecases/cancelar_reserva.dart';
import '../../domain/usecases/consultas_reservas.dart';
import '../../domain/usecases/crear_reserva.dart';

part 'reservas_event.dart';
part 'reservas_state.dart';

/// Reservas del lector y colas de espera.
class ReservasBloc extends Bloc<ReservasEvent, ReservasState> {
  ReservasBloc({
    required ObtenerReservasDeLector obtenerDeLector,
    required ObtenerTodasLasReservas obtenerTodas,
    required CrearReserva crearReserva,
    required CancelarReserva cancelarReserva,
  })  : _obtenerDeLector = obtenerDeLector,
        _obtenerTodas = obtenerTodas,
        _crearReserva = crearReserva,
        _cancelarReserva = cancelarReserva,
        super(const ReservasState()) {
    on<ReservasDeLectorSolicitadas>(_alSolicitarDeLector);
    on<TodasLasReservasSolicitadas>(_alSolicitarTodas);
    on<ReservaCreada>(_alCrearReserva);
    on<ReservaCancelada>(_alCancelarReserva);
    on<MensajeReservasDescartado>(
      (_, emit) => emit(state.copyWith(limpiarMensajes: true)),
    );
  }

  final ObtenerReservasDeLector _obtenerDeLector;
  final ObtenerTodasLasReservas _obtenerTodas;
  final CrearReserva _crearReserva;
  final CancelarReserva _cancelarReserva;

  String? _ultimoLectorId;

  Future<void> _alSolicitarDeLector(
    ReservasDeLectorSolicitadas event,
    Emitter<ReservasState> emit,
  ) async {
    _ultimoLectorId = event.lectorId;
    emit(state.copyWith(estado: EstadoCarga.cargando, limpiarMensajes: true));
    await _recargar(emit, event.lectorId);
  }

  Future<void> _alSolicitarTodas(
    TodasLasReservasSolicitadas event,
    Emitter<ReservasState> emit,
  ) async {
    emit(state.copyWith(estado: EstadoCarga.cargando, limpiarMensajes: true));

    final todas = await _obtenerTodas(const SinParametros());
    todas.fold(
      (failure) => emit(state.copyWith(
        estado: EstadoCarga.error,
        mensajeError: failure.mensaje,
      )),
      (reservas) => emit(state.copyWith(
        estado: EstadoCarga.exito,
        todas: reservas,
      )),
    );
  }

  Future<void> _alCrearReserva(
    ReservaCreada event,
    Emitter<ReservasState> emit,
  ) async {
    emit(state.copyWith(operando: true, limpiarMensajes: true));

    final resultado = await _crearReserva(CrearReservaParams(
      lectorId: event.lectorId,
      libroId: event.libroId,
    ));

    await resultado.fold(
      (failure) async => emit(state.copyWith(
        operando: false,
        mensajeError: failure.mensaje,
      )),
      (reserva) async {
        await _recargar(emit, event.lectorId);
        emit(state.copyWith(
          operando: false,
          mensajeExito: reserva.estaRetenida
              ? '¡Ya está lista para retirar! Tenés '
                  '${reserva.plazoRetiroHorasAlReservar} horas.'
              : 'Quedaste en la lista de espera. Te avisamos cuando se libere '
                  'un ejemplar.',
        ));
      },
    );
  }

  Future<void> _alCancelarReserva(
    ReservaCancelada event,
    Emitter<ReservasState> emit,
  ) async {
    emit(state.copyWith(operando: true, limpiarMensajes: true));

    final resultado =
        await _cancelarReserva(CancelarReservaParams(event.reservaId));

    await resultado.fold(
      (failure) async => emit(state.copyWith(
        operando: false,
        mensajeError: failure.mensaje,
      )),
      (reserva) async {
        await _recargar(emit, _ultimoLectorId ?? reserva.lectorId);
        emit(state.copyWith(
          operando: false,
          mensajeExito: 'Reserva cancelada',
        ));
      },
    );
  }

  Future<void> _recargar(Emitter<ReservasState> emit, String lectorId) async {
    final propias = await _obtenerDeLector(ReservasDeLectorParams(lectorId));
    final todas = await _obtenerTodas(const SinParametros());

    propias.fold(
      (failure) => emit(state.copyWith(
        estado: EstadoCarga.error,
        mensajeError: failure.mensaje,
      )),
      (reservas) => emit(state.copyWith(
        estado: EstadoCarga.exito,
        propias: reservas,
        todas: todas.valorONull ?? const [],
      )),
    );
  }
}
