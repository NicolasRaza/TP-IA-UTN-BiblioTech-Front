import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/presentation/estado_carga.dart';
import '../../../lectores/domain/entities/lector.dart';
import '../../../lectores/domain/entities/solicitud_de_registro.dart';
import '../../../lectores/domain/usecases/autorregistro.dart';

part 'registro_state.dart';

/// Autorregistro desde la pantalla de acceso.
///
/// Vive aparte del [SesionCubit] porque no abre ninguna sesión: registrarse y
/// entrar son dos cosas distintas, y entre una y otra tiene que pasar un
/// bibliotecario.
class RegistroCubit extends Cubit<RegistroState> {
  RegistroCubit({required RegistrarseComoLector registrarse})
      : _registrarse = registrarse,
        super(const RegistroState());

  final RegistrarseComoLector _registrarse;

  Future<void> registrar(SolicitudDeRegistro solicitud) async {
    emit(const RegistroState(estado: EstadoCarga.cargando));

    final resultado = await _registrarse(
      RegistrarseComoLectorParams(solicitud),
    );

    resultado.fold(
      (failure) => emit(RegistroState(
        estado: EstadoCarga.error,
        mensajeError: failure.mensaje,
      )),
      (lector) => emit(RegistroState(
        estado: EstadoCarga.exito,
        registrado: lector,
      )),
    );
  }
}
