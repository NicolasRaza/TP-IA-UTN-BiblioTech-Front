import 'package:equatable/equatable.dart';

/// Confianza de un campo sugerido por el Agente Analizador.
///
/// La spec v2 §4.2 exige que ningún campo de baja confianza se complete sin
/// quedar marcado como tal, y que un ISBN sin resultados quede `pendiente`.
enum NivelConfianza {
  alta('alta'),
  media('media'),
  baja('baja'),

  /// Sin dato: ninguna fuente externa respondió. Requiere carga manual.
  pendiente('pendiente'),

  /// Dos fuentes discrepan y ninguna tiene autoridad suficiente para desempatar.
  enConflicto('en_conflicto');

  const NivelConfianza(this.code);
  final String code;

  static NivelConfianza fromPorcentaje(int pct) {
    if (pct >= 85) return NivelConfianza.alta;
    if (pct >= 65) return NivelConfianza.media;
    return NivelConfianza.baja;
  }

  /// Un campo necesita intervención explícita del bibliotecario.
  bool get requiereRevision =>
      this == NivelConfianza.baja ||
      this == NivelConfianza.pendiente ||
      this == NivelConfianza.enConflicto;
}

/// Autoridad editorial de una fuente externa.
///
/// La spec v2 §4.2 pide priorizar la fuente con mayor autoridad editorial
/// ("ISBN agency / editorial oficial por sobre bases colaborativas") cuando
/// dos fuentes discrepan sobre el mismo campo.
enum AutoridadFuente {
  /// Texto extraído del propio libro por OCR.
  ocr('OCR', 0),

  /// Bases colaborativas (Open Library, wikis).
  colaborativa('Base colaborativa', 1),

  /// Catálogo de la editorial o agencia de ISBN.
  editorialOficial('Editorial / agencia ISBN', 2);

  const AutoridadFuente(this.label, this.peso);
  final String label;
  final int peso;
}

/// Un valor propuesto para un campo, con su origen.
class DatoDeFuente extends Equatable {
  const DatoDeFuente({
    required this.valor,
    required this.fuente,
    required this.nombreFuente,
  });

  final String valor;
  final AutoridadFuente fuente;
  final String nombreFuente;

  @override
  List<Object?> get props => [valor, fuente, nombreFuente];
}

/// Campo de la ficha con su nivel de confianza y trazabilidad de origen.
class CampoSugerido extends Equatable {
  const CampoSugerido({
    required this.valor,
    required this.confianza,
    this.porcentaje = 0,
    this.fuente,
    this.alternativas = const [],
  });

  /// Campo sin resolver: ninguna fuente respondió (spec v2 §4.2).
  const CampoSugerido.pendiente()
      : valor = '',
        confianza = NivelConfianza.pendiente,
        porcentaje = 0,
        fuente = null,
        alternativas = const [];

  final String valor;
  final NivelConfianza confianza;
  final int porcentaje;

  /// Nombre legible de la fuente que aportó el valor.
  final String? fuente;

  /// Valores alternativos cuando hay discrepancia sin desempate claro.
  /// El bibliotecario elige cuál queda.
  final List<DatoDeFuente> alternativas;

  bool get requiereRevision => confianza.requiereRevision;
  bool get tieneConflicto => confianza == NivelConfianza.enConflicto;

  CampoSugerido copyWith({
    String? valor,
    NivelConfianza? confianza,
    int? porcentaje,
    String? fuente,
  }) =>
      CampoSugerido(
        valor: valor ?? this.valor,
        confianza: confianza ?? this.confianza,
        porcentaje: porcentaje ?? this.porcentaje,
        fuente: fuente ?? this.fuente,
        alternativas: alternativas,
      );

  @override
  List<Object?> get props =>
      [valor, confianza, porcentaje, fuente, alternativas];
}

/// Ficha propuesta por el agente, previa a la validación del bibliotecario.
class FichaSugerida extends Equatable {
  const FichaSugerida({required this.campos});

  final Map<String, CampoSugerido> campos;

  CampoSugerido campo(String nombre) =>
      campos[nombre] ?? const CampoSugerido.pendiente();

  /// Campos que ninguna fuente pudo completar y quedan para carga manual.
  List<String> get camposPendientes => campos.entries
      .where((e) => e.value.confianza == NivelConfianza.pendiente)
      .map((e) => e.key)
      .toList();

  /// Campos donde dos fuentes discrepan y hace falta que decida una persona.
  List<String> get camposEnConflicto => campos.entries
      .where((e) => e.value.tieneConflicto)
      .map((e) => e.key)
      .toList();

  /// Campos que el bibliotecario debería mirar antes de aprobar.
  List<String> get camposARevisar => campos.entries
      .where((e) => e.value.requiereRevision)
      .map((e) => e.key)
      .toList();

  @override
  List<Object?> get props => [campos];
}
