import 'package:flutter/material.dart';

import '../../core/tema.dart';
import '../widgets/shell_adaptativo.dart';
import 'seccion_parametros.dart';
import 'seccion_reportes.dart';
import 'secciones_varias.dart';

/// Panel de administración (spec v2 §9), portado de `admin.html`.
class PanelAdmin extends StatelessWidget {
  const PanelAdmin({super.key});

  @override
  Widget build(BuildContext context) {
    return ShellAdaptativo(
      titulo: 'Administración',
      colorRol: Paleta.pink,
      destinos: [
        Destino(
          etiqueta: 'Reportes',
          icono: Icons.insights_outlined,
          iconoActivo: Icons.insights,
          constructor: (_) => const SeccionReportes(),
        ),
        Destino(
          etiqueta: 'Parámetros',
          icono: Icons.tune_outlined,
          iconoActivo: Icons.tune,
          constructor: (_) => const SeccionParametros(),
        ),
        Destino(
          etiqueta: 'Auditoría',
          icono: Icons.receipt_long_outlined,
          iconoActivo: Icons.receipt_long,
          constructor: (_) => const SeccionAuditoria(),
        ),
        Destino(
          etiqueta: 'Aprendizaje',
          icono: Icons.psychology_outlined,
          iconoActivo: Icons.psychology,
          constructor: (_) => const SeccionAprendizaje(),
        ),
        Destino(
          etiqueta: 'Sugerencias',
          icono: Icons.lightbulb_outline,
          iconoActivo: Icons.lightbulb,
          constructor: (_) => const SeccionSugerencias(),
        ),
        Destino(
          etiqueta: 'Acerca de',
          icono: Icons.info_outline,
          iconoActivo: Icons.info,
          constructor: (_) => const SeccionAcerca(),
        ),
      ],
    );
  }
}
