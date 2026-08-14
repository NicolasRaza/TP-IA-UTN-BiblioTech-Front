import 'package:flutter/foundation.dart';

import '../agents/agente_aprendizaje.dart';
import '../agents/agente_evaluador.dart';
import '../agents/agente_planificador.dart';
import '../agents/decisiones.dart';
import '../data/repositorio.dart';
import '../domain/enums.dart';
import '../domain/models.dart';

/// Estado global de la aplicación.
///
/// Envuelve al [Repositorio] y a los agentes, y avisa a la UI cuando algo
/// cambia. Toda mutación pasa por acá para que la pantalla se refresque sola.
class AppState extends ChangeNotifier {
  AppState(this.repo)
      : evaluador = AgenteEvaluador(repo),
        planificador = AgentePlanificador(repo),
        aprendizaje = AgenteAprendizaje(repo);

  final Repositorio repo;
  final AgenteEvaluador evaluador;
  final AgentePlanificador planificador;
  final AgenteAprendizaje aprendizaje;

  Lector? _usuario;
  Lector? get usuario => _usuario;
  bool get haySesion => _usuario != null;

  /// Registro de lo que hicieron los agentes en esta sesión.
  /// Alimenta el "log de sesión real de uso" que pide el TP.
  final List<String> bitacora = [];

  void arrancar() {
    repo.inicializar();
    _usuario = repo.sesionActiva;
    if (_usuario != null) correrCicloDeAgentes();
    notifyListeners();
  }

  // ─────────────────────────────── Sesión ───────────────────────────────

  bool iniciarSesion(String email, String pin) {
    final u = repo.iniciarSesion(email, pin);
    if (u == null) return false;
    _usuario = u;
    correrCicloDeAgentes();
    notifyListeners();
    return true;
  }

  void cerrarSesion() {
    repo.cerrarSesion();
    _usuario = null;
    bitacora.clear();
    notifyListeners();
  }

  // ──────────────────────────── Ciclo de agentes ────────────────────────────

  /// Corre el ciclo Observación → Análisis → Decisión → Acción de la spec v2 §5.
  ///
  /// El Evaluador decide y el Planificador ejecuta: nunca al revés.
  List<ResultadoEjecucion> correrCicloDeAgentes() {
    repo.procesarVencimientos();
    final decisiones = evaluador.decidir();
    final resultados = planificador.ejecutar(decisiones);
    final hechas = resultados.where((r) => r.ejecutada).length;
    if (decisiones.isNotEmpty) {
      bitacora.add(
        '[${repo.ahora.toIso8601String()}] Ciclo de agentes: '
        '${decisiones.length} decisiones del Evaluador, '
        '$hechas ejecutadas por el Planificador.',
      );
    }
    return resultados;
  }

  // ───────────────────────────── Operaciones ─────────────────────────────

  ResultadoOperacion<Reserva> reservar(String libroId) {
    final u = _usuario;
    if (u == null) {
      return const ResultadoOperacion.error('No hay sesión activa');
    }
    final r = repo.crearReserva(lectorId: u.id, libroId: libroId);
    if (r.exito) {
      repo.registrarClic(u.id, libroId, 'reserva');
      _refrescarUsuario();
      bitacora.add('Reserva creada sobre "${repo.libro(libroId)?.titulo}"');
    }
    notifyListeners();
    return r;
  }

  void cancelarReserva(String reservaId) {
    repo.cancelarReserva(reservaId);
    _refrescarUsuario();
    notifyListeners();
  }

  ResultadoOperacion<Prestamo> prestar({
    required String lectorId,
    required String libroId,
    String? ejemplarId,
  }) {
    final r = repo.crearPrestamo(
      lectorId: lectorId,
      libroId: libroId,
      ejemplarId: ejemplarId,
      usuarioId: _usuario?.id,
    );
    if (r.exito) {
      bitacora.add(
          'Préstamo registrado: "${repo.libro(libroId)?.titulo}" → ${repo.lector(lectorId)?.nombreCompleto}');
    }
    _refrescarUsuario();
    notifyListeners();
    return r;
  }

  ResultadoOperacion<Prestamo> devolver(String prestamoId) {
    final r = repo.devolver(prestamoId, usuarioId: _usuario?.id);
    if (r.exito) {
      bitacora.add('Devolución registrada del préstamo $prestamoId');
    }
    _refrescarUsuario();
    notifyListeners();
    return r;
  }

  Libro agregarLibro(Libro libro) {
    final l = repo.agregarLibro(libro, usuarioId: _usuario?.id);
    bitacora.add('Alta de "${l.titulo}" pendiente de validación');
    notifyListeners();
    return l;
  }

  void validarLibro(String libroId) {
    repo.validarLibro(libroId, usuarioId: _usuario?.id);
    bitacora.add('Libro validado y publicado en el catálogo: $libroId');
    notifyListeners();
  }

  void registrarCorreccion(String campo, String sugerido, String finalValor) {
    repo.registrarCorreccion(campo, sugerido, finalValor);
    notifyListeners();
  }

  Lector agregarLector(Lector lector) {
    final l = repo.agregarLector(lector, usuarioId: _usuario?.id);
    notifyListeners();
    return l;
  }

  void actualizarLector(String id, Lector Function(Lector) cambio) {
    repo.actualizarLector(id, cambio, usuarioId: _usuario?.id, auditar: true);
    _refrescarUsuario();
    notifyListeners();
  }

  void cambiarCategoria(String lectorId, CategoriaLector nueva) {
    repo.cambiarCategoria(lectorId, nueva, usuarioId: _usuario?.id);
    _refrescarUsuario();
    notifyListeners();
  }

  ResultadoOperacion<Ejemplar> reimprimirEtiqueta(
      String libroId, String ejemplarId, String motivo) {
    final r = repo.reimprimirEtiqueta(libroId, ejemplarId,
        motivo: motivo, usuarioId: _usuario?.id);
    notifyListeners();
    return r;
  }

  void agregarEjemplar(String libroId, CondicionEjemplar condicion) {
    repo.agregarEjemplar(libroId, condicion);
    notifyListeners();
  }

  void guardarConfig(ConfiguracionBiblioteca cfg) {
    repo.guardarConfig(cfg, usuarioId: _usuario?.id);
    notifyListeners();
  }

  void marcarNotificacionLeida(String id) {
    repo.marcarLeida(id);
    notifyListeners();
  }

  void marcarTodasLeidas() {
    final u = _usuario;
    if (u == null) return;
    repo.marcarTodasLeidas(u.id);
    notifyListeners();
  }

  void reiniciarDatos() {
    repo.reiniciar();
    _usuario = null;
    bitacora.clear();
    notifyListeners();
  }

  void _refrescarUsuario() {
    final u = _usuario;
    if (u != null) _usuario = repo.lector(u.id);
  }

  // ──────────────────────────── Consultas de UI ────────────────────────────

  List<Recomendacion> get misRecomendaciones =>
      _usuario == null ? [] : evaluador.recomendarPara(_usuario!.id);

  List<Prestamo> get misPrestamos => _usuario == null
      ? []
      : repo
          .prestamosDeLector(_usuario!.id)
          .where((p) => p.estaAbierto)
          .toList()
    ..sort((a, b) => a.fechaVencimiento.compareTo(b.fechaVencimiento));

  List<Prestamo> get miHistorial {
    if (_usuario == null) return [];
    final l = repo
        .prestamosDeLector(_usuario!.id)
        .where((p) => p.estado == EstadoPrestamo.devuelto)
        .toList()
      ..sort((a, b) => (b.fechaDevolucion ?? b.fechaPrestamo)
          .compareTo(a.fechaDevolucion ?? a.fechaPrestamo));
    return l;
  }

  List<Reserva> get misReservas {
    if (_usuario == null) return [];
    final l = repo.reservasDeLector(_usuario!.id).toList()
      ..sort((a, b) => b.fechaReserva.compareTo(a.fechaReserva));
    return l;
  }

  List<Notificacion> get misNotificaciones =>
      _usuario == null ? [] : repo.notificacionesDe(_usuario!.id);

  int get misNoLeidas => _usuario == null ? 0 : repo.noLeidasDe(_usuario!.id);
}
