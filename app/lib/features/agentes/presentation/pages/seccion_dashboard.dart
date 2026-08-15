import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/presentation/widgets/comunes.dart';
import '../../../../core/theme/tema.dart';
import '../../../../core/utils/formato.dart';
import '../../../../core/utils/responsive.dart';
import '../../domain/entities/decision.dart';
import '../../../prestamos/presentation/bloc/prestamos_bloc.dart';
import '../bloc/agentes_bloc.dart';
/// Dashboard del bibliotecario, portado de `bibliotecario.html #s-dashboard`.
class SeccionDashboard extends StatelessWidget {
  const SeccionDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final agentes = context.watch<AgentesBloc>().state;
    final indicadores = agentes.indicadores;
    final stats = context.watch<PrestamosBloc>().state.estadisticas;
    if (stats == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Seccion(
      children: [
        EncabezadoSeccion(
          'Dashboard',
          subtitulo:
              'Estado de la biblioteca al ${Formato.fecha(DateTime.now())}',
        ),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: context.esCompacto ? 2 : 4,
          crossAxisSpacing: 13,
          mainAxisSpacing: 13,
          childAspectRatio: context.esCompacto ? 1.05 : 1.25,
          children: [
            TarjetaMetrica(
              titulo: 'Préstamos activos',
              valor: '${stats.activos}',
              icono: Icons.menu_book_outlined,
              color: Paleta.primary,
            ),
            TarjetaMetrica(
              titulo: 'Vencidos',
              valor: '${stats.vencidos}',
              icono: Icons.error_outline,
              color: Paleta.danger,
              detalle: agentes.prestamosVencidos > 0
                  ? 'Requieren aviso'
                  : 'Sin atrasos',
            ),
            TarjetaMetrica(
              titulo: 'Por vencer',
              valor: '${agentes.vencimientosProximos}',
              icono: Icons.schedule,
              color: Paleta.warning,
              detalle:
                  'Próximos ${agentes.configuracion.recordatorioAntesDias} días',
            ),
            TarjetaMetrica(
              titulo: 'Tasa de tardanza',
              valor: Formato.porcentaje(stats.tasaTardia),
              icono: Icons.trending_up,
              color: stats.tasaTardia > 20 ? Paleta.danger : Paleta.success,
              detalle: 'Sobre ${stats.total} préstamos',
            ),
          ],
        ),
        const SizedBox(height: 26),
        const _DecisionesAbiertas(),
        const SizedBox(height: 26),
        if (indicadores != null && indicadores.topLibros.isNotEmpty) ...[
          const Text('Títulos más prestados',
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: Paleta.textPrimary)),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  for (final t in indicadores.topLibros)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 7),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              t.libro.titulo,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: Paleta.textPrimary, fontSize: 13.5),
                            ),
                          ),
                          const SizedBox(width: 12),
                          SizedBox(
                            width: 110,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(Radios.sm),
                              child: LinearProgressIndicator(
                                value: t.prestamos /
                                    indicadores.topLibros.first.prestamos,
                                minHeight: 6,
                                backgroundColor: Paleta.bgHover,
                                valueColor: const AlwaysStoppedAnimation(
                                    Paleta.primary),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          SizedBox(
                            width: 26,
                            child: Text('${t.prestamos}',
                                textAlign: TextAlign.end,
                                style: const TextStyle(
                                    color: Paleta.textSecondary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Decisiones que el Agente Evaluador dejó abiertas.
///
/// El botón ejecuta el lote a través del Agente Planificador, respetando la
/// separación de la spec v2 §4.3.
class _DecisionesAbiertas extends StatelessWidget {
  const _DecisionesAbiertas();

  @override
  Widget build(BuildContext context) {
    final decisiones = context.watch<AgentesBloc>().state.decisiones;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text('Decisiones del Agente Evaluador',
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: Paleta.textPrimary)),
            ),
            if (decisiones.isNotEmpty)
              FilledButton.icon(
                onPressed: () => context
                    .read<AgentesBloc>()
                    .add(const CicloDeAgentesSolicitado()),
                icon: const Icon(Icons.play_arrow, size: 18),
                label: const Text('Ejecutar ciclo'),
              ),
          ],
        ),
        const SizedBox(height: 6),
        const Text(
          'El Evaluador decide qué corresponde hacer; el Planificador lo ejecuta.',
          style: TextStyle(color: Paleta.textMuted, fontSize: 12.5),
        ),
        const SizedBox(height: 12),
        if (decisiones.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Row(
                children: [
                  Icon(Icons.check_circle_outline,
                      color: Paleta.success, size: 19),
                  SizedBox(width: 11),
                  Expanded(
                    child: Text('No hay acciones pendientes',
                        style: TextStyle(color: Paleta.textSecondary)),
                  ),
                ],
              ),
            ),
          )
        else
          Card(
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Column(
                children: [
                  for (final d in decisiones.take(8))
                    ListTile(
                      dense: true,
                      leading:
                          Icon(_icono(d.tipo), size: 19, color: _color(d.tipo)),
                      title: Text(d.motivo,
                          style: const TextStyle(fontSize: 13, height: 1.4)),
                    ),
                  if (decisiones.length > 8)
                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: Text('y ${decisiones.length - 8} más…',
                          style: const TextStyle(
                              color: Paleta.textMuted, fontSize: 12.5)),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }

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
