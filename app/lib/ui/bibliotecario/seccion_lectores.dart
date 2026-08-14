import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/formato.dart';
import '../../core/tema.dart';
import '../../domain/enums.dart';
import '../../domain/models.dart';
import '../../state/app_state.dart';
import '../widgets/comunes.dart';
import '../widgets/shell_adaptativo.dart';

/// Gestión de lectores, portada de `bibliotecario.html #s-lectores`.
class SeccionLectores extends StatefulWidget {
  const SeccionLectores({super.key});

  @override
  State<SeccionLectores> createState() => _SeccionLectoresState();
}

class _SeccionLectoresState extends State<SeccionLectores> {
  final _busqueda = TextEditingController();

  @override
  void dispose() {
    _busqueda.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final estado = context.watch<AppState>();
    final q = _busqueda.text.trim().toLowerCase();
    final lectores = estado.repo.lectores
        .where((l) =>
            q.isEmpty ||
            l.nombreCompleto.toLowerCase().contains(q) ||
            l.dni.contains(q) ||
            l.email.toLowerCase().contains(q))
        .toList()
      ..sort((a, b) => a.apellido.compareTo(b.apellido));

    final desactualizados = estado.repo.lectoresConCategoriaDesactualizada();

    return Seccion(
      children: [
        EncabezadoSeccion(
          'Lectores',
          subtitulo: '${estado.repo.lectores.length} socios registrados',
        ),
        if (desactualizados.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Paleta.info.withOpacity(0.09),
              borderRadius: BorderRadius.circular(Radios.base),
              border: Border.all(color: Paleta.info.withOpacity(0.28)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.badge_outlined, size: 17, color: Paleta.info),
                const SizedBox(width: 11),
                Expanded(
                  child: Text(
                    '${desactualizados.length} ${desactualizados.length == 1 ? 'lector tiene' : 'lectores tienen'} '
                    'la categoría desactualizada respecto de su edad. Al cambiarla, '
                    'los préstamos y reservas vigentes conservan sus condiciones.',
                    style: const TextStyle(
                        color: Paleta.textSecondary,
                        fontSize: 12.5,
                        height: 1.45),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],
        TextField(
          controller: _busqueda,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            hintText: 'Buscar por nombre, DNI o email…',
            prefixIcon: Icon(Icons.search, size: 20),
          ),
        ),
        const SizedBox(height: 16),
        for (final l in lectores)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _FilaLector(lector: l),
          ),
      ],
    );
  }
}

class _FilaLector extends StatelessWidget {
  const _FilaLector({required this.lector});

  final Lector lector;

  @override
  Widget build(BuildContext context) {
    final estado = context.watch<AppState>();
    final prestamos = estado.repo.prestamosDeLector(lector.id);
    final activos = prestamos.where((p) => p.estaAbierto).length;
    final cfg = estado.repo.config;

    return Card(
      child: ExpansionTile(
        shape: const Border(),
        collapsedShape: const Border(),
        tilePadding: const EdgeInsets.symmetric(horizontal: 16),
        leading: AvatarLector(lector, radio: 19),
        title: Text(lector.nombreCompleto,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        subtitle: Text('DNI ${lector.dni} · $activos préstamos abiertos',
            style: const TextStyle(fontSize: 12)),
        trailing: lector.multasPendientes > 0
            ? Insignia(Formato.pesos(lector.multasPendientes),
                color: Paleta.danger)
            : Insignia.categoria(lector.categoria),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _dato('Email', lector.email),
                _dato('Teléfono', lector.telefono),
                if (lector.tutor != null) _dato('Tutor', lector.tutor!),
                _dato('Socio desde', Formato.fecha(lector.fechaAlta)),
                _dato('Categoría vigente', lector.categoria.label),
                _dato(
                    'Límites',
                    '${cfg.limiteEjemplaresPara(lector.categoria)} préstamos · '
                        '${cfg.limiteReservasPara(lector.categoria)} reservas · '
                        '${cfg.plazoPara(lector.categoria)} días'),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => _cambiarCategoria(context, lector),
                      icon: const Icon(Icons.swap_horiz, size: 17),
                      label: const Text('Cambiar categoría'),
                    ),
                    if (lector.multasPendientes > 0)
                      FilledButton.icon(
                        onPressed: () {
                          context.read<AppState>().actualizarLector(lector.id,
                              (l) => l.copyWith(multasPendientes: 0));
                          avisar(context,
                              'Multa saldada para ${lector.nombreCompleto}');
                        },
                        icon: const Icon(Icons.payments_outlined, size: 17),
                        label: Text(
                            'Registrar pago de ${Formato.pesos(lector.multasPendientes)}'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget _dato(String etiqueta, String valor) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 140,
              child: Text(etiqueta,
                  style:
                      const TextStyle(color: Paleta.textMuted, fontSize: 12.5)),
            ),
            Expanded(
              child: Text(valor,
                  style: const TextStyle(
                      color: Paleta.textPrimary, fontSize: 12.5)),
            ),
          ],
        ),
      );

  static Future<void> _cambiarCategoria(
      BuildContext context, Lector lector) async {
    final nueva = await showDialog<CategoriaLector>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Cambiar categoría'),
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(24, 0, 24, 12),
            child: Text(
              'Los préstamos y reservas vigentes conservan el plazo y los límites '
              'con los que se generaron. La nueva categoría rige solo para lo que '
              'venga después.',
              style: TextStyle(
                  color: Paleta.textMuted, fontSize: 12.5, height: 1.45),
            ),
          ),
          for (final c in CategoriaLector.values)
            if (c != CategoriaLector.personal)
              SimpleDialogOption(
                onPressed: () => Navigator.of(ctx).pop(c),
                child: Row(
                  children: [
                    Insignia.categoria(c),
                    const SizedBox(width: 10),
                    if (c == lector.categoria)
                      const Text('(actual)',
                          style:
                              TextStyle(color: Paleta.textMuted, fontSize: 12)),
                  ],
                ),
              ),
        ],
      ),
    );
    if (nueva == null || nueva == lector.categoria || !context.mounted) return;
    context.read<AppState>().cambiarCategoria(lector.id, nueva);
    if (context.mounted) {
      avisar(context,
          'Categoría actualizada a ${nueva.label}. Los préstamos vigentes no cambian.');
    }
  }
}
