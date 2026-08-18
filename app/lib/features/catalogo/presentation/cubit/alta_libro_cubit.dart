import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/result.dart';
import '../../../../core/presentation/estado_carga.dart';
import '../../../../core/services/reloj.dart';
import '../../../agentes/domain/entities/ficha_sugerida.dart';
import '../../../agentes/domain/services/agente_analizador.dart';
import '../../../agentes/domain/usecases/consultas_agentes.dart';
import '../../domain/entities/ejemplar.dart';
import '../../domain/entities/libro.dart';
import '../../domain/usecases/agregar_ejemplar.dart';
import '../../domain/usecases/registrar_libro.dart';
import '../../domain/usecases/validar_libro.dart';

part 'alta_libro_state.dart';

/// Alta de un título asistida por el Agente Analizador (spec v2 §4.2).
///
/// Concentra el flujo completo: analizar el texto del OCR, dejar que el
/// bibliotecario corrija los campos, y guardar el libro registrando cada
/// corrección como insumo del Agente de Aprendizaje.
class AltaLibroCubit extends Cubit<AltaLibroState> {
  AltaLibroCubit({
    required RegistrarLibro registrarLibro,
    required ValidarLibro validarLibro,
    required AgregarEjemplar agregarEjemplar,
    required RegistrarCorreccion registrarCorreccion,
    required Reloj reloj,
    required String? Function() usuarioActualId,
    AgenteAnalizador analizador = const AgenteAnalizador(),
  })  : _registrarLibro = registrarLibro,
        _validarLibro = validarLibro,
        _agregarEjemplar = agregarEjemplar,
        _registrarCorreccion = registrarCorreccion,
        _reloj = reloj,
        _usuarioActualId = usuarioActualId,
        _analizador = analizador,
        super(const AltaLibroState());

  final RegistrarLibro _registrarLibro;
  final ValidarLibro _validarLibro;
  final AgregarEjemplar _agregarEjemplar;
  final RegistrarCorreccion _registrarCorreccion;
  final Reloj _reloj;
  final String? Function() _usuarioActualId;
  final AgenteAnalizador _analizador;

  /// Estructura el texto crudo del OCR en campos editoriales.
  void analizar(String textoOcr) {
    if (textoOcr.trim().isEmpty) {
      emit(state.copyWith(
        mensajeError: 'Pegá el texto del OCR para poder analizarlo',
      ));
      return;
    }

    final ficha = _analizador.procesarTextoOcr(textoOcr);
    emit(state.copyWith(
      estado: EstadoCarga.exito,
      ficha: ficha,
      // Se guarda lo sugerido para poder detectar después qué cambió la
      // persona: esa diferencia es la señal que alimenta al agente 5.
      sugeridos: {
        for (final e in ficha.campos.entries) e.key: e.value.valor,
      },
      limpiarMensajes: true,
    ));
  }

  void limpiar() => emit(const AltaLibroState());

  void limpiarMensajes() => emit(state.copyWith(limpiarMensajes: true));

  /// Guarda el libro con los valores finales que dejó el bibliotecario.
  ///
  /// Si [publicar] es `true` además lo valida, que es lo único que lo hace
  /// visible en el catálogo público (spec v2 §7).
  Future<void> guardar({
    required Map<String, String> valores,
    required bool publicar,
  }) async {
    final titulo = (valores['titulo'] ?? '').trim();
    if (titulo.isEmpty) {
      emit(state.copyWith(mensajeError: 'El título es obligatorio'));
      return;
    }

    emit(state.copyWith(guardando: true, limpiarMensajes: true));

    // Los campos que el agente marcó para revisar y quedaron vacíos se
    // asientan como pendientes de carga manual.
    final pendientes = <String>[
      for (final campo in state.ficha?.camposARevisar ?? const <String>[])
        if ((valores[campo] ?? '').trim().isEmpty) campo,
    ];

    final resultado = await _registrarLibro(RegistrarLibroParams(
      libro: Libro(
        id: '',
        titulo: titulo,
        autor: (valores['autor'] ?? '').trim(),
        editorial: (valores['editorial'] ?? '').trim(),
        anio: int.tryParse((valores['anio'] ?? '').trim()),
        isbn: (valores['isbn'] ?? '').trim(),
        paginas: int.tryParse((valores['paginas'] ?? '').trim()),
        fechaAlta: _reloj.ahora,
        camposPendientes: pendientes,
      ),
      usuarioId: _usuarioActualId(),
    ));

    if (resultado case Fallo(:final failure)) {
      emit(state.copyWith(guardando: false, mensajeError: failure.mensaje));
      return;
    }

    final libro = resultado.valorONull!;

    // Todo título nace con al menos una copia física.
    await _agregarEjemplar(AgregarEjemplarParams(
      libroId: libro.id,
      condicion: CondicionEjemplar.bueno,
    ));

    await _registrarCorrecciones(valores);

    if (publicar) {
      await _validarLibro(ValidarLibroParams(
        libroId: libro.id,
        usuarioId: _usuarioActualId(),
      ));
    }

    emit(AltaLibroState(
      guardando: false,
      mensajeExito: publicar
          ? '"$titulo" se publicó en el catálogo'
          : '"$titulo" quedó guardado como borrador, sin publicar en el '
              'catálogo',
    ));
  }

  /// Cada corrección sobre lo sugerido alimenta al Agente de Aprendizaje.
  Future<void> _registrarCorrecciones(Map<String, String> valores) async {
    for (final entrada in state.sugeridos.entries) {
      final sugerido = entrada.value;
      final finalValor = (valores[entrada.key] ?? '').trim();
      if (sugerido.isEmpty || finalValor == sugerido) continue;

      await _registrarCorreccion(RegistrarCorreccionParams(
        campo: entrada.key,
        valorSugerido: sugerido,
        valorFinal: finalValor,
      ));
    }
  }
}
