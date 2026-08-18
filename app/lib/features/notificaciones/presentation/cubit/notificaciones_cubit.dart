import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/presentation/estado_carga.dart';
import '../../domain/entities/notificacion.dart';
import '../../domain/usecases/gestionar_notificaciones.dart';

part 'notificaciones_state.dart';

/// Buzón de avisos del lector.
///
/// Cubit y no Bloc: son tres operaciones sin ramificaciones, y una capa de
/// eventos sólo agregaría ceremonia.
class NotificacionesCubit extends Cubit<NotificacionesState> {
  NotificacionesCubit({
    required ObtenerNotificaciones obtenerNotificaciones,
    required ContarNoLeidas contarNoLeidas,
    required MarcarNotificacionLeida marcarLeida,
    required MarcarTodasLeidas marcarTodasLeidas,
  })  : _obtener = obtenerNotificaciones,
        _contar = contarNoLeidas,
        _marcarLeida = marcarLeida,
        _marcarTodas = marcarTodasLeidas,
        super(const NotificacionesState());

  final ObtenerNotificaciones _obtener;
  final ContarNoLeidas _contar;
  final MarcarNotificacionLeida _marcarLeida;
  final MarcarTodasLeidas _marcarTodas;

  String? _lectorId;

  Future<void> cargar(String lectorId) async {
    _lectorId = lectorId;
    emit(state.copyWith(estado: EstadoCarga.cargando));
    await _recargar();
  }

  Future<void> marcarComoLeida(String notificacionId) async {
    await _marcarLeida(MarcarNotificacionLeidaParams(notificacionId));
    await _recargar();
  }

  Future<void> marcarTodasComoLeidas() async {
    final id = _lectorId;
    if (id == null) return;
    await _marcarTodas(LectorParams(id));
    await _recargar();
  }

  Future<void> _recargar() async {
    final id = _lectorId;
    if (id == null) return;

    final lista = await _obtener(LectorParams(id));
    final noLeidas = await _contar(LectorParams(id));

    lista.fold(
      (failure) => emit(state.copyWith(
        estado: EstadoCarga.error,
        mensajeError: failure.mensaje,
      )),
      (notificaciones) => emit(state.copyWith(
        estado: EstadoCarga.exito,
        notificaciones: notificaciones,
        noLeidas: noLeidas.valorONull ?? 0,
      )),
    );
  }
}
