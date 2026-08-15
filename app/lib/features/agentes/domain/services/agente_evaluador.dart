import '../../../catalogo/domain/entities/libro.dart';
import '../../../lectores/domain/entities/lector.dart';
import '../../../lectores/domain/services/politica_de_categoria.dart';
import '../../../prestamos/domain/entities/prestamo.dart';
import '../entities/decision.dart';
import '../entities/estado_del_sistema.dart';
import '../entities/recomendacion.dart';

/// Agente 4 — Evaluador (spec v2 §4.3, §5).
///
/// Monitorea el estado del sistema y **decide** qué corresponde hacer, sin
/// ejecutar nada: devuelve una lista de [Decision] que el Agente Planificador
/// lleva a cabo. También produce las recomendaciones de lectura y los
/// indicadores de negocio.
///
/// Es una clase **pura**: no recibe repositorios ni reloj, sólo el
/// [EstadoDelSistema] que armó el [ObservadorDelSistema]. Por construcción no
/// puede modificar nada, que es exactamente la garantía que la spec pide de
/// este agente.
class AgenteEvaluador {
  const AgenteEvaluador({
    PoliticaDeCategoria politicaDeCategoria = const PoliticaDeCategoria(),
  }) : _politicaDeCategoria = politicaDeCategoria;

  final PoliticaDeCategoria _politicaDeCategoria;

  // ─────────────────────────────── Decisiones ───────────────────────────────

  /// Recorre el estado del sistema y decide las acciones que corresponden.
  List<Decision> decidir(EstadoDelSistema estado) => [
        ..._decidirSobrePrestamos(estado),
        ..._decidirSobreReservasCaidas(estado),
        ..._decidirSobreColasConStock(estado),
        ..._decidirSobreMultas(estado),
        ..._decidirSobreCategorias(estado),
      ];

  Iterable<Decision> _decidirSobrePrestamos(EstadoDelSistema estado) sync* {
    for (final p in estado.prestamosAbiertos) {
      final libro = estado.libro(p.libroId);
      final lector = estado.lector(p.lectorId);
      if (libro == null || lector == null) continue;

      if (estado.momento.isAfter(p.fechaVencimiento)) {
        final atraso = estado.momento.difference(p.fechaVencimiento).inDays;
        yield Decision(
          tipo: TipoDecision.notificarPrestamoVencido,
          motivo: 'El préstamo de "${libro.titulo}" venció hace $atraso '
              '${atraso == 1 ? 'día' : 'días'}: corresponde notificar al '
              'lector.',
          prestamo: p,
          libro: libro,
          lector: lector,
          dias: atraso,
        );
      } else {
        final faltan = p.fechaVencimiento.difference(estado.momento).inDays;
        if (faltan > estado.configuracion.recordatorioAntesDias) continue;
        yield Decision(
          tipo: TipoDecision.notificarVencimientoProximo,
          motivo: 'El préstamo de "${libro.titulo}" vence en $faltan '
              '${faltan == 1 ? 'día' : 'días'}: corresponde recordar la '
              'devolución.',
          prestamo: p,
          libro: libro,
          lector: lector,
          dias: faltan,
        );
      }
    }
  }

  Iterable<Decision> _decidirSobreReservasCaidas(
      EstadoDelSistema estado) sync* {
    for (final r in estado.reservas) {
      if (!r.venceRetiroA(estado.momento)) continue;
      final libro = estado.libro(r.libroId);
      yield Decision(
        tipo: TipoDecision.liberarReservaNoRetirada,
        motivo: 'La reserva de "${libro?.titulo ?? r.libroId}" superó las '
            '${r.plazoRetiroHorasAlReservar} hs de retención sin retirarse: '
            'corresponde liberarla y pasar al siguiente de la cola.',
        reserva: r,
        libro: libro,
        lector: estado.lector(r.lectorId),
      );
    }
  }

  /// Títulos con ejemplar libre y gente esperando en la cola.
  Iterable<Decision> _decidirSobreColasConStock(
      EstadoDelSistema estado) sync* {
    for (final libro in estado.catalogoPublico) {
      if (!libro.hayDisponible) continue;
      final cola = estado.colaDe(libro.id);
      if (cola.isEmpty) continue;
      // Si ya hay una retenida, el ejemplar está comprometido.
      if (cola.any((r) => r.estaRetenida)) continue;

      yield Decision(
        tipo: TipoDecision.asignarReservaAlSiguiente,
        motivo: 'Hay un ejemplar disponible de "${libro.titulo}" y '
            '${cola.length} ${cola.length == 1 ? 'lector esperando' : 'lectores esperando'}: '
            'corresponde asignarlo al primero de la cola.',
        libro: libro,
        reserva: cola.first,
        lector: estado.lector(cola.first.lectorId),
      );
    }
  }

  Iterable<Decision> _decidirSobreMultas(EstadoDelSistema estado) sync* {
    for (final l in estado.lectores.where((l) => l.tieneMultas)) {
      yield Decision(
        tipo: TipoDecision.alertarMultaPendiente,
        motivo: '${l.nombreCompleto} tiene \$${l.multasPendientes} de multa '
            'impaga: queda bloqueado para nuevos préstamos y reservas.',
        lector: l,
      );
    }
  }

  Iterable<Decision> _decidirSobreCategorias(EstadoDelSistema estado) sync* {
    for (final l in estado.lectores) {
      final desactualizada = _politicaDeCategoria.estaDesactualizada(
        lector: l,
        configuracion: estado.configuracion,
        ahora: estado.momento,
      );
      if (!desactualizada) continue;

      final sugerida = _politicaDeCategoria.categoriaPara(
        fechaNacimiento: l.fechaNacimiento!,
        configuracion: estado.configuracion,
        ahora: estado.momento,
      );
      yield Decision(
        tipo: TipoDecision.sugerirRevisionCategoria,
        motivo: '${l.nombreCompleto} figura como ${l.categoria.label} pero '
            'por su edad corresponde ${sugerida.label}. Los préstamos '
            'vigentes conservan sus condiciones actuales.',
        lector: l,
      );
    }
  }

  /// Resumen de decisiones agrupadas, para el dashboard del bibliotecario.
  ResumenDecisiones resumir(List<Decision> decisiones) => ResumenDecisiones(
        vencidos: decisiones
            .where((d) => d.tipo == TipoDecision.notificarPrestamoVencido)
            .length,
        proximos: decisiones
            .where((d) => d.tipo == TipoDecision.notificarVencimientoProximo)
            .length,
        reservasPorLiberar: decisiones
            .where((d) => d.tipo == TipoDecision.liberarReservaNoRetirada)
            .length,
        multas: decisiones
            .where((d) => d.tipo == TipoDecision.alertarMultaPendiente)
            .length,
      );

  // ──────────────────────────── Recomendaciones ────────────────────────────

  /// Recomienda libros combinando historial personal y popularidad general.
  ///
  /// Regla de Ponderación (spec v2 §2): por defecto 70% historial personal /
  /// 30% popularidad general. Para lectores sin historial suficiente
  /// ("cold start") el peso se invierte automáticamente a 100% popularidad,
  /// hasta que acumulen datos propios.
  List<Recomendacion> recomendarPara(
    EstadoDelSistema estado,
    String lectorId, {
    int limite = 8,
  }) {
    final lector = estado.lector(lectorId);
    if (lector == null) return const [];

    final cfg = estado.configuracion;
    final prestamosDelLector = estado.prestamosDe(lectorId);
    final reservasDelLector = estado.reservasDe(lectorId);

    final esColdStart =
        prestamosDelLector.length < cfg.minPrestamosParaHistorial;

    final pesoHistorial = esColdStart ? 0.0 : cfg.pesoHistorialRecomendacion;
    final pesoPopularidad =
        esColdStart ? 1.0 : cfg.pesoPopularidadRecomendacion;

    // No se recomienda lo que ya tiene o ya pidió.
    final excluidos = {
      ...prestamosDelLector.map((p) => p.libroId),
      ...reservasDelLector.where((r) => r.esActiva).map((r) => r.libroId),
    };

    final leidos = prestamosDelLector
        .map((p) => estado.libro(p.libroId))
        .whereType<Libro>()
        .toList();
    final autoresLeidos = leidos
        .map((l) => l.autor.toLowerCase())
        .where((a) => a.isNotEmpty)
        .toSet();
    final generosLeidos =
        leidos.map((l) => l.genero).where((g) => g.isNotEmpty).toSet();
    final generosInteres = lector.generosInteres.toSet();

    final maxPrestamos = _maxPrestamosPorLibro(estado.prestamos);

    final recomendaciones = <Recomendacion>[];
    for (final libro in estado.catalogoPublico) {
      if (excluidos.contains(libro.id)) continue;

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
          estado.prestamos.where((p) => p.libroId == libro.id).length;
      final popularidad = maxPrestamos == 0
          ? 0.0
          : (prestamosDelLibro / maxPrestamos).clamp(0.0, 1.0);

      var puntaje = afinidad * pesoHistorial + popularidad * pesoPopularidad;

      // Pequeño empujón a lo que se puede retirar hoy mismo.
      if (libro.hayDisponible) puntaje += 0.05;

      recomendaciones.add(Recomendacion(
        libro: libro,
        puntaje: puntaje,
        motivo: _motivo(
          esColdStart: esColdStart,
          prestamosDelLibro: prestamosDelLibro,
          razones: razones,
        ),
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

  String _motivo({
    required bool esColdStart,
    required int prestamosDelLibro,
    required List<String> razones,
  }) {
    if (esColdStart) {
      return prestamosDelLibro > 0
          ? 'Entre los más prestados de la biblioteca'
          : 'Nuevo en el catálogo';
    }
    return razones.isEmpty
        ? 'Popular entre los lectores'
        : 'Porque ${razones.join(' y ')}';
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
  Indicadores calcularIndicadores(EstadoDelSistema estado) {
    final porLibro = <String, int>{};
    final porLector = <String, int>{};
    final porGenero = <String, int>{};

    for (final p in estado.prestamos) {
      porLibro.update(p.libroId, (n) => n + 1, ifAbsent: () => 1);
      porLector.update(p.lectorId, (n) => n + 1, ifAbsent: () => 1);
      final genero = estado.libro(p.libroId)?.genero;
      if (genero != null && genero.isNotEmpty) {
        porGenero.update(genero, (n) => n + 1, ifAbsent: () => 1);
      }
    }

    final topLibros = porLibro.entries
        .map((e) => (libro: estado.libro(e.key), prestamos: e.value))
        .where((e) => e.libro != null)
        .map((e) => ConteoLibro(libro: e.libro!, prestamos: e.prestamos))
        .toList()
      ..sort((a, b) => b.prestamos.compareTo(a.prestamos));

    final topLectores = porLector.entries
        .map((e) => (lector: estado.lector(e.key), prestamos: e.value))
        .where((e) => e.lector != null)
        .map((e) => ConteoLector(lector: e.lector!, prestamos: e.prestamos))
        .toList()
      ..sort((a, b) => b.prestamos.compareTo(a.prestamos));

    final topGeneros = porGenero.entries
        .map((e) => ConteoGenero(genero: e.key, prestamos: e.value))
        .toList()
      ..sort((a, b) => b.prestamos.compareTo(a.prestamos));

    return Indicadores(
      topLibros: topLibros.take(5).toList(),
      topLectores: topLectores.take(5).toList(),
      topGeneros: topGeneros.take(6).toList(),
      porMes: _prestamosPorMes(estado),
    );
  }

  List<ConteoMes> _prestamosPorMes(EstadoDelSistema estado) {
    const nombresMes = [
      'ene', 'feb', 'mar', 'abr', 'may', 'jun', //
      'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
    ];

    final porMes = <ConteoMes>[];
    for (var i = 5; i >= 0; i--) {
      final d = DateTime(estado.momento.year, estado.momento.month - i, 1);
      final delMes = estado.prestamos.where((p) =>
          p.fechaPrestamo.year == d.year && p.fechaPrestamo.month == d.month);
      porMes.add(ConteoMes(
        mes: nombresMes[d.month - 1],
        total: delMes.length,
        tardios: delMes.where((p) => p.tardio).length,
      ));
    }
    return porMes;
  }

  /// Sugerencias estratégicas para la biblioteca (spec v2 §2).
  List<Sugerencia> generarSugerencias(EstadoDelSistema estado) {
    final sugerencias = <Sugerencia>[];
    final indicadores = calcularIndicadores(estado);

    for (final t in indicadores.topLibros) {
      if (t.prestamos >= 3 && !t.libro.hayDisponible) {
        sugerencias.add(Sugerencia(
          tipo: TipoSugerencia.compra,
          texto: '"${t.libro.titulo}" tiene alta demanda (${t.prestamos} '
              'préstamos) y ningún ejemplar disponible. Conviene sumar '
              'ejemplares.',
        ));
      }
    }

    final prestados = estado.prestamos.map((p) => p.libroId).toSet();
    final nuncaPrestados =
        estado.catalogoPublico.where((l) => !prestados.contains(l.id)).length;
    if (nuncaPrestados > 0) {
      sugerencias.add(Sugerencia(
        tipo: TipoSugerencia.promocion,
        texto: '$nuncaPrestados ${nuncaPrestados == 1 ? 'libro nunca fue prestado' : 'libros nunca fueron prestados'}. '
            'Se podrían promocionar o evaluar para baja.',
      ));
    }

    final estadisticas = EstadisticasPrestamos.desde(estado.prestamos);
    if (estadisticas.tasaTardia > 20) {
      sugerencias.add(Sugerencia(
        tipo: TipoSugerencia.politica,
        texto: 'La tasa de devoluciones tardías es del '
            '${estadisticas.tasaTardia.toStringAsFixed(1)}%. Conviene revisar '
            'los plazos o reforzar los recordatorios.',
      ));
    }

    for (final libro in estado.catalogoPublico) {
      final cola = estado.colaDe(libro.id).length;
      if (cola < 2) continue;
      sugerencias.add(Sugerencia(
        tipo: TipoSugerencia.compra,
        texto: '"${libro.titulo}" tiene $cola lectores en lista de espera. '
            'Conviene reforzar el stock.',
      ));
    }

    return sugerencias;
  }
}

/// Conteo de decisiones por tipo, para las tarjetas del dashboard.
class ResumenDecisiones {
  const ResumenDecisiones({
    required this.vencidos,
    required this.proximos,
    required this.reservasPorLiberar,
    required this.multas,
  });

  final int vencidos;
  final int proximos;
  final int reservasPorLiberar;
  final int multas;
}

class ConteoLibro {
  const ConteoLibro({required this.libro, required this.prestamos});
  final Libro libro;
  final int prestamos;
}

class ConteoLector {
  const ConteoLector({required this.lector, required this.prestamos});
  final Lector lector;
  final int prestamos;
}

class ConteoGenero {
  const ConteoGenero({required this.genero, required this.prestamos});
  final String genero;
  final int prestamos;
}

class ConteoMes {
  const ConteoMes({
    required this.mes,
    required this.total,
    required this.tardios,
  });
  final String mes;
  final int total;
  final int tardios;
}

class Indicadores {
  const Indicadores({
    required this.topLibros,
    required this.topLectores,
    required this.topGeneros,
    required this.porMes,
  });

  final List<ConteoLibro> topLibros;
  final List<ConteoLector> topLectores;
  final List<ConteoGenero> topGeneros;
  final List<ConteoMes> porMes;
}

enum TipoSugerencia { compra, promocion, politica }

class Sugerencia {
  const Sugerencia({required this.tipo, required this.texto});
  final TipoSugerencia tipo;
  final String texto;
}
