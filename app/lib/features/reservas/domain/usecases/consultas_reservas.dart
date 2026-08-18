/// Consultas de sólo lectura sobre las reservas.
library;

import 'package:equatable/equatable.dart';

import '../../../../core/error/result.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/reserva.dart';
import '../repositories/reserva_repository.dart';

class ReservasDeLectorParams extends Equatable {
  const ReservasDeLectorParams(this.lectorId);

  final String lectorId;

  @override
  List<Object?> get props => [lectorId];
}

/// Reservas del lector, de la más reciente a la más vieja.
class ObtenerReservasDeLector
    implements UseCase<List<Reserva>, ReservasDeLectorParams> {
  const ObtenerReservasDeLector(this._repository);

  final ReservaRepository _repository;

  @override
  Future<Result<List<Reserva>>> call(ReservasDeLectorParams params) async {
    final result = await _repository.obtenerDeLector(params.lectorId);
    return result.map((reservas) {
      final ordenadas = reservas.toList()
        ..sort((a, b) => b.fechaReserva.compareTo(a.fechaReserva));
      return ordenadas;
    });
  }
}

class ColaDeReservasParams extends Equatable {
  const ColaDeReservasParams(this.libroId);

  final String libroId;

  @override
  List<Object?> get props => [libroId];
}

/// Cola de espera de un título, en orden cronológico estricto.
class ObtenerColaDeReservas
    implements UseCase<List<Reserva>, ColaDeReservasParams> {
  const ObtenerColaDeReservas(this._repository);

  final ReservaRepository _repository;

  @override
  Future<Result<List<Reserva>>> call(ColaDeReservasParams params) =>
      _repository.obtenerCola(params.libroId);
}

class ObtenerTodasLasReservas implements UseCase<List<Reserva>, SinParametros> {
  const ObtenerTodasLasReservas(this._repository);

  final ReservaRepository _repository;

  @override
  Future<Result<List<Reserva>>> call(SinParametros params) =>
      _repository.obtenerTodas();
}
