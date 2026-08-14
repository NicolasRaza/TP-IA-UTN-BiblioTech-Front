import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/formato.dart';
import '../../core/tema.dart';
import '../../state/app_state.dart';
import '../widgets/comunes.dart';
import '../widgets/shell_adaptativo.dart';

/// Perfil del lector: datos, límites vigentes, multas, intereses y su QR.
class SeccionPerfil extends StatelessWidget {
  const SeccionPerfil({super.key});

  @override
  Widget build(BuildContext context) {
    final estado = context.watch<AppState>();
    final lector = estado.usuario;
    if (lector == null) return const SizedBox.shrink();

    final cfg = estado.repo.config;
    final activos = estado.misPrestamos.length;
    final reservasActivas = estado.misReservas.where((r) => r.esActiva).length;

    return Seccion(
      anchoMaximo: 760,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              children: [
                AvatarLector(lector, radio: 36),
                const SizedBox(height: 14),
                Text(lector.nombreCompleto,
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 4),
                Text(lector.email,
                    style:
                        const TextStyle(color: Paleta.textMuted, fontSize: 13)),
                const SizedBox(height: 14),
                Insignia.categoria(lector.categoria),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        if (lector.multasPendientes > 0) ...[
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Paleta.danger.withOpacity(0.1),
              borderRadius: BorderRadius.circular(Radios.base),
              border: Border.all(color: Paleta.danger.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded,
                    color: Paleta.danger, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Multa pendiente de ${Formato.pesos(lector.multasPendientes)}',
                        style: const TextStyle(
                            color: Paleta.danger, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 3),
                      const Text(
                        'Mientras tengas multas impagas no podés pedir ni reservar libros. '
                        'Saldala en el mostrador.',
                        style: TextStyle(
                            color: Paleta.textSecondary,
                            fontSize: 12.5,
                            height: 1.4),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Tus límites',
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Paleta.textPrimary,
                        fontSize: 15)),
                const SizedBox(height: 4),
                Text(
                  'Definidos por tu categoría (${lector.categoria.label})',
                  style:
                      const TextStyle(color: Paleta.textMuted, fontSize: 12.5),
                ),
                const SizedBox(height: 16),
                _Limite(
                  etiqueta: 'Préstamos simultáneos',
                  usado: activos,
                  total: cfg.limiteEjemplaresPara(lector.categoria),
                  color: Paleta.primary,
                ),
                const SizedBox(height: 12),
                _Limite(
                  etiqueta: 'Reservas simultáneas',
                  usado: reservasActivas,
                  total: cfg.limiteReservasPara(lector.categoria),
                  color: Paleta.teal,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.schedule,
                        size: 15, color: Paleta.textMuted),
                    const SizedBox(width: 8),
                    Text(
                      'Plazo de préstamo: ${cfg.plazoPara(lector.categoria)} días',
                      style: const TextStyle(
                          color: Paleta.textSecondary, fontSize: 12.5),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        if (lector.generosInteres.isNotEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Géneros de interés',
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Paleta.textPrimary,
                          fontSize: 15)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final g in lector.generosInteres)
                        Insignia(g, color: Paleta.primary),
                    ],
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 14),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              children: [
                const Text('Tu credencial',
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Paleta.textPrimary,
                        fontSize: 15)),
                const SizedBox(height: 4),
                const Text(
                  'Mostralo en el mostrador para identificarte',
                  style: TextStyle(color: Paleta.textMuted, fontSize: 12.5),
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(Radios.base),
                  ),
                  child: QrImageView(
                    data: lector.qr,
                    size: 168,
                    backgroundColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  lector.qr,
                  style: const TextStyle(
                      color: Paleta.textMuted,
                      fontSize: 12,
                      fontFamily: 'monospace'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        OutlinedButton.icon(
          onPressed: () => context.read<AppState>().cerrarSesion(),
          icon: const Icon(Icons.logout, size: 18),
          label: const Text('Cerrar sesión'),
        ),
      ],
    );
  }
}

class _Limite extends StatelessWidget {
  const _Limite({
    required this.etiqueta,
    required this.usado,
    required this.total,
    required this.color,
  });

  final String etiqueta;
  final int usado;
  final int total;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final proporcion = total == 0 ? 0.0 : (usado / total).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(etiqueta,
                  style: const TextStyle(
                      color: Paleta.textSecondary, fontSize: 13)),
            ),
            Text('$usado de $total',
                style: TextStyle(
                    color: color, fontWeight: FontWeight.w700, fontSize: 13)),
          ],
        ),
        const SizedBox(height: 7),
        ClipRRect(
          borderRadius: BorderRadius.circular(Radios.sm),
          child: LinearProgressIndicator(
            value: proporcion,
            minHeight: 7,
            backgroundColor: Paleta.bgHover,
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ],
    );
  }
}
