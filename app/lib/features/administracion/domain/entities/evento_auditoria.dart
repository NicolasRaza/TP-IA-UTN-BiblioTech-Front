import 'package:equatable/equatable.dart';

enum TipoEventoAuditoria {
  altaLibro('alta_libro'),
  bajaLibro('baja_libro'),
  edicionLibro('edicion_libro'),
  altaLector('alta_lector'),
  edicionLector('edicion_lector'),
  verificacionLector('verificacion_lector'),
  altaUsuarioInterno('alta_usuario_interno'),
  bajaUsuarioInterno('baja_usuario_interno'),
  prestamo('prestamo'),
  devolucion('devolucion'),
  reimpresionQr('reimpresion_qr'),
  correccionOcr('correccion_ocr'),
  cambioCategoria('cambio_categoria'),
  cambioConfig('cambio_config');

  const TipoEventoAuditoria(this.code);
  final String code;

  static TipoEventoAuditoria fromCode(String? code) =>
      TipoEventoAuditoria.values.firstWhere(
        (t) => t.code == code,
        orElse: () => TipoEventoAuditoria.edicionLibro,
      );
}

/// Entrada del registro de auditoría. Es append-only: se conservan los últimos
/// [EventoAuditoria.maximoRetenido] eventos y nunca se editan.
class EventoAuditoria extends Equatable {
  const EventoAuditoria({
    required this.id,
    required this.tipo,
    required this.descripcion,
    required this.usuarioId,
    required this.fecha,
  });

  /// Tope de eventos que se conservan en el almacenamiento local.
  static const maximoRetenido = 200;

  final String id;
  final TipoEventoAuditoria tipo;
  final String descripcion;
  final String usuarioId;
  final DateTime fecha;

  @override
  List<Object?> get props => [id, tipo, descripcion, usuarioId, fecha];
}
