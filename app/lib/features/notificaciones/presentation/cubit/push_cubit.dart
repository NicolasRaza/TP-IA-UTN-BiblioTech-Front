import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/presentation/estado_carga.dart';
import '../../../../core/push/servicio_push.dart';
import '../../../auth/domain/entities/credenciales_api.dart';
import '../../domain/repositories/push_repository.dart';
import '../../domain/usecases/activar_notificaciones_push.dart';

part 'push_state.dart';

/// Estado de las notificaciones push del dispositivo.
///
/// Cubit y no Bloc: una sola operación —activar— y un stream que escuchar.
class PushCubit extends Cubit<PushState> {
  PushCubit({
    required ActivarNotificacionesPush activarNotificacionesPush,
    required PushRepository repository,
  })  : _activar = activarNotificacionesPush,
        super(PushState(soportado: repository.soportado)) {
    _avisos = repository.mensajesRecibidos.listen(
      (mensaje) => emit(state.copyWith(
        ultimoAviso: mensaje.titulo ?? mensaje.cuerpo,
      )),
    );
  }

  final ActivarNotificacionesPush _activar;
  late final StreamSubscription<MensajePush> _avisos;

  /// Pide permiso, obtiene el token FCM y lo registra en el backend.
  Future<void> activar(
      {required String email, required String password}) async {
    emit(state.copyWith(estado: EstadoCarga.cargando));

    final resultado =
        await _activar(CredencialesApi(email: email, password: password));

    resultado.fold(
      (failure) => emit(state.copyWith(
        estado: EstadoCarga.error,
        mensajeError: failure.mensaje,
      )),
      (token) => emit(state.copyWith(
        estado: EstadoCarga.exito,
        token: token,
      )),
    );
  }

  @override
  Future<void> close() {
    _avisos.cancel();
    return super.close();
  }
}
