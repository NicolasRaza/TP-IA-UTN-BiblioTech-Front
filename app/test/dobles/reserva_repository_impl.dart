import 'package:bibliotech/core/error/failures.dart';
import 'package:bibliotech/core/error/result.dart';
import 'package:bibliotech/core/services/reloj.dart';
import 'package:bibliotech/features/reservas/domain/entities/reserva.dart';
import 'package:bibliotech/features/reservas/domain/repositories/reserva_repository.dart';
import 'reserva_local_datasource.dart';

/// Implementación del [ReservaRepository] sobre el almacenamiento local.
class ReservaRepositoryImpl implements ReservaRepository {
  const ReservaRepositoryImpl({
    required ReservaLocalDataSource localDataSource,
    required GeneradorId generadorId,
  })  : _local = localDataSource,
        _generadorId = generadorId;

  final ReservaLocalDataSource _local;
  final GeneradorId _generadorId;

  @override
  Future<Result<List<Reserva>>> obtenerTodas() async =>
      _local.leer().map((r) => r.cast<Reserva>());

  @override
  Future<Result<List<Reserva>>> obtenerDeLector(String lectorId) async =>
      _local.leer().map(
            (reservas) => reservas
                .where((r) => r.lectorId == lectorId)
                .cast<Reserva>()
                .toList(),
          );

  @override
  Future<Result<List<Reserva>>> obtenerCola(String libroId) async =>
      _local.leer().map((reservas) {
        // El orden cronológico estricto es la regla de la cola (spec v2 §7);
        // se aplica acá para que ningún llamador pueda olvidarse de ordenar.
        final cola = reservas
            .where((r) => r.libroId == libroId && r.esActiva)
            .cast<Reserva>()
            .toList()
          ..sort((a, b) => a.fechaReserva.compareTo(b.fechaReserva));
        return cola;
      });

  @override
  Future<Result<Reserva>> obtenerPorId(String reservaId) async {
    final leidas = _local.leer();
    if (leidas case Fallo(:final failure)) return Fallo(failure);

    for (final r in leidas.valorONull!) {
      if (r.id == reservaId) return Exito(r);
    }
    return const Fallo(NoEncontradoFailure('La reserva no existe'));
  }

  @override
  Future<Result<Reserva>> crear(Reserva reserva) async {
    final leidas = _local.leer();
    if (leidas case Fallo(:final failure)) return Fallo(failure);

    final nueva = reserva.id.isEmpty
        ? _conId(reserva, 'res-${_generadorId.generar()}')
        : reserva;

    final guardado = _local.guardar([...leidas.valorONull!, nueva]);
    if (guardado case Fallo(:final failure)) return Fallo(failure);

    return Exito(nueva);
  }

  @override
  Future<Result<Reserva>> actualizar(Reserva reserva) async {
    final leidas = _local.leer();
    if (leidas case Fallo(:final failure)) return Fallo(failure);

    final lista = leidas.valorONull!.cast<Reserva>().toList();
    final i = lista.indexWhere((r) => r.id == reserva.id);
    if (i < 0) return const Fallo(NoEncontradoFailure('La reserva no existe'));

    lista[i] = reserva;
    final guardado = _local.guardar(lista);
    if (guardado case Fallo(:final failure)) return Fallo(failure);

    return Exito(reserva);
  }

  @override
  Future<Result<void>> actualizarVarias(List<Reserva> reservas) async {
    if (reservas.isEmpty) return const Exito(null);

    final leidas = _local.leer();
    if (leidas case Fallo(:final failure)) return Fallo(failure);

    final porId = {for (final r in reservas) r.id: r};
    final lista =
        leidas.valorONull!.map<Reserva>((r) => porId[r.id] ?? r).toList();

    return _local.guardar(lista);
  }

  Reserva _conId(Reserva r, String id) => Reserva(
        id: id,
        lectorId: r.lectorId,
        libroId: r.libroId,
        fechaReserva: r.fechaReserva,
        fechaVencimientoRetiro: r.fechaVencimientoRetiro,
        estado: r.estado,
        ejemplarAsignadoId: r.ejemplarAsignadoId,
        plazoRetiroHorasAlReservar: r.plazoRetiroHorasAlReservar,
      );
}
