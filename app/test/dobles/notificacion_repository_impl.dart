import 'package:bibliotech/core/error/result.dart';
import 'package:bibliotech/core/services/reloj.dart';
import 'package:bibliotech/features/notificaciones/domain/entities/notificacion.dart';
import 'package:bibliotech/features/notificaciones/domain/repositories/notificacion_repository.dart';
import 'notificacion_local_datasource.dart';

/// Implementación del [NotificacionRepository] sobre el almacenamiento local.
class NotificacionRepositoryImpl implements NotificacionRepository {
  const NotificacionRepositoryImpl({
    required NotificacionLocalDataSource localDataSource,
    required GeneradorId generadorId,
  })  : _local = localDataSource,
        _generadorId = generadorId;

  final NotificacionLocalDataSource _local;
  final GeneradorId _generadorId;

  @override
  Future<Result<List<Notificacion>>> obtenerDeLector(String lectorId) async =>
      _local.leer().map((todas) {
        final propias = todas
            .where((n) => n.lectorId == lectorId)
            .cast<Notificacion>()
            .toList()
          ..sort((a, b) => b.fecha.compareTo(a.fecha));
        return propias;
      });

  @override
  Future<Result<int>> contarNoLeidas(String lectorId) async =>
      _local.leer().map(
            (todas) =>
                todas.where((n) => n.lectorId == lectorId && !n.leida).length,
          );

  @override
  Future<Result<Notificacion>> crear(Notificacion notificacion) async {
    final leidas = _local.leer();
    if (leidas case Fallo(:final failure)) return Fallo(failure);

    final nueva = notificacion.id.isEmpty
        ? _conId(notificacion, 'not-${_generadorId.generar()}')
        : notificacion;

    final guardado = _local.guardar([...leidas.valorONull!, nueva]);
    if (guardado case Fallo(:final failure)) return Fallo(failure);

    return Exito(nueva);
  }

  @override
  Future<Result<bool>> existeSimilar(
    String lectorId,
    TipoNotificacion tipo,
    String textoClave,
  ) async =>
      _local.leer().map(
            (todas) => todas.any((n) =>
                n.lectorId == lectorId &&
                n.tipo == tipo &&
                n.descripcion.contains(textoClave)),
          );

  @override
  Future<Result<void>> marcarLeida(String notificacionId) async {
    final leidas = _local.leer();
    if (leidas case Fallo(:final failure)) return Fallo(failure);

    final lista = leidas.valorONull!
        .map<Notificacion>(
            (n) => n.id == notificacionId ? n.copyWith(leida: true) : n)
        .toList();

    return _local.guardar(lista);
  }

  @override
  Future<Result<void>> marcarTodasLeidas(String lectorId) async {
    final leidas = _local.leer();
    if (leidas case Fallo(:final failure)) return Fallo(failure);

    final lista = leidas.valorONull!
        .map<Notificacion>(
            (n) => n.lectorId == lectorId ? n.copyWith(leida: true) : n)
        .toList();

    return _local.guardar(lista);
  }

  Notificacion _conId(Notificacion n, String id) => Notificacion(
        id: id,
        lectorId: n.lectorId,
        tipo: n.tipo,
        titulo: n.titulo,
        descripcion: n.descripcion,
        fecha: n.fecha,
        leida: n.leida,
      );
}
