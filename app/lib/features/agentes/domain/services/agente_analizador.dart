import '../entities/ficha_sugerida.dart';

/// Agente 2 — Analizador y de Enriquecimiento (spec v2 §4.2).
///
/// Estructura el texto crudo del OCR en campos editoriales y resuelve las
/// discrepancias entre fuentes externas. Es una clase pura: no toca
/// repositorios ni red, así que se puede testear campo por campo.
class AgenteAnalizador {
  const AgenteAnalizador();

  static const _editorialesConocidas = <String>[
    'sudamericana',
    'emecé',
    'emece',
    'planeta',
    'alfaguara',
    'anagrama',
    'seix barral',
    'tusquets',
    'debolsillo',
    'salamandra',
    'fondo de cultura',
    'debate',
    'crítica',
    'critica',
    'lumen',
    'alba',
    'suma',
    'random house',
    'siglo xxi',
    'losada',
    'cátedra',
    'catedra',
    'minotauro',
  ];

  /// Estructura el texto crudo del OCR en campos editoriales.
  ///
  /// Es deliberadamente heurístico: el resultado siempre pasa por la pantalla
  /// de revisión del bibliotecario antes de publicarse.
  FichaSugerida procesarTextoOcr(String textoOcr) {
    final lineas = textoOcr
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    final campos = <String, CampoSugerido>{};

    // ── ISBN (10 o 13 dígitos, con o sin separadores) ──
    final isbn = extraerIsbn(textoOcr);
    campos['isbn'] = isbn == null
        ? const CampoSugerido.pendiente()
        : CampoSugerido(
            valor: isbn,
            confianza: NivelConfianza.alta,
            porcentaje: 95,
            fuente: AutoridadFuente.ocr.label,
          );

    // ── Año de publicación ──
    final anio = RegExp(r'\b(1[5-9]\d{2}|20[0-4]\d)\b').firstMatch(textoOcr);
    campos['anio'] = anio == null
        ? const CampoSugerido.pendiente()
        : CampoSugerido(
            valor: anio.group(1)!,
            confianza: NivelConfianza.alta,
            porcentaje: 88,
            fuente: AutoridadFuente.ocr.label,
          );

    // ── Cantidad de páginas ──
    final pags = RegExp(r'(\d{2,4})\s*(?:páginas?|paginas?|pags?\.?|pp\.?)',
            caseSensitive: false)
        .firstMatch(textoOcr);
    campos['paginas'] = pags == null
        ? const CampoSugerido.pendiente()
        : CampoSugerido(
            valor: pags.group(1)!,
            confianza: NivelConfianza.alta,
            porcentaje: 85,
            fuente: AutoridadFuente.ocr.label,
          );

    campos['editorial'] = _detectarEditorial(lineas);
    campos['autor'] = _detectarAutor(lineas);
    campos['titulo'] = _detectarTitulo(lineas, campos['autor']!.valor);

    return FichaSugerida(campos: campos);
  }

  /// Extrae y normaliza un ISBN del texto. Devuelve `null` si no hay ninguno
  /// con longitud válida.
  String? extraerIsbn(String texto) {
    final m = RegExp(
      r'(?:ISBN[-:\s]*(?:13|10)?[-:\s]*)?((?:97[89][\s-]?)?[\d][\d\s-]{8,}[\dXx])',
      caseSensitive: false,
    ).firstMatch(texto);
    if (m == null) return null;
    final limpio = m.group(1)!.replaceAll(RegExp(r'[\s-]'), '').toUpperCase();
    if (limpio.length != 10 && limpio.length != 13) return null;
    return limpio;
  }

  CampoSugerido _detectarEditorial(List<String> lineas) {
    for (final linea in lineas) {
      final ll = linea.toLowerCase();
      for (final ed in _editorialesConocidas) {
        if (ll.contains(ed)) {
          return CampoSugerido(
            valor: _capitalizar(ed),
            confianza: NivelConfianza.media,
            porcentaje: 82,
            fuente: AutoridadFuente.ocr.label,
          );
        }
      }
    }

    // Patrones "© 2001 Editorial X" o "Publicado por X".
    for (final linea in lineas) {
      final m = RegExp(r'©\s*\d{4}\s+(.+)').firstMatch(linea) ??
          RegExp(r'(?:Publicado|Published)\s+(?:por|by)\s+(.+)',
                  caseSensitive: false)
              .firstMatch(linea);
      if (m != null) {
        final v = m.group(1)!.trim();
        return CampoSugerido(
          valor: v.length > 50 ? v.substring(0, 50) : v,
          confianza: NivelConfianza.media,
          porcentaje: 72,
          fuente: AutoridadFuente.ocr.label,
        );
      }
    }

    return const CampoSugerido.pendiente();
  }

  CampoSugerido _detectarAutor(List<String> lineas) {
    final patron = RegExp(
        r'^([A-ZÁÉÍÓÚÜÑ][a-záéíóúüñ]+(?:\s+(?:de|del|la|van|von)\s+)?(?:\s*[A-ZÁÉÍÓÚÜÑ][a-záéíóúüñ]+){1,3})$');
    for (final linea in lineas.take(8)) {
      if (linea.contains(RegExp(r'\d'))) continue;
      if (linea.length >= 60) continue;
      if (patron.hasMatch(linea)) {
        return CampoSugerido(
          valor: linea,
          confianza: NivelConfianza.media,
          porcentaje: 75,
          fuente: AutoridadFuente.ocr.label,
        );
      }
    }
    return const CampoSugerido.pendiente();
  }

  CampoSugerido _detectarTitulo(List<String> lineas, String autorDetectado) {
    final candidatos = lineas
        .take(5)
        .where((l) =>
            l.length > 3 &&
            l.length < 120 &&
            !l.startsWith(RegExp(r'\d')) &&
            l != autorDetectado)
        .toList();
    if (candidatos.isEmpty) return const CampoSugerido.pendiente();

    return CampoSugerido(
      valor: candidatos.first,
      // Baja a propósito: el título por OCR es el campo menos confiable y la
      // spec v2 §4.2 exige que quede marcado para revisión humana.
      confianza: NivelConfianza.baja,
      porcentaje: 60,
      fuente: AutoridadFuente.ocr.label,
    );
  }

  /// Fusiona la ficha del OCR con lo que devolvieron las fuentes externas.
  ///
  /// Implementa la Regla de Resolución de Fuentes Externas (spec v2 §4.2):
  ///
  /// - Sin resultados para el campo → queda `pendiente` de carga manual.
  /// - Dos fuentes que coinciden → confianza alta.
  /// - Dos fuentes que discrepan → gana la de mayor autoridad editorial.
  /// - Discrepancia entre fuentes de igual autoridad → se marca
  ///   `enConflicto` y se le presentan ambas opciones al bibliotecario.
  ///
  /// Nunca completa un campo con un dato de baja confianza sin marcarlo.
  FichaSugerida resolverFuentes({
    required FichaSugerida fichaOcr,
    required List<Map<String, DatoDeFuente>> resultadosExternos,
  }) {
    final campos = <String, CampoSugerido>{...fichaOcr.campos};
    final nombres = <String>{
      ...fichaOcr.campos.keys,
      for (final r in resultadosExternos) ...r.keys,
    };

    for (final nombre in nombres) {
      final propuestas = <DatoDeFuente>[
        for (final r in resultadosExternos)
          if (r[nombre] != null && r[nombre]!.valor.trim().isNotEmpty)
            r[nombre]!,
      ];

      if (propuestas.isEmpty) {
        // Ninguna fuente externa aportó. Si el OCR tampoco, queda pendiente.
        final delOcr = fichaOcr.campos[nombre];
        campos[nombre] = (delOcr == null || delOcr.valor.trim().isEmpty)
            ? const CampoSugerido.pendiente()
            : delOcr;
        continue;
      }

      final distintos =
          propuestas.map((p) => p.valor.trim().toLowerCase()).toSet();

      if (distintos.length == 1) {
        // Todas las fuentes coinciden.
        final mejor =
            propuestas.reduce((a, b) => a.fuente.peso >= b.fuente.peso ? a : b);
        campos[nombre] = CampoSugerido(
          valor: mejor.valor.trim(),
          confianza: NivelConfianza.alta,
          porcentaje: propuestas.length > 1 ? 98 : 92,
          fuente: mejor.nombreFuente,
        );
        continue;
      }

      // Hay discrepancia: buscar desempate por autoridad editorial.
      final pesoMax =
          propuestas.map((p) => p.fuente.peso).reduce((a, b) => a > b ? a : b);
      final top = propuestas.where((p) => p.fuente.peso == pesoMax).toList();
      final valoresTop = top.map((p) => p.valor.trim().toLowerCase()).toSet();

      if (top.length == 1 || valoresTop.length == 1) {
        // Una fuente tiene más autoridad y desempata.
        campos[nombre] = CampoSugerido(
          valor: top.first.valor.trim(),
          confianza: NivelConfianza.media,
          porcentaje: 80,
          fuente: top.first.nombreFuente,
          alternativas: propuestas,
        );
      } else {
        // Empate de autoridad con valores distintos: decide una persona.
        campos[nombre] = CampoSugerido(
          valor: '',
          confianza: NivelConfianza.enConflicto,
          porcentaje: 0,
          fuente: null,
          alternativas: propuestas,
        );
      }
    }

    return FichaSugerida(campos: campos);
  }

  static String _capitalizar(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}
