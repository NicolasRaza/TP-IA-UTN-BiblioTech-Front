import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/presentation/widgets/comunes.dart';
import '../../../../core/theme/tema.dart';
import '../../../../core/utils/formato.dart';
import '../../domain/entities/evento_auditoria.dart';
import '../../../agentes/presentation/bloc/agentes_bloc.dart';
import '../cubit/administracion_cubit.dart';
import '../../../agentes/domain/services/agente_evaluador.dart';
/// Registro de auditoría, portado de `admin.html #s-auditoria`.
class SeccionAuditoria extends StatefulWidget {
  const SeccionAuditoria({super.key});

  @override
  State<SeccionAuditoria> createState() => _SeccionAuditoriaState();
}

class _SeccionAuditoriaState extends State<SeccionAuditoria> {
  TipoEventoAuditoria? _filtro;

  @override
  Widget build(BuildContext context) {
    final estado = context.watch<AdministracionCubit>().state;
    final eventos = estado.auditoria
        .where((e) => _filtro == null || e.tipo == _filtro)
        .toList();

    return Seccion(
      anchoMaximo: 900,
      children: [
        EncabezadoSeccion(
          'Auditoría',
          subtitulo: '${eventos.length} eventos registrados',
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              FilterChip(
                label: const Text('Todos'),
                selected: _filtro == null,
                onSelected: (_) => setState(() => _filtro = null),
                selectedColor: Paleta.pink.withOpacity(0.25),
              ),
              const SizedBox(width: 8),
              for (final t in TipoEventoAuditoria.values) ...[
                FilterChip(
                  label: Text(_etiqueta(t)),
                  selected: _filtro == t,
                  onSelected: (_) => setState(() => _filtro = t),
                  selectedColor: Paleta.pink.withOpacity(0.25),
                ),
                const SizedBox(width: 8),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (eventos.isEmpty)
          const EstadoVacio(
            icono: Icons.receipt_long_outlined,
            titulo: 'Sin eventos de este tipo',
          )
        else
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                children: [
                  for (final e in eventos.take(100))
                    ListTile(
                      dense: true,
                      leading:
                          Icon(_icono(e.tipo), size: 18, color: _color(e.tipo)),
                      title: Text(e.descripcion,
                          style: const TextStyle(fontSize: 13, height: 1.4)),
                      subtitle: Text(
                        '${Formato.fechaHora(e.fecha)} · ${estado.nombreDeUsuario(e.usuarioId)}',
                        style: const TextStyle(fontSize: 11.5),
                      ),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  static String _etiqueta(TipoEventoAuditoria t) => switch (t) {
        TipoEventoAuditoria.altaLibro => 'Altas de libro',
        TipoEventoAuditoria.bajaLibro => 'Bajas de libro',
        TipoEventoAuditoria.edicionLibro => 'Ediciones',
        TipoEventoAuditoria.altaLector => 'Altas de lector',
        TipoEventoAuditoria.edicionLector => 'Ediciones de lector',
        TipoEventoAuditoria.prestamo => 'Préstamos',
        TipoEventoAuditoria.devolucion => 'Devoluciones',
        TipoEventoAuditoria.reimpresionQr => 'Reimpresiones QR',
        TipoEventoAuditoria.correccionOcr => 'Correcciones',
        TipoEventoAuditoria.cambioCategoria => 'Cambios de categoría',
        TipoEventoAuditoria.cambioConfig => 'Parámetros',
      };

  static IconData _icono(TipoEventoAuditoria t) => switch (t) {
        TipoEventoAuditoria.altaLibro => Icons.library_add_outlined,
        TipoEventoAuditoria.bajaLibro => Icons.delete_outline,
        TipoEventoAuditoria.edicionLibro => Icons.edit_outlined,
        TipoEventoAuditoria.altaLector => Icons.person_add_outlined,
        TipoEventoAuditoria.edicionLector => Icons.manage_accounts_outlined,
        TipoEventoAuditoria.prestamo => Icons.output_outlined,
        TipoEventoAuditoria.devolucion => Icons.input_outlined,
        TipoEventoAuditoria.reimpresionQr => Icons.print_outlined,
        TipoEventoAuditoria.correccionOcr => Icons.spellcheck,
        TipoEventoAuditoria.cambioCategoria => Icons.badge_outlined,
        TipoEventoAuditoria.cambioConfig => Icons.tune,
      };

  static Color _color(TipoEventoAuditoria t) => switch (t) {
        TipoEventoAuditoria.bajaLibro => Paleta.danger,
        TipoEventoAuditoria.prestamo => Paleta.primary,
        TipoEventoAuditoria.devolucion => Paleta.success,
        TipoEventoAuditoria.reimpresionQr => Paleta.info,
        TipoEventoAuditoria.cambioCategoria => Paleta.gold,
        _ => Paleta.textMuted,
      };
}

/// Aprendizaje del sistema, portado de `admin.html #s-aprendizaje`.
class SeccionAprendizaje extends StatelessWidget {
  const SeccionAprendizaje({super.key});

  @override
  Widget build(BuildContext context) {
    final reporte = context.watch<AdministracionCubit>().state.reporteAprendizaje;
    if (reporte == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final reco = reporte;

    return Seccion(
      anchoMaximo: 820,
      children: [
        const EncabezadoSeccion(
          'Aprendizaje',
          subtitulo:
              'Qué está aprendiendo el sistema de las correcciones humanas',
        ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.psychology_outlined,
                    size: 20, color: Paleta.primary),
                const SizedBox(width: 13),
                Expanded(
                  child: Text(reporte.resumen,
                      style: const TextStyle(
                          color: Paleta.textSecondary,
                          fontSize: 13,
                          height: 1.5)),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (reporte.patrones.isEmpty)
          const EstadoVacio(
            icono: Icons.spellcheck,
            titulo: 'Todavía no hay correcciones registradas',
            detalle:
                'Cuando el bibliotecario corrija fichas sugeridas, acá se van a ver '
                'los campos que más falla el reconocimiento.',
          )
        else ...[
          const Text('Campos que más se corrigen',
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: Paleta.textPrimary)),
          const SizedBox(height: 12),
          for (final p in reporte.patrones)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(p.campo,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: Paleta.textPrimary)),
                          ),
                          Insignia('${p.correcciones}', color: Paleta.warning),
                        ],
                      ),
                      const SizedBox(height: 7),
                      Text(p.sugerencia,
                          style: const TextStyle(
                              color: Paleta.textMuted,
                              fontSize: 12.5,
                              height: 1.45)),
                    ],
                  ),
                ),
              ),
            ),
        ],
        if (reco.masEfectivas.isNotEmpty) ...[
          const SizedBox(height: 18),
          const Text('Recomendaciones que terminaron en reserva',
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: Paleta.textPrimary)),
          const SizedBox(height: 10),
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                children: [
                  for (final r in reco.masEfectivas)
                    ListTile(
                      dense: true,
                      title:
                          Text(r.titulo, style: const TextStyle(fontSize: 13)),
                      trailing: Text('${r.conversiones}',
                          style: const TextStyle(
                              color: Paleta.teal, fontWeight: FontWeight.w700)),
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

/// Sugerencias estratégicas, portadas de `admin.html #s-sugerencias`.
class SeccionSugerencias extends StatelessWidget {
  const SeccionSugerencias({super.key});

  @override
  Widget build(BuildContext context) {
    final sugerencias = context.watch<AdministracionCubit>().state.sugerencias;

    if (sugerencias.isEmpty) {
      return const EstadoVacio(
        icono: Icons.lightbulb_outline,
        titulo: 'Sin sugerencias por ahora',
        detalle: 'El sistema no detectó situaciones que ameriten una decisión.',
      );
    }

    return Seccion(
      anchoMaximo: 820,
      children: [
        EncabezadoSeccion(
          'Sugerencias',
          subtitulo:
              '${sugerencias.length} ${sugerencias.length == 1 ? 'recomendación' : 'recomendaciones'} para el fondo bibliográfico',
        ),
        for (final s in sugerencias)
          Padding(
            padding: const EdgeInsets.only(bottom: 11),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: _color(s.tipo).withOpacity(0.14),
                        borderRadius: BorderRadius.circular(Radios.base),
                      ),
                      child:
                          Icon(_icono(s.tipo), size: 18, color: _color(s.tipo)),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_titulo(s.tipo),
                              style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13.5,
                                  color: _color(s.tipo))),
                          const SizedBox(height: 5),
                          Text(s.texto,
                              style: const TextStyle(
                                  color: Paleta.textSecondary,
                                  fontSize: 13,
                                  height: 1.5)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  static String _titulo(TipoSugerencia tipo) => switch (tipo) {
        TipoSugerencia.compra => 'Reforzar stock',
        TipoSugerencia.promocion => 'Promoción',
        TipoSugerencia.politica => 'Política de préstamos',
      };

  static IconData _icono(TipoSugerencia tipo) => switch (tipo) {
        TipoSugerencia.compra => Icons.add_shopping_cart,
        TipoSugerencia.promocion => Icons.campaign_outlined,
        TipoSugerencia.politica => Icons.policy_outlined,
      };

  static Color _color(TipoSugerencia tipo) => switch (tipo) {
        TipoSugerencia.compra => Paleta.teal,
        TipoSugerencia.promocion => Paleta.gold,
        TipoSugerencia.politica => Paleta.pink,
      };
}

/// Acerca del sistema, portado de `admin.html #s-acerca`.
class SeccionAcerca extends StatelessWidget {
  const SeccionAcerca({super.key});

  @override
  Widget build(BuildContext context) {
    final bitacora = context.watch<AgentesBloc>().state.bitacora;

    return Seccion(
      anchoMaximo: 760,
      children: [
        const EncabezadoSeccion('Acerca de BiblioTech'),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(11),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                            colors: [Paleta.primary, Paleta.teal]),
                        borderRadius: BorderRadius.circular(Radios.md),
                      ),
                      child: const Icon(Icons.auto_stories_outlined,
                          size: 24, color: Colors.white),
                    ),
                    const SizedBox(width: 15),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('BiblioTech',
                            style: Theme.of(context).textTheme.titleLarge),
                        const Text('Sistema de Gestión de Bibliotecas',
                            style: TextStyle(
                                color: Paleta.textMuted, fontSize: 12.5)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Text(
                  'Trabajo práctico del curso IA para Desarrolladores, UTN.\n'
                  'Equipo: Tomás Bacchetta, Julio Flores, Matías Ledesma y Alex Raza.',
                  style: TextStyle(
                      color: Paleta.textSecondary, fontSize: 13, height: 1.6),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Red de agentes',
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: Paleta.textPrimary)),
                const SizedBox(height: 12),
                for (final a in _agentes)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 7),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(a.$1, size: 17, color: Paleta.primary),
                        const SizedBox(width: 11),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(a.$2,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13.5,
                                      color: Paleta.textPrimary)),
                              const SizedBox(height: 2),
                              Text(a.$3,
                                  style: const TextStyle(
                                      color: Paleta.textMuted,
                                      fontSize: 12.5,
                                      height: 1.45)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (bitacora.isNotEmpty) ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Bitácora de esta sesión',
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: Paleta.textPrimary)),
                  const SizedBox(height: 10),
                  for (final linea in bitacora.reversed.take(15))
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Text(linea,
                          style: const TextStyle(
                              color: Paleta.textMuted,
                              fontSize: 11.5,
                              fontFamily: 'monospace',
                              height: 1.4)),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
        OutlinedButton.icon(
          onPressed: () => _confirmarReinicio(context),
          icon: const Icon(Icons.restart_alt, size: 18),
          label: const Text('Reiniciar datos de demostración'),
        ),
      ],
    );
  }

  static const _agentes = <(IconData, String, String)>[
    (
      Icons.document_scanner_outlined,
      'Agente de Captura',
      'Digitaliza las fotos del ejemplar y lee los códigos QR.'
    ),
    (
      Icons.auto_fix_high,
      'Agente Analizador',
      'Estructura el texto en campos editoriales y resuelve las discrepancias entre fuentes externas.'
    ),
    (
      Icons.event_note_outlined,
      'Agente Planificador',
      'Ejecuta las decisiones: envía avisos, libera reservas y actualiza estados.'
    ),
    (
      Icons.analytics_outlined,
      'Agente Evaluador',
      'Monitorea el sistema y decide qué corresponde hacer. También arma las recomendaciones.'
    ),
    (
      Icons.psychology_outlined,
      'Agente de Aprendizaje',
      'Analiza las correcciones humanas para afinar el criterio del próximo ciclo.'
    ),
  ];

  static Future<void> _confirmarReinicio(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reiniciar datos'),
        content: const Text(
            'Se borran los libros, lectores, préstamos y reservas cargados, y se '
            'vuelve a los datos de demostración. La sesión se cierra.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Reiniciar')),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    context.read<AdministracionCubit>().reiniciarDatos();
  }
}
