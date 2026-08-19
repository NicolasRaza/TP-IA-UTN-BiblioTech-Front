import '../../../../core/error/result.dart';
import '../../domain/entities/evento_auditoria.dart';
import '../../domain/repositories/auditoria_repository.dart';
import '../datasources/auditoria_api_datasource.dart';

/// El registro de auditoría servido por el backend.
///
/// `usuarioId` queda fuera del cuerpo a propósito: el caso de uso lo sigue
/// pasando porque el contrato de dominio lo pide, pero el que vale es el del
/// token. Un cliente no puede firmar un evento a nombre de otro.
class AuditoriaRepositoryApi implements AuditoriaRepository {
  const AuditoriaRepositoryApi(this._api);

  final AuditoriaApiDataSource _api;

  @override
  Future<Result<List<EventoAuditoria>>> obtenerTodos() => _api.listar();

  @override
  Future<Result<EventoAuditoria>> registrar({
    required TipoEventoAuditoria tipo,
    required String descripcion,
    String? usuarioId,
  }) =>
      _api.registrar(tipo: tipo, descripcion: descripcion);
}
