/// Casos de uso del panel del administrador: parámetros, auditoría y
/// reinicio de los datos de demostración.
library;

import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/error/result.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/configuracion_biblioteca.dart';
import '../entities/evento_auditoria.dart';
import '../repositories/auditoria_repository.dart';
import '../repositories/configuracion_repository.dart';

class ObtenerConfiguracion
    implements UseCase<ConfiguracionBiblioteca, SinParametros> {
  const ObtenerConfiguracion(this._repository);

  final ConfiguracionRepository _repository;

  @override
  Future<Result<ConfiguracionBiblioteca>> call(SinParametros params) =>
      _repository.obtener();
}

class GuardarConfiguracionParams extends Equatable {
  const GuardarConfiguracionParams({
    required this.configuracion,
    this.usuarioId,
  });

  final ConfiguracionBiblioteca configuracion;
  final String? usuarioId;

  @override
  List<Object?> get props => [configuracion, usuarioId];
}

/// Persiste los parámetros de la biblioteca.
///
/// Valida los rangos antes de guardar: un plazo de cero días o una multa
/// negativa dejarían al sistema calculando vencimientos imposibles.
class GuardarConfiguracion
    implements UseCase<ConfiguracionBiblioteca, GuardarConfiguracionParams> {
  const GuardarConfiguracion({
    required ConfiguracionRepository configuracionRepository,
    required AuditoriaRepository auditoriaRepository,
  })  : _configuracion = configuracionRepository,
        _auditoria = auditoriaRepository;

  final ConfiguracionRepository _configuracion;
  final AuditoriaRepository _auditoria;

  @override
  Future<Result<ConfiguracionBiblioteca>> call(
      GuardarConfiguracionParams params) async {
    final cfg = params.configuracion;

    if (cfg.plazoPrestamoDias.values.any((d) => d < 1)) {
      return const Fallo(ValidacionFailure(
          'Los plazos de préstamo deben ser de al menos 1 día'));
    }
    if (cfg.limiteEjemplares.values.any((n) => n < 1) ||
        cfg.limiteReservas.values.any((n) => n < 1)) {
      return const Fallo(
          ValidacionFailure('Los límites deben ser de al menos 1'));
    }
    if (cfg.multaPorDiaDemora < 0) {
      return const Fallo(
          ValidacionFailure('La multa por día no puede ser negativa'));
    }
    if (cfg.plazoRetiroReservaHoras < 1) {
      return const Fallo(
          ValidacionFailure('El plazo de retiro debe ser de al menos 1 hora'));
    }
    if (cfg.pesoHistorialRecomendacion < 0 ||
        cfg.pesoHistorialRecomendacion > 1) {
      return const Fallo(
          ValidacionFailure('El peso del historial debe estar entre 0 y 1'));
    }

    final guardada = await _configuracion.guardar(cfg);
    if (guardada case Fallo(:final failure)) return Fallo(failure);

    await _auditoria.registrar(
      tipo: TipoEventoAuditoria.cambioConfig,
      descripcion: 'Actualización de parámetros de la biblioteca',
      usuarioId: params.usuarioId,
    );

    return guardada;
  }
}

class ObtenerAuditoria
    implements UseCase<List<EventoAuditoria>, SinParametros> {
  const ObtenerAuditoria(this._repository);

  final AuditoriaRepository _repository;

  @override
  Future<Result<List<EventoAuditoria>>> call(SinParametros params) =>
      _repository.obtenerTodos();
}
