import 'dart:convert';

import '../domain/enums.dart';
import '../domain/models.dart';
import 'seed_data.dart';
import 'store.dart';

/// Claves de persistencia. Se conservan los nombres del prototipo (`bt_*`).
class _Keys {
  static const libros = 'bt_libros';
  static const lectores = 'bt_lectores';
  static const prestamos = 'bt_prestamos';
  static const reservas = 'bt_reservas';
  static const notificaciones = 'bt_notificaciones';
  static const config = 'bt_config';
  static const auditoria = 'bt_auditoria';
  static const aprendizaje = 'bt_aprendizaje';
  static const sesion = 'bt_sesion';
  static const inicializado = 'bt_initialized';
}

/// Repositorio de datos de BiblioTech.
///
/// Concentra las reglas de negocio de la spec v2 §7. El reloj y el generador
/// de IDs se inyectan para que los tests puedan fijar el tiempo y obtener
/// identificadores predecibles.
class Repositorio {
  Repositorio({
    required KeyValueStore store,
    DateTime Function()? reloj,
    String Function()? generadorId,
  })  : _store = store,
        _reloj = reloj ?? DateTime.now {
    _generadorId = generadorId ?? _idPorDefecto;
  }

  final KeyValueStore _store;
  final DateTime Function() _reloj;
  late final String Function() _generadorId;

  int _contadorId = 0;
  String _idPorDefecto() =>
      '${_reloj().microsecondsSinceEpoch}-${_contadorId++}';

  DateTime get ahora => _reloj();

  // ─────────────────────────── Infraestructura ───────────────────────────

  List<T> _leerLista<T>(String key, T Function(Map<String, dynamic>) desde) {
    final raw = _store.read(key);
    if (raw == null || raw.isEmpty) return [];
    final data = jsonDecode(raw) as List<dynamic>;
    return data.map((e) => desde(e as Map<String, dynamic>)).toList();
  }

  void _guardarLista<T>(
      String key, List<T> lista, Map<String, dynamic> Function(T) aJson) {
    _store.write(key, jsonEncode(lista.map(aJson).toList()));
  }

  /// Carga los datos de demostración la primera vez que se abre la app.
  void inicializar() {
    if (_store.read(_Keys.inicializado) == 'true') {
      procesarVencimientos();
      return;
    }
    final seed = SeedData(ahora);
    _guardarLista(_Keys.libros, seed.libros(), (l) => l.toJson());
    _guardarLista(_Keys.lectores, seed.lectores(), (l) => l.toJson());
    _guardarLista(_Keys.prestamos, seed.prestamos(), (p) => p.toJson());
    _guardarLista(_Keys.reservas, seed.reservas(), (r) => r.toJson());
    _guardarLista(
        _Keys.notificaciones, seed.notificaciones(), (n) => n.toJson());
    _guardarLista(_Keys.auditoria, seed.auditoria(), (a) => a.toJson());
    _store.write(
        _Keys.config, jsonEncode(const ConfiguracionBiblioteca().toJson()));
    _store.write(
        _Keys.aprendizaje, jsonEncode({'correcciones': [], 'clics': []}));
    _store.write(_Keys.inicializado, 'true');
    procesarVencimientos();
  }

  /// Borra todo y vuelve a los datos de demostración.
  void reiniciar() {
    for (final k in [
      _Keys.libros,
      _Keys.lectores,
      _Keys.prestamos,
      _Keys.reservas,
      _Keys.notificaciones,
      _Keys.config,
      _Keys.auditoria,
      _Keys.aprendizaje,
      _Keys.sesion,
      _Keys.inicializado,
    ]) {
      _store.remove(k);
    }
    inicializar();
  }

  // ────────────────────────────── Libros ──────────────────────────────

  List<Libro> get libros => _leerLista(_Keys.libros, Libro.fromJson);

  Libro? libro(String id) {
    for (final l in libros) {
      if (l.id == id) return l;
    }
    return null;
  }

  /// Catálogo visible para el lector.
  ///
  /// Regla de Validación Estricta (spec v2 §7): solo los libros aprobados
  /// explícitamente por el bibliotecario llegan acá.
  List<Libro> get catalogoPublico => libros.where((l) => l.validado).toList();

  List<Libro> get pendientesValidacion =>
      libros.where((l) => !l.validado).toList();

  void _guardarLibros(List<Libro> lista) =>
      _guardarLista(_Keys.libros, lista, (l) => l.toJson());

  /// Da de alta un libro. Nace sin validar: no aparece en el catálogo
  /// público hasta que el bibliotecario lo confirme con [validarLibro].
  Libro agregarLibro(Libro libro, {String? usuarioId}) {
    final lista = libros;
    final nuevo = libro.validado ? libro.copyWith(validado: false) : libro;
    lista.add(nuevo);
    _guardarLibros(lista);
    registrarAuditoria(
      TipoEventoAuditoria.altaLibro,
      'Alta del libro "${nuevo.titulo}" (pendiente de validación)',
      usuarioId,
    );
    return nuevo;
  }

  /// Confirmación explícita del bibliotecario que publica el libro.
  Libro? validarLibro(String libroId, {String? usuarioId}) {
    final lista = libros;
    final i = lista.indexWhere((l) => l.id == libroId);
    if (i < 0) return null;
    lista[i] = lista[i].copyWith(validado: true);
    _guardarLibros(lista);
    registrarAuditoria(
      TipoEventoAuditoria.altaLibro,
      'Validación y publicación de "${lista[i].titulo}"',
      usuarioId,
    );
    return lista[i];
  }

  Libro? actualizarLibro(String libroId, Libro Function(Libro) cambio,
      {String? usuarioId, bool auditar = true}) {
    final lista = libros;
    final i = lista.indexWhere((l) => l.id == libroId);
    if (i < 0) return null;
    lista[i] = cambio(lista[i]);
    _guardarLibros(lista);
    if (auditar) {
      registrarAuditoria(TipoEventoAuditoria.edicionLibro,
          'Edición del libro "${lista[i].titulo}"', usuarioId);
    }
    return lista[i];
  }

  void eliminarLibro(String libroId, {String? usuarioId}) {
    final lista = libros;
    final l = lista.where((x) => x.id == libroId).firstOrNull;
    lista.removeWhere((x) => x.id == libroId);
    _guardarLibros(lista);
    registrarAuditoria(TipoEventoAuditoria.bajaLibro,
        'Baja del libro "${l?.titulo ?? libroId}"', usuarioId);
  }

  Ejemplar? agregarEjemplar(String libroId, CondicionEjemplar condicion) {
    final l = libro(libroId);
    if (l == null) return null;
    final nuevo = Ejemplar(
      id: 'ej-${_generadorId()}',
      libroId: libroId,
      condicion: condicion,
      estado: EstadoEjemplar.disponible,
    );
    actualizarLibro(
        libroId, (x) => x.copyWith(ejemplares: [...x.ejemplares, nuevo]),
        auditar: false);
    return nuevo;
  }

  void actualizarEjemplar(
      String libroId, String ejemplarId, Ejemplar Function(Ejemplar) cambio) {
    actualizarLibro(libroId, (l) {
      final ejs =
          l.ejemplares.map((e) => e.id == ejemplarId ? cambio(e) : e).toList();
      return l.copyWith(ejemplares: ejs);
    }, auditar: false);
  }

  /// Reimprime la etiqueta QR de un ejemplar.
  ///
  /// Regla de Continuidad de Identidad (spec v2 §7): el identificador interno
  /// no cambia, así que la etiqueta reimpresa es idéntica a la original y el
  /// historial de préstamos del ejemplar queda intacto. Solo se incrementa el
  /// contador de reimpresiones y se registra el motivo en auditoría.
  ResultadoOperacion<Ejemplar> reimprimirEtiqueta(
    String libroId,
    String ejemplarId, {
    required String motivo,
    String? usuarioId,
  }) {
    final l = libro(libroId);
    if (l == null) {
      return const ResultadoOperacion.error('El libro no existe');
    }
    final ej = l.ejemplares.where((e) => e.id == ejemplarId).firstOrNull;
    if (ej == null) {
      return const ResultadoOperacion.error('El ejemplar no existe');
    }
    actualizarEjemplar(libroId, ejemplarId,
        (e) => e.copyWith(reimpresionesQr: e.reimpresionesQr + 1));
    registrarAuditoria(
      TipoEventoAuditoria.reimpresionQr,
      'Reimpresión de etiqueta ${ej.qr} ("${l.titulo}"). Motivo: $motivo',
      usuarioId,
    );
    final actualizado =
        libro(libroId)!.ejemplares.firstWhere((e) => e.id == ejemplarId);
    return ResultadoOperacion.ok(actualizado);
  }

  /// Busca un ejemplar por el contenido de su etiqueta QR.
  ({Libro libro, Ejemplar ejemplar})? buscarPorQr(String qr) {
    for (final l in libros) {
      for (final e in l.ejemplares) {
        if (e.qr == qr) return (libro: l, ejemplar: e);
      }
    }
    return null;
  }

  List<Libro> buscarLibros({String texto = '', String genero = 'Todos'}) {
    var lista = catalogoPublico;
    if (texto.trim().isNotEmpty) {
      final q = texto.toLowerCase().trim();
      lista = lista
          .where((l) =>
              l.titulo.toLowerCase().contains(q) ||
              l.autor.toLowerCase().contains(q) ||
              l.isbn.contains(q) ||
              l.genero.toLowerCase().contains(q))
          .toList();
    }
    if (genero != 'Todos' && genero.isNotEmpty) {
      lista = lista.where((l) => l.genero == genero).toList();
    }
    return lista;
  }

  List<String> get generos {
    final s = catalogoPublico
        .map((l) => l.genero)
        .where((g) => g.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return s;
  }

  // ────────────────────────────── Lectores ──────────────────────────────

  List<Lector> get usuarios => _leerLista(_Keys.lectores, Lector.fromJson);

  /// Solo los lectores; excluye bibliotecarios y administradores.
  List<Lector> get lectores => usuarios.where((l) => !l.esPersonal).toList();

  Lector? lector(String id) {
    for (final l in usuarios) {
      if (l.id == id) return l;
    }
    return null;
  }

  Lector? lectorPorQr(String qr) {
    for (final l in usuarios) {
      if (l.qr == qr) return l;
    }
    return null;
  }

  Lector? lectorPorEmail(String email) {
    for (final l in usuarios) {
      if (l.email.toLowerCase() == email.toLowerCase()) return l;
    }
    return null;
  }

  void _guardarUsuarios(List<Lector> lista) =>
      _guardarLista(_Keys.lectores, lista, (l) => l.toJson());

  Lector agregarLector(Lector lector, {String? usuarioId}) {
    final lista = usuarios..add(lector);
    _guardarUsuarios(lista);
    registrarAuditoria(TipoEventoAuditoria.altaLector,
        'Alta del lector ${lector.nombreCompleto}', usuarioId);
    return lector;
  }

  Lector? actualizarLector(String lectorId, Lector Function(Lector) cambio,
      {String? usuarioId, bool auditar = false}) {
    final lista = usuarios;
    final i = lista.indexWhere((l) => l.id == lectorId);
    if (i < 0) return null;
    lista[i] = cambio(lista[i]);
    _guardarUsuarios(lista);
    if (auditar) {
      registrarAuditoria(TipoEventoAuditoria.edicionLector,
          'Edición del lector ${lista[i].nombreCompleto}', usuarioId);
    }
    return lista[i];
  }

  /// Cambia la categoría de un lector.
  ///
  /// Regla de Transición de Categoría (spec v2 §7): la nueva categoría rige
  /// solo para préstamos y reservas futuros. Los que ya están activos
  /// conservan las condiciones con las que se generaron, porque cada uno
  /// guarda su propio plazo y categoría en el momento de crearse.
  Lector? cambiarCategoria(String lectorId, CategoriaLector nueva,
      {String? usuarioId}) {
    final actual = lector(lectorId);
    if (actual == null || actual.categoria == nueva) return actual;
    final actualizado =
        actualizarLector(lectorId, (l) => l.copyWith(categoria: nueva));
    registrarAuditoria(
      TipoEventoAuditoria.cambioCategoria,
      'Cambio de categoría de ${actual.nombreCompleto}: '
      '${actual.categoria.label} → ${nueva.label}. '
      'Los préstamos y reservas vigentes conservan sus condiciones originales.',
      usuarioId,
    );
    return actualizado;
  }

  /// Deriva la categoría que corresponde a una fecha de nacimiento.
  CategoriaLector categoriaPorEdad(DateTime fechaNacimiento) {
    final cfg = config;
    final edad = _edadEnAnios(fechaNacimiento, ahora);
    return edad < cfg.edadMayoriaEdad
        ? CategoriaLector.menor
        : CategoriaLector.adulto;
  }

  static int _edadEnAnios(DateTime nacimiento, DateTime ahora) {
    var edad = ahora.year - nacimiento.year;
    final cumpleEsteAnio =
        DateTime(ahora.year, nacimiento.month, nacimiento.day);
    if (ahora.isBefore(cumpleEsteAnio)) edad--;
    return edad;
  }

  /// Detecta lectores cuya categoría quedó desactualizada respecto de su edad
  /// (ej. un menor que cumplió la mayoría de edad).
  List<Lector> lectoresConCategoriaDesactualizada() {
    return lectores.where((l) {
      if (l.fechaNacimiento == null) return false;
      if (l.categoria == CategoriaLector.docente ||
          l.categoria == CategoriaLector.senior) {
        return false;
      }
      return categoriaPorEdad(l.fechaNacimiento!) != l.categoria;
    }).toList();
  }

  /// ¿Puede el lector llevarse un ejemplar más? (spec v2 §7)
  ResultadoOperacion<Lector> puedePedirPrestado(String lectorId) {
    final l = lector(lectorId);
    if (l == null) {
      return const ResultadoOperacion.error('Lector no encontrado');
    }
    if (!l.activo) {
      return const ResultadoOperacion.error('La cuenta está inactiva');
    }
    if (l.multasPendientes > 0) {
      return ResultadoOperacion.error(
          'Multa pendiente de \$${l.multasPendientes}. Saldala en el mostrador.');
    }
    final vencidos = prestamosDeLector(lectorId)
        .where((p) => p.estado == EstadoPrestamo.vencido)
        .length;
    if (vencidos > 0) {
      return const ResultadoOperacion.error(
          'Tenés préstamos vencidos sin devolver. Devolvelos antes de pedir nuevos.');
    }
    final limite = config.limiteEjemplaresPara(l.categoria);
    final activos = prestamosDeLector(lectorId)
        .where((p) => p.estado == EstadoPrestamo.activo)
        .length;
    if (activos >= limite) {
      return ResultadoOperacion.error(
          'Alcanzaste el límite de $limite préstamos simultáneos de tu categoría');
    }
    return ResultadoOperacion.ok(l);
  }

  /// ¿Puede reservar? Misma restricción de multas y vencidos que el préstamo
  /// (spec v2 §7: "no puede reservar nuevos libros si posee material con fecha
  /// de devolución vencida o multas impagas").
  ResultadoOperacion<Lector> puedeReservar(String lectorId) {
    final l = lector(lectorId);
    if (l == null) {
      return const ResultadoOperacion.error('Lector no encontrado');
    }
    if (!l.activo) {
      return const ResultadoOperacion.error('La cuenta está inactiva');
    }
    if (l.multasPendientes > 0) {
      return ResultadoOperacion.error(
          'Multa pendiente de \$${l.multasPendientes}. Saldala en el mostrador.');
    }
    final vencidos = prestamosDeLector(lectorId)
        .where((p) => p.estado == EstadoPrestamo.vencido)
        .length;
    if (vencidos > 0) {
      return const ResultadoOperacion.error(
          'Tenés préstamos vencidos. Regularizalos para poder reservar.');
    }
    final limite = config.limiteReservasPara(l.categoria);
    final activas = reservasDeLector(lectorId).where((r) => r.esActiva).length;
    if (activas >= limite) {
      return ResultadoOperacion.error(
          'Alcanzaste el límite de $limite reservas simultáneas');
    }
    return ResultadoOperacion.ok(l);
  }

  // ────────────────────────────── Préstamos ──────────────────────────────

  List<Prestamo> get prestamos =>
      _leerLista(_Keys.prestamos, Prestamo.fromJson);

  Prestamo? prestamo(String id) {
    for (final p in prestamos) {
      if (p.id == id) return p;
    }
    return null;
  }

  List<Prestamo> prestamosDeLector(String lectorId) =>
      prestamos.where((p) => p.lectorId == lectorId).toList();

  void _guardarPrestamos(List<Prestamo> lista) =>
      _guardarLista(_Keys.prestamos, lista, (p) => p.toJson());

  /// Registra un préstamo, congelando plazo y categoría vigentes.
  ResultadoOperacion<Prestamo> crearPrestamo({
    required String lectorId,
    required String libroId,
    String? ejemplarId,
    String? usuarioId,
  }) {
    final permiso = puedePedirPrestado(lectorId);
    if (!permiso.exito) return ResultadoOperacion.error(permiso.motivo);

    final l = libro(libroId);
    if (l == null) return const ResultadoOperacion.error('El libro no existe');

    final ej = ejemplarId != null
        ? l.ejemplares.where((e) => e.id == ejemplarId).firstOrNull
        : l.ejemplares.where((e) => e.estaDisponible).firstOrNull;
    if (ej == null) {
      return const ResultadoOperacion.error('No hay ejemplares disponibles');
    }
    if (!ej.estaDisponible && ej.estado != EstadoEjemplar.reservado) {
      return const ResultadoOperacion.error('El ejemplar no está disponible');
    }

    final lectorObj = lector(lectorId)!;
    final cfg = config;
    final plazo = cfg.plazoPara(lectorObj.categoria);

    final nuevo = Prestamo(
      id: 'pres-${_generadorId()}',
      lectorId: lectorId,
      ejemplarId: ej.id,
      libroId: libroId,
      fechaPrestamo: ahora,
      fechaVencimiento: ahora.add(Duration(days: plazo)),
      estado: EstadoPrestamo.activo,
      categoriaAlPrestar: lectorObj.categoria,
      plazoDiasAlPrestar: plazo,
    );

    _guardarPrestamos(prestamos..add(nuevo));
    actualizarEjemplar(
        libroId, ej.id, (e) => e.copyWith(estado: EstadoEjemplar.prestado));

    // Si el préstamo satisface una reserva del lector, se cierra la reserva.
    final lista = reservas;
    final i = lista.indexWhere(
        (r) => r.lectorId == lectorId && r.libroId == libroId && r.esActiva);
    if (i >= 0) {
      lista[i] = lista[i].copyWith(estado: EstadoReserva.completada);
      _guardarReservas(lista);
    }

    agregarNotificacion(
      lectorId: lectorId,
      tipo: TipoNotificacion.reservaConfirmada,
      titulo: 'Préstamo confirmado',
      descripcion:
          'Te llevaste "${l.titulo}". Vence el ${_fechaCorta(nuevo.fechaVencimiento)}.',
    );

    registrarAuditoria(
      TipoEventoAuditoria.prestamo,
      'Préstamo otorgado: "${l.titulo}" a ${lectorObj.nombreCompleto} '
      '(DNI ${lectorObj.dni}), plazo $plazo días',
      usuarioId,
    );
    return ResultadoOperacion.ok(nuevo);
  }

  /// Registra la devolución, aplica multa si corresponde y libera el ejemplar.
  ///
  /// Al liberarlo, el primero de la cola de reservas pasa a "lista para
  /// retirar" con el plazo de 48 hs corriendo (spec v2 §7).
  ResultadoOperacion<Prestamo> devolver(String prestamoId,
      {String? usuarioId}) {
    final lista = prestamos;
    final i = lista.indexWhere((p) => p.id == prestamoId);
    if (i < 0) return const ResultadoOperacion.error('El préstamo no existe');
    final p = lista[i];
    if (p.estado == EstadoPrestamo.devuelto) {
      return const ResultadoOperacion.error('El préstamo ya fue devuelto');
    }

    final momento = ahora;
    final tardio = momento.isAfter(p.fechaVencimiento);
    var multaNueva = 0;
    if (tardio) {
      final diasTarde = _diasEnteros(p.fechaVencimiento, momento);
      final total = diasTarde * config.multaPorDiaDemora;
      // Solo se cobra lo que todavía no se había cargado por este préstamo.
      multaNueva = (total - p.multaAplicada).clamp(0, total);
    }

    lista[i] = p.copyWith(
      fechaDevolucion: momento,
      estado: EstadoPrestamo.devuelto,
      tardio: tardio,
      multaAplicada: p.multaAplicada + multaNueva,
    );
    _guardarPrestamos(lista);

    if (multaNueva > 0) {
      actualizarLector(p.lectorId,
          (l) => l.copyWith(multasPendientes: l.multasPendientes + multaNueva));
    }

    actualizarEjemplar(p.libroId, p.ejemplarId,
        (e) => e.copyWith(estado: EstadoEjemplar.disponible));

    final lectorObj = lector(p.lectorId);
    final libroObj = libro(p.libroId);
    registrarAuditoria(
      TipoEventoAuditoria.devolucion,
      'Devolución: "${libroObj?.titulo ?? p.libroId}" de '
      '${lectorObj?.nombreCompleto ?? p.lectorId}${tardio ? ' (tardía)' : ''}',
      usuarioId,
    );

    // El ejemplar liberado se ofrece al primero de la cola.
    asignarSiguienteDeLaCola(p.libroId);

    return ResultadoOperacion.ok(lista[i]);
  }

  ({int total, int activos, int vencidos, int devueltos, double tasaTardia})
      estadisticasPrestamos() {
    final all = prestamos;
    final tardios = all.where((p) => p.tardio).length;
    return (
      total: all.length,
      activos: all.where((p) => p.estado == EstadoPrestamo.activo).length,
      vencidos: all.where((p) => p.estado == EstadoPrestamo.vencido).length,
      devueltos: all.where((p) => p.estado == EstadoPrestamo.devuelto).length,
      tasaTardia: all.isEmpty ? 0 : tardios * 100 / all.length,
    );
  }

  // ────────────────────────────── Reservas ──────────────────────────────

  List<Reserva> get reservas => _leerLista(_Keys.reservas, Reserva.fromJson);

  List<Reserva> reservasDeLector(String lectorId) =>
      reservas.where((r) => r.lectorId == lectorId).toList();

  void _guardarReservas(List<Reserva> lista) =>
      _guardarLista(_Keys.reservas, lista, (r) => r.toJson());

  /// Cola de espera de un título, en orden estrictamente cronológico (§7).
  List<Reserva> colaDeReservas(String libroId) {
    final cola = reservas
        .where((r) => r.libroId == libroId && r.esActiva)
        .toList()
      ..sort((a, b) => a.fechaReserva.compareTo(b.fechaReserva));
    return cola;
  }

  ResultadoOperacion<Reserva> crearReserva({
    required String lectorId,
    required String libroId,
  }) {
    final permiso = puedeReservar(lectorId);
    if (!permiso.exito) return ResultadoOperacion.error(permiso.motivo);

    final l = libro(libroId);
    if (l == null || !l.validado) {
      return const ResultadoOperacion.error(
          'El libro no está disponible en el catálogo');
    }
    final duplicada = reservas.any(
        (r) => r.lectorId == lectorId && r.libroId == libroId && r.esActiva);
    if (duplicada) {
      return const ResultadoOperacion.error(
          'Ya tenés una reserva activa para este libro');
    }

    final cfg = config;
    final nueva = Reserva(
      id: 'res-${_generadorId()}',
      lectorId: lectorId,
      libroId: libroId,
      fechaReserva: ahora,
      estado: EstadoReserva.pendiente,
      plazoRetiroHorasAlReservar: cfg.plazoRetiroReservaHoras,
    );
    _guardarReservas(reservas..add(nueva));

    // Si hay un ejemplar libre y nadie por delante, queda lista de inmediato.
    asignarSiguienteDeLaCola(libroId);
    final refrescada =
        reservas.where((r) => r.id == nueva.id).firstOrNull ?? nueva;
    return ResultadoOperacion.ok(refrescada);
  }

  void cancelarReserva(String reservaId) {
    final lista = reservas;
    final i = lista.indexWhere((r) => r.id == reservaId);
    if (i < 0) return;
    final libroId = lista[i].libroId;
    final estabaLista = lista[i].estado == EstadoReserva.lista;
    final ejemplarId = lista[i].ejemplarAsignadoId;
    lista[i] = lista[i].copyWith(estado: EstadoReserva.cancelada);
    _guardarReservas(lista);
    if (estabaLista && ejemplarId != null) {
      actualizarEjemplar(libroId, ejemplarId,
          (e) => e.copyWith(estado: EstadoEjemplar.disponible));
    }
    asignarSiguienteDeLaCola(libroId);
  }

  /// Ofrece un ejemplar libre al primero de la cola, si lo hay.
  ///
  /// Retiene el ejemplar y arranca el plazo de retiro de 48 hs guardado en la
  /// reserva. Respeta el orden cronológico: nunca saltea a nadie.
  Reserva? asignarSiguienteDeLaCola(String libroId) {
    final cola = colaDeReservas(libroId);
    if (cola.isEmpty) return null;
    // Si ya hay una reserva retenida, el ejemplar está comprometido.
    if (cola.any((r) => r.estado == EstadoReserva.lista)) return null;

    final l = libro(libroId);
    final disponible = l?.ejemplares.where((e) => e.estaDisponible).firstOrNull;
    if (disponible == null) return null;

    final primera = cola.first;
    final lista = reservas;
    final i = lista.indexWhere((r) => r.id == primera.id);
    if (i < 0) return null;

    lista[i] = lista[i].copyWith(
      estado: EstadoReserva.lista,
      fechaVencimientoRetiro:
          ahora.add(Duration(hours: primera.plazoRetiroHorasAlReservar)),
      ejemplarAsignadoId: disponible.id,
    );
    _guardarReservas(lista);
    actualizarEjemplar(libroId, disponible.id,
        (e) => e.copyWith(estado: EstadoEjemplar.reservado));

    agregarNotificacion(
      lectorId: primera.lectorId,
      tipo: TipoNotificacion.reservaDisponible,
      titulo: '¡Tu reserva está lista!',
      descripcion: '"${l!.titulo}" ya está disponible para retirar. Tenés '
          '${primera.plazoRetiroHorasAlReservar} horas para buscarlo.',
    );
    return lista[i];
  }

  // ──────────────────────── Vencimientos (ciclo) ────────────────────────

  /// Actualiza el estado del sistema respecto del calendario.
  ///
  /// Marca préstamos vencidos con su multa acumulada y libera las reservas que
  /// superaron el plazo de retiro, pasando el ejemplar al siguiente de la cola.
  /// Es idempotente: correrla dos veces no duplica multas ni notificaciones.
  ({int prestamosVencidos, int reservasLiberadas}) procesarVencimientos() {
    final momento = ahora;
    final cfg = config;
    var vencidos = 0;
    var liberadas = 0;

    // ── Préstamos ──
    final listaP = prestamos;
    var cambioP = false;
    for (var i = 0; i < listaP.length; i++) {
      final p = listaP[i];
      if (!p.estaAbierto) continue;
      if (!momento.isAfter(p.fechaVencimiento)) continue;

      final diasTarde = _diasEnteros(p.fechaVencimiento, momento);
      final multaTotal = diasTarde * cfg.multaPorDiaDemora;
      final delta = multaTotal - p.multaAplicada;

      if (p.estado != EstadoPrestamo.vencido || delta > 0) {
        listaP[i] = p.copyWith(
          estado: EstadoPrestamo.vencido,
          tardio: true,
          multaAplicada: p.multaAplicada + (delta > 0 ? delta : 0),
        );
        cambioP = true;
        if (delta > 0) {
          actualizarLector(p.lectorId,
              (l) => l.copyWith(multasPendientes: l.multasPendientes + delta));
        }
      }
      vencidos++;
    }
    if (cambioP) _guardarPrestamos(listaP);

    // ── Reservas retenidas que nadie retiró ──
    final listaR = reservas;
    var cambioR = false;
    final librosATocar = <String>{};
    for (var i = 0; i < listaR.length; i++) {
      final r = listaR[i];
      if (r.estado != EstadoReserva.lista) continue;
      final limite = r.fechaVencimientoRetiro;
      if (limite == null || !momento.isAfter(limite)) continue;

      listaR[i] = r.copyWith(estado: EstadoReserva.vencida);
      cambioR = true;
      liberadas++;
      if (r.ejemplarAsignadoId != null) {
        actualizarEjemplar(r.libroId, r.ejemplarAsignadoId!,
            (e) => e.copyWith(estado: EstadoEjemplar.disponible));
      }
      librosATocar.add(r.libroId);
      agregarNotificacion(
        lectorId: r.lectorId,
        tipo: TipoNotificacion.reservaVencida,
        titulo: 'Reserva vencida',
        descripcion:
            'Se venció el plazo para retirar "${libro(r.libroId)?.titulo ?? ''}". '
            'La reserva pasó al siguiente lector en la lista.',
      );
    }
    if (cambioR) _guardarReservas(listaR);

    // El ejemplar liberado se ofrece al siguiente de cada cola afectada.
    for (final libroId in librosATocar) {
      asignarSiguienteDeLaCola(libroId);
    }

    return (prestamosVencidos: vencidos, reservasLiberadas: liberadas);
  }

  static int _diasEnteros(DateTime desde, DateTime hasta) {
    final diff = hasta.difference(desde);
    return diff.inHours <= 0 ? 0 : (diff.inHours / 24).ceil();
  }

  // ─────────────────────────── Notificaciones ───────────────────────────

  List<Notificacion> get notificaciones =>
      _leerLista(_Keys.notificaciones, Notificacion.fromJson);

  List<Notificacion> notificacionesDe(String lectorId) {
    final l = notificaciones.where((n) => n.lectorId == lectorId).toList()
      ..sort((a, b) => b.fecha.compareTo(a.fecha));
    return l;
  }

  int noLeidasDe(String lectorId) =>
      notificaciones.where((n) => n.lectorId == lectorId && !n.leida).length;

  Notificacion agregarNotificacion({
    required String lectorId,
    required TipoNotificacion tipo,
    required String titulo,
    required String descripcion,
  }) {
    final n = Notificacion(
      id: 'not-${_generadorId()}',
      lectorId: lectorId,
      tipo: tipo,
      titulo: titulo,
      descripcion: descripcion,
      fecha: ahora,
    );
    _guardarLista(
        _Keys.notificaciones, notificaciones..add(n), (x) => x.toJson());
    return n;
  }

  /// Evita apilar avisos repetidos del mismo tipo para el mismo libro.
  bool existeNotificacion(
      String lectorId, TipoNotificacion tipo, String textoClave) {
    return notificaciones.any((n) =>
        n.lectorId == lectorId &&
        n.tipo == tipo &&
        n.descripcion.contains(textoClave));
  }

  void marcarLeida(String notificacionId) {
    final lista = notificaciones
        .map((n) => n.id == notificacionId ? n.copyWith(leida: true) : n)
        .toList();
    _guardarLista(_Keys.notificaciones, lista, (n) => n.toJson());
  }

  void marcarTodasLeidas(String lectorId) {
    final lista = notificaciones
        .map((n) => n.lectorId == lectorId ? n.copyWith(leida: true) : n)
        .toList();
    _guardarLista(_Keys.notificaciones, lista, (n) => n.toJson());
  }

  // ──────────────────────────── Configuración ────────────────────────────

  ConfiguracionBiblioteca get config {
    final raw = _store.read(_Keys.config);
    if (raw == null || raw.isEmpty) return const ConfiguracionBiblioteca();
    return ConfiguracionBiblioteca.fromJson(
        jsonDecode(raw) as Map<String, dynamic>);
  }

  ConfiguracionBiblioteca guardarConfig(ConfiguracionBiblioteca cfg,
      {String? usuarioId}) {
    _store.write(_Keys.config, jsonEncode(cfg.toJson()));
    registrarAuditoria(TipoEventoAuditoria.cambioConfig,
        'Actualización de parámetros de la biblioteca', usuarioId);
    return cfg;
  }

  // ────────────────────────────── Auditoría ──────────────────────────────

  List<EventoAuditoria> get auditoria {
    final l = _leerLista(_Keys.auditoria, EventoAuditoria.fromJson)
      ..sort((a, b) => b.fecha.compareTo(a.fecha));
    return l;
  }

  void registrarAuditoria(
      TipoEventoAuditoria tipo, String descripcion, String? usuarioId) {
    final lista = _leerLista(_Keys.auditoria, EventoAuditoria.fromJson);
    lista.insert(
      0,
      EventoAuditoria(
        id: 'aud-${_generadorId()}',
        tipo: tipo,
        descripcion: descripcion,
        usuarioId: usuarioId ?? 'sistema',
        fecha: ahora,
      ),
    );
    // Se conservan los últimos 200 eventos.
    final recortada = lista.take(200).toList();
    _guardarLista(_Keys.auditoria, recortada, (e) => e.toJson());
  }

  // ────────────────────────────── Aprendizaje ──────────────────────────────

  Map<String, dynamic> get aprendizaje {
    final raw = _store.read(_Keys.aprendizaje);
    if (raw == null || raw.isEmpty) return {'correcciones': [], 'clics': []};
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  void registrarCorreccion(
      String campo, String valorSugerido, String valorFinal) {
    final data = aprendizaje;
    final correcciones = (data['correcciones'] as List<dynamic>? ?? []).toList()
      ..add({
        'campo': campo,
        'valorSugerido': valorSugerido,
        'valorFinal': valorFinal,
        'fecha': ahora.toIso8601String(),
      });
    data['correcciones'] = correcciones;
    _store.write(_Keys.aprendizaje, jsonEncode(data));
  }

  void registrarClic(String lectorId, String libroId, String tipo) {
    final data = aprendizaje;
    final clics = (data['clics'] as List<dynamic>? ?? []).toList()
      ..add({
        'lectorId': lectorId,
        'libroId': libroId,
        'tipo': tipo,
        'fecha': ahora.toIso8601String(),
      });
    data['clics'] = clics;
    _store.write(_Keys.aprendizaje, jsonEncode(data));
  }

  // ─────────────────────────────── Sesión ───────────────────────────────

  Lector? get sesionActiva {
    final id = _store.read(_Keys.sesion);
    if (id == null || id.isEmpty) return null;
    return lector(id);
  }

  Lector? iniciarSesion(String email, String pin) {
    final u = lectorPorEmail(email);
    if (u == null || u.pin != pin) return null;
    if (!u.activo && !u.esPersonal) return null;
    _store.write(_Keys.sesion, u.id);
    return u;
  }

  void cerrarSesion() => _store.remove(_Keys.sesion);

  static String _fechaCorta(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
