/// Consultas de sólo lectura sobre la circulación.
library;

import 'package:equatable/equatable.dart';

import '../../../../core/error/result.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/prestamo.dart';
import '../repositories/prestamo_repository.dart';

class PrestamosDeLectorParams extends Equatable {
  const PrestamosDeLectorParams(this.lectorId);

  final String lectorId;

  @override
  List<Object?> get props => [lectorId];
}

/// Préstamos abiertos del lector, del que vence antes al que vence después.
class ObtenerPrestamosActivos
    implements UseCase<List<Prestamo>, PrestamosDeLectorParams> {
  const ObtenerPrestamosActivos(this._repository);

  final PrestamoRepository _repository;

  @override
  Future<Result<List<Prestamo>>> call(PrestamosDeLectorParams params) async {
    final result = await _repository.obtenerDeLector(params.lectorId);
    return result.map((prestamos) {
      final abiertos = prestamos.where((p) => p.estaAbierto).toList()
        ..sort((a, b) => a.fechaVencimiento.compareTo(b.fechaVencimiento));
      return abiertos;
    });
  }
}

/// Préstamos ya devueltos, del más reciente al más viejo.
class ObtenerHistorialPrestamos
    implements UseCase<List<Prestamo>, PrestamosDeLectorParams> {
  const ObtenerHistorialPrestamos(this._repository);

  final PrestamoRepository _repository;

  @override
  Future<Result<List<Prestamo>>> call(PrestamosDeLectorParams params) async {
    final result = await _repository.obtenerDeLector(params.lectorId);
    return result.map((prestamos) {
      final devueltos = prestamos
          .where((p) => p.estado == EstadoPrestamo.devuelto)
          .toList()
        ..sort((a, b) => (b.fechaDevolucion ?? b.fechaPrestamo)
            .compareTo(a.fechaDevolucion ?? a.fechaPrestamo));
      return devueltos;
    });
  }
}

class ObtenerTodosLosPrestamos
    implements UseCase<List<Prestamo>, SinParametros> {
  const ObtenerTodosLosPrestamos(this._repository);

  final PrestamoRepository _repository;

  @override
  Future<Result<List<Prestamo>>> call(SinParametros params) =>
      _repository.obtenerTodos();
}

/// Indicadores de circulación para el panel del bibliotecario.
class ObtenerEstadisticasPrestamos
    implements UseCase<EstadisticasPrestamos, SinParametros> {
  const ObtenerEstadisticasPrestamos(this._repository);

  final PrestamoRepository _repository;

  @override
  Future<Result<EstadisticasPrestamos>> call(SinParametros params) async {
    final result = await _repository.obtenerTodos();
    return result.map(EstadisticasPrestamos.desde);
  }
}
