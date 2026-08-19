import '../../../../core/error/failures.dart';
import '../../../../core/error/result.dart';
import '../../domain/entities/prestamo.dart';
import '../../domain/repositories/prestamo_repository.dart';
import '../datasources/prestamo_api_datasource.dart';

/// Implementación del [PrestamoRepository] contra la API del backend.
///
/// Es de sólo lectura a propósito: dar un préstamo o registrar una devolución
/// son transacciones del servidor y viajan por `PrestamoRemotoApi`, no por
/// este contrato. Los métodos de escritura del contrato local —`crear`,
/// `actualizar`— fallan explícitamente en vez de simular que guardaron algo.
class PrestamoRepositoryApi implements PrestamoRepository {
  const PrestamoRepositoryApi(this._api);

  final PrestamoApiDataSource _api;

  @override
  Future<Result<List<Prestamo>>> obtenerDeLector(String lectorId) =>
      _api.deLector(lectorId);

  /// `GET /prestamos`, que además completa el título de cada préstamo. Sólo
  /// responde a bibliotecarios y administradores, que son los únicos que ven
  /// la circulación completa.
  @override
  Future<Result<List<Prestamo>>> obtenerTodos() => _api.todos();

  @override
  Future<Result<Prestamo>> obtenerPorId(String prestamoId) async {
    final todos = await obtenerTodos();
    if (todos case Fallo(:final failure)) return Fallo(failure);

    for (final p in todos.valorONull!) {
      if (p.id == prestamoId) return Exito(p);
    }
    return const Fallo(NoEncontradoFailure('El préstamo no existe'));
  }

  @override
  Future<Result<Prestamo>> crear(Prestamo prestamo) async => const Fallo(
        ReglaDeNegocioFailure(
          'El préstamo lo registra el servidor al escanear la etiqueta',
        ),
      );

  @override
  Future<Result<Prestamo>> actualizar(Prestamo prestamo) async => const Fallo(
        ReglaDeNegocioFailure(
          'El estado del préstamo lo administra el servidor',
        ),
      );

  @override
  Future<Result<void>> actualizarVarios(List<Prestamo> prestamos) async =>
      const Fallo(ReglaDeNegocioFailure(
        'El vencimiento de los préstamos lo procesa el servidor',
      ));
}
