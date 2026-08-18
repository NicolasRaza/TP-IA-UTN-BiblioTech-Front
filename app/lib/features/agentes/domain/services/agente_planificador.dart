import '../../../../core/services/reloj.dart';
import '../../../notificaciones/domain/entities/notificacion.dart';
import '../../../notificaciones/domain/repositories/notificacion_repository.dart';
import '../../../reservas/domain/services/asignador_de_cola.dart';
import '../entities/decision.dart';

/// Agente 3 — Planificador y de Gestión Operativa (spec v2 §4.3).
///
/// Es exclusivamente el **ejecutor**: recibe decisiones ya tomadas por el
/// Agente Evaluador y las traduce en tareas concretas sobre el sistema
/// (mandar la notificación, avanzar la cola de reservas).
///
/// No evalúa criterios de negocio por su cuenta: si una decisión no está en la
/// lista que recibe, no la ejecuta. Y como no tiene acceso al
/// [EstadoDelSistema], tampoco podría re-evaluar aunque quisiera.
class AgentePlanificador {
  const AgentePlanificador({
    required NotificacionRepository notificacionRepository,
    required AsignadorDeCola asignadorDeCola,
    required Reloj reloj,
  })  : _notificaciones = notificacionRepository,
        _asignador = asignadorDeCola,
        _reloj = reloj;

  final NotificacionRepository _notificaciones;
  final AsignadorDeCola _asignador;
  final Reloj _reloj;

  /// Ejecuta un lote de decisiones y devuelve qué se hizo con cada una.
  Future<List<ResultadoEjecucion>> ejecutar(List<Decision> decisiones) async {
    final resultados = <ResultadoEjecucion>[];
    for (final d in decisiones) {
      resultados.add(await ejecutarUna(d));
    }
    return resultados;
  }

  Future<ResultadoEjecucion> ejecutarUna(Decision d) async {
    switch (d.tipo) {
      case TipoDecision.notificarPrestamoVencido:
        return _notificar(
          d,
          tipo: TipoNotificacion.prestamoVencido,
          titulo: 'Préstamo vencido',
          descripcion: 'Tu préstamo de "${d.libro?.titulo ?? ''}" venció hace '
              '${d.dias} ${d.dias == 1 ? 'día' : 'días'}. Por favor devolvelo '
              'a la brevedad.',
        );

      case TipoDecision.notificarVencimientoProximo:
        return _notificar(
          d,
          tipo: TipoNotificacion.vencimientoProximo,
          titulo: 'Préstamo próximo a vencer',
          descripcion: 'Tu préstamo de "${d.libro?.titulo ?? ''}" vence en '
              '${d.dias} ${d.dias == 1 ? 'día' : 'días'}.',
        );

      case TipoDecision.liberarReservaNoRetirada:
      case TipoDecision.asignarReservaAlSiguiente:
        // Ambas se resuelven avanzando la cola del título.
        final libroId = d.libro?.id ?? d.reserva?.libroId;
        if (libroId == null) {
          return ResultadoEjecucion(
            decision: d,
            ejecutada: false,
            detalle: 'Sin libro asociado',
          );
        }
        final promovida = await _asignador.asignarSiguiente(libroId);
        return ResultadoEjecucion(
          decision: d,
          ejecutada: promovida != null,
          detalle: promovida != null
              ? 'Ejemplar retenido para el primero de la cola'
              : 'No había ejemplar libre o la cola ya estaba atendida',
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

  Future<ResultadoEjecucion> _notificar(
    Decision d, {
    required TipoNotificacion tipo,
    required String titulo,
    required String descripcion,
  }) async {
    final lectorId = d.lector?.id ?? d.prestamo?.lectorId;
    if (lectorId == null) {
      return ResultadoEjecucion(
        decision: d,
        ejecutada: false,
        detalle: 'Sin lector asociado',
      );
    }

    // El ciclo corre en cada arranque; sin esta guarda el lector recibiría el
    // mismo recordatorio una vez por sesión.
    final clave = d.libro?.titulo ?? '';
    if (clave.isNotEmpty) {
      final yaAvisado =
          await _notificaciones.existeSimilar(lectorId, tipo, clave);
      if (yaAvisado.valorONull ?? false) {
        return ResultadoEjecucion(
          decision: d,
          ejecutada: false,
          detalle: 'Ya se había notificado',
        );
      }
    }

    final creada = await _notificaciones.crear(
      Notificacion(
        id: '',
        lectorId: lectorId,
        tipo: tipo,
        titulo: titulo,
        descripcion: descripcion,
        fecha: _reloj.ahora,
      ),
    );

    return ResultadoEjecucion(
      decision: d,
      ejecutada: creada.esExito,
      detalle: creada.esExito
          ? 'Notificación enviada'
          : 'No se pudo registrar la notificación',
    );
  }
}
