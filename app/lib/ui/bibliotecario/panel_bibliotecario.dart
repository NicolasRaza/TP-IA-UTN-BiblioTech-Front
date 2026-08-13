import 'package:flutter/material.dart';

import '../../core/tema.dart';
import '../widgets/seccion_pendiente.dart';
import '../widgets/shell_adaptativo.dart';

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
          constructor: (_) => const SeccionPendiente(
            titulo: 'Dashboard',
            descripcion:
                'Métricas de préstamos activos, vencidos y devoluciones, gráficos de '
                'uso y las decisiones abiertas que el Agente Evaluador dejó pendientes.',
            origen: 'bibliotecario.html #s-dashboard',
          ),
        ),
        Destino(
          etiqueta: 'Alta de libro',
          icono: Icons.add_photo_alternate_outlined,
          iconoActivo: Icons.add_photo_alternate,
          constructor: (_) => const SeccionPendiente(
            titulo: 'Alta de libro',
            descripcion:
                'Carga de las tres fotos (tapa, contratapa y ficha técnica), ficha '
                'sugerida por el Agente Analizador con el nivel de confianza de cada '
                'campo, resolución de fuentes en conflicto y confirmación explícita '
                'que publica el libro en el catálogo.',
            origen: 'bibliotecario.html #s-agregar-libro',
          ),
        ),
        Destino(
          etiqueta: 'Catálogo',
          icono: Icons.inventory_2_outlined,
          iconoActivo: Icons.inventory_2,
          constructor: (_) => const SeccionPendiente(
            titulo: 'Catálogo e inventario',
            descripcion:
                'Listado completo con ejemplares por título, estado y condición de '
                'cada uno, alta de ejemplares y reimpresión de etiquetas QR '
                'conservando el identificador interno.',
            origen: 'bibliotecario.html #s-catalogo-bib',
          ),
        ),
        Destino(
          etiqueta: 'Préstamo',
          icono: Icons.output_outlined,
          iconoActivo: Icons.output,
          constructor: (_) => const SeccionPendiente(
            titulo: 'Registrar préstamo',
            descripcion:
                'Identificación del lector por QR o búsqueda, escaneo del ejemplar, '
                'validación de límites y multas, y confirmación del préstamo con el '
                'plazo que corresponde a la categoría del lector.',
            origen: 'bibliotecario.html #s-prestamo',
          ),
        ),
        Destino(
          etiqueta: 'Devolución',
          icono: Icons.input_outlined,
          iconoActivo: Icons.input,
          constructor: (_) => const SeccionPendiente(
            titulo: 'Registrar devolución',
            descripcion:
                'Escaneo del ejemplar, cálculo de multa por atraso y liberación del '
                'ejemplar, que pasa automáticamente al primero de la cola de reservas.',
            origen: 'bibliotecario.html #s-devolucion',
          ),
        ),
        Destino(
          etiqueta: 'Lectores',
          icono: Icons.people_outline,
          iconoActivo: Icons.people,
          constructor: (_) => const SeccionPendiente(
            titulo: 'Lectores',
            descripcion:
                'Alta y edición de lectores, categoría y tutor si es menor, multas '
                'pendientes y cambio de categoría respetando las condiciones de los '
                'préstamos ya vigentes.',
            origen: 'bibliotecario.html #s-lectores',
          ),
        ),
        Destino(
          etiqueta: 'Alertas',
          icono: Icons.warning_amber_outlined,
          iconoActivo: Icons.warning_amber,
          constructor: (_) => const SeccionPendiente(
            titulo: 'Alertas operativas',
            descripcion:
                'Préstamos vencidos y próximos a vencer, reservas sin retirar dentro '
                'del plazo y lectores bloqueados por multa, con el motivo que registró '
                'el Agente Evaluador en cada caso.',
            origen: 'bibliotecario.html #s-alertas',
          ),
        ),
      ],
    );
  }
}
