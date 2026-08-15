import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/presentation/widgets/comunes.dart';
import '../../../catalogo/presentation/widgets/libro_widgets.dart';
import '../../../../core/theme/tema.dart';
import '../../../../core/utils/formato.dart';
import '../../../catalogo/domain/entities/libro.dart';
import '../../../reservas/domain/entities/reserva.dart';
import '../../domain/entities/prestamo.dart';
import '../../../agentes/presentation/cubit/recomendaciones_cubit.dart';
import '../../../catalogo/presentation/bloc/catalogo_bloc.dart';
import '../../../reservas/presentation/bloc/reservas_bloc.dart';
import '../bloc/prestamos_bloc.dart';

/// Actividad del lector: préstamos vigentes, reservas e historial.
///
/// Reúne `#s-prestamos`, `#s-reservas` y `#s-historial` de `lector.html`.
class SeccionActividad extends StatelessWidget {
  const SeccionActividad({super.key});

  @override
  Widget build(BuildContext context) {
    final prestamos = context.watch<PrestamosBloc>().state;
    final reservas = context.watch<ReservasBloc>().state;

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
                Tab(text: 'Préstamos (${prestamos.activos.length})'),
                Tab(text: 'Reservas (${reservas.activas.length})'),
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
    final prestamos = context.watch<PrestamosBloc>().state.activos;
    final ahora = DateTime.now();

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
    final libro = context
        .watch<CatalogoBloc>()
        .state
        .todosLosLibros
        .where((l) => l.id == prestamo.libroId)
        .firstOrNull;
    if (libro == null) return const SizedBox.shrink();

    final vencido = prestamo.estado == EstadoPrestamo.vencido;
    final dias = prestamo.fechaVencimiento.difference(ahora).inDays;
    final porVencer = !vencido &&
        dias <=
            context
                .watch<RecomendacionesCubit>()
                .state
                .configuracion
                .recordatorioAntesDias;

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
    final reservas = context.watch<ReservasBloc>().state.activas;
    final ahora = DateTime.now();

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
    final libro = context
        .watch<CatalogoBloc>()
        .state
        .todosLosLibros
        .where((l) => l.id == reserva.libroId)
        .firstOrNull;
    if (libro == null) return const SizedBox.shrink();

    final lista = reserva.estado == EstadoReserva.lista;
    final cola = context.watch<ReservasBloc>().state.colaDe(reserva.libroId);
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
    context.read<ReservasBloc>().add(ReservaCancelada(reservaId));
    if (context.mounted) avisar(context, 'Reserva cancelada');
  }
}

class _Historial extends StatelessWidget {
  const _Historial();

  @override
  Widget build(BuildContext context) {
    final historial = context.watch<PrestamosBloc>().state.historial;
    final libros = context.watch<CatalogoBloc>().state.todosLosLibros;

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
                    libros.where((l) => l.id == p.libroId).firstOrNull ??
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
                  libros.where((l) => l.id == p.libroId).firstOrNull?.titulo ??
                      'Libro dado de baja',
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
