import 'package:flutter/material.dart';

import '../../core/tema.dart';
import '../widgets/seccion_pendiente.dart';
import '../widgets/shell_adaptativo.dart';

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
          constructor: (_) => const SeccionPendiente(
            titulo: 'Reportes e indicadores',
            descripcion:
                'Títulos más prestados, lectores más activos, géneros más leídos y '
                'evolución mensual de préstamos y devoluciones tardías.',
            origen: 'admin.html #s-reportes',
          ),
        ),
        Destino(
          etiqueta: 'Parámetros',
          icono: Icons.tune_outlined,
          iconoActivo: Icons.tune,
          constructor: (_) => const SeccionPendiente(
            titulo: 'Parámetros de la biblioteca',
            descripcion:
                'Plazos de préstamo y límites de ejemplares y reservas por categoría, '
                'plazo de retiro de reservas, multa por día de demora y ponderación '
                'del motor de recomendaciones.',
            origen: 'admin.html #s-configuracion',
          ),
        ),
        Destino(
          etiqueta: 'Auditoría',
          icono: Icons.receipt_long_outlined,
          iconoActivo: Icons.receipt_long,
          constructor: (_) => const SeccionPendiente(
            titulo: 'Registro de auditoría',
            descripcion:
                'Altas y bajas de libros y lectores, préstamos y devoluciones, '
                'reimpresiones de QR con su motivo y cambios de categoría, con quién '
                'y cuándo los hizo.',
            origen: 'admin.html #s-auditoria',
          ),
        ),
        Destino(
          etiqueta: 'Aprendizaje',
          icono: Icons.psychology_outlined,
          iconoActivo: Icons.psychology,
          constructor: (_) => const SeccionPendiente(
            titulo: 'Aprendizaje del sistema',
            descripcion:
                'Campos que el bibliotecario corrige con más frecuencia sobre las '
                'fichas sugeridas, y qué recomendaciones terminaron en una reserva.',
            origen: 'admin.html #s-aprendizaje',
          ),
        ),
        Destino(
          etiqueta: 'Sugerencias',
          icono: Icons.lightbulb_outline,
          iconoActivo: Icons.lightbulb,
          constructor: (_) => const SeccionPendiente(
            titulo: 'Sugerencias estratégicas',
            descripcion:
                'Recomendaciones de compra por alta demanda o colas de espera, '
                'títulos nunca prestados y alertas sobre la tasa de devoluciones '
                'tardías.',
            origen: 'admin.html #s-sugerencias',
          ),
        ),
        Destino(
          etiqueta: 'Acerca de',
          icono: Icons.info_outline,
          iconoActivo: Icons.info,
          constructor: (_) => const SeccionPendiente(
            titulo: 'Acerca de BiblioTech',
            descripcion:
                'Descripción del sistema, red de agentes y equipo del trabajo '
                'práctico, con la opción de reiniciar los datos de demostración.',
            origen: 'admin.html #s-acerca',
          ),
        ),
      ],
    );
  }
}
