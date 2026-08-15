import '../../../catalogo/domain/entities/libro.dart';
import '../entities/recomendacion.dart';

/// Conversión de una recomendación en una reserva concreta.
class ConversionRecomendacion {
  const ConversionRecomendacion({
    required this.libroId,
    required this.titulo,
    required this.conversiones,
  });

  final String libroId;
  final String titulo;
  final int conversiones;
}

/// Efectividad medida de las recomendaciones.
class EfectividadRecomendaciones {
  const EfectividadRecomendaciones({
    required this.masEfectivas,
    required this.totalInteracciones,
    required this.tasaConversion,
  });

  final List<ConversionRecomendacion> masEfectivas;
  final int totalInteracciones;
  final double tasaConversion;
}

/// Reporte consolidado para el panel de administración.
class ReporteAprendizaje {
  const ReporteAprendizaje({
    required this.resumen,
    required this.patrones,
    required this.mejora,
    required this.tasaConversion,
    required this.totalCorrecciones,
  });

  final String resumen;
  final List<PatronCorreccion> patrones;
  final double mejora;
  final double tasaConversion;
  final int totalCorrecciones;
}

/// Agente 5 — Aprendizaje continuo (spec v2 §5).
///
/// Cierra el ciclo: mira qué corrigió el bibliotecario sobre las sugerencias
/// de catalogación y qué recomendaciones aceptaron los lectores, para refinar
/// el criterio del próximo ciclo.
///
/// Igual que el Evaluador, es puro: recibe las listas ya leídas y devuelve el
/// análisis.
class AgenteAprendizaje {
  const AgenteAprendizaje();

  /// Tope de mejora estimada que se le atribuye al aprendizaje, en puntos.
  static const topeMejora = 40;

  /// Analiza el historial de correcciones sobre los datos sugeridos.
  ///
  /// Los campos que se corrigen seguido son los que peor está resolviendo el
  /// reconocimiento automático.
  InformeAprendizaje analizarCorrecciones(List<Correccion> correcciones) {
    if (correcciones.isEmpty) {
      return const InformeAprendizaje(
        patrones: [],
        totalCorrecciones: 0,
        mejora: 0,
      );
    }

    final porCampo = <String, int>{};
    for (final c in correcciones) {
      final campo = c.campo.isEmpty ? 'desconocido' : c.campo;
      porCampo.update(campo, (n) => n + 1, ifAbsent: () => 1);
    }

    final patrones = porCampo.entries
        .map((e) => PatronCorreccion(
              campo: e.key,
              correcciones: e.value,
              sugerencia: 'El campo "${e.key}" se corrigió ${e.value} '
                  '${e.value == 1 ? 'vez' : 'veces'}. Conviene bajar su '
                  'confianza inicial y pedir revisión explícita.',
            ))
        .toList()
      ..sort((a, b) => b.correcciones.compareTo(a.correcciones));

    // Estimación de mejora del modelo: cada corrección aporta señal, con
    // rendimientos decrecientes y un tope.
    final mejora = (correcciones.length * 2).clamp(0, topeMejora).toDouble();

    return InformeAprendizaje(
      patrones: patrones,
      totalCorrecciones: correcciones.length,
      mejora: mejora,
    );
  }

  /// Analiza qué recomendaciones terminaron en una reserva concreta.
  EfectividadRecomendaciones analizarRecomendaciones({
    required List<InteraccionLector> interacciones,
    required List<Libro> libros,
  }) {
    final titulos = {for (final l in libros) l.id: l.titulo};
    final reservas =
        interacciones.where((i) => i.tipo == 'reserva').toList();

    final porLibro = <String, int>{};
    for (final i in reservas) {
      if (i.libroId.isEmpty) continue;
      porLibro.update(i.libroId, (n) => n + 1, ifAbsent: () => 1);
    }

    final masEfectivas = porLibro.entries
        .map((e) => ConversionRecomendacion(
              libroId: e.key,
              titulo: titulos[e.key] ?? e.key,
              conversiones: e.value,
            ))
        .toList()
      ..sort((a, b) => b.conversiones.compareTo(a.conversiones));

    return EfectividadRecomendaciones(
      masEfectivas: masEfectivas.take(5).toList(),
      totalInteracciones: interacciones.length,
      tasaConversion: interacciones.isEmpty
          ? 0
          : reservas.length * 100 / interacciones.length,
    );
  }

  /// Reporte consolidado para el panel de administración.
  ReporteAprendizaje generarReporte({
    required List<Correccion> correcciones,
    required List<InteraccionLector> interacciones,
    required List<Libro> libros,
  }) {
    final ocr = analizarCorrecciones(correcciones);
    final reco = analizarRecomendaciones(
      interacciones: interacciones,
      libros: libros,
    );

    return ReporteAprendizaje(
      resumen: 'Se registraron ${ocr.totalCorrecciones} correcciones sobre '
          'las fichas sugeridas y ${reco.totalInteracciones} interacciones '
          'con recomendaciones. Mejora estimada del reconocimiento: '
          '${ocr.mejora.toStringAsFixed(0)}%.',
      patrones: ocr.patrones,
      mejora: ocr.mejora,
      tasaConversion: reco.tasaConversion,
      totalCorrecciones: ocr.totalCorrecciones,
    );
  }
}
