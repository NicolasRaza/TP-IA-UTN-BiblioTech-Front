import '../../domain/entities/evento_auditoria.dart';

/// [EventoAuditoria] con serialización.
class EventoAuditoriaModel extends EventoAuditoria {
  const EventoAuditoriaModel({
    required super.id,
    required super.tipo,
    required super.descripcion,
    required super.usuarioId,
    required super.fecha,
  });

  factory EventoAuditoriaModel.fromEntity(EventoAuditoria e) =>
      EventoAuditoriaModel(
        id: e.id,
        tipo: e.tipo,
        descripcion: e.descripcion,
        usuarioId: e.usuarioId,
        fecha: e.fecha,
      );

  factory EventoAuditoriaModel.fromJson(Map<String, dynamic> json) =>
      EventoAuditoriaModel(
        id: json['id'] as String,
        tipo: TipoEventoAuditoria.fromCode(json['tipo'] as String?),
        descripcion: json['descripcion'] as String? ?? '',
        usuarioId: json['usuario'] as String? ?? 'sistema',
        fecha: DateTime.parse(json['fecha'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'tipo': tipo.code,
        'descripcion': descripcion,
        // La clave se llama 'usuario' desde el prototipo HTML/JS original;
        // se conserva para no invalidar los datos ya guardados.
        'usuario': usuarioId,
        'fecha': fecha.toIso8601String(),
      };
}
