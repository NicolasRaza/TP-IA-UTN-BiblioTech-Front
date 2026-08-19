/// Casos de uso de la sesión: iniciar, cerrar y recuperar la sesión activa.
library;

import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/error/result.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../lectores/domain/entities/lector.dart';
import '../repositories/sesion_repository.dart';

class IniciarSesionParams extends Equatable {
  const IniciarSesionParams({required this.email, required this.clave});

  final String email;

  /// PIN o contraseña, según contra qué esté corriendo la app.
  final String clave;

  @override
  List<Object?> get props => [email, clave];
}

/// Valida credenciales y abre la sesión.
class IniciarSesion implements UseCase<Lector, IniciarSesionParams> {
  const IniciarSesion(this._repository);

  final SesionRepository _repository;

  @override
  Future<Result<Lector>> call(IniciarSesionParams params) async {
    if (params.email.trim().isEmpty) {
      return const Fallo(ValidacionFailure('Ingresá tu email'));
    }
    if (params.clave.trim().isEmpty) {
      return const Fallo(ValidacionFailure('Ingresá tu clave'));
    }

    return _repository.iniciarSesion(
      email: params.email.trim(),
      clave: params.clave.trim(),
    );
  }
}

class CerrarSesion implements UseCase<void, SinParametros> {
  const CerrarSesion(this._repository);

  final SesionRepository _repository;

  @override
  Future<Result<void>> call(SinParametros params) => _repository.cerrarSesion();
}

/// Recupera la sesión persistida al arrancar la app.
class ObtenerSesionActiva implements UseCase<Lector?, SinParametros> {
  const ObtenerSesionActiva(this._repository);

  final SesionRepository _repository;

  @override
  Future<Result<Lector?>> call(SinParametros params) =>
      _repository.obtenerSesionActiva();
}
