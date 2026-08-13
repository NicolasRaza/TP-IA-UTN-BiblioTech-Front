import 'package:flutter/material.dart';

import '../../core/tema.dart';
import 'shell_adaptativo.dart';

/// Marcador de una sección cuyo contenido todavía no se migró.
///
/// El esqueleto de navegación de los tres roles ya está armado y refleja las
/// secciones del prototipo HTML; falta portar el cuerpo de cada una. Ver
/// `docs/estado-migracion-flutter.md` para el detalle de lo pendiente.
class SeccionPendiente extends StatelessWidget {
  const SeccionPendiente({
    super.key,
    required this.titulo,
    required this.descripcion,
    required this.origen,
  });

  /// Nombre de la sección.
  final String titulo;

  /// Qué va a hacer esta pantalla cuando esté portada.
  final String descripcion;

  /// Archivo del prototipo del que se porta (ej. `lector.html #s-catalogo`).
  final String origen;

  @override
  Widget build(BuildContext context) {
    return Seccion(
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Paleta.warning.withOpacity(0.14),
                        borderRadius: BorderRadius.circular(Radios.base),
                      ),
                      child: const Icon(Icons.construction_outlined,
                          color: Paleta.warning, size: 20),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(titulo,
                          style: Theme.of(context).textTheme.titleLarge),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  descripcion,
                  style: const TextStyle(
                      color: Paleta.textSecondary, height: 1.5, fontSize: 14),
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Paleta.bgInput,
                    borderRadius: BorderRadius.circular(Radios.base),
                    border: Border.all(color: Paleta.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.code, size: 15, color: Paleta.textMuted),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Text(
                          'Se porta desde $origen',
                          style: const TextStyle(
                              color: Paleta.textMuted,
                              fontSize: 12.5,
                              fontFamily: 'monospace'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'La lógica de negocio y los agentes que alimentan esta pantalla '
                  'ya están migrados y cubiertos por tests.',
                  style: TextStyle(color: Paleta.textMuted, fontSize: 12.5),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
