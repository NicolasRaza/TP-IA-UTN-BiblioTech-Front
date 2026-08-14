import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/formato.dart';
import '../../core/tema.dart';
import '../../domain/enums.dart';
import '../../domain/models.dart';
import '../../state/app_state.dart';
import '../widgets/comunes.dart';
import '../widgets/libro_widgets.dart';
import '../widgets/shell_adaptativo.dart';

/// Actividad del lector: préstamos vigentes, reservas e historial.
///
/// Reúne `#s-prestamos`, `#s-reservas` y `#s-historial` de `lector.html`.
class SeccionActividad extends StatelessWidget {
  const SeccionActividad({super.key});

  @override
  Widget build(BuildContext context) {
    final estado = context.watch<AppState>();

    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          Material(
            color: Paleta.bgSurface,
            child: TabBar(
              indicatorColor: Paleta.teal,
              labelColor: Paleta.textPrimary,
              unselectedLabelColor: Paleta.textMuted,
              tabs: [
                Tab(text: 'Préstamos (${estado.misPrestamos.length})'),
                Tab(
                    text:
                        'Reservas (${estado.misReservas.where((r) => r.esActiva).length})'),
                const Tab(text: 'Historial'),
              ],
            ),
          ),
          const Expanded(
            child: TabBarView(
              children: [
                _Prestamos(),
                _Reservas(),
                _Historial(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Prestamos extends StatelessWidget {
  const _Prestamos();

  @override
  Widget build(BuildContext context) {
    final estado = context.watch<AppState>();
    final prestamos = estado.misPrestamos;
    final ahora = estado.repo.ahora;

    if (prestamos.isEmpty) {
      return const EstadoVacio(
        icono: Icons.menu_book_outlined,
        titulo: 'No tenés préstamos activos',
        detalle: 'Buscá un libro en el catálogo y reservalo.',
      );
    }

    return Seccion(
      anchoMaximo: 820,
      children: [
        for (final p in prestamos) ...[
          _TarjetaPrestamo(prestamo: p, ahora: ahora),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _TarjetaPrestamo extends StatelessWidget {
  const _TarjetaPrestamo({required this.prestamo, required this.ahora});

  final Prestamo prestamo;
  final DateTime ahora;

  @override
  Widget build(BuildContext context) {
    final estado = context.watch<AppState>();
    final libro = estado.repo.libro(prestamo.libroId);
    if (libro == null) return const SizedBox.shrink();

    final vencido = prestamo.estado == EstadoPrestamo.vencido;
    final dias = prestamo.fechaVencimiento.difference(ahora).inDays;
    final porVencer =
        !vencido && dias <= estado.repo.config.recordatorioAntesDias;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(Radios.md),
        onTap: () => mostrarFichaLibro(context, libro),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Portada(libro, alto: 92, ancho: 64),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(libro.titulo,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14.5,
                            color: Paleta.textPrimary)),
                    const SizedBox(height: 2),
                    Text(libro.autor,
                        style: const TextStyle(
                            color: Paleta.textMuted, fontSize: 12.5)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(
                          vencido
                              ? Icons.error_outline
                              : (porVencer
                                  ? Icons.schedule
                                  : Icons.check_circle_outline),
                          size: 15,
                          color: vencido
                              ? Paleta.danger
                              : (porVencer ? Paleta.warning : Paleta.success),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            Formato.vencimiento(prestamo.fechaVencimiento,
                                ahora: ahora),
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: vencido
                                  ? Paleta.danger
                                  : (porVencer
                                      ? Paleta.warning
                                      : Paleta.textSecondary),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Plazo de ${prestamo.plazoDiasAlPrestar} días '
                      '(categoría ${prestamo.categoriaAlPrestar.label} al momento del préstamo)',
                      style: const TextStyle(
                          color: Paleta.textMuted, fontSize: 11.5),
                    ),
                  ],
                ),
              ),
              Insignia.estadoPrestamo(prestamo.estado),
            ],
          ),
        ),
      ),
    );
  }
}

class _Reservas extends StatelessWidget {
  const _Reservas();

  @override
  Widget build(BuildContext context) {
    final estado = context.watch<AppState>();
    final reservas = estado.misReservas.where((r) => r.esActiva).toList();
    final ahora = estado.repo.ahora;

    if (reservas.isEmpty) {
      return const EstadoVacio(
        icono: Icons.bookmark_border,
        titulo: 'No tenés reservas activas',
        detalle: 'Reservá desde la ficha de cualquier libro del catálogo.',
      );
    }

    return Seccion(
      anchoMaximo: 820,
      children: [
        for (final r in reservas) ...[
          _TarjetaReserva(reserva: r, ahora: ahora),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _TarjetaReserva extends StatelessWidget {
  const _TarjetaReserva({required this.reserva, required this.ahora});

  final Reserva reserva;
  final DateTime ahora;

  @override
  Widget build(BuildContext context) {
    final estado = context.watch<AppState>();
    final libro = estado.repo.libro(reserva.libroId);
    if (libro == null) return const SizedBox.shrink();

    final lista = reserva.estado == EstadoReserva.lista;
    final cola = estado.repo.colaDeReservas(reserva.libroId);
    final posicion = cola.indexWhere((r) => r.id == reserva.id) + 1;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Portada(libro, alto: 92, ancho: 64),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(libro.titulo,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14.5,
                          color: Paleta.textPrimary)),
                  const SizedBox(height: 8),
                  Insignia.estadoReserva(reserva.estado),
                  const SizedBox(height: 8),
                  if (lista && reserva.fechaVencimientoRetiro != null)
                    Text(
                      'Retiralo antes del ${Formato.fechaHora(reserva.fechaVencimientoRetiro)} '
                      '— si no, pasa al siguiente de la lista.',
                      style: const TextStyle(
                          color: Paleta.teal, fontSize: 12, height: 1.4),
                    )
                  else if (posicion > 0)
                    Text(
                      posicion == 1
                          ? 'Sos el próximo en la lista de espera'
                          : 'Estás en la posición $posicion de la lista de espera',
                      style: const TextStyle(
                          color: Paleta.textMuted, fontSize: 12),
                    ),
                  const SizedBox(height: 4),
                  Text('Reservado el ${Formato.fecha(reserva.fechaReserva)}',
                      style: const TextStyle(
                          color: Paleta.textMuted, fontSize: 11.5)),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Cancelar reserva',
              icon: const Icon(Icons.close, size: 18),
              onPressed: () => _cancelar(context, reserva.id),
            ),
          ],
        ),
      ),
    );
  }

  static Future<void> _cancelar(BuildContext context, String reservaId) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancelar reserva'),
        content: const Text(
            '¿Querés cancelar esta reserva? El ejemplar va a pasar al siguiente lector en espera.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('No'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Sí, cancelar'),
          ),
        ],
      ),
    );
    if (confirmado != true || !context.mounted) return;
    context.read<AppState>().cancelarReserva(reservaId);
    if (context.mounted) avisar(context, 'Reserva cancelada');
  }
}

class _Historial extends StatelessWidget {
  const _Historial();

  @override
  Widget build(BuildContext context) {
    final estado = context.watch<AppState>();
    final historial = estado.miHistorial;

    if (historial.isEmpty) {
      return const EstadoVacio(
        icono: Icons.history,
        titulo: 'Todavía no devolviste ningún libro',
        detalle: 'Acá va a quedar registrado tu historial de lectura.',
      );
    }

    return Seccion(
      anchoMaximo: 820,
      children: [
        for (final p in historial)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Card(
              child: ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                leading: SizedBox(
                  width: 42,
                  child: Portada(
                    estado.repo.libro(p.libroId) ??
                        Libro(
                            id: '',
                            titulo: '—',
                            autor: '',
                            fechaAlta: p.fechaPrestamo),
                    alto: 60,
                    ancho: 42,
                  ),
                ),
                title: Text(
                  estado.repo.libro(p.libroId)?.titulo ?? 'Libro dado de baja',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  'Devuelto el ${Formato.fecha(p.fechaDevolucion)}',
                  style: const TextStyle(fontSize: 12),
                ),
                trailing: p.tardio
                    ? const Insignia('Tardía', color: Paleta.warning)
                    : const Insignia('A tiempo', color: Paleta.success),
              ),
            ),
          ),
      ],
    );
  }
}
