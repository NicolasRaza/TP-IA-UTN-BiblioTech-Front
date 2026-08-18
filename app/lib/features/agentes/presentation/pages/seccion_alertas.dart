import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/presentation/widgets/comunes.dart';
import '../../../../core/theme/tema.dart';
import '../../domain/entities/decision.dart';
import '../bloc/agentes_bloc.dart';

/// Alertas operativas, portadas de `bibliotecario.html #s-alertas`.
///
/// Cada alerta es una decisión del Agente Evaluador, con el motivo por el que
/// la tomó (spec v2 §4.3).
class SeccionAlertas extends StatelessWidget {
  const SeccionAlertas({super.key});

  @override
  Widget build(BuildContext context) {
    final decisiones = context.watch<AgentesBloc>().state.decisiones;

    if (decisiones.isEmpty) {
      return const EstadoVacio(
        icono: Icons.check_circle_outline,
        titulo: 'Todo en orden',
        detalle: 'No hay vencimientos, reservas caídas ni multas pendientes.',
      );
    }

    final grupos = <TipoDecision, List<Decision>>{};
    for (final d in decisiones) {
      grupos.putIfAbsent(d.tipo, () => []).add(d);
    }

    return Seccion(
      anchoMaximo: 880,
      children: [
        EncabezadoSeccion(
          'Alertas operativas',
          subtitulo:
              '${decisiones.length} ${decisiones.length == 1 ? 'situación detectada' : 'situaciones detectadas'} por el Agente Evaluador',
          accion: FilledButton.icon(
            onPressed: () => context
                .read<AgentesBloc>()
                .add(const CicloDeAgentesSolicitado()),
            icon: const Icon(Icons.play_arrow, size: 18),
            label: const Text('Ejecutar'),
          ),
        ),
        for (final entrada in grupos.entries) ...[
          Row(
            children: [
              Icon(_icono(entrada.key), size: 17, color: _color(entrada.key)),
              const SizedBox(width: 9),
              Text(
                _titulo(entrada.key),
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14.5,
                    color: _color(entrada.key)),
              ),
              const SizedBox(width: 8),
              Text('(${entrada.value.length})',
                  style:
                      const TextStyle(color: Paleta.textMuted, fontSize: 12.5)),
            ],
          ),
          const SizedBox(height: 9),
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                children: [
                  for (final d in entrada.value)
                    ListTile(
                      dense: true,
                      title: Text(d.motivo,
                          style: const TextStyle(fontSize: 13, height: 1.4)),
                      subtitle: d.lector == null
                          ? null
                          : Text(d.lector!.nombreCompleto,
                              style: const TextStyle(fontSize: 11.5)),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
        ],
      ],
    );
  }

  static String _titulo(TipoDecision t) => switch (t) {
        TipoDecision.notificarPrestamoVencido => 'Préstamos vencidos',
        TipoDecision.notificarVencimientoProximo => 'Próximos a vencer',
        TipoDecision.liberarReservaNoRetirada => 'Reservas sin retirar',
        TipoDecision.asignarReservaAlSiguiente => 'Reservas por asignar',
        TipoDecision.alertarMultaPendiente => 'Multas impagas',
        TipoDecision.sugerirRevisionCategoria => 'Categorías a revisar',
      };

  static IconData _icono(TipoDecision t) => switch (t) {
        TipoDecision.notificarPrestamoVencido => Icons.error_outline,
        TipoDecision.notificarVencimientoProximo => Icons.schedule,
        TipoDecision.liberarReservaNoRetirada =>
          Icons.hourglass_disabled_outlined,
        TipoDecision.asignarReservaAlSiguiente => Icons.forward_outlined,
        TipoDecision.alertarMultaPendiente => Icons.attach_money,
        TipoDecision.sugerirRevisionCategoria => Icons.badge_outlined,
      };

  static Color _color(TipoDecision t) => switch (t) {
        TipoDecision.notificarPrestamoVencido => Paleta.danger,
        TipoDecision.notificarVencimientoProximo => Paleta.warning,
        TipoDecision.liberarReservaNoRetirada => Paleta.pink,
        TipoDecision.asignarReservaAlSiguiente => Paleta.teal,
        TipoDecision.alertarMultaPendiente => Paleta.gold,
        TipoDecision.sugerirRevisionCategoria => Paleta.info,
      };
}
