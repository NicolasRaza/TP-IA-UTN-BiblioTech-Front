/// Casos de uso del buzón de avisos del lector.
library;

import 'package:equatable/equatable.dart';

import '../../../../core/error/result.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/notificacion.dart';
import '../repositories/notificacion_repository.dart';

class LectorParams extends Equatable {
  const LectorParams(this.lectorId);

  final String lectorId;

  @override
  List<Object?> get props => [lectorId];
}

class ObtenerNotificaciones
    implements UseCase<List<Notificacion>, LectorParams> {
  const ObtenerNotificaciones(this._repository);

  final NotificacionRepository _repository;

  @override
  Future<Result<List<Notificacion>>> call(LectorParams params) =>
      _repository.obtenerDeLector(params.lectorId);
}

class ContarNoLeidas implements UseCase<int, LectorParams> {
  const ContarNoLeidas(this._repository);

  final NotificacionRepository _repository;

  @override
  Future<Result<int>> call(LectorParams params) =>
      _repository.contarNoLeidas(params.lectorId);
}

class MarcarNotificacionLeidaParams extends Equatable {
  const MarcarNotificacionLeidaParams(this.notificacionId);

  final String notificacionId;

  @override
  List<Object?> get props => [notificacionId];
}

class MarcarNotificacionLeida
    implements UseCase<void, MarcarNotificacionLeidaParams> {
  const MarcarNotificacionLeida(this._repository);

  final NotificacionRepository _repository;

  @override
  Future<Result<void>> call(MarcarNotificacionLeidaParams params) =>
      _repository.marcarLeida(params.notificacionId);
}

class MarcarTodasLeidas implements UseCase<void, LectorParams> {
  const MarcarTodasLeidas(this._repository);

  final NotificacionRepository _repository;

  @override
  Future<Result<void>> call(LectorParams params) =>
      _repository.marcarTodasLeidas(params.lectorId);
}
