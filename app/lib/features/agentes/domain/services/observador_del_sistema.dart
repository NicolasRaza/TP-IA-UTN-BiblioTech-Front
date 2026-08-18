import '../../../../core/error/result.dart';
import '../../../../core/services/reloj.dart';
import '../../../administracion/domain/repositories/configuracion_repository.dart';
import '../../../catalogo/domain/repositories/catalogo_repository.dart';
import '../../../lectores/domain/repositories/lector_repository.dart';
import '../../../prestamos/domain/repositories/prestamo_repository.dart';
import '../../../reservas/domain/repositories/reserva_repository.dart';
import '../entities/estado_del_sistema.dart';

/// Fase de **Observación** del ciclo de agentes (spec v2 §5).
///
/// Reúne en una sola pasada todo lo que los agentes necesitan mirar y lo
/// congela en un [EstadoDelSistema]. Es el único punto del ciclo que habla con
/// los repositorios: de acá en adelante, Evaluador y Planificador trabajan
/// sobre datos ya leídos y consistentes entre sí.
class ObservadorDelSistema {
  const ObservadorDelSistema({
    required CatalogoRepository catalogoRepository,
    required LectorRepository lectorRepository,
    required PrestamoRepository prestamoRepository,
    required ReservaRepository reservaRepository,
    required ConfiguracionRepository configuracionRepository,
    required Reloj reloj,
  })  : _catalogo = catalogoRepository,
        _lectores = lectorRepository,
        _prestamos = prestamoRepository,
        _reservas = reservaRepository,
        _configuracion = configuracionRepository,
        _reloj = reloj;

  final CatalogoRepository _catalogo;
  final LectorRepository _lectores;
  final PrestamoRepository _prestamos;
  final ReservaRepository _reservas;
  final ConfiguracionRepository _configuracion;
  final Reloj _reloj;

  Future<Result<EstadoDelSistema>> observar() async {
    final librosResult = await _catalogo.obtenerTodos();
    if (librosResult case Fallo(:final failure)) return Fallo(failure);

    final lectoresResult = await _lectores.obtenerLectores();
    if (lectoresResult case Fallo(:final failure)) return Fallo(failure);

    final prestamosResult = await _prestamos.obtenerTodos();
    if (prestamosResult case Fallo(:final failure)) return Fallo(failure);

    final reservasResult = await _reservas.obtenerTodas();
    if (reservasResult case Fallo(:final failure)) return Fallo(failure);

    final configResult = await _configuracion.obtener();
    if (configResult case Fallo(:final failure)) return Fallo(failure);

    return Exito(EstadoDelSistema(
      momento: _reloj.ahora,
      configuracion: configResult.valorONull!,
      libros: librosResult.valorONull!,
      lectores: lectoresResult.valorONull!,
      prestamos: prestamosResult.valorONull!,
      reservas: reservasResult.valorONull!,
    ));
  }
}
