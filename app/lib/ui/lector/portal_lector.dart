import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/tema.dart';
import '../../state/app_state.dart';
import '../widgets/shell_adaptativo.dart';
import 'seccion_actividad.dart';
import 'seccion_catalogo.dart';
import 'seccion_notificaciones.dart';
import 'seccion_perfil.dart';
import 'seccion_recomendaciones.dart';

/// Portal del lector (spec v2 §9), portado de `lector.html`.
///
/// Las siete secciones del prototipo se agrupan en cinco destinos: préstamos,
/// reservas e historial comparten "Mi actividad" con solapas, para que la
/// barra inferior siga siendo cómoda en un celular.
class PortalLector extends StatelessWidget {
  const PortalLector({super.key});

  @override
  Widget build(BuildContext context) {
    final noLeidas = context.select<AppState, int>((s) => s.misNoLeidas);

    return ShellAdaptativo(
      titulo: 'Portal del Lector',
      colorRol: Paleta.teal,
      destinos: [
        Destino(
          etiqueta: 'Catálogo',
          icono: Icons.search_outlined,
          iconoActivo: Icons.search,
          constructor: (_) => const SeccionCatalogo(),
        ),
        Destino(
          etiqueta: 'Para vos',
          icono: Icons.auto_awesome_outlined,
          iconoActivo: Icons.auto_awesome,
          constructor: (_) => const SeccionRecomendaciones(),
        ),
        Destino(
          etiqueta: 'Mi actividad',
          icono: Icons.menu_book_outlined,
          iconoActivo: Icons.menu_book,
          constructor: (_) => const SeccionActividad(),
        ),
        Destino(
          etiqueta: 'Avisos',
          icono: Icons.notifications_outlined,
          iconoActivo: Icons.notifications,
          contador: noLeidas,
          constructor: (_) => const SeccionNotificaciones(),
        ),
        Destino(
          etiqueta: 'Perfil',
          icono: Icons.person_outline,
          iconoActivo: Icons.person,
          constructor: (_) => const SeccionPerfil(),
        ),
      ],
    );
  }
}
