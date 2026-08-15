import '../../../../core/error/failures.dart';
import '../../../../core/error/result.dart';
import '../../../../core/services/reloj.dart';
import '../../domain/entities/prestamo.dart';
import '../../domain/repositories/prestamo_repository.dart';
import '../datasources/prestamo_local_datasource.dart';

/// Implementación del [PrestamoRepository] sobre el almacenamiento local.
class PrestamoRepositoryImpl implements PrestamoRepository {
  const PrestamoRepositoryImpl({
    required PrestamoLocalDataSource localDataSource,
    required GeneradorId generadorId,
  })  : _local = localDataSource,
        _generadorId = generadorId;

  final PrestamoLocalDataSource _local;
  final GeneradorId _generadorId;

  @override
  Future<Result<List<Prestamo>>> obtenerTodos() async =>
      _local.leer().map((p) => p.cast<Prestamo>());

  @override
  Future<Result<List<Prestamo>>> obtenerDeLector(String lectorId) async =>
      _local.leer().map(
            (prestamos) => prestamos
                .where((p) => p.lectorId == lectorId)
                .cast<Prestamo>()
                .toList(),
          );

  @override
  Future<Result<Prestamo>> obtenerPorId(String prestamoId) async {
    final leidos = _local.leer();
    if (leidos case Fallo(:final failure)) return Fallo(failure);

    for (final p in leidos.valorONull!) {
      if (p.id == prestamoId) return Exito(p);
    }
    return const Fallo(NoEncontradoFailure('El préstamo no existe'));
  }

  @override
  Future<Result<Prestamo>> crear(Prestamo prestamo) async {
    final leidos = _local.leer();
    if (leidos case Fallo(:final failure)) return Fallo(failure);

    final nuevo = prestamo.id.isEmpty
        ? _conId(prestamo, 'pres-${_generadorId.generar()}')
        : prestamo;

    final guardado = _local.guardar([...leidos.valorONull!, nuevo]);
    if (guardado case Fallo(:final failure)) return Fallo(failure);

    return Exito(nuevo);
  }

  @override
  Future<Result<Prestamo>> actualizar(Prestamo prestamo) async {
    final leidos = _local.leer();
    if (leidos case Fallo(:final failure)) return Fallo(failure);

    final lista = leidos.valorONull!.cast<Prestamo>().toList();
    final i = lista.indexWhere((p) => p.id == prestamo.id);
    if (i < 0) {
      return const Fallo(NoEncontradoFailure('El préstamo no existe'));
    }

    lista[i] = prestamo;
    final guardado = _local.guardar(lista);
    if (guardado case Fallo(:final failure)) return Fallo(failure);

    return Exito(prestamo);
  }

  @override
  Future<Result<void>> actualizarVarios(List<Prestamo> prestamos) async {
    if (prestamos.isEmpty) return const Exito(null);

    final leidos = _local.leer();
    if (leidos case Fallo(:final failure)) return Fallo(failure);

    final porId = {for (final p in prestamos) p.id: p};
    final lista =
        leidos.valorONull!.map<Prestamo>((p) => porId[p.id] ?? p).toList();

    return _local.guardar(lista);
  }

  Prestamo _conId(Prestamo p, String id) => Prestamo(
        id: id,
        lectorId: p.lectorId,
        ejemplarId: p.ejemplarId,
        libroId: p.libroId,
        fechaPrestamo: p.fechaPrestamo,
        fechaVencimiento: p.fechaVencimiento,
        fechaDevolucion: p.fechaDevolucion,
        estado: p.estado,
        tardio: p.tardio,
        categoriaAlPrestar: p.categoriaAlPrestar,
        plazoDiasAlPrestar: p.plazoDiasAlPrestar,
        multaAplicada: p.multaAplicada,
      );
}
