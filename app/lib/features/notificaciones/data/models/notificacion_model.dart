import '../../domain/entities/notificacion.dart';

/// [Notificacion] con serialización.
class NotificacionModel extends Notificacion {
  const NotificacionModel({
    required super.id,
    required super.lectorId,
    required super.tipo,
    required super.titulo,
    required super.descripcion,
    required super.fecha,
    super.leida,
  });

  factory NotificacionModel.fromEntity(Notificacion n) => NotificacionModel(
        id: n.id,
        lectorId: n.lectorId,
        tipo: n.tipo,
        titulo: n.titulo,
        descripcion: n.descripcion,
        fecha: n.fecha,
        leida: n.leida,
      );

  factory NotificacionModel.fromJson(Map<String, dynamic> json) =>
      NotificacionModel(
        id: json['id'] as String,
        lectorId: json['lectorId'] as String,
        tipo: TipoNotificacion.fromCode(json['tipo'] as String?),
        titulo: json['titulo'] as String? ?? '',
        descripcion: json['descripcion'] as String? ?? '',
        fecha: DateTime.parse(json['fecha'] as String),
        leida: json['leida'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'lectorId': lectorId,
        'tipo': tipo.code,
        'titulo': titulo,
        'descripcion': descripcion,
        'fecha': fecha.toIso8601String(),
        'leida': leida,
      };
}
