import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/tema.dart';
import '../../domain/enums.dart';
import '../../domain/models.dart';
import '../../state/app_state.dart';
import '../widgets/comunes.dart';
import '../widgets/shell_adaptativo.dart';

/// Parámetros de la biblioteca, portados de `admin.html #s-configuracion`.
///
/// Son los "Parámetros de configuración" de la spec v2 §3, definidos por el
/// Administrador. Los cambios rigen para operaciones nuevas: los préstamos y
/// reservas ya generados conservan las condiciones con las que nacieron.
class SeccionParametros extends StatefulWidget {
  const SeccionParametros({super.key});

  @override
  State<SeccionParametros> createState() => _SeccionParametrosState();
}

class _SeccionParametrosState extends State<SeccionParametros> {
  ConfiguracionBiblioteca? _borrador;

  static const _categorias = [
    CategoriaLector.menor,
    CategoriaLector.adulto,
    CategoriaLector.docente,
    CategoriaLector.senior,
  ];

  void _actualizar(ConfiguracionBiblioteca nueva) =>
      setState(() => _borrador = nueva);

  @override
  Widget build(BuildContext context) {
    final estado = context.watch<AppState>();
    final cfg = _borrador ?? estado.repo.config;
    final haycambios = _borrador != null;

    return Seccion(
      anchoMaximo: 860,
      children: [
        EncabezadoSeccion(
          'Parámetros de la biblioteca',
          subtitulo:
              'Rigen para los préstamos y reservas que se generen de acá en adelante',
          accion: haycambios
              ? FilledButton.icon(
                  onPressed: () {
                    context.read<AppState>().guardarConfig(cfg);
                    setState(() => _borrador = null);
                    avisar(context, 'Parámetros actualizados');
                  },
                  icon: const Icon(Icons.save_outlined, size: 18),
                  label: const Text('Guardar'),
                )
              : null,
        ),
        _Bloque(
          titulo: 'Plazos de préstamo',
          detalle: 'Días que dura un préstamo según la categoría del socio',
          hijos: [
            for (final c in _categorias)
              _Numero(
                etiqueta: c.label,
                valor: cfg.plazoPara(c),
                sufijo: 'días',
                minimo: 1,
                maximo: 90,
                onCambio: (v) => _actualizar(cfg.copyWith(
                  plazoPrestamoDias: {...cfg.plazoPrestamoDias, c: v},
                )),
              ),
          ],
        ),
        _Bloque(
          titulo: 'Límite de préstamos simultáneos',
          detalle: 'Ejemplares que un socio puede tener al mismo tiempo',
          hijos: [
            for (final c in _categorias)
              _Numero(
                etiqueta: c.label,
                valor: cfg.limiteEjemplaresPara(c),
                sufijo: 'ejemplares',
                minimo: 1,
                maximo: 20,
                onCambio: (v) => _actualizar(cfg.copyWith(
                  limiteEjemplares: {...cfg.limiteEjemplares, c: v},
                )),
              ),
          ],
        ),
        _Bloque(
          titulo: 'Límite de reservas simultáneas',
          detalle: 'Títulos que un socio puede tener reservados a la vez',
          hijos: [
            for (final c in _categorias)
              _Numero(
                etiqueta: c.label,
                valor: cfg.limiteReservasPara(c),
                sufijo: 'reservas',
                minimo: 1,
                maximo: 20,
                onCambio: (v) => _actualizar(cfg.copyWith(
                  limiteReservas: {...cfg.limiteReservas, c: v},
                )),
              ),
          ],
        ),
        _Bloque(
          titulo: 'Reservas y avisos',
          detalle:
              'El plazo de retención define cuánto se guarda un ejemplar antes de pasarlo al siguiente de la cola',
          hijos: [
            _Numero(
              etiqueta: 'Retención de la reserva',
              valor: cfg.plazoRetiroReservaHoras,
              sufijo: 'horas',
              minimo: 1,
              maximo: 168,
              onCambio: (v) =>
                  _actualizar(cfg.copyWith(plazoRetiroReservaHoras: v)),
            ),
            _Numero(
              etiqueta: 'Aviso previo al vencimiento',
              valor: cfg.recordatorioAntesDias,
              sufijo: 'días',
              minimo: 0,
              maximo: 15,
              onCambio: (v) =>
                  _actualizar(cfg.copyWith(recordatorioAntesDias: v)),
            ),
            _Numero(
              etiqueta: 'Multa por día de demora',
              valor: cfg.multaPorDiaDemora,
              sufijo: 'pesos',
              minimo: 0,
              maximo: 10000,
              paso: 50,
              onCambio: (v) => _actualizar(cfg.copyWith(multaPorDiaDemora: v)),
            ),
          ],
        ),
        _Bloque(
          titulo: 'Motor de recomendaciones',
          detalle:
              'Cómo se combina el historial del lector con la popularidad general (spec v2 §2)',
          hijos: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text('Peso del historial personal',
                            style: TextStyle(
                                color: Paleta.textSecondary, fontSize: 13)),
                      ),
                      Text(
                        '${(cfg.pesoHistorialRecomendacion * 100).round()}% historial / '
                        '${(cfg.pesoPopularidadRecomendacion * 100).round()}% popularidad',
                        style: const TextStyle(
                            color: Paleta.primaryLight,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  Slider(
                    value: cfg.pesoHistorialRecomendacion,
                    divisions: 10,
                    onChanged: (v) => _actualizar(
                        cfg.copyWith(pesoHistorialRecomendacion: v)),
                  ),
                ],
              ),
            ),
            _Numero(
              etiqueta: 'Préstamos mínimos para usar el historial',
              valor: cfg.minPrestamosParaHistorial,
              sufijo: 'préstamos',
              minimo: 1,
              maximo: 50,
              onCambio: (v) =>
                  _actualizar(cfg.copyWith(minPrestamosParaHistorial: v)),
            ),
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'Por debajo de ese mínimo el lector se considera nuevo y la '
                'recomendación pasa a 100% popularidad general.',
                style: TextStyle(
                    color: Paleta.textMuted, fontSize: 12, height: 1.45),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Bloque extends StatelessWidget {
  const _Bloque({
    required this.titulo,
    required this.detalle,
    required this.hijos,
  });

  final String titulo;
  final String detalle;
  final List<Widget> hijos;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Card(
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
              const SizedBox(height: 4),
              Text(detalle,
                  style: const TextStyle(
                      color: Paleta.textMuted, fontSize: 12.5, height: 1.4)),
              const SizedBox(height: 12),
              ...hijos,
            ],
          ),
        ),
      ),
    );
  }
}

class _Numero extends StatelessWidget {
  const _Numero({
    required this.etiqueta,
    required this.valor,
    required this.sufijo,
    required this.minimo,
    required this.maximo,
    required this.onCambio,
    this.paso = 1,
  });

  final String etiqueta;
  final int valor;
  final String sufijo;
  final int minimo;
  final int maximo;
  final int paso;
  final ValueChanged<int> onCambio;

  @override
  Widget build(BuildContext context) {
    return Padding(
      // La key identifica la fila en los tests sin depender del orden.
      key: ValueKey('parametro-$etiqueta'),
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: Text(etiqueta,
                style:
                    const TextStyle(color: Paleta.textSecondary, fontSize: 13)),
          ),
          IconButton(
            icon: const Icon(Icons.remove_circle_outline, size: 19),
            onPressed:
                valor - paso < minimo ? null : () => onCambio(valor - paso),
          ),
          SizedBox(
            width: 46,
            child: Text('$valor',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Paleta.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 14)),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline, size: 19),
            onPressed:
                valor + paso > maximo ? null : () => onCambio(valor + paso),
          ),
          SizedBox(
            width: 78,
            child: Text(sufijo,
                style:
                    const TextStyle(color: Paleta.textMuted, fontSize: 11.5)),
          ),
        ],
      ),
    );
  }
}
