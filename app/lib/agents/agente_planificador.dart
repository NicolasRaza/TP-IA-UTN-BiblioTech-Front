import '../data/repositorio.dart';
import '../domain/enums.dart';
import 'decisiones.dart';

/// Agente 3 — Planificador y de Gestión Operativa (spec v2 §4.3).
///
/// Es exclusivamente el **ejecutor**: recibe decisiones ya tomadas por el
/// Agente Evaluador y las traduce en tareas concretas sobre el sistema (enviar
/// la notificación, liberar el cupo de la reserva, actualizar estados).
///
/// No evalúa criterios de negocio por su cuenta: si una decisión no está en la
/// lista que recibe, no la ejecuta.
class AgentePlanificador {
  const AgentePlanificador(this.repo);

  final Repositorio repo;

  /// Ejecuta un lote de decisiones y devuelve qué se hizo con cada una.
  List<ResultadoEjecucion> ejecutar(List<Decision> decisiones) {
    return decisiones.map(ejecutarUna).toList();
  }

  ResultadoEjecucion ejecutarUna(Decision d) {
    switch (d.tipo) {
      case TipoDecision.notificarPrestamoVencido:
        return _notificar(
          d,
          tipo: TipoNotificacion.prestamoVencido,
          titulo: 'Préstamo vencido',
          descripcion:
              'Tu préstamo de "${d.libro?.titulo ?? ''}" venció hace ${d.dias} ${d.dias == 1 ? 'día' : 'días'}. Por favor devolvelo a la brevedad.',
        );

      case TipoDecision.notificarVencimientoProximo:
        return _notificar(
          d,
          tipo: TipoNotificacion.vencimientoProximo,
          titulo: 'Préstamo próximo a vencer',
          descripcion:
              'Tu préstamo de "${d.libro?.titulo ?? ''}" vence en ${d.dias} ${d.dias == 1 ? 'día' : 'días'}.',
        );

      case TipoDecision.liberarReservaNoRetirada:
      case TipoDecision.asignarReservaAlSiguiente:
        // Ambas se resuelven avanzando la cola: procesarVencimientos libera
        // las retenciones caídas y asignarSiguienteDeLaCola ofrece el ejemplar
        // al primero que está esperando.
        final antes = repo.reservas.where((r) => r.esActiva).length;
        repo.procesarVencimientos();
        final libroId = d.libro?.id ?? d.reserva?.libroId;
        if (libroId != null) repo.asignarSiguienteDeLaCola(libroId);
        final despues = repo.reservas.where((r) => r.esActiva).length;
        return ResultadoEjecucion(
          decision: d,
          ejecutada: true,
          detalle: 'Cola actualizada (reservas activas: $antes → $despues)',
        );

      case TipoDecision.alertarMultaPendiente:
      case TipoDecision.sugerirRevisionCategoria:
        // Son avisos para el bibliotecario en el panel: no disparan ninguna
        // acción automática sobre la cuenta del lector. La spec v2 §7 deja el
        // cambio de categoría y el cobro de multas en manos de una persona.
        return ResultadoEjecucion(
          decision: d,
          ejecutada: false,
          detalle:
              'Informado en el panel; requiere intervención del bibliotecario',
        );
    }
  }

  ResultadoEjecucion _notificar(
    Decision d, {
    required TipoNotificacion tipo,
    required String titulo,
    required String descripcion,
  }) {
    final lectorId = d.lector?.id ?? d.prestamo?.lectorId;
    if (lectorId == null) {
      return ResultadoEjecucion(
        decision: d,
        ejecutada: false,
        detalle: 'Sin lector asociado',
      );
    }
    final clave = d.libro?.titulo ?? '';
    // No apilar el mismo aviso sobre el mismo libro.
    if (clave.isNotEmpty && repo.existeNotificacion(lectorId, tipo, clave)) {
      return ResultadoEjecucion(
        decision: d,
        ejecutada: false,
        detalle: 'Ya se había notificado',
      );
    }
    repo.agregarNotificacion(
      lectorId: lectorId,
      tipo: tipo,
      titulo: titulo,
      descripcion: descripcion,
    );
    return ResultadoEjecucion(
      decision: d,
      ejecutada: true,
      detalle: 'Notificación enviada',
    );
  }
}
