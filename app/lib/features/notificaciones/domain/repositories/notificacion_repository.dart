import '../../../../core/error/result.dart';
import '../entities/notificacion.dart';

/// Contrato de acceso a las notificaciones.
abstract interface class NotificacionRepository {
  /// Avisos de un lector, del más reciente al más viejo.
  Future<Result<List<Notificacion>>> obtenerDeLector(String lectorId);

  Future<Result<int>> contarNoLeidas(String lectorId);

  Future<Result<Notificacion>> crear(Notificacion notificacion);

  /// ¿Ya existe un aviso del mismo tipo que mencione [textoClave]?
  ///
  /// El ciclo de agentes corre en cada arranque; sin esta verificación el
  /// lector recibiría el mismo recordatorio una vez por sesión.
  Future<Result<bool>> existeSimilar(
    String lectorId,
    TipoNotificacion tipo,
    String textoClave,
  );

  Future<Result<void>> marcarLeida(String notificacionId);

  Future<Result<void>> marcarTodasLeidas(String lectorId);
}
