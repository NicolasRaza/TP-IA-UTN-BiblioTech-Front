import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../core/di/inyeccion.dart';
import '../core/theme/tema.dart';
import '../features/auth/presentation/cubit/sesion_cubit.dart';
import '../features/auth/presentation/pages/pantalla_login.dart';
import '../features/lectores/domain/entities/lector.dart';
import 'panel_admin.dart';
import 'panel_bibliotecario.dart';
import 'portal_lector.dart';

class BiblioTechApp extends StatelessWidget {
  const BiblioTechApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      // La sesión es el único bloc global: toda la app rutea según ella.
      // Los blocs de cada feature se crean en la pantalla que los usa.
      value: sl<SesionCubit>()..arrancar(),
      child: MaterialApp(
        title: 'BiblioTech',
        debugShowCheckedModeBanner: false,
        theme: construirTema(),
        home: const _Raiz(),
      ),
    );
  }
}

/// Elige la pantalla según haya sesión y qué rol tenga el usuario.
class _Raiz extends StatelessWidget {
  const _Raiz();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SesionCubit, SesionState>(
      builder: (context, state) {
        if (state.estado.sinDatosAun) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final usuario = state.usuario;
        if (usuario == null) return const PantallaLogin();

        return switch (usuario.rol) {
          RolUsuario.lector => const PortalLector(),
          RolUsuario.bibliotecario => const PanelBibliotecario(),
          RolUsuario.administrador => const PanelAdmin(),
        };
      },
    );
  }
}
