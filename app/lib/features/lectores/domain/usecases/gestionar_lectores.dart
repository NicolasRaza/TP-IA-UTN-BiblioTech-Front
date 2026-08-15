/// Alta, edición y consultas del padrón de lectores.
library;

import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/error/result.dart';
import '../../../../core/services/reloj.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../administracion/domain/entities/evento_auditoria.dart';
import '../../../administracion/domain/repositories/auditoria_repository.dart';
import '../../../administracion/domain/repositories/configuracion_repository.dart';
import '../entities/lector.dart';
import '../repositories/lector_repository.dart';
import '../services/politica_de_categoria.dart';

/// Lectores registrados, sin el personal de la biblioteca.
class ObtenerLectores implements UseCase<List<Lector>, SinParametros> {
  const ObtenerLectores(this._repository);

  final LectorRepository _repository;

  @override
  Future<Result<List<Lector>>> call(SinParametros params) =>
      _repository.obtenerLectores();
}

/// Todas las personas registradas, personal incluido. La auditoría lo usa
/// para resolver el nombre de quien ejecutó cada acción.
class ObtenerUsuarios implements UseCase<List<Lector>, SinParametros> {
  const ObtenerUsuarios(this._repository);

  final LectorRepository _repository;

  @override
  Future<Result<List<Lector>>> call(SinParametros params) =>
      _repository.obtenerUsuarios();
}

class ObtenerLectorParams extends Equatable {
  const ObtenerLectorParams(this.lectorId);

  final String lectorId;

  @override
  List<Object?> get props => [lectorId];
}

class ObtenerLector implements UseCase<Lector, ObtenerLectorParams> {
  const ObtenerLector(this._repository);

  final LectorRepository _repository;

  @override
  Future<Result<Lector>> call(ObtenerLectorParams params) =>
      _repository.obtenerPorId(params.lectorId);
}

class BuscarLectorPorQrParams extends Equatable {
  const BuscarLectorPorQrParams(this.qr);

  final String qr;

  @override
  List<Object?> get props => [qr];
}

/// Identifica al lector por su credencial. Es la entrada del mostrador.
class BuscarLectorPorQr implements UseCase<Lector, BuscarLectorPorQrParams> {
  const BuscarLectorPorQr(this._repository);

  final LectorRepository _repository;

  @override
  Future<Result<Lector>> call(BuscarLectorPorQrParams params) =>
      _repository.obtenerPorQr(params.qr);
}

class RegistrarLectorParams extends Equatable {
  const RegistrarLectorParams({required this.lector, this.usuarioId});

  final Lector lector;
  final String? usuarioId;

  @override
  List<Object?> get props => [lector, usuarioId];
}

/// Da de alta un lector.
///
/// Un menor de edad necesita tutor declarado (spec v2 §3), y el email no
/// puede repetirse porque es la credencial de acceso.
class RegistrarLector implements UseCase<Lector, RegistrarLectorParams> {
  const RegistrarLector({
    required LectorRepository lectorRepository,
    required AuditoriaRepository auditoriaRepository,
  })  : _lectores = lectorRepository,
        _auditoria = auditoriaRepository;

  final LectorRepository _lectores;
  final AuditoriaRepository _auditoria;

  @override
  Future<Result<Lector>> call(RegistrarLectorParams params) async {
    final lector = params.lector;

    if (lector.nombre.trim().isEmpty || lector.apellido.trim().isEmpty) {
      return const Fallo(
          ValidacionFailure('Nombre y apellido son obligatorios'));
    }
    if (lector.email.trim().isEmpty) {
      return const Fallo(ValidacionFailure('El email es obligatorio'));
    }
    if (lector.categoria == CategoriaLector.menor &&
        (lector.tutor == null || lector.tutor!.trim().isEmpty)) {
      return const Fallo(ValidacionFailure(
          'Un lector menor de edad necesita un tutor declarado'));
    }

    final existente = await _lectores.obtenerPorEmail(lector.email);
    if (existente.esExito) {
      return const Fallo(ValidacionFailure('Ya hay una cuenta con ese email'));
    }

    final creado = await _lectores.crear(lector);
    if (creado case Fallo(:final failure)) return Fallo(failure);

    await _auditoria.registrar(
      tipo: TipoEventoAuditoria.altaLector,
      descripcion: 'Alta del lector ${creado.valorONull!.nombreCompleto}',
      usuarioId: params.usuarioId,
    );

    return creado;
  }
}

class ActualizarLectorParams extends Equatable {
  const ActualizarLectorParams({required this.lector, this.usuarioId});

  final Lector lector;
  final String? usuarioId;

  @override
  List<Object?> get props => [lector, usuarioId];
}

class ActualizarLector implements UseCase<Lector, ActualizarLectorParams> {
  const ActualizarLector({
    required LectorRepository lectorRepository,
    required AuditoriaRepository auditoriaRepository,
  })  : _lectores = lectorRepository,
        _auditoria = auditoriaRepository;

  final LectorRepository _lectores;
  final AuditoriaRepository _auditoria;

  @override
  Future<Result<Lector>> call(ActualizarLectorParams params) async {
    final actualizado = await _lectores.actualizar(params.lector);
    if (actualizado case Fallo(:final failure)) return Fallo(failure);

    await _auditoria.registrar(
      tipo: TipoEventoAuditoria.edicionLector,
      descripcion: 'Edición del lector ${params.lector.nombreCompleto}',
      usuarioId: params.usuarioId,
    );

    return actualizado;
  }
}

/// Lectores cuya categoría quedó desfasada respecto de su edad.
///
/// Alimenta la decisión `sugerirRevisionCategoria` del Agente Evaluador: el
/// sistema no cambia la categoría por su cuenta, sólo la propone.
class ObtenerLectoresConCategoriaDesactualizada
    implements UseCase<List<Lector>, SinParametros> {
  const ObtenerLectoresConCategoriaDesactualizada({
    required LectorRepository lectorRepository,
    required ConfiguracionRepository configuracionRepository,
    required Reloj reloj,
    PoliticaDeCategoria politica = const PoliticaDeCategoria(),
  })  : _lectores = lectorRepository,
        _configuracion = configuracionRepository,
        _reloj = reloj,
        _politica = politica;

  final LectorRepository _lectores;
  final ConfiguracionRepository _configuracion;
  final Reloj _reloj;
  final PoliticaDeCategoria _politica;

  @override
  Future<Result<List<Lector>>> call(SinParametros params) async {
    final lectoresResult = await _lectores.obtenerLectores();
    if (lectoresResult case Fallo(:final failure)) return Fallo(failure);

    final configResult = await _configuracion.obtener();
    if (configResult case Fallo(:final failure)) return Fallo(failure);

    final ahora = _reloj.ahora;
    final desactualizados = lectoresResult.valorONull!
        .where((l) => _politica.estaDesactualizada(
              lector: l,
              configuracion: configResult.valorONull!,
              ahora: ahora,
            ))
        .toList();

    return Exito(desactualizados);
  }
}
