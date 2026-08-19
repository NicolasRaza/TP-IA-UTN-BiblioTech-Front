import '../../../../core/api/sesion_api.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/error/result.dart';
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
    required SesionApi sesion,
  })  : _api = api,
        _sesion = sesion;

  final ReservaApiDataSource _api;

  /// Para saber de quién es la sesión: `GET /reservas` pide rol bibliotecario,
  /// así que un lector sólo puede llegar a las suyas.
  final SesionApi _sesion;

  @override
  Future<Result<List<Reserva>>> obtenerDeLector(String lectorId) =>
      _api.deLector(lectorId);

  /// `GET /reservas`. Sólo responde a bibliotecarios y administradores.
  @override
  Future<Result<List<Reserva>>> obtenerTodas() => _api.todas();

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

  /// Busca primero entre las reservas del dueño de la sesión y recién después
  /// en el conjunto.
  ///
  /// El orden importa por permisos, no por rendimiento: un lector puede leer
  /// las suyas —que son las únicas que va a cancelar— pero no `GET /reservas`.
  /// Empezar por el listado global le daría un 403 al cancelar su propia
  /// reserva.
  @override
  Future<Result<Reserva>> obtenerPorId(String reservaId) async {
    final lectorId = _sesion.usuario?.lectorId;
    if (lectorId != null) {
      final propias = await _api.deLector('$lectorId');
      for (final r in propias.valorONull ?? const <Reserva>[]) {
        if (r.id == reservaId) return Exito(r);
      }
    }

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
