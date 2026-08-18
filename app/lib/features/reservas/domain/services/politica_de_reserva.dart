import '../../../../core/error/failures.dart';
import '../../../../core/error/result.dart';
import '../../../administracion/domain/entities/configuracion_biblioteca.dart';
import '../../../lectores/domain/entities/lector.dart';
import '../../../prestamos/domain/entities/prestamo.dart';
import '../entities/reserva.dart';

/// Habilitación de un lector para reservar un título.
///
/// Spec v2 §7: "no puede reservar nuevos libros si posee material con fecha de
/// devolución vencida o multas impagas". Misma restricción que el préstamo,
/// más su propio límite de reservas simultáneas.
class PoliticaDeReserva {
  const PoliticaDeReserva();

  Result<Lector> verificar({
    required Lector lector,
    required List<Prestamo> prestamosDelLector,
    required List<Reserva> reservasDelLector,
    required ConfiguracionBiblioteca configuracion,
  }) {
    if (!lector.activo) {
      return const Fallo(ReglaDeNegocioFailure('La cuenta está inactiva'));
    }

    if (lector.tieneMultas) {
      return Fallo(ReglaDeNegocioFailure(
        'Multa pendiente de \$${lector.multasPendientes}. '
        'Saldala en el mostrador.',
      ));
    }

    final vencidos = prestamosDelLector
        .where((p) => p.estado == EstadoPrestamo.vencido)
        .length;
    if (vencidos > 0) {
      return const Fallo(ReglaDeNegocioFailure(
        'Tenés préstamos vencidos. Regularizalos para poder reservar.',
      ));
    }

    final limite = configuracion.limiteReservasPara(lector.categoria);
    final activas = reservasDelLector.where((r) => r.esActiva).length;
    if (activas >= limite) {
      return Fallo(ReglaDeNegocioFailure(
        'Alcanzaste el límite de $limite reservas simultáneas',
      ));
    }

    return Exito(lector);
  }
}
