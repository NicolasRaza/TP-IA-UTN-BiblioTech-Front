import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/formato.dart';
import '../../core/tema.dart';
import '../../domain/models.dart';
import '../../state/app_state.dart';
import 'comunes.dart';

/// Tarjeta de libro del catálogo.
class TarjetaLibro extends StatelessWidget {
  const TarjetaLibro({
    super.key,
    required this.libro,
    this.motivo = '',
    this.onTap,
  });

  final Libro libro;

  /// Explicación de por qué se recomienda, si viene de una recomendación.
  final String motivo;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap ?? () => mostrarFichaLibro(context, libro),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: Portada(libro, alto: 170),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Insignia(
                    libro.hayDisponible
                        ? '${libro.ejemplaresDisponibles} disponible${libro.ejemplaresDisponibles == 1 ? '' : 's'}'
                        : 'Sin ejemplares',
                    color: libro.hayDisponible ? Paleta.success : Paleta.danger,
                  ),
                ),
              ],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(13, 12, 13, 13),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      libro.titulo,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        height: 1.25,
                        color: Paleta.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      libro.autor,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Paleta.textMuted, fontSize: 12.5),
                    ),
                    if (motivo.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.auto_awesome,
                              size: 12, color: Paleta.teal),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              motivo,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: Paleta.teal,
                                  fontSize: 11.5,
                                  height: 1.3),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const Spacer(),
                    if (libro.genero.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          color: Paleta.bgHover,
                          borderRadius: BorderRadius.circular(Radios.xl),
                        ),
                        child: Text(
                          libro.genero,
                          style: const TextStyle(
                              color: Paleta.textSecondary, fontSize: 10.5),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Abre la ficha completa del libro, con la acción de reservar.
void mostrarFichaLibro(BuildContext context, Libro libro) {
  showDialog<void>(
    context: context,
    builder: (_) => _FichaLibro(libroId: libro.id),
  );
}

class _FichaLibro extends StatelessWidget {
  const _FichaLibro({required this.libroId});

  final String libroId;

  @override
  Widget build(BuildContext context) {
    final estado = context.watch<AppState>();
    final libro = estado.repo.libro(libroId);
    if (libro == null) return const SizedBox.shrink();

    final usuario = estado.usuario;
    final cola = estado.repo.colaDeReservas(libro.id);
    final yaReservado = usuario != null &&
        estado.repo
            .reservasDeLector(usuario.id)
            .any((r) => r.libroId == libro.id && r.esActiva);

    return Dialog(
      insetPadding: const EdgeInsets.all(20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620, maxHeight: 680),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Portada(libro, alto: 190, ancho: 130),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(libro.titulo,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(fontSize: 19, height: 1.25)),
                              const SizedBox(height: 5),
                              Text(libro.autor,
                                  style: const TextStyle(
                                      color: Paleta.textSecondary,
                                      fontSize: 14)),
                              const SizedBox(height: 14),
                              Wrap(
                                spacing: 7,
                                runSpacing: 7,
                                children: [
                                  Insignia(
                                    libro.hayDisponible
                                        ? '${libro.ejemplaresDisponibles} de ${libro.totalEjemplares} disponibles'
                                        : 'Sin ejemplares libres',
                                    color: libro.hayDisponible
                                        ? Paleta.success
                                        : Paleta.danger,
                                  ),
                                  if (libro.genero.isNotEmpty)
                                    Insignia(libro.genero,
                                        color: Paleta.primary),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    _Datos(libro: libro),
                    if (libro.sinopsis.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      const Text('Sinopsis',
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Paleta.textPrimary)),
                      const SizedBox(height: 7),
                      Text(
                        libro.sinopsis,
                        style: const TextStyle(
                            color: Paleta.textSecondary,
                            height: 1.55,
                            fontSize: 13.5),
                      ),
                    ],
                    if (cola.isNotEmpty) ...[
                      const SizedBox(height: 18),
                      Container(
                        padding: const EdgeInsets.all(13),
                        decoration: BoxDecoration(
                          color: Paleta.info.withOpacity(0.09),
                          borderRadius: BorderRadius.circular(Radios.base),
                          border:
                              Border.all(color: Paleta.info.withOpacity(0.25)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.people_outline,
                                size: 16, color: Paleta.info),
                            const SizedBox(width: 9),
                            Expanded(
                              child: Text(
                                '${cola.length} ${cola.length == 1 ? 'lector espera' : 'lectores esperan'} este título. '
                                'Las reservas se otorgan por orden de llegada.',
                                style: const TextStyle(
                                    color: Paleta.info, fontSize: 12.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const Divider(height: 1, color: Paleta.border),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cerrar'),
                  ),
                  const Spacer(),
                  if (usuario != null && !usuario.esPersonal)
                    FilledButton.icon(
                      onPressed: yaReservado
                          ? null
                          : () => _reservar(context, libro.id),
                      icon: Icon(
                          yaReservado
                              ? Icons.check
                              : Icons.bookmark_add_outlined,
                          size: 18),
                      label: Text(yaReservado ? 'Ya reservado' : 'Reservar'),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static void _reservar(BuildContext context, String libroId) {
    final r = context.read<AppState>().reservar(libroId);
    if (r.exito) {
      final lista = r.valor!.estado.label;
      avisar(context, 'Reserva registrada — $lista');
    } else {
      avisar(context, r.motivo, esError: true);
    }
  }
}

class _Datos extends StatelessWidget {
  const _Datos({required this.libro});

  final Libro libro;

  @override
  Widget build(BuildContext context) {
    final filas = <(String, String)>[
      if (libro.editorial.isNotEmpty) ('Editorial', libro.editorial),
      if (libro.anio != null) ('Año', '${libro.anio}'),
      if (libro.paginas != null) ('Páginas', '${libro.paginas}'),
      if (libro.isbn.isNotEmpty) ('ISBN', libro.isbn),
      ('Alta en catálogo', Formato.fecha(libro.fechaAlta)),
    ];

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Paleta.bgInput,
        borderRadius: BorderRadius.circular(Radios.base),
        border: Border.all(color: Paleta.border),
      ),
      child: Column(
        children: [
          for (final (etiqueta, valor) in filas)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 130,
                    child: Text(etiqueta,
                        style: const TextStyle(
                            color: Paleta.textMuted, fontSize: 12.5)),
                  ),
                  Expanded(
                    child: Text(valor,
                        style: const TextStyle(
                            color: Paleta.textPrimary, fontSize: 12.5)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
