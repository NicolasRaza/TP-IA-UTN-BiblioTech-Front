import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/formato.dart';
import '../../core/responsive.dart';
import '../../core/tema.dart';
import '../../state/app_state.dart';
import '../widgets/comunes.dart';
import '../widgets/shell_adaptativo.dart';

/// Reportes e indicadores, portados de `admin.html #s-reportes`.
class SeccionReportes extends StatelessWidget {
  const SeccionReportes({super.key});

  @override
  Widget build(BuildContext context) {
    final estado = context.watch<AppState>();
    final ind = estado.evaluador.calcularIndicadores();
    final stats = estado.repo.estadisticasPrestamos();

    return Seccion(
      children: [
        const EncabezadoSeccion(
          'Reportes',
          subtitulo: 'Indicadores de uso de la biblioteca',
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
              titulo: 'Préstamos totales',
              valor: '${stats.total}',
              icono: Icons.swap_horiz,
              color: Paleta.primary,
            ),
            TarjetaMetrica(
              titulo: 'Devueltos',
              valor: '${stats.devueltos}',
              icono: Icons.assignment_turned_in_outlined,
              color: Paleta.success,
            ),
            TarjetaMetrica(
              titulo: 'Socios activos',
              valor: '${ind.topLectores.length}',
              icono: Icons.people_outline,
              color: Paleta.teal,
              detalle: 'Con al menos un préstamo',
            ),
            TarjetaMetrica(
              titulo: 'Devoluciones tardías',
              valor: Formato.porcentaje(stats.tasaTardia),
              icono: Icons.timelapse,
              color: stats.tasaTardia > 20 ? Paleta.danger : Paleta.warning,
            ),
          ],
        ),
        const SizedBox(height: 24),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Préstamos por mes',
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: Paleta.textPrimary)),
                const SizedBox(height: 4),
                const Row(
                  children: [
                    _Leyenda(color: Paleta.primary, texto: 'Total'),
                    SizedBox(width: 14),
                    _Leyenda(color: Paleta.danger, texto: 'Tardíos'),
                  ],
                ),
                const SizedBox(height: 18),
                SizedBox(
                  height: 190,
                  child: _GraficoMensual(datos: ind.porMes),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        if (ind.topGeneros.isNotEmpty)
          _ListaRanking(
            titulo: 'Géneros más leídos',
            filas: [
              for (final g in ind.topGeneros)
                (etiqueta: g.genero, valor: g.prestamos),
            ],
            color: Paleta.teal,
          ),
        const SizedBox(height: 18),
        if (ind.topLibros.isNotEmpty)
          _ListaRanking(
            titulo: 'Títulos más prestados',
            filas: [
              for (final t in ind.topLibros)
                (etiqueta: t.libro.titulo, valor: t.prestamos),
            ],
            color: Paleta.primary,
          ),
        const SizedBox(height: 18),
        if (ind.topLectores.isNotEmpty)
          _ListaRanking(
            titulo: 'Lectores más activos',
            filas: [
              for (final l in ind.topLectores)
                (etiqueta: l.lector.nombreCompleto, valor: l.prestamos),
            ],
            color: Paleta.gold,
          ),
      ],
    );
  }
}

class _GraficoMensual extends StatelessWidget {
  const _GraficoMensual({required this.datos});

  final List<({String mes, int total, int tardios})> datos;

  @override
  Widget build(BuildContext context) {
    final maximo = datos.fold<int>(1, (m, d) => d.total > m ? d.total : m);

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maximo.toDouble() + 1,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) =>
              const FlLine(color: Paleta.border, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(),
          rightTitles: const AxisTitles(),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: 1,
              getTitlesWidget: (v, _) => Text(
                v.toInt().toString(),
                style: const TextStyle(color: Paleta.textMuted, fontSize: 10),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 26,
              getTitlesWidget: (v, _) {
                final i = v.toInt();
                if (i < 0 || i >= datos.length) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    datos[i].mes,
                    style: const TextStyle(
                        color: Paleta.textMuted, fontSize: 10.5),
                  ),
                );
              },
            ),
          ),
        ),
        barGroups: [
          for (var i = 0; i < datos.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: datos[i].total.toDouble(),
                  color: Paleta.primary,
                  width: 15,
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(Radios.sm)),
                  rodStackItems: [
                    BarChartRodStackItem(
                        0, datos[i].tardios.toDouble(), Paleta.danger),
                  ],
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _Leyenda extends StatelessWidget {
  const _Leyenda({required this.color, required this.texto});

  final Color color;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(texto,
            style: const TextStyle(color: Paleta.textMuted, fontSize: 11.5)),
      ],
    );
  }
}

class _ListaRanking extends StatelessWidget {
  const _ListaRanking({
    required this.titulo,
    required this.filas,
    required this.color,
  });

  final String titulo;
  final List<({String etiqueta, int valor})> filas;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final maximo = filas.fold<int>(1, (m, f) => f.valor > m ? f.valor : m);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(titulo,
                style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: Paleta.textPrimary)),
            const SizedBox(height: 14),
            for (final f in filas)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(f.etiqueta,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: Paleta.textSecondary, fontSize: 13)),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 110,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(Radios.sm),
                        child: LinearProgressIndicator(
                          value: f.valor / maximo,
                          minHeight: 6,
                          backgroundColor: Paleta.bgHover,
                          valueColor: AlwaysStoppedAnimation(color),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 24,
                      child: Text('${f.valor}',
                          textAlign: TextAlign.end,
                          style: TextStyle(
                              color: color,
                              fontSize: 13,
                              fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
