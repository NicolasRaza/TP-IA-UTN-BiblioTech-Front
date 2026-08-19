import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../core/presentation/widgets/comunes.dart';
import '../../../../core/theme/tema.dart';
import '../../domain/entities/ejemplar.dart';
import '../../domain/entities/libro.dart';
import '../bloc/catalogo_bloc.dart';

/// Catálogo e inventario del bibliotecario (spec v2 §9).
class SeccionInventario extends StatefulWidget {
  const SeccionInventario({super.key});

  @override
  State<SeccionInventario> createState() => _SeccionInventarioState();
}

class _SeccionInventarioState extends State<SeccionInventario> {
  final _busqueda = TextEditingController();

  @override
  void dispose() {
    _busqueda.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final estado = context.watch<CatalogoBloc>().state;
    final q = _busqueda.text.trim();
    // El inventario del bibliotecario incluye lo no validado, así que filtra
    // sobre todosLosLibros y no sobre el catálogo público del bloc.
    final libros = estado.todosLosLibros.where((l) => l.coincideCon(q)).toList()
      ..sort((a, b) => a.titulo.compareTo(b.titulo));

    final pendientes = estado.pendientesValidacion;

    return Seccion(
      children: [
        EncabezadoSeccion(
          'Catálogo e inventario',
          subtitulo: '${estado.todosLosLibros.length} títulos · '
              '${estado.todosLosLibros.fold<int>(0, (s, l) => s + l.totalEjemplares)} ejemplares',
        ),
        if (pendientes.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Paleta.warning.withOpacity(0.09),
              borderRadius: BorderRadius.circular(Radios.base),
              border: Border.all(color: Paleta.warning.withOpacity(0.28)),
            ),
            child: Row(
              children: [
                const Icon(Icons.pending_actions,
                    size: 17, color: Paleta.warning),
                const SizedBox(width: 11),
                Expanded(
                  child: Text(
                    '${pendientes.length} ${pendientes.length == 1 ? 'título espera' : 'títulos esperan'} tu validación para aparecer en el catálogo público.',
                    style: const TextStyle(
                        color: Paleta.textSecondary, fontSize: 12.5),
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
            hintText: 'Buscar por título, autor o ISBN…',
            prefixIcon: Icon(Icons.search, size: 20),
          ),
        ),
        const SizedBox(height: 16),
        for (final libro in libros)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _FilaLibro(libro: libro),
          ),
      ],
    );
  }
}

class _FilaLibro extends StatelessWidget {
  const _FilaLibro({required this.libro});

  final Libro libro;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ExpansionTile(
        shape: const Border(),
        collapsedShape: const Border(),
        tilePadding: const EdgeInsets.symmetric(horizontal: 16),
        leading:
            SizedBox(width: 40, child: Portada(libro, alto: 58, ancho: 40)),
        title: Text(libro.titulo,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        subtitle: Text(
          '${libro.autor} · ${libro.ejemplaresDisponibles} de ${libro.totalEjemplares} disponibles',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: libro.validado
            ? null
            : const Insignia('Sin publicar', color: Paleta.warning),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!libro.validado) ...[
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          libro.camposPendientes.isEmpty
                              ? 'Este título todavía no se publicó en el catálogo.'
                              : 'Campos sin resolver: ${libro.camposPendientes.join(', ')}.',
                          style: const TextStyle(
                              color: Paleta.textMuted, fontSize: 12.5),
                        ),
                      ),
                      FilledButton.icon(
                        onPressed: () => context
                            .read<CatalogoBloc>()
                            .add(LibroValidado(libro.id)),
                        icon: const Icon(Icons.check, size: 17),
                        label: const Text('Publicar'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                ],
                Row(
                  children: [
                    const Text('Ejemplares',
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13.5,
                            color: Paleta.textPrimary)),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () => _agregarEjemplar(context, libro.id),
                      icon: const Icon(Icons.add, size: 17),
                      label: const Text('Agregar'),
                    ),
                  ],
                ),
                for (final ej in libro.ejemplares)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            ej.qr,
                            style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 12,
                                color: Paleta.textSecondary),
                          ),
                        ),
                        Insignia.condicion(ej.condicion),
                        const SizedBox(width: 7),
                        Insignia.estadoEjemplar(ej.estado),
                        IconButton(
                          tooltip: 'Ver o reimprimir etiqueta',
                          icon: const Icon(Icons.qr_code_2, size: 19),
                          onPressed: () => _mostrarEtiqueta(context, libro, ej),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Future<void> _agregarEjemplar(
      BuildContext context, String libroId) async {
    final condicion = await showDialog<CondicionEjemplar>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Condición del nuevo ejemplar'),
        children: [
          for (final c in CondicionEjemplar.values)
            SimpleDialogOption(
              onPressed: () => Navigator.of(ctx).pop(c),
              child: Text(c.label),
            ),
        ],
      ),
    );
    if (condicion == null || !context.mounted) return;
    context
        .read<CatalogoBloc>()
        .add(EjemplarAgregado(libroId: libroId, condicion: condicion));
  }

  static void _mostrarEtiqueta(
      BuildContext context, Libro libro, Ejemplar ejemplar) {
    showDialog<void>(
      context: context,
      builder: (_) =>
          _DialogoEtiqueta(libroId: libro.id, ejemplarId: ejemplar.id),
    );
  }
}

/// Etiqueta QR del ejemplar, con la opción de reimprimirla.
///
/// Regla de Continuidad de Identidad (spec v2 §7): la reimpresión reusa el
/// mismo identificador interno, así que la etiqueta sale idéntica y el
/// historial del ejemplar queda intacto.
class _DialogoEtiqueta extends StatelessWidget {
  const _DialogoEtiqueta({required this.libroId, required this.ejemplarId});

  final String libroId;
  final String ejemplarId;

  @override
  Widget build(BuildContext context) {
    final libros = context.watch<CatalogoBloc>().state.todosLosLibros;
    final libro = libros.where((l) => l.id == libroId).firstOrNull;
    final ejemplar = libro?.ejemplar(ejemplarId);
    if (libro == null || ejemplar == null) return const SizedBox.shrink();

    return AlertDialog(
      title: const Text('Etiqueta del ejemplar'),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(Radios.base),
              ),
              child: QrImageView(
                data: ejemplar.qr,
                size: 170,
                backgroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Text(ejemplar.qr,
                style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    color: Paleta.textSecondary)),
            const SizedBox(height: 4),
            Text(libro.titulo,
                textAlign: TextAlign.center,
                style:
                    const TextStyle(color: Paleta.textMuted, fontSize: 12.5)),
            if (ejemplar.reimpresionesQr > 0) ...[
              const SizedBox(height: 10),
              Insignia(
                'Reimpresa ${ejemplar.reimpresionesQr} ${ejemplar.reimpresionesQr == 1 ? 'vez' : 'veces'}',
                color: Paleta.info,
              ),
            ],
            const SizedBox(height: 14),
            const Text(
              'Al reimprimir se conserva el mismo identificador: el historial de '
              'préstamos del ejemplar no se ve afectado.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Paleta.textMuted, fontSize: 11.5, height: 1.4),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cerrar'),
        ),
        FilledButton.icon(
          onPressed: () => _reimprimir(context, libroId, ejemplarId),
          icon: const Icon(Icons.print_outlined, size: 17),
          label: const Text('Reimprimir'),
        ),
      ],
    );
  }

  static Future<void> _reimprimir(
      BuildContext context, String libroId, String ejemplarId) async {
    final motivo = await showDialog<String>(
      context: context,
      builder: (ctx) => const _DialogoMotivo(),
    );
    if (motivo == null || !context.mounted) return;
    context.read<CatalogoBloc>().add(EtiquetaReimpresa(
          libroId: libroId,
          ejemplarId: ejemplarId,
          motivo: motivo,
        ));
  }
}

class _DialogoMotivo extends StatefulWidget {
  const _DialogoMotivo();

  @override
  State<_DialogoMotivo> createState() => _DialogoMotivoState();
}

class _DialogoMotivoState extends State<_DialogoMotivo> {
  final _motivo = TextEditingController();

  static const _sugerencias = [
    'Etiqueta rota',
    'Etiqueta ilegible por desgaste',
    'Etiqueta despegada',
  ];

  @override
  void dispose() {
    _motivo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Motivo de la reimpresión'),
      content: SizedBox(
        width: 340,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Queda registrado en el log de auditoría.',
              style: TextStyle(color: Paleta.textMuted, fontSize: 12.5),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _motivo,
              autofocus: true,
              decoration: const InputDecoration(hintText: 'Motivo'),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: [
                for (final s in _sugerencias)
                  ActionChip(
                    label: Text(s, style: const TextStyle(fontSize: 11.5)),
                    onPressed: () => setState(() => _motivo.text = s),
                  ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _motivo.text.trim().isEmpty
              ? null
              : () => Navigator.of(context).pop(_motivo.text.trim()),
          child: const Text('Reimprimir'),
        ),
      ],
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
