import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_picker/file_picker.dart';

import '../../../../core/presentation/widgets/comunes.dart';
import '../../../../core/theme/tema.dart';
import '../../../agentes/domain/entities/ficha_sugerida.dart';
import '../cubit/alta_libro_cubit.dart';

/// Alta de libro con reconocimiento asistido.
///
/// Alta de libro (spec v2 §9). El flujo respeta la Regla de
/// Validación Estricta (spec v2 §7): el libro se crea sin validar y solo se
/// publica cuando el bibliotecario confirma explícitamente.
class SeccionAltaLibro extends StatefulWidget {
  const SeccionAltaLibro({super.key});

  @override
  State<SeccionAltaLibro> createState() => _SeccionAltaLibroState();
}

class _SeccionAltaLibroState extends State<SeccionAltaLibro> {
  PlatformFile? _fotoTapa;
  PlatformFile? _fotoContratapa;
  PlatformFile? _fotoFicha;

  final _controles = <String, TextEditingController>{};

  /// Sólo queda como estado local lo que es propio del formulario: el texto
  /// que la persona está tipeando. La ficha sugerida, las correcciones y el
  /// guardado los maneja el [AltaLibroCubit].

  @override
  void dispose() {
    for (final c in _controles.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _analizar() {
    if (_fotoTapa == null || _fotoContratapa == null || _fotoFicha == null) {
      return;
    }

    context.read<AltaLibroCubit>().analizar(
          fotoTapa: _fotoTapa!.bytes!,
          fotoContratapa: _fotoContratapa!.bytes!,
          fotoFicha: _fotoFicha!.bytes!,
          extensionTapa: _fotoTapa!.extension,
          extensionContratapa: _fotoContratapa!.extension,
          extensionFicha: _fotoFicha!.extension,
        );
  }

  /// Vuelca los valores sugeridos en los campos editables del formulario.
  void _volcarEnFormulario(FichaSugerida ficha) {
    for (final e in ficha.campos.entries) {
      _controles.putIfAbsent(e.key, () => TextEditingController()).text =
          e.value.valor;
    }
  }

  void _limpiar() {
    context.read<AltaLibroCubit>().limpiar();
    setState(() {
      _fotoTapa = null;
      _fotoContratapa = null;
      _fotoFicha = null;
      for (final c in _controles.values) {
        c.clear();
      }
    });
  }

  void _guardar({required bool publicar}) {
    context.read<AltaLibroCubit>().guardar(
      valores: {
        for (final e in _controles.entries) e.key: e.value.text,
      },
      publicar: publicar,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AltaLibroCubit, AltaLibroState>(
      listener: (context, state) {
        final ficha = state.ficha;
        if (ficha != null) _volcarEnFormulario(ficha);

        final exito = state.mensajeExito;
        final error = state.mensajeError;
        if (exito != null) {
          avisar(context, exito);
          _limpiarCampos();
        }
        if (error != null) avisar(context, error, esError: true);
      },
      builder: (context, state) => _formulario(context, state.ficha),
    );
  }

  /// Limpia sólo los campos, sin volver a tocar el cubit: el estado ya se
  /// reinició solo después de guardar.
  void _limpiarCampos() {
    setState(() {
      _fotoTapa = null;
      _fotoContratapa = null;
      _fotoFicha = null;
      for (final c in _controles.values) {
        c.clear();
      }
    });
  }

  Widget _formulario(BuildContext context, FichaSugerida? ficha) {
    return Seccion(
      anchoMaximo: 900,
      children: [
        const EncabezadoSeccion(
          'Alta de libro',
          subtitulo:
              'El sistema propone la ficha; vos la confirmás antes de publicarla',
        ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.document_scanner_outlined,
                        size: 18, color: Paleta.primary),
                    const SizedBox(width: 10),
                    Text('Captura del ejemplar',
                        style: Theme.of(context).textTheme.titleMedium),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Subí las fotos de la tapa, contratapa y la página con la '
                  'ficha técnica del ejemplar para extraer los datos automáticamente.',
                  style: TextStyle(
                      color: Paleta.textMuted, fontSize: 12.5, height: 1.45),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                        child: _SelectorDeFoto(
                      titulo: 'Tapa',
                      archivo: _fotoTapa,
                      alSeleccionar: (f) => setState(() => _fotoTapa = f),
                    )),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _SelectorDeFoto(
                      titulo: 'Contratapa',
                      archivo: _fotoContratapa,
                      alSeleccionar: (f) => setState(() => _fotoContratapa = f),
                    )),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _SelectorDeFoto(
                      titulo: 'Ficha Técnica / ISBN',
                      archivo: _fotoFicha,
                      alSeleccionar: (f) => setState(() => _fotoFicha = f),
                    )),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    FilledButton.icon(
                      onPressed: (_fotoTapa != null &&
                              _fotoContratapa != null &&
                              _fotoFicha != null)
                          ? _analizar
                          : null,
                      icon: const Icon(Icons.auto_fix_high, size: 18),
                      label: const Text('Analizar'),
                    ),
                    const Spacer(),
                    if (ficha != null)
                      TextButton(
                          onPressed: _limpiar, child: const Text('Limpiar')),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (ficha != null) ...[
          const SizedBox(height: 18),
          _ResumenRevision(ficha: ficha),
          const SizedBox(height: 14),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Ficha sugerida',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  const Text(
                    'Revisá cada campo. Los marcados necesitan tu atención.',
                    style: TextStyle(color: Paleta.textMuted, fontSize: 12.5),
                  ),
                  const SizedBox(height: 16),
                  for (final campo in _ordenCampos)
                    if (ficha.campos.containsKey(campo))
                      _CampoFicha(
                        nombre: campo,
                        etiqueta: _etiquetas[campo] ?? campo,
                        sugerido: ficha.campo(campo),
                        controlador: _controles[campo]!,
                        onElegirAlternativa: (v) =>
                            setState(() => _controles[campo]!.text = v),
                      ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Paleta.warning.withOpacity(0.09),
              borderRadius: BorderRadius.circular(Radios.base),
              border: Border.all(color: Paleta.warning.withOpacity(0.28)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.gavel_outlined, size: 17, color: Paleta.warning),
                SizedBox(width: 11),
                Expanded(
                  child: Text(
                    'Ningún libro entra al catálogo público sin tu confirmación, '
                    'por más que el reconocimiento tenga confianza alta en todos '
                    'los campos.',
                    style: TextStyle(
                        color: Paleta.textSecondary,
                        fontSize: 12.5,
                        height: 1.45),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: () => _guardar(publicar: false),
                icon: const Icon(Icons.save_outlined, size: 18),
                label: const Text('Guardar sin publicar'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _guardar(publicar: true),
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('Confirmar y publicar'),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  static const _ordenCampos = [
    'titulo',
    'autor',
    'editorial',
    'anio',
    'isbn',
    'paginas',
  ];

  static const _etiquetas = {
    'titulo': 'Título',
    'autor': 'Autor',
    'editorial': 'Editorial',
    'anio': 'Año',
    'isbn': 'ISBN',
    'paginas': 'Páginas',
  };
}

/// Aviso con el estado general de la revisión.
class _ResumenRevision extends StatelessWidget {
  const _ResumenRevision({required this.ficha});

  final FichaSugerida ficha;

  @override
  Widget build(BuildContext context) {
    final pendientes = ficha.camposPendientes.length;
    final conflictos = ficha.camposEnConflicto.length;
    final revisar = ficha.camposARevisar.length;

    final (color, icono, texto) = revisar == 0
        ? (
            Paleta.success,
            Icons.check_circle_outline,
            'Todos los campos se reconocieron con buena confianza. Revisalos igual antes de publicar.'
          )
        : (
            Paleta.warning,
            Icons.rule,
            '$revisar ${revisar == 1 ? 'campo necesita' : 'campos necesitan'} revisión'
                '${pendientes > 0 ? ' · $pendientes sin dato' : ''}'
                '${conflictos > 0 ? ' · $conflictos con fuentes en conflicto' : ''}.'
          );

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: color.withOpacity(0.09),
        borderRadius: BorderRadius.circular(Radios.base),
        border: Border.all(color: color.withOpacity(0.28)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icono, size: 17, color: color),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              texto,
              style: const TextStyle(
                  color: Paleta.textSecondary, fontSize: 12.5, height: 1.45),
            ),
          ),
        ],
      ),
    );
  }
}

/// Un campo editable con su nivel de confianza y sus alternativas.
class _CampoFicha extends StatelessWidget {
  const _CampoFicha({
    required this.nombre,
    required this.etiqueta,
    required this.sugerido,
    required this.controlador,
    required this.onElegirAlternativa,
  });

  final String nombre;
  final String etiqueta;
  final CampoSugerido sugerido;
  final TextEditingController controlador;
  final ValueChanged<String> onElegirAlternativa;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(etiqueta,
                  style: const TextStyle(
                      color: Paleta.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
              const SizedBox(width: 10),
              Insignia.confianza(sugerido.confianza),
              if (sugerido.porcentaje > 0) ...[
                const SizedBox(width: 7),
                Text('${sugerido.porcentaje}%',
                    style: const TextStyle(
                        color: Paleta.textMuted, fontSize: 11.5)),
              ],
            ],
          ),
          const SizedBox(height: 7),
          TextField(
            controller: controlador,
            decoration: InputDecoration(
              hintText: sugerido.confianza == NivelConfianza.pendiente
                  ? 'Ninguna fuente lo resolvió — cargalo a mano'
                  : null,
              suffixIcon: sugerido.requiereRevision
                  ? const Icon(Icons.edit_note, size: 19, color: Paleta.warning)
                  : null,
            ),
          ),
          if (sugerido.alternativas.length > 1) ...[
            const SizedBox(height: 8),
            const Text('Las fuentes no coinciden. Elegí cuál vale:',
                style: TextStyle(color: Paleta.pink, fontSize: 12)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final alt in sugerido.alternativas)
                  ActionChip(
                    label: Text('${alt.valor}  ·  ${alt.nombreFuente}',
                        style: const TextStyle(fontSize: 11.5)),
                    onPressed: () => onElegirAlternativa(alt.valor),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _SelectorDeFoto extends StatelessWidget {
  const _SelectorDeFoto({
    required this.titulo,
    required this.archivo,
    required this.alSeleccionar,
  });

  final String titulo;
  final PlatformFile? archivo;
  final ValueChanged<PlatformFile?> alSeleccionar;

  Future<void> _elegirArchivo() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result != null && result.files.isNotEmpty) {
      alSeleccionar(result.files.first);
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: _elegirArchivo,
      borderRadius: BorderRadius.circular(Radios.base),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
            color: archivo != null ? Paleta.primary : Paleta.border,
            width: archivo != null ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(Radios.base),
          color: archivo != null ? Paleta.primary.withOpacity(0.05) : null,
        ),
        child: Column(
          children: [
            Icon(
              archivo != null
                  ? Icons.image
                  : Icons.add_photo_alternate_outlined,
              size: 28,
              color: archivo != null ? Paleta.primary : Paleta.textMuted,
            ),
            const SizedBox(height: 8),
            Text(
              titulo,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: archivo != null ? Paleta.primary : Paleta.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (archivo != null) ...[
              const SizedBox(height: 4),
              Text(
                archivo!.name,
                style: const TextStyle(fontSize: 11, color: Paleta.textMuted),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ]
          ],
        ),
      ),
    );
  }
}
