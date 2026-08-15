import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/presentation/estado_carga.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/entities/prestamo.dart';
import '../../domain/usecases/consultas_prestamos.dart';
import '../../domain/usecases/registrar_devolucion.dart';
import '../../domain/usecases/registrar_prestamo.dart';

part 'prestamos_event.dart';
part 'prestamos_state.dart';

/// Circulación: los préstamos del lector y las operaciones de mostrador.
///
/// Va como Bloc porque el mostrador es el flujo más complejo de la app —
/// identificar lector, elegir ejemplar, prestar o devolver— y conviene tener
/// cada intención registrada como evento.
class PrestamosBloc extends Bloc<PrestamosEvent, PrestamosState> {
  PrestamosBloc({
    required ObtenerPrestamosActivos obtenerActivos,
    required ObtenerHistorialPrestamos obtenerHistorial,
    required ObtenerTodosLosPrestamos obtenerTodos,
    required ObtenerEstadisticasPrestamos obtenerEstadisticas,
    required RegistrarPrestamo registrarPrestamo,
    required RegistrarDevolucion registrarDevolucion,
    required String? Function() usuarioActualId,
  })  : _obtenerActivos = obtenerActivos,
        _obtenerHistorial = obtenerHistorial,
        _obtenerTodos = obtenerTodos,
        _obtenerEstadisticas = obtenerEstadisticas,
        _registrarPrestamo = registrarPrestamo,
        _registrarDevolucion = registrarDevolucion,
        _usuarioActualId = usuarioActualId,
        super(const PrestamosState()) {
    on<PrestamosDeLectorSolicitados>(_alSolicitarDeLector);
    on<TodosLosPrestamosSolicitados>(_alSolicitarTodos);
    on<PrestamoRegistrado>(_alRegistrarPrestamo);
    on<DevolucionRegistrada>(_alRegistrarDevolucion);
    on<MensajePrestamosDescartado>(
      (_, emit) => emit(state.copyWith(limpiarMensajes: true)),
    );
  }

  final ObtenerPrestamosActivos _obtenerActivos;
  final ObtenerHistorialPrestamos _obtenerHistorial;
  final ObtenerTodosLosPrestamos _obtenerTodos;
  final ObtenerEstadisticasPrestamos _obtenerEstadisticas;
  final RegistrarPrestamo _registrarPrestamo;
  final RegistrarDevolucion _registrarDevolucion;
  final String? Function() _usuarioActualId;

  /// Último lector consultado, para poder recargar su vista después de una
  /// operación sin que la pantalla tenga que volver a pedirlo.
  String? _ultimoLectorId;

  Future<void> _alSolicitarDeLector(
    PrestamosDeLectorSolicitados event,
    Emitter<PrestamosState> emit,
  ) async {
    _ultimoLectorId = event.lectorId;
    emit(state.copyWith(estado: EstadoCarga.cargando, limpiarMensajes: true));
    await _recargarDeLector(emit, event.lectorId);
  }

  Future<void> _alSolicitarTodos(
    TodosLosPrestamosSolicitados event,
    Emitter<PrestamosState> emit,
  ) async {
    emit(state.copyWith(estado: EstadoCarga.cargando, limpiarMensajes: true));

    final todos = await _obtenerTodos(const SinParametros());
    final estadisticas = await _obtenerEstadisticas(const SinParametros());

    todos.fold(
      (failure) => emit(state.copyWith(
        estado: EstadoCarga.error,
        mensajeError: failure.mensaje,
      )),
      (prestamos) => emit(state.copyWith(
        estado: EstadoCarga.exito,
        todos: prestamos,
        estadisticas: estadisticas.valorONull,
      )),
    );
  }

  Future<void> _alRegistrarPrestamo(
    PrestamoRegistrado event,
    Emitter<PrestamosState> emit,
  ) async {
    emit(state.copyWith(operando: true, limpiarMensajes: true));

    final resultado = await _registrarPrestamo(RegistrarPrestamoParams(
      lectorId: event.lectorId,
      libroId: event.libroId,
      ejemplarId: event.ejemplarId,
      usuarioId: _usuarioActualId(),
    ));

    await resultado.fold(
      (failure) async => emit(state.copyWith(
        operando: false,
        mensajeError: failure.mensaje,
      )),
      (prestamo) async {
        await _recargarDeLector(emit, event.lectorId);
        emit(state.copyWith(
          operando: false,
          mensajeExito: 'Préstamo registrado. Vence el '
              '${_fechaCorta(prestamo.fechaVencimiento)}.',
        ));
      },
    );
  }

  Future<void> _alRegistrarDevolucion(
    DevolucionRegistrada event,
    Emitter<PrestamosState> emit,
  ) async {
    emit(state.copyWith(operando: true, limpiarMensajes: true));

    final resultado = await _registrarDevolucion(RegistrarDevolucionParams(
      prestamoId: event.prestamoId,
      usuarioId: _usuarioActualId(),
    ));

    await resultado.fold(
      (failure) async => emit(state.copyWith(
        operando: false,
        mensajeError: failure.mensaje,
      )),
      (prestamo) async {
        final lectorId = _ultimoLectorId ?? prestamo.lectorId;
        await _recargarDeLector(emit, lectorId);
        emit(state.copyWith(
          operando: false,
          mensajeExito: prestamo.tardio
              ? 'Devolución registrada. Se aplicó una multa de '
                  '\$${prestamo.multaAplicada} por la demora.'
              : 'Devolución registrada.',
        ));
      },
    );
  }

  Future<void> _recargarDeLector(
    Emitter<PrestamosState> emit,
    String lectorId,
  ) async {
    final activos =
        await _obtenerActivos(PrestamosDeLectorParams(lectorId));
    final historial =
        await _obtenerHistorial(PrestamosDeLectorParams(lectorId));
    final todos = await _obtenerTodos(const SinParametros());
    final estadisticas = await _obtenerEstadisticas(const SinParametros());

    activos.fold(
      (failure) => emit(state.copyWith(
        estado: EstadoCarga.error,
        mensajeError: failure.mensaje,
      )),
      (lista) => emit(state.copyWith(
        estado: EstadoCarga.exito,
        activos: lista,
        historial: historial.valorONull ?? const [],
        todos: todos.valorONull ?? const [],
        estadisticas: estadisticas.valorONull,
      )),
    );
  }

  static String _fechaCorta(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/${d.year}';
}
