import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/formato.dart';
import '../../core/tema.dart';
import '../../domain/enums.dart';
import '../../state/app_state.dart';
import '../widgets/comunes.dart';
import '../widgets/shell_adaptativo.dart';

/// Avisos generados por el Agente Planificador (spec v2 §4.3).
class SeccionNotificaciones extends StatelessWidget {
  const SeccionNotificaciones({super.key});

  @override
  Widget build(BuildContext context) {
    final estado = context.watch<AppState>();
    final notificaciones = estado.misNotificaciones;
    final ahora = estado.repo.ahora;

    if (notificaciones.isEmpty) {
      return const EstadoVacio(
        icono: Icons.notifications_none,
        titulo: 'No tenés avisos',
        detalle:
            'Acá van a llegar los recordatorios de vencimiento y reservas.',
      );
    }

    return Seccion(
      anchoMaximo: 760,
      children: [
        EncabezadoSeccion(
          'Avisos',
          subtitulo: '${estado.misNoLeidas} sin leer',
          accion: estado.misNoLeidas == 0
              ? null
              : TextButton.icon(
                  onPressed: () => context.read<AppState>().marcarTodasLeidas(),
                  icon: const Icon(Icons.done_all, size: 17),
                  label: const Text('Marcar todo'),
                ),
        ),
        for (final n in notificaciones)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Card(
              child: InkWell(
                borderRadius: BorderRadius.circular(Radios.md),
                onTap: n.leida
                    ? null
                    : () =>
                        context.read<AppState>().marcarNotificacionLeida(n.id),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          color: _color(n.tipo).withOpacity(0.14),
                          borderRadius: BorderRadius.circular(Radios.base),
                        ),
                        child: Icon(_icono(n.tipo),
                            size: 18, color: _color(n.tipo)),
                      ),
                      const SizedBox(width: 13),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    n.titulo,
                                    style: TextStyle(
                                      fontWeight: n.leida
                                          ? FontWeight.w500
                                          : FontWeight.w700,
                                      fontSize: 14,
                                      color: Paleta.textPrimary,
                                    ),
                                  ),
                                ),
                                if (!n.leida)
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: Paleta.teal,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 5),
                            Text(
                              n.descripcion,
                              style: const TextStyle(
                                  color: Paleta.textSecondary,
                                  fontSize: 13,
                                  height: 1.45),
                            ),
                            const SizedBox(height: 7),
                            Text(
                              Formato.relativa(n.fecha, ahora: ahora),
                              style: const TextStyle(
                                  color: Paleta.textMuted, fontSize: 11.5),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  static IconData _icono(TipoNotificacion t) => switch (t) {
        TipoNotificacion.vencimientoProximo => Icons.schedule,
        TipoNotificacion.prestamoVencido => Icons.error_outline,
        TipoNotificacion.reservaDisponible =>
          Icons.notifications_active_outlined,
        TipoNotificacion.reservaConfirmada => Icons.check_circle_outline,
        TipoNotificacion.reservaVencida => Icons.hourglass_disabled_outlined,
        TipoNotificacion.recomendacion => Icons.auto_awesome,
      };

  static Color _color(TipoNotificacion t) => switch (t) {
        TipoNotificacion.vencimientoProximo => Paleta.warning,
        TipoNotificacion.prestamoVencido => Paleta.danger,
        TipoNotificacion.reservaDisponible => Paleta.teal,
        TipoNotificacion.reservaConfirmada => Paleta.success,
        TipoNotificacion.reservaVencida => Paleta.textMuted,
        TipoNotificacion.recomendacion => Paleta.primary,
      };
}
