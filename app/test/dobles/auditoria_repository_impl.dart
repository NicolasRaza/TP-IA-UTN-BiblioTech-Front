import 'package:bibliotech/core/error/result.dart';
import 'package:bibliotech/core/services/reloj.dart';
import 'package:bibliotech/features/administracion/domain/entities/evento_auditoria.dart';
import 'package:bibliotech/features/administracion/domain/repositories/auditoria_repository.dart';
import 'administracion_local_datasource.dart';

/// Implementación del [AuditoriaRepository] sobre el almacenamiento local.
class AuditoriaRepositoryImpl implements AuditoriaRepository {
  const AuditoriaRepositoryImpl({
    required AdministracionLocalDataSource localDataSource,
    required GeneradorId generadorId,
    required Reloj reloj,
  })  : _local = localDataSource,
        _generadorId = generadorId,
        _reloj = reloj;

  final AdministracionLocalDataSource _local;
  final GeneradorId _generadorId;
  final Reloj _reloj;

  @override
  Future<Result<List<EventoAuditoria>>> obtenerTodos() async =>
      _local.leerAuditoria().map((eventos) {
        final ordenados = eventos.cast<EventoAuditoria>().toList()
          ..sort((a, b) => b.fecha.compareTo(a.fecha));
        return ordenados;
      });

  @override
  Future<Result<EventoAuditoria>> registrar({
    required TipoEventoAuditoria tipo,
    required String descripcion,
    String? usuarioId,
  }) async {
    final leidos = _local.leerAuditoria();
    if (leidos case Fallo(:final failure)) return Fallo(failure);

    final evento = EventoAuditoria(
      id: 'aud-${_generadorId.generar()}',
      tipo: tipo,
      descripcion: descripcion,
      usuarioId: usuarioId ?? 'sistema',
      fecha: _reloj.ahora,
    );

    // El registro es append-only y se recorta a los últimos N eventos, para
    // que el almacenamiento local no crezca sin límite.
    final lista = <EventoAuditoria>[evento, ...leidos.valorONull!]
        .take(EventoAuditoria.maximoRetenido)
        .toList();

    final guardado = _local.guardarAuditoria(lista);
    if (guardado case Fallo(:final failure)) return Fallo(failure);

    return Exito(evento);
  }
}
