import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/presentation/widgets/comunes.dart';
import '../widgets/libro_widgets.dart';
import '../../../../core/theme/tema.dart';
import '../../../../core/utils/responsive.dart';
import '../bloc/catalogo_bloc.dart';

/// Catálogo público (spec v2 §9), portado de `lector.html #s-catalogo`.
///
/// Solo lista libros validados por el bibliotecario: la Regla de Validación
/// Estricta la aplica el repositorio de catálogo, que separa el catálogo
/// público del inventario completo.
class SeccionCatalogo extends StatefulWidget {
  const SeccionCatalogo({super.key});

  @override
  State<SeccionCatalogo> createState() => _SeccionCatalogoState();
}

class _SeccionCatalogoState extends State<SeccionCatalogo> {
  final _busqueda = TextEditingController();
  bool _soloDisponibles = false;

  @override
  void dispose() {
    _busqueda.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final catalogo = context.watch<CatalogoBloc>().state;
    final generos = ['Todos', ...catalogo.generos];

    // El filtrado por texto y género lo resuelve el bloc; la disponibilidad
    // es un filtro puramente visual y se aplica acá.
    var resultados = catalogo.libros;
    if (_soloDisponibles) {
      resultados = resultados.where((l) => l.hayDisponible).toList();
    }

    return Seccion(
      children: [
        const EncabezadoSeccion(
          'Catálogo',
          subtitulo: 'Buscá por título, autor, ISBN o género',
        ),
        TextField(
          controller: _busqueda,
          onChanged: (texto) =>
              context.read<CatalogoBloc>().add(BusquedaCambiada(texto)),
          decoration: InputDecoration(
            hintText: 'Buscar en el catálogo…',
            prefixIcon: const Icon(Icons.search, size: 20),
            suffixIcon: _busqueda.text.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () {
                      _busqueda.clear();
                      setState(() {});
                    },
                  ),
          ),
        ),
        const SizedBox(height: 14),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final g in generos) ...[
                FilterChip(
                  label: Text(g),
                  selected: catalogo.genero == g,
                  onSelected: (_) =>
                      context.read<CatalogoBloc>().add(GeneroCambiado(g)),
                  selectedColor: Paleta.primary.withOpacity(0.25),
                  checkmarkColor: Paleta.primaryLight,
                ),
                const SizedBox(width: 8),
              ],
            ],
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Switch(
              value: _soloDisponibles,
              onChanged: (v) => setState(() => _soloDisponibles = v),
            ),
            const SizedBox(width: 4),
            const Text('Solo con ejemplares disponibles',
                style: TextStyle(color: Paleta.textSecondary, fontSize: 13)),
            const Spacer(),
            Text(
              '${resultados.length} ${resultados.length == 1 ? 'resultado' : 'resultados'}',
              style: const TextStyle(color: Paleta.textMuted, fontSize: 12.5),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (resultados.isEmpty)
          const EstadoVacio(
            icono: Icons.search_off,
            titulo: 'Sin resultados',
            detalle: 'Probá con otro título, autor o género.',
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: resultados.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: context.columnasGrilla(anchoMinimo: 190),
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: 0.60,
            ),
            itemBuilder: (_, i) => TarjetaLibro(libro: resultados[i]),
          ),
      ],
    );
  }
}
