import '../../../../core/error/failures.dart';
import '../../../../core/error/result.dart';
import '../../../administracion/domain/entities/configuracion_biblioteca.dart';
import '../../../lectores/domain/entities/lector.dart';
import '../entities/prestamo.dart';

/// Habilitación de un lector para llevarse un ejemplar más (spec v2 §7).
///
/// Es una función pura: recibe todo lo que necesita y no toca repositorios.
/// Eso la vuelve trivial de testear —sin dobles de prueba ni almacenamiento—
/// y permite reusarla tanto en el caso de uso que registra el préstamo como
/// en la UI del mostrador, que necesita anticipar el rechazo antes de que el
/// bibliotecario apriete el botón.
class PoliticaDePrestamo {
  const PoliticaDePrestamo();

  Result<Lector> verificar({
    required Lector lector,
    required List<Prestamo> prestamosDelLector,
    required ConfiguracionBiblioteca configuracion,
  }) {
    if (lector.pendienteDeVerificacion) {
      return const Fallo(ReglaDeNegocioFailure(
        'La cuenta está pendiente de verificación por un bibliotecario.',
      ));
    }

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
        'Tenés préstamos vencidos sin devolver. '
        'Devolvelos antes de pedir nuevos.',
      ));
    }

    final limite = configuracion.limiteEjemplaresPara(lector.categoria);
    final activos = prestamosDelLector
        .where((p) => p.estado == EstadoPrestamo.activo)
        .length;
    if (activos >= limite) {
      return Fallo(ReglaDeNegocioFailure(
        'Alcanzaste el límite de $limite préstamos simultáneos de tu categoría',
      ));
    }

    return Exito(lector);
  }
}
