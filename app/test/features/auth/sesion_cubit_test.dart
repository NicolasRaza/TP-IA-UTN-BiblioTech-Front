import 'package:bibliotech/core/presentation/estado_carga.dart';
import 'package:bibliotech/features/auth/presentation/cubit/sesion_cubit.dart';
import 'package:bibliotech/features/lectores/domain/entities/lector.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/entorno_de_prueba.dart';

/// Tests del [SesionCubit] contra el grafo real de la aplicación.
void main() {
  late EntornoDePrueba entorno;

  setUp(() async {
    entorno = await EntornoDePrueba.montar();
  });

  tearDown(() => entorno.desmontar());

  blocTest<SesionCubit, SesionState>(
    'con credenciales válidas abre la sesión y expone el rol',
    build: () => entorno<SesionCubit>(),
    act: (cubit) => cubit.iniciarSesion(
      // Credenciales de la semilla de demostración.
      email: 'laura@demo.com',
      clave: '1234',
    ),
    expect: () => [
      isA<SesionState>()
          .having((s) => s.estado, 'estado', EstadoCarga.cargando),
      isA<SesionState>()
          .having((s) => s.estado, 'estado', EstadoCarga.exito)
          .having((s) => s.haySesion, 'haySesion', isTrue)
          .having((s) => s.rol, 'rol', RolUsuario.lector),
    ],
  );

  blocTest<SesionCubit, SesionState>(
    'con PIN incorrecto no abre sesión y explica por qué',
    build: () => entorno<SesionCubit>(),
    act: (cubit) => cubit.iniciarSesion(
      email: 'laura@demo.com',
      clave: '0000',
    ),
    expect: () => [
      isA<SesionState>()
          .having((s) => s.estado, 'estado', EstadoCarga.cargando),
      isA<SesionState>()
          .having((s) => s.estado, 'estado', EstadoCarga.error)
          .having((s) => s.haySesion, 'haySesion', isFalse)
          .having(
              (s) => s.mensajeError, 'mensajeError', contains('incorrecto')),
    ],
  );

  blocTest<SesionCubit, SesionState>(
    'el mismo mensaje para email inexistente, para no filtrar qué cuentas hay',
    build: () => entorno<SesionCubit>(),
    act: (cubit) => cubit.iniciarSesion(
      email: 'nadie@demo.com',
      clave: '1234',
    ),
    expect: () => [
      isA<SesionState>()
          .having((s) => s.estado, 'estado', EstadoCarga.cargando),
      isA<SesionState>().having(
        (s) => s.mensajeError,
        'mensajeError',
        'Email o PIN incorrectos',
      ),
    ],
  );

  blocTest<SesionCubit, SesionState>(
    'cerrar sesión deja el estado sin usuario',
    build: () => entorno<SesionCubit>(),
    act: (cubit) async {
      await cubit.iniciarSesion(email: 'laura@demo.com', clave: '1234');
      await cubit.cerrarSesion();
    },
    skip: 2,
    expect: () => [
      isA<SesionState>().having((s) => s.haySesion, 'haySesion', isFalse),
    ],
  );

  blocTest<SesionCubit, SesionState>(
    'los campos vacíos se rechazan sin llegar al repositorio',
    build: () => entorno<SesionCubit>(),
    act: (cubit) => cubit.iniciarSesion(email: '', clave: ''),
    expect: () => [
      isA<SesionState>()
          .having((s) => s.estado, 'estado', EstadoCarga.cargando),
      isA<SesionState>()
          .having((s) => s.mensajeError, 'mensajeError', contains('email')),
    ],
  );
}
