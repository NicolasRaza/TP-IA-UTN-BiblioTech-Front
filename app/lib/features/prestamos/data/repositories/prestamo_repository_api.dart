import '../../../../core/error/failures.dart';
import '../../../../core/error/result.dart';
import '../../../lectores/domain/repositories/lector_repository.dart';
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
  const PrestamoRepositoryApi({
    required PrestamoApiDataSource api,
    required LectorRepository lectores,
  })  : _api = api,
        _lectores = lectores;

  final PrestamoApiDataSource _api;
  final LectorRepository _lectores;

  @override
  Future<Result<List<Prestamo>>> obtenerDeLector(String lectorId) =>
      _api.deLector(lectorId);

  /// La API v1 sólo expone los préstamos de un lector puntual: no hay una ruta
  /// que devuelva la circulación completa. Se arma recorriendo el padrón, que
  /// es la única fuente real disponible.
  ///
  /// Son N+1 requests, aceptable para el tamaño de una biblioteca de la demo y
  /// preferible a mostrar datos inventados. Un `GET /prestamos` en el backend
  /// lo reemplazaría por una sola llamada.
  @override
  Future<Result<List<Prestamo>>> obtenerTodos() async {
    final padron = await _lectores.obtenerLectores();
    if (padron case Fallo(:final failure)) return Fallo(failure);

    final todos = <Prestamo>[];
    for (final lector in padron.valorONull!) {
      final suyos = await _api.deLector(lector.id);
      if (suyos case Fallo(:final failure)) return Fallo(failure);
      todos.addAll(suyos.valorONull!);
    }
    return Exito(todos);
  }

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
