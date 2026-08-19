import '../../../../core/error/failures.dart';
import '../../../../core/error/result.dart';
import '../../../lectores/domain/repositories/lector_repository.dart';
import '../../domain/entities/reserva.dart';
import '../../domain/repositories/reserva_repository.dart';
import '../datasources/reserva_api_datasource.dart';

/// Implementación del [ReservaRepository] contra la API del backend.
///
/// De sólo lectura, por el mismo motivo que `PrestamoRepositoryApi`: crear y
/// cancelar reservas son transacciones del servidor y viajan por
/// `ReservaRemotaApi`.
class ReservaRepositoryApi implements ReservaRepository {
  const ReservaRepositoryApi({
    required ReservaApiDataSource api,
    required LectorRepository lectores,
  })  : _api = api,
        _lectores = lectores;

  final ReservaApiDataSource _api;
  final LectorRepository _lectores;

  @override
  Future<Result<List<Reserva>>> obtenerDeLector(String lectorId) =>
      _api.deLector(lectorId);

  /// Igual que con los préstamos, la API sólo expone las reservas de un lector
  /// puntual; el conjunto se arma recorriendo el padrón. Un `GET /reservas` en
  /// el backend lo reduciría a una sola llamada.
  @override
  Future<Result<List<Reserva>>> obtenerTodas() async {
    final padron = await _lectores.obtenerLectores();
    if (padron case Fallo(:final failure)) return Fallo(failure);

    final todas = <Reserva>[];
    for (final lector in padron.valorONull!) {
      final suyas = await _api.deLector(lector.id);
      if (suyas case Fallo(:final failure)) return Fallo(failure);
      todas.addAll(suyas.valorONull!);
    }
    return Exito(todas);
  }

  @override
  Future<Result<List<Reserva>>> obtenerCola(String libroId) async {
    final todas = await obtenerTodas();
    if (todas case Fallo(:final failure)) return Fallo(failure);

    final cola = todas.valorONull!
        .where((r) => r.libroId == libroId && r.esActiva)
        .toList()
      ..sort((a, b) => a.fechaReserva.compareTo(b.fechaReserva));

    return Exito(cola);
  }

  @override
  Future<Result<Reserva>> obtenerPorId(String reservaId) async {
    final todas = await obtenerTodas();
    if (todas case Fallo(:final failure)) return Fallo(failure);

    for (final r in todas.valorONull!) {
      if (r.id == reservaId) return Exito(r);
    }
    return const Fallo(NoEncontradoFailure('La reserva no existe'));
  }

  @override
  Future<Result<Reserva>> crear(Reserva reserva) async => const Fallo(
        ReglaDeNegocioFailure('La reserva la registra el servidor'),
      );

  @override
  Future<Result<Reserva>> actualizar(Reserva reserva) async => const Fallo(
        ReglaDeNegocioFailure(
          'El estado de la reserva lo administra el servidor',
        ),
      );

  @override
  Future<Result<void>> actualizarVarias(List<Reserva> reservas) async =>
      const Fallo(ReglaDeNegocioFailure(
        'El vencimiento de las reservas lo procesa el servidor',
      ));
}
