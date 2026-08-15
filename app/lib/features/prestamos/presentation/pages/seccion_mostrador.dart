import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/presentation/widgets/comunes.dart';
import '../../../../core/theme/tema.dart';
import '../../../../core/utils/formato.dart';
import '../../../catalogo/domain/entities/ejemplar.dart';
import '../../../catalogo/domain/entities/libro.dart';
import '../../../lectores/domain/entities/lector.dart';
import '../../domain/entities/prestamo.dart';
import '../../../agentes/presentation/bloc/agentes_bloc.dart';
import '../../../catalogo/domain/repositories/catalogo_repository.dart';
import '../../../catalogo/presentation/bloc/catalogo_bloc.dart';
import '../../../lectores/presentation/bloc/lectores_bloc.dart';
import '../../domain/services/politica_de_prestamo.dart';
import '../bloc/prestamos_bloc.dart';

/// Registrar préstamo, portado de `bibliotecario.html #s-prestamo`.
///
/// El lector se identifica por su QR o por búsqueda, y el ejemplar por el QR
/// de su etiqueta. El repositorio valida límites, multas y vencidos.
class SeccionPrestamo extends StatefulWidget {
  const SeccionPrestamo({super.key});

  @override
  State<SeccionPrestamo> createState() => _SeccionPrestamoState();
}

class _SeccionPrestamoState extends State<SeccionPrestamo> {
  Lector? _lector;
  ({Libro libro, Ejemplar ejemplar})? _ejemplar;

  final _qrEjemplar = TextEditingController();

  @override
  void dispose() {
    _qrEjemplar.dispose();
    super.dispose();
  }

  void _buscarEjemplar() {
    final qr = _qrEjemplar.text.trim();
    final libros = context.read<CatalogoBloc>().state.todosLosLibros;

    EjemplarLocalizado? encontrado;
    for (final libro in libros) {
      for (final ejemplar in libro.ejemplares) {
        if (ejemplar.qr == qr) {
          encontrado = (libro: libro, ejemplar: ejemplar);
          break;
        }
      }
      if (encontrado != null) break;
    }

    setState(() => _ejemplar = encontrado);
    if (encontrado == null) {
      avisar(context, 'No se encontró ningún ejemplar con ese código',
          esError: true);
    }
  }

  void _confirmar() {
    final lector = _lector;
    final ejemplar = _ejemplar;
    if (lector == null || ejemplar == null) return;

    context.read<PrestamosBloc>().add(PrestamoRegistrado(
          lectorId: lector.id,
          libroId: ejemplar.libro.id,
          ejemplarId: ejemplar.ejemplar.id,
        ));

    setState(() {
      _lector = null;
      _ejemplar = null;
      _qrEjemplar.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final prestamos = context.watch<PrestamosBloc>().state;
    final cfg = context.watch<AgentesBloc>().state.configuracion;

    // La política es una función pura del dominio: la presentación puede
    // consultarla para anticipar el rechazo antes de disparar el evento.
    final permiso = _lector == null
        ? null
        : const PoliticaDePrestamo().verificar(
            lector: _lector!,
            prestamosDelLector: prestamos.todos
                .where((p) => p.lectorId == _lector!.id)
                .toList(),
            configuracion: cfg,
          );

    return Seccion(
      anchoMaximo: 780,
      children: [
        const EncabezadoSeccion(
          'Registrar préstamo',
          subtitulo: 'Identificá al lector y escaneá el ejemplar',
        ),
        _PasoLector(
          lector: _lector,
          onElegir: (l) => setState(() => _lector = l),
        ),
        if (permiso != null && permiso.esFallo) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Paleta.danger.withOpacity(0.1),
              borderRadius: BorderRadius.circular(Radios.base),
              border: Border.all(color: Paleta.danger.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.block, color: Paleta.danger, size: 19),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(permiso.failureONull!.mensaje,
                      style: const TextStyle(
                          color: Paleta.danger, fontSize: 13, height: 1.4)),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 14),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('2. Ejemplar',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _qrEjemplar,
                        decoration: const InputDecoration(
                          hintText: 'Código QR del ejemplar (BT-lib-…-ej-…)',
                          prefixIcon: Icon(Icons.qr_code_scanner, size: 20),
                        ),
                        onSubmitted: (_) => _buscarEjemplar(),
                      ),
                    ),
                    const SizedBox(width: 10),
                    FilledButton(
                      onPressed: () => _buscarEjemplar(),
                      child: const Text('Buscar'),
                    ),
                  ],
                ),
                if (_ejemplar != null) ...[
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Portada(_ejemplar!.libro, alto: 68, ancho: 48),
                      const SizedBox(width: 13),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_ejemplar!.libro.titulo,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: Paleta.textPrimary)),
                            const SizedBox(height: 3),
                            Text(_ejemplar!.libro.autor,
                                style: const TextStyle(
                                    color: Paleta.textMuted, fontSize: 12.5)),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Insignia.estadoEjemplar(
                                    _ejemplar!.ejemplar.estado),
                                const SizedBox(width: 7),
                                Insignia.condicion(
                                    _ejemplar!.ejemplar.condicion),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (_lector != null && _ejemplar != null)
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Paleta.bgInput,
              borderRadius: BorderRadius.circular(Radios.base),
              border: Border.all(color: Paleta.border),
            ),
            child: Row(
              children: [
                const Icon(Icons.event_available,
                    size: 17, color: Paleta.textMuted),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Plazo de ${cfg.plazoPara(_lector!.categoria)} días por ser '
                    '${_lector!.categoria.label}. El préstamo conserva este plazo '
                    'aunque después cambie de categoría.',
                    style: const TextStyle(
                        color: Paleta.textSecondary,
                        fontSize: 12.5,
                        height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: (_lector != null &&
                  _ejemplar != null &&
                  (permiso?.esExito ?? false))
              ? () => _confirmar()
              : null,
          icon: const Icon(Icons.check, size: 18),
          label: const Text('Confirmar préstamo'),
        ),
      ],
    );
  }
}

/// Registrar devolución, portado de `bibliotecario.html #s-devolucion`.
class SeccionDevolucion extends StatefulWidget {
  const SeccionDevolucion({super.key});

  @override
  State<SeccionDevolucion> createState() => _SeccionDevolucionState();
}

class _SeccionDevolucionState extends State<SeccionDevolucion> {
  final _busqueda = TextEditingController();

  @override
  void dispose() {
    _busqueda.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ahora = DateTime.now();
    final q = _busqueda.text.trim().toLowerCase();

    var abiertos = context
        .watch<PrestamosBloc>()
        .state
        .todos
        .where((p) => p.estaAbierto)
        .toList();
    if (q.isNotEmpty) {
      abiertos = abiertos.where((p) {
        final libro = _libro(context, p.libroId);
        final lector = _lector(context, p.lectorId);
        return (libro?.titulo.toLowerCase().contains(q) ?? false) ||
            (lector?.nombreCompleto.toLowerCase().contains(q) ?? false) ||
            p.ejemplarId.toLowerCase().contains(q);
      }).toList();
    }
    abiertos.sort((a, b) => a.fechaVencimiento.compareTo(b.fechaVencimiento));

    return Seccion(
      anchoMaximo: 840,
      children: [
        const EncabezadoSeccion(
          'Registrar devolución',
          subtitulo: 'Préstamos abiertos, ordenados por vencimiento',
        ),
        TextField(
          controller: _busqueda,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            hintText: 'Buscar por libro, lector o ejemplar…',
            prefixIcon: Icon(Icons.search, size: 20),
          ),
        ),
        const SizedBox(height: 16),
        if (abiertos.isEmpty)
          const EstadoVacio(
            icono: Icons.done_all,
            titulo: 'No hay préstamos pendientes de devolución',
          )
        else
          for (final p in abiertos)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _FilaDevolucion(prestamo: p, ahora: ahora),
            ),
      ],
    );
  }
}

class _FilaDevolucion extends StatelessWidget {
  const _FilaDevolucion({required this.prestamo, required this.ahora});

  final Prestamo prestamo;
  final DateTime ahora;

  @override
  Widget build(BuildContext context) {
    final libro = _libro(context, prestamo.libroId);
    final lector = _lector(context, prestamo.lectorId);
    final cfg = context.watch<AgentesBloc>().state.configuracion;
    if (libro == null || lector == null) return const SizedBox.shrink();

    final vencido = prestamo.estado == EstadoPrestamo.vencido;
    final diasTarde =
        vencido ? ahora.difference(prestamo.fechaVencimiento).inDays : 0;
    final multaEstimada = vencido
        ? diasTarde * cfg.multaPorDiaDemora - prestamo.multaAplicada
        : 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Portada(libro, alto: 64, ancho: 45),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(libro.titulo,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: Paleta.textPrimary)),
                  const SizedBox(height: 3),
                  Text(lector.nombreCompleto,
                      style: const TextStyle(
                          color: Paleta.textMuted, fontSize: 12.5)),
                  const SizedBox(height: 7),
                  Row(
                    children: [
                      Insignia.estadoPrestamo(prestamo.estado),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          Formato.vencimiento(prestamo.fechaVencimiento,
                              ahora: ahora),
                          style: TextStyle(
                              color: vencido ? Paleta.danger : Paleta.textMuted,
                              fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  if (multaEstimada > 0) ...[
                    const SizedBox(height: 5),
                    Text(
                      'Se va a cargar una multa de ${Formato.pesos(multaEstimada)}',
                      style: const TextStyle(
                          color: Paleta.warning, fontSize: 11.5),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 10),
            FilledButton(
              onPressed: () => context
                  .read<PrestamosBloc>()
                  .add(DevolucionRegistrada(prestamo.id)),
              child: const Text('Devolver'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Selector de lector por QR o por búsqueda, compartido por el mostrador.
class _PasoLector extends StatefulWidget {
  const _PasoLector({required this.lector, required this.onElegir});

  final Lector? lector;
  final ValueChanged<Lector?> onElegir;

  @override
  State<_PasoLector> createState() => _PasoLectorState();
}

class _PasoLectorState extends State<_PasoLector> {
  final _busqueda = TextEditingController();

  @override
  void dispose() {
    _busqueda.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final q = _busqueda.text.trim().toLowerCase();
    final coincidencias = q.isEmpty
        ? <Lector>[]
        : context
            .watch<LectoresBloc>()
            .state
            .lectores
            .where((l) =>
                l.nombreCompleto.toLowerCase().contains(q) ||
                l.dni.contains(q) ||
                l.qr.toLowerCase() == q)
            .take(5)
            .toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('1. Lector', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            if (widget.lector == null) ...[
              TextField(
                controller: _busqueda,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  hintText: 'Nombre, DNI o QR del lector…',
                  prefixIcon: Icon(Icons.badge_outlined, size: 20),
                ),
              ),
              for (final l in coincidencias)
                ListTile(
                  dense: true,
                  leading: AvatarLector(l, radio: 15),
                  title: Text(l.nombreCompleto,
                      style: const TextStyle(fontSize: 13.5)),
                  subtitle: Text('DNI ${l.dni}',
                      style: const TextStyle(fontSize: 11.5)),
                  trailing: Insignia.categoria(l.categoria),
                  onTap: () {
                    widget.onElegir(l);
                    _busqueda.clear();
                  },
                ),
            ] else
              Row(
                children: [
                  AvatarLector(widget.lector!, radio: 21),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.lector!.nombreCompleto,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: Paleta.textPrimary)),
                        const SizedBox(height: 3),
                        Text('DNI ${widget.lector!.dni}',
                            style: const TextStyle(
                                color: Paleta.textMuted, fontSize: 12.5)),
                      ],
                    ),
                  ),
                  Insignia.categoria(widget.lector!.categoria),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () => widget.onElegir(null),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

/// Resuelve el libro de un préstamo desde el estado del catálogo.
Libro? _libro(BuildContext context, String libroId) => context
    .watch<CatalogoBloc>()
    .state
    .todosLosLibros
    .where((l) => l.id == libroId)
    .firstOrNull;

/// Resuelve el lector de un préstamo desde el padrón cargado.
Lector? _lector(BuildContext context, String lectorId) => context
    .watch<LectoresBloc>()
    .state
    .lectores
    .where((l) => l.id == lectorId)
    .firstOrNull;
