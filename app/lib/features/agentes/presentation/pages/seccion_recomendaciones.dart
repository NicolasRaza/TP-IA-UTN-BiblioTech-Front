import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/presentation/widgets/comunes.dart';
import '../../../catalogo/presentation/widgets/libro_widgets.dart';
import '../../../../core/theme/tema.dart';
import '../../../../core/utils/responsive.dart';
import '../cubit/recomendaciones_cubit.dart';

/// Recomendaciones del Agente Evaluador (spec v2 §2).
///
/// Muestra el motivo de cada sugerencia y avisa cuando el lector todavía no
/// tiene historial suficiente y la recomendación se apoya solo en popularidad.
class SeccionRecomendaciones extends StatelessWidget {
  const SeccionRecomendaciones({super.key});

  @override
  Widget build(BuildContext context) {
    final estado = context.watch<RecomendacionesCubit>().state;
    final recomendaciones = estado.recomendaciones;
    final cfg = estado.configuracion;
    final esColdStart = estado.esColdStart;

    return Seccion(
      children: [
        const EncabezadoSeccion(
          'Recomendado para vos',
          subtitulo: 'Sugerencias en base a tu historial y a lo más leído',
        ),
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: (esColdStart ? Paleta.gold : Paleta.teal).withOpacity(0.09),
            borderRadius: BorderRadius.circular(Radios.base),
            border: Border.all(
                color: (esColdStart ? Paleta.gold : Paleta.teal)
                    .withOpacity(0.28)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(esColdStart ? Icons.explore_outlined : Icons.tune,
                  size: 18, color: esColdStart ? Paleta.gold : Paleta.teal),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      esColdStart
                          ? 'Todavía estamos conociéndote'
                          : 'Cómo armamos esta lista',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5,
                        color: esColdStart ? Paleta.gold : Paleta.teal,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      esColdStart
                          ? 'Con menos de ${cfg.minPrestamosParaHistorial} préstamos registrados '
                              'te mostramos lo más leído por la comunidad. A medida que '
                              'pidas libros, la lista se va a ir personalizando.'
                          : 'Combinamos tu historial de lectura '
                              '(${(cfg.pesoHistorialRecomendacion * 100).round()}%) '
                              'con lo más leído en la biblioteca '
                              '(${(cfg.pesoPopularidadRecomendacion * 100).round()}%).',
                      style: const TextStyle(
                          color: Paleta.textSecondary,
                          fontSize: 12.5,
                          height: 1.45),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        if (recomendaciones.isEmpty)
          const EstadoVacio(
            icono: Icons.auto_awesome_outlined,
            titulo: 'Todavía no hay recomendaciones',
            detalle: 'Explorá el catálogo y reservá tu primer libro.',
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: recomendaciones.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: context.columnasGrilla(anchoMinimo: 190),
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: 0.58,
            ),
            itemBuilder: (_, i) => TarjetaLibro(
              libro: recomendaciones[i].libro,
              motivo: recomendaciones[i].motivo,
            ),
          ),
      ],
    );
  }
}
