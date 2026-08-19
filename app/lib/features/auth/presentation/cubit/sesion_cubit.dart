import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/presentation/estado_carga.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../administracion/domain/usecases/gestionar_configuracion.dart';
import '../../../lectores/domain/entities/lector.dart';
import '../../domain/usecases/gestionar_sesion.dart';

part 'sesion_state.dart';

/// Sesión del usuario.
///
/// Va como Cubit y no como Bloc porque su estado es simple —hay sesión o no
/// la hay— y las tres transiciones posibles no ganan nada con una capa de
/// eventos de por medio.
class SesionCubit extends Cubit<SesionState> {
  SesionCubit({
    required IniciarSesion iniciarSesion,
    required CerrarSesion cerrarSesion,
    required ObtenerSesionActiva obtenerSesionActiva,
    required InicializarDatos inicializarDatos,
  })  : _iniciarSesion = iniciarSesion,
        _cerrarSesion = cerrarSesion,
        _obtenerSesionActiva = obtenerSesionActiva,
        _inicializarDatos = inicializarDatos,
        super(const SesionState());

  final IniciarSesion _iniciarSesion;
  final CerrarSesion _cerrarSesion;
  final ObtenerSesionActiva _obtenerSesionActiva;
  final InicializarDatos _inicializarDatos;

  /// Arranque de la app: siembra los datos de demostración si hace falta y
  /// recupera la sesión persistida.
  Future<void> arrancar() async {
    emit(state.copyWith(estado: EstadoCarga.cargando, limpiarError: true));

    await _inicializarDatos(const SinParametros());

    final sesion = await _obtenerSesionActiva(const SinParametros());
    sesion.fold(
      (failure) => emit(state.copyWith(
        estado: EstadoCarga.error,
        mensajeError: failure.mensaje,
      )),
      (usuario) => emit(SesionState(
        estado: EstadoCarga.exito,
        usuario: usuario,
      )),
    );
  }

  Future<void> iniciarSesion({
    required String email,
    required String clave,
  }) async {
    emit(state.copyWith(estado: EstadoCarga.cargando, limpiarError: true));

    final resultado =
        await _iniciarSesion(IniciarSesionParams(email: email, clave: clave));

    resultado.fold(
      (failure) => emit(SesionState(
        estado: EstadoCarga.error,
        mensajeError: failure.mensaje,
        cuentaPendiente: failure is CuentaPendienteFailure,
      )),
      (usuario) => emit(SesionState(
        estado: EstadoCarga.exito,
        usuario: usuario,
      )),
    );
  }

  Future<void> cerrarSesion() async {
    await _cerrarSesion(const SinParametros());
    emit(const SesionState(estado: EstadoCarga.exito));
  }

  /// Relee los datos del usuario logueado.
  ///
  /// Hace falta después de cualquier operación que le cambie el saldo de
  /// multas o la categoría, para que el perfil no muestre datos viejos.
  Future<void> refrescarUsuario() async {
    if (!state.haySesion) return;
    final sesion = await _obtenerSesionActiva(const SinParametros());
    final usuario = sesion.valorONull;
    if (usuario != null) emit(state.copyWith(usuario: usuario));
  }

  void limpiarError() => emit(state.copyWith(limpiarError: true));
}
