import '../../../../core/error/result.dart';
import '../entities/evento_auditoria.dart';

/// Contrato del registro de auditoría.
///
/// A diferencia del diseño anterior, donde el repositorio se auto-auditaba
/// dentro de cada operación, acá el registro es explícito: es el caso de uso
/// el que decide qué queda asentado. Eso hace visible la traza en la firma de
/// cada operación en lugar de esconderla como efecto secundario.
abstract interface class AuditoriaRepository {
  /// Eventos del más reciente al más viejo.
  Future<Result<List<EventoAuditoria>>> obtenerTodos();

  Future<Result<EventoAuditoria>> registrar({
    required TipoEventoAuditoria tipo,
    required String descripcion,
    String? usuarioId,
  });
}
