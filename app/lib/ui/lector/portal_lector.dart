import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/tema.dart';
import '../../state/app_state.dart';
import '../widgets/seccion_pendiente.dart';
import '../widgets/shell_adaptativo.dart';

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
          constructor: (_) => const SeccionPendiente(
            titulo: 'Catálogo',
            descripcion:
                'Búsqueda por título, autor, ISBN o género sobre el catálogo público, '
                'con filtro por género, ficha de cada libro y botón de reserva. '
                'Solo lista libros validados por el bibliotecario.',
            origen: 'lector.html #s-catalogo',
          ),
        ),
        Destino(
          etiqueta: 'Para vos',
          icono: Icons.auto_awesome_outlined,
          iconoActivo: Icons.auto_awesome,
          constructor: (_) => const SeccionPendiente(
            titulo: 'Recomendaciones',
            descripcion:
                'Libros sugeridos por el Agente Evaluador con la ponderación 70/30 '
                'entre historial personal y popularidad, mostrando el motivo de cada '
                'recomendación y el aviso de "cold start" cuando no hay historial.',
            origen: 'lector.html #s-recomendaciones',
          ),
        ),
        Destino(
          etiqueta: 'Mi actividad',
          icono: Icons.menu_book_outlined,
          iconoActivo: Icons.menu_book,
          constructor: (_) => const SeccionPendiente(
            titulo: 'Mi actividad',
            descripcion:
                'Solapas de préstamos vigentes con su vencimiento, reservas en cola '
                'o listas para retirar con el plazo de 48 hs corriendo, e historial '
                'de devoluciones.',
            origen: 'lector.html #s-prestamos, #s-reservas, #s-historial',
          ),
        ),
        Destino(
          etiqueta: 'Avisos',
          icono: Icons.notifications_outlined,
          iconoActivo: Icons.notifications,
          contador: noLeidas,
          constructor: (_) => const SeccionPendiente(
            titulo: 'Notificaciones',
            descripcion:
                'Avisos generados por el Agente Planificador: vencimientos próximos, '
                'préstamos vencidos, reservas listas para retirar y recomendaciones.',
            origen: 'lector.html #s-notificaciones',
          ),
        ),
        Destino(
          etiqueta: 'Perfil',
          icono: Icons.person_outline,
          iconoActivo: Icons.person,
          constructor: (_) => const SeccionPendiente(
            titulo: 'Perfil',
            descripcion:
                'Datos del lector, su categoría y límites vigentes, multas pendientes, '
                'géneros de interés editables y el QR de identificación en mostrador.',
            origen: 'lector.html #s-perfil',
          ),
        ),
      ],
    );
  }
}
