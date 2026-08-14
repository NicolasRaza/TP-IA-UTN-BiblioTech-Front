import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/tema.dart';
import 'domain/enums.dart';
import 'state/app_state.dart';
import 'ui/admin/panel_admin.dart';
import 'ui/bibliotecario/panel_bibliotecario.dart';
import 'ui/lector/portal_lector.dart';
import 'ui/login/pantalla_login.dart';

class BiblioTechApp extends StatelessWidget {
  const BiblioTechApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BiblioTech',
      debugShowCheckedModeBanner: false,
      theme: construirTema(),
      home: const _Raiz(),
    );
  }
}

/// Elige la pantalla según haya sesión y qué rol tenga el usuario.
class _Raiz extends StatelessWidget {
  const _Raiz();

  @override
  Widget build(BuildContext context) {
    final estado = context.watch<AppState>();
    final usuario = estado.usuario;

    if (usuario == null) return const PantallaLogin();

    return switch (usuario.rol) {
      RolUsuario.lector => const PortalLector(),
      RolUsuario.bibliotecario => const PanelBibliotecario(),
      RolUsuario.administrador => const PanelAdmin(),
    };
  }
}
