import '../data/repositorio.dart';
import '../domain/enums.dart';
import '../domain/models.dart';
import 'decisiones.dart';

/// Libro recomendado junto con la explicación de por qué se recomendó.
class Recomendacion {
  const Recomendacion({
    required this.libro,
    required this.puntaje,
    required this.motivo,
    required this.esColdStart,
  });

  final Libro libro;
  final double puntaje;
  final String motivo;

  /// `true` cuando la recomendación se basó solo en popularidad general por
  /// no haber historial suficiente del lector.
  final bool esColdStart;
}

/// Agente 4 — Evaluador (spec v2 §4.3, §5).
///
/// Monitorea el estado del sistema y **decide** qué corresponde hacer, sin
/// ejecutar nada: devuelve una lista de [Decision] que el Agente Planificador
/// se encarga de llevar a cabo. También produce las recomendaciones de lectura
/// y los indicadores de negocio.
class AgenteEvaluador {
  const AgenteEvaluador(this.repo);

  final Repositorio repo;

  // ─────────────────────────────── Decisiones ───────────────────────────────

  /// Recorre el estado del sistema y decide las acciones que corresponden.
  ///
  /// No modifica nada: es una función de lectura sobre el repositorio.
  List<Decision> decidir() {
    final decisiones = <Decision>[];
    final ahora = repo.ahora;
    final cfg = repo.config;

    for (final p in repo.prestamos.where((p) => p.estaAbierto)) {
      final libro = repo.libro(p.libroId);
      final lector = repo.lector(p.lectorId);
      if (libro == null || lector == null) continue;

      if (ahora.isAfter(p.fechaVencimiento)) {
        final diasAtraso = ahora.difference(p.fechaVencimiento).inDays;
        decisiones.add(Decision(
          tipo: TipoDecision.notificarPrestamoVencido,
          motivo:
              'El préstamo de "${libro.titulo}" venció hace $diasAtraso ${diasAtraso == 1 ? 'día' : 'días'}: corresponde notificar al lector.',
          prestamo: p,
          libro: libro,
          lector: lector,
          dias: diasAtraso,
        ));
      } else {
        final faltan = p.fechaVencimiento.difference(ahora).inDays;
        if (faltan <= cfg.recordatorioAntesDias) {
          decisiones.add(Decision(
            tipo: TipoDecision.notificarVencimientoProximo,
            motivo:
                'El préstamo de "${libro.titulo}" vence en $faltan ${faltan == 1 ? 'día' : 'días'}: corresponde recordar la devolución.',
            prestamo: p,
            libro: libro,
            lector: lector,
            dias: faltan,
          ));
        }
      }
    }

    for (final r in repo.reservas.where((r) => r.estado == EstadoReserva.lista)) {
      final limite = r.fechaVencimientoRetiro;
      if (limite == null || !ahora.isAfter(limite)) continue;
      final libro = repo.libro(r.libroId);
      decisiones.add(Decision(
        tipo: TipoDecision.liberarReservaNoRetirada,
        motivo:
            'La reserva de "${libro?.titulo ?? r.libroId}" superó las ${r.plazoRetiroHorasAlReservar} hs de retención sin retirarse: corresponde liberarla y pasar al siguiente de la cola.',
        reserva: r,
        libro: libro,
        lector: repo.lector(r.lectorId),
      ));
    }

    // Títulos con ejemplar libre y gente esperando en la cola.
    for (final libro in repo.catalogoPublico) {
      if (!libro.hayDisponible) continue;
      final cola = repo.colaDeReservas(libro.id);
      if (cola.isEmpty) continue;
      if (cola.any((r) => r.estado == EstadoReserva.lista)) continue;
      decisiones.add(Decision(
        tipo: TipoDecision.asignarReservaAlSiguiente,
        motivo:
            'Hay un ejemplar disponible de "${libro.titulo}" y ${cola.length} ${cola.length == 1 ? 'lector esperando' : 'lectores esperando'}: corresponde asignarlo al primero de la cola.',
        libro: libro,
        reserva: cola.first,
        lector: repo.lector(cola.first.lectorId),
      ));
    }

    for (final l in repo.lectores.where((l) => l.multasPendientes > 0)) {
      decisiones.add(Decision(
        tipo: TipoDecision.alertarMultaPendiente,
        motivo:
            '${l.nombreCompleto} tiene \$${l.multasPendientes} de multa impaga: queda bloqueado para nuevos préstamos y reservas.',
        lector: l,
      ));
    }

    for (final l in repo.lectoresConCategoriaDesactualizada()) {
      final sugerida = repo.categoriaPorEdad(l.fechaNacimiento!);
      decisiones.add(Decision(
        tipo: TipoDecision.sugerirRevisionCategoria,
        motivo:
            '${l.nombreCompleto} figura como ${l.categoria.label} pero por su edad corresponde ${sugerida.label}. Los préstamos vigentes conservan sus condiciones actuales.',
        lector: l,
      ));
    }

    return decisiones;
  }

  /// Resumen de decisiones agrupadas, para el dashboard del bibliotecario.
  ({int vencidos, int proximos, int reservasPorLiberar, int multas})
      resumen() {
    final d = decidir();
    return (
      vencidos: d
          .where((x) => x.tipo == TipoDecision.notificarPrestamoVencido)
          .length,
      proximos: d
          .where((x) => x.tipo == TipoDecision.notificarVencimientoProximo)
          .length,
      reservasPorLiberar: d
          .where((x) => x.tipo == TipoDecision.liberarReservaNoRetirada)
          .length,
      multas:
          d.where((x) => x.tipo == TipoDecision.alertarMultaPendiente).length,
    );
  }

  // ──────────────────────────── Recomendaciones ────────────────────────────

  /// Recomienda libros combinando historial personal y popularidad general.
  ///
  /// Regla de Ponderación (spec v2 §2): por defecto 70% historial personal /
  /// 30% popularidad general. Para lectores sin historial suficiente
  /// ("cold start"), el peso se invierte automáticamente a 100% popularidad
  /// hasta que acumulen datos propios.
  List<Recomendacion> recomendarPara(String lectorId, {int limite = 8}) {
    final lector = repo.lector(lectorId);
    if (lector == null) return [];

    final cfg = repo.config;
    final prestamosDelLector = repo.prestamosDeLector(lectorId);
    final reservasDelLector = repo.reservasDeLector(lectorId);

    final esColdStart =
        prestamosDelLector.length < cfg.minPrestamosParaHistorial;

    // Cold start: 100% popularidad. Con historial: 70/30 configurable.
    final pesoHistorial = esColdStart ? 0.0 : cfg.pesoHistorialRecomendacion;
    final pesoPopularidad = esColdStart ? 1.0 : cfg.pesoPopularidadRecomendacion;

    final excluidos = {
      ...prestamosDelLector.map((p) => p.libroId),
      ...reservasDelLector.where((r) => r.esActiva).map((r) => r.libroId),
    };

    final leidos = prestamosDelLector
        .map((p) => repo.libro(p.libroId))
        .whereType<Libro>()
        .toList();
    final autoresLeidos =
        leidos.map((l) => l.autor.toLowerCase()).where((a) => a.isNotEmpty).toSet();
    final generosLeidos =
        leidos.map((l) => l.genero).where((g) => g.isNotEmpty).toSet();
    final generosInteres = lector.generosInteres.toSet();

    final todosPrestamos = repo.prestamos;
    final maxPrestamos = todosPrestamos.isEmpty
        ? 1
        : _maxPrestamosPorLibro(todosPrestamos);

    final candidatos =
        repo.catalogoPublico.where((l) => !excluidos.contains(l.id)).toList();

    final recomendaciones = <Recomendacion>[];
    for (final libro in candidatos) {
      // ── Señal 1: afinidad con el historial del lector (0..1) ──
      var afinidad = 0.0;
      final razones = <String>[];

      if (autoresLeidos.contains(libro.autor.toLowerCase())) {
        afinidad += 0.5;
        razones.add('ya leíste a ${libro.autor}');
      }
      if (generosLeidos.contains(libro.genero)) {
        afinidad += 0.3;
        razones.add('leés ${libro.genero}');
      }
      if (generosInteres.contains(libro.genero)) {
        afinidad += 0.2;
        razones.add('${libro.genero} está entre tus intereses');
      }
      if (afinidad > 1) afinidad = 1;

      // ── Señal 2: popularidad general (0..1) ──
      final prestamosDelLibro =
          todosPrestamos.where((p) => p.libroId == libro.id).length;
      final popularidad = maxPrestamos == 0
          ? 0.0
          : (prestamosDelLibro / maxPrestamos).clamp(0.0, 1.0);

      var puntaje = afinidad * pesoHistorial + popularidad * pesoPopularidad;

      // Pequeño empujón a lo que se puede retirar hoy mismo.
      if (libro.hayDisponible) puntaje += 0.05;

      final motivo = esColdStart
          ? (prestamosDelLibro > 0
              ? 'Entre los más prestados de la biblioteca'
              : 'Nuevo en el catálogo')
          : (razones.isEmpty
              ? 'Popular entre los lectores'
              : 'Porque ${razones.join(' y ')}');

      recomendaciones.add(Recomendacion(
        libro: libro,
        puntaje: puntaje,
        motivo: motivo,
        esColdStart: esColdStart,
      ));
    }

    recomendaciones.sort((a, b) {
      final c = b.puntaje.compareTo(a.puntaje);
      // Desempate estable por título, para que el orden sea reproducible.
      return c != 0 ? c : a.libro.titulo.compareTo(b.libro.titulo);
    });
    return recomendaciones.take(limite).toList();
  }

  static int _maxPrestamosPorLibro(List<Prestamo> prestamos) {
    final conteo = <String, int>{};
    for (final p in prestamos) {
      conteo[p.libroId] = (conteo[p.libroId] ?? 0) + 1;
    }
    if (conteo.isEmpty) return 1;
    return conteo.values.reduce((a, b) => a > b ? a : b);
  }

  // ────────────────────────────── Indicadores ──────────────────────────────

  /// Indicadores de negocio para el dashboard (spec v2 §6).
  ({
    List<({Libro libro, int prestamos})> topLibros,
    List<({Lector lector, int prestamos})> topLectores,
    List<({String genero, int prestamos})> topGeneros,
    List<({String mes, int total, int tardios})> porMes,
  }) calcularIndicadores() {
    final prestamos = repo.prestamos;

    final porLibro = <String, int>{};
    final porLector = <String, int>{};
    final porGenero = <String, int>{};
    for (final p in prestamos) {
      porLibro[p.libroId] = (porLibro[p.libroId] ?? 0) + 1;
      porLector[p.lectorId] = (porLector[p.lectorId] ?? 0) + 1;
      final g = repo.libro(p.libroId)?.genero;
      if (g != null && g.isNotEmpty) {
        porGenero[g] = (porGenero[g] ?? 0) + 1;
      }
    }

    final topLibros = porLibro.entries
        .map((e) => (libro: repo.libro(e.key), prestamos: e.value))
        .where((e) => e.libro != null)
        .map((e) => (libro: e.libro!, prestamos: e.prestamos))
        .toList()
      ..sort((a, b) => b.prestamos.compareTo(a.prestamos));

    final topLectores = porLector.entries
        .map((e) => (lector: repo.lector(e.key), prestamos: e.value))
        .where((e) => e.lector != null)
        .map((e) => (lector: e.lector!, prestamos: e.prestamos))
        .toList()
      ..sort((a, b) => b.prestamos.compareTo(a.prestamos));

    final topGeneros = porGenero.entries
        .map((e) => (genero: e.key, prestamos: e.value))
        .toList()
      ..sort((a, b) => b.prestamos.compareTo(a.prestamos));

    const nombresMes = [
      'ene', 'feb', 'mar', 'abr', 'may', 'jun',
      'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
    ];
    final porMes = <({String mes, int total, int tardios})>[];
    final ahora = repo.ahora;
    for (var i = 5; i >= 0; i--) {
      final d = DateTime(ahora.year, ahora.month - i, 1);
      final delMes = prestamos.where((p) =>
          p.fechaPrestamo.year == d.year && p.fechaPrestamo.month == d.month);
      porMes.add((
        mes: nombresMes[d.month - 1],
        total: delMes.length,
        tardios: delMes.where((p) => p.tardio).length,
      ));
    }

    return (
      topLibros: topLibros.take(5).toList(),
      topLectores: topLectores.take(5).toList(),
      topGeneros: topGeneros.take(6).toList(),
      porMes: porMes,
    );
  }

  /// Sugerencias estratégicas para la biblioteca (spec v2 §2).
  List<({String tipo, String texto})> generarSugerencias() {
    final sugerencias = <({String tipo, String texto})>[];
    final ind = calcularIndicadores();

    for (final t in ind.topLibros) {
      if (t.prestamos >= 3 && !t.libro.hayDisponible) {
        sugerencias.add((
          tipo: 'compra',
          texto:
              '"${t.libro.titulo}" tiene alta demanda (${t.prestamos} préstamos) y ningún ejemplar disponible. Conviene sumar ejemplares.',
        ));
      }
    }

    final prestados = repo.prestamos.map((p) => p.libroId).toSet();
    final nuncaPrestados =
        repo.catalogoPublico.where((l) => !prestados.contains(l.id)).length;
    if (nuncaPrestados > 0) {
      sugerencias.add((
        tipo: 'promocion',
        texto:
            '$nuncaPrestados ${nuncaPrestados == 1 ? 'libro nunca fue prestado' : 'libros nunca fueron prestados'}. Se podrían promocionar o evaluar para baja.',
      ));
    }

    final stats = repo.estadisticasPrestamos();
    if (stats.tasaTardia > 20) {
      sugerencias.add((
        tipo: 'politica',
        texto:
            'La tasa de devoluciones tardías es del ${stats.tasaTardia.toStringAsFixed(1)}%. Conviene revisar los plazos o reforzar los recordatorios.',
      ));
    }

    final colasLargas = repo.catalogoPublico
        .map((l) => (libro: l, cola: repo.colaDeReservas(l.id).length))
        .where((e) => e.cola >= 2)
        .toList();
    for (final c in colasLargas) {
      sugerencias.add((
        tipo: 'compra',
        texto:
            '"${c.libro.titulo}" tiene ${c.cola} lectores en lista de espera. Conviene reforzar el stock.',
      ));
    }

    return sugerencias;
  }
}
