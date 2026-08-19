import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/presentation/estado_carga.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../lectores/domain/entities/lector.dart';
import '../../domain/entities/usuario_interno.dart';
import '../../domain/usecases/gestionar_usuarios_internos.dart';

part 'usuarios_internos_state.dart';

/// Cuentas del personal, en el panel del administrador.
class UsuariosInternosCubit extends Cubit<UsuariosInternosState> {
  UsuariosInternosCubit({
    required ObtenerUsuariosInternos obtenerUsuarios,
    required RegistrarUsuarioInterno registrarUsuario,
    required CambiarEstadoUsuarioInterno cambiarEstado,
    required String? Function() usuarioActualId,
  })  : _obtenerUsuarios = obtenerUsuarios,
        _registrarUsuario = registrarUsuario,
        _cambiarEstado = cambiarEstado,
        _usuarioActualId = usuarioActualId,
        super(const UsuariosInternosState());

  final ObtenerUsuariosInternos _obtenerUsuarios;
  final RegistrarUsuarioInterno _registrarUsuario;
  final CambiarEstadoUsuarioInterno _cambiarEstado;
  final String? Function() _usuarioActualId;

  Future<void> cargar() async {
    emit(state.copyWith(estado: EstadoCarga.cargando, limpiarMensajes: true));
    await _recargar();
  }

  Future<void> registrar({
    required String email,
    required String password,
    required RolUsuario rol,
  }) async {
    emit(state.copyWith(guardando: true, limpiarMensajes: true));

    final resultado = await _registrarUsuario(RegistrarUsuarioInternoParams(
      email: email,
      password: password,
      rol: rol,
      usuarioId: _usuarioActualId(),
    ));

    await resultado.fold(
      (failure) async => emit(state.copyWith(
        guardando: false,
        mensajeError: failure.mensaje,
      )),
      (usuario) async {
        await _recargar();
        emit(state.copyWith(
          guardando: false,
          mensajeExito: '${usuario.email} quedó dado de alta como '
              '${usuario.etiquetaRol.toLowerCase()}.',
        ));
      },
    );
  }

  Future<void> cambiarEstado(UsuarioInterno usuario,
      {required bool activar}) async {
    emit(state.copyWith(guardando: true, limpiarMensajes: true));

    final resultado = await _cambiarEstado(CambiarEstadoUsuarioInternoParams(
      usuario: usuario,
      activar: activar,
      usuarioId: _usuarioActualId(),
    ));

    await resultado.fold(
      (failure) async => emit(state.copyWith(
        guardando: false,
        mensajeError: failure.mensaje,
      )),
      (_) async {
        await _recargar();
        emit(state.copyWith(
          guardando: false,
          mensajeExito: activar
              ? '${usuario.email} vuelve a tener acceso.'
              : '${usuario.email} ya no puede iniciar sesión.',
        ));
      },
    );
  }

  Future<void> _recargar() async {
    final usuarios = await _obtenerUsuarios(const SinParametros());

    usuarios.fold(
      (failure) => emit(state.copyWith(
        estado: EstadoCarga.error,
        mensajeError: failure.mensaje,
      )),
      (lista) => emit(state.copyWith(
        estado: EstadoCarga.exito,
        usuarios: lista,
      )),
    );
  }
}
