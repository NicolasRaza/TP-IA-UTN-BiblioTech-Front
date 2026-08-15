import '../../../../core/services/reloj.dart';
import '../../../catalogo/domain/entities/ejemplar.dart';
import '../../../catalogo/domain/repositories/catalogo_repository.dart';
import '../../../notificaciones/domain/entities/notificacion.dart';
import '../../../notificaciones/domain/repositories/notificacion_repository.dart';
import '../entities/reserva.dart';
import '../repositories/reserva_repository.dart';

/// Ofrece un ejemplar libre al primero de la cola de un título.
///
/// Es un servicio de dominio y no un caso de uso porque no lo dispara el
/// usuario: es una consecuencia que tres flujos distintos deben producir —una
/// devolución, la cancelación de una reserva retenida, y el vencimiento del
/// plazo de retiro—. Tenerlo en un solo lugar es lo que garantiza que el
/// orden cronológico de la cola (spec v2 §7) se respete siempre igual.
class AsignadorDeCola {
  const AsignadorDeCola({
    required ReservaRepository reservaRepository,
    required CatalogoRepository catalogoRepository,
    required NotificacionRepository notificacionRepository,
    required Reloj reloj,
  })  : _reservas = reservaRepository,
        _catalogo = catalogoRepository,
        _notificaciones = notificacionRepository,
        _reloj = reloj;

  final ReservaRepository _reservas;
  final CatalogoRepository _catalogo;
  final NotificacionRepository _notificaciones;
  final Reloj _reloj;

  /// Retiene un ejemplar para el primero de la cola y arranca su plazo de
  /// retiro. Devuelve la reserva promovida, o `null` si no había a quién
  /// asignarle nada.
  ///
  /// No falla si no hay cola o no hay ejemplares: ese es un desenlace
  /// esperado, no un error.
  Future<Reserva?> asignarSiguiente(String libroId) async {
    final colaResult = await _reservas.obtenerCola(libroId);
    final cola = colaResult.valorONull;
    if (cola == null || cola.isEmpty) return null;

    // Si ya hay una reserva retenida, el ejemplar está comprometido: nadie
    // más de la cola puede recibirlo hasta que se resuelva.
    if (cola.any((r) => r.estaRetenida)) return null;

    final libroResult = await _catalogo.obtenerPorId(libroId);
    final libro = libroResult.valorONull;
    final disponible = libro?.primerEjemplarDisponible;
    if (libro == null || disponible == null) return null;

    final primera = cola.first;
    final promovida = primera.copyWith(
      estado: EstadoReserva.lista,
      fechaVencimientoRetiro: _reloj.ahora
          .add(Duration(hours: primera.plazoRetiroHorasAlReservar)),
      ejemplarAsignadoId: disponible.id,
    );

    final guardada = await _reservas.actualizar(promovida);
    if (guardada.esFallo) return null;

    await _catalogo.cambiarEstadoEjemplar(
      libroId,
      disponible.id,
      EstadoEjemplar.reservado,
    );

    await _notificaciones.crear(
      Notificacion(
        id: '',
        lectorId: primera.lectorId,
        tipo: TipoNotificacion.reservaDisponible,
        titulo: '¡Tu reserva está lista!',
        descripcion: '"${libro.titulo}" ya está disponible para retirar. '
            'Tenés ${primera.plazoRetiroHorasAlReservar} horas para buscarlo.',
        fecha: _reloj.ahora,
      ),
    );

    return guardada.valorONull;
  }
}
