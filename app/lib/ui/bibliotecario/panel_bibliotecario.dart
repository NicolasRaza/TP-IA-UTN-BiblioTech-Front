import 'package:flutter/material.dart';

import '../../core/tema.dart';
import '../widgets/shell_adaptativo.dart';
import 'seccion_alertas.dart';
import 'seccion_alta_libro.dart';
import 'seccion_dashboard.dart';
import 'seccion_inventario.dart';
import 'seccion_lectores.dart';
import 'seccion_mostrador.dart';

/// Panel del bibliotecario (spec v2 §9), portado de `bibliotecario.html`.
class PanelBibliotecario extends StatelessWidget {
  const PanelBibliotecario({super.key});

  @override
  Widget build(BuildContext context) {
    return ShellAdaptativo(
      titulo: 'Panel del Bibliotecario',
      colorRol: Paleta.primary,
      destinos: [
        Destino(
          etiqueta: 'Dashboard',
          icono: Icons.dashboard_outlined,
          iconoActivo: Icons.dashboard,
          constructor: (_) => const SeccionDashboard(),
        ),
        Destino(
          etiqueta: 'Alta de libro',
          icono: Icons.add_photo_alternate_outlined,
          iconoActivo: Icons.add_photo_alternate,
          constructor: (_) => const SeccionAltaLibro(),
        ),
        Destino(
          etiqueta: 'Catálogo',
          icono: Icons.inventory_2_outlined,
          iconoActivo: Icons.inventory_2,
          constructor: (_) => const SeccionInventario(),
        ),
        Destino(
          etiqueta: 'Préstamo',
          icono: Icons.output_outlined,
          iconoActivo: Icons.output,
          constructor: (_) => const SeccionPrestamo(),
        ),
        Destino(
          etiqueta: 'Devolución',
          icono: Icons.input_outlined,
          iconoActivo: Icons.input,
          constructor: (_) => const SeccionDevolucion(),
        ),
        Destino(
          etiqueta: 'Lectores',
          icono: Icons.people_outline,
          iconoActivo: Icons.people,
          constructor: (_) => const SeccionLectores(),
        ),
        Destino(
          etiqueta: 'Alertas',
          icono: Icons.warning_amber_outlined,
          iconoActivo: Icons.warning_amber,
          constructor: (_) => const SeccionAlertas(),
        ),
      ],
    );
  }
}
