import 'package:equatable/equatable.dart';

enum TipoNotificacion {
  vencimientoProximo('vencimiento_proximo', '⏰'),
  prestamoVencido('prestamo_vencido', '🚨'),
  reservaDisponible('reserva_disponible', '🔔'),
  reservaConfirmada('reserva_confirmada', '📚'),
  reservaVencida('reserva_vencida', '⌛'),
  recomendacion('recomendacion', '✨');

  const TipoNotificacion(this.code, this.icono);
  final String code;
  final String icono;

  static TipoNotificacion fromCode(String? code) =>
      TipoNotificacion.values.firstWhere(
        (t) => t.code == code,
        orElse: () => TipoNotificacion.recomendacion,
      );
}

/// Aviso dirigido a un lector. Las genera el Agente Planificador al ejecutar
/// las decisiones del Evaluador, o el propio flujo de préstamos y reservas.
class Notificacion extends Equatable {
  const Notificacion({
    required this.id,
    required this.lectorId,
    required this.tipo,
    required this.titulo,
    required this.descripcion,
    required this.fecha,
    this.leida = false,
  });

  final String id;
  final String lectorId;
  final TipoNotificacion tipo;
  final String titulo;
  final String descripcion;
  final DateTime fecha;
  final bool leida;

  String get icono => tipo.icono;

  Notificacion copyWith({bool? leida}) => Notificacion(
        id: id,
        lectorId: lectorId,
        tipo: tipo,
        titulo: titulo,
        descripcion: descripcion,
        fecha: fecha,
        leida: leida ?? this.leida,
      );

  @override
  List<Object?> get props =>
      [id, lectorId, tipo, titulo, descripcion, fecha, leida];
}
