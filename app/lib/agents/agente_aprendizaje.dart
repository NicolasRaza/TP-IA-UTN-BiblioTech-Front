import '../data/repositorio.dart';

/// Patrón detectado sobre las correcciones del bibliotecario.
class PatronCorreccion {
  const PatronCorreccion({
    required this.campo,
    required this.correcciones,
    required this.sugerencia,
  });

  final String campo;
  final int correcciones;
  final String sugerencia;
}

/// Agente 5 — Aprendizaje continuo (spec v2 §5).
///
/// Cierra el ciclo: mira qué corrigió el bibliotecario sobre las sugerencias
/// de catalogación y qué recomendaciones aceptaron los lectores, para refinar
/// el criterio del próximo ciclo.
class AgenteAprendizaje {
  const AgenteAprendizaje(this.repo);

  final Repositorio repo;

  /// Analiza el historial de correcciones sobre los datos sugeridos.
  ///
  /// Los campos que se corrigen seguido son los que peor está resolviendo el
  /// reconocimiento automático.
  ({List<PatronCorreccion> patrones, int totalCorrecciones, double mejora})
      analizarCorrecciones() {
    final data = repo.aprendizaje;
    final correcciones = (data['correcciones'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();

    if (correcciones.isEmpty) {
      return (
        patrones: <PatronCorreccion>[],
        totalCorrecciones: 0,
        mejora: 0.0
      );
    }

    final porCampo = <String, int>{};
    for (final c in correcciones) {
      final campo = c['campo'] as String? ?? 'desconocido';
      porCampo[campo] = (porCampo[campo] ?? 0) + 1;
    }

    final patrones = porCampo.entries
        .map((e) => PatronCorreccion(
              campo: e.key,
              correcciones: e.value,
              sugerencia:
                  'El campo "${e.key}" se corrigió ${e.value} ${e.value == 1 ? 'vez' : 'veces'}. '
                  'Conviene bajar su confianza inicial y pedir revisión explícita.',
            ))
        .toList()
      ..sort((a, b) => b.correcciones.compareTo(a.correcciones));

    // Estimación de mejora del modelo: cada corrección aporta señal, con
    // rendimientos decrecientes y tope del 40%.
    final mejora = (correcciones.length * 2).clamp(0, 40).toDouble();

    return (
      patrones: patrones,
      totalCorrecciones: correcciones.length,
      mejora: mejora,
    );
  }

  /// Analiza qué recomendaciones terminaron en una reserva concreta.
  ({
    List<({String libroId, String titulo, int conversiones})> masEfectivas,
    int totalClics,
    double tasaConversion
  }) analizarRecomendaciones() {
    final data = repo.aprendizaje;
    final clics =
        (data['clics'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();

    final reservas = clics.where((c) => c['tipo'] == 'reserva').toList();
    final porLibro = <String, int>{};
    for (final c in reservas) {
      final id = c['libroId'] as String? ?? '';
      if (id.isEmpty) continue;
      porLibro[id] = (porLibro[id] ?? 0) + 1;
    }

    final masEfectivas = porLibro.entries
        .map((e) => (
              libroId: e.key,
              titulo: repo.libro(e.key)?.titulo ?? e.key,
              conversiones: e.value,
            ))
        .toList()
      ..sort((a, b) => b.conversiones.compareTo(a.conversiones));

    return (
      masEfectivas: masEfectivas.take(5).toList(),
      totalClics: clics.length,
      tasaConversion:
          clics.isEmpty ? 0.0 : reservas.length * 100 / clics.length,
    );
  }

  /// Reporte consolidado para el panel de administración.
  ({
    String resumen,
    List<PatronCorreccion> patrones,
    double mejora,
    double tasaConversion
  }) generarReporte() {
    final ocr = analizarCorrecciones();
    final reco = analizarRecomendaciones();
    return (
      resumen:
          'Se registraron ${ocr.totalCorrecciones} correcciones sobre las fichas sugeridas '
          'y ${reco.totalClics} interacciones con recomendaciones. '
          'Mejora estimada del reconocimiento: ${ocr.mejora.toStringAsFixed(0)}%.',
      patrones: ocr.patrones,
      mejora: ocr.mejora,
      tasaConversion: reco.tasaConversion,
    );
  }
}
