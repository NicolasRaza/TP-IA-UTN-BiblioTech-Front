/// Serialización de la memoria del Agente de Aprendizaje.
library;

import '../../domain/entities/recomendacion.dart';

class CorreccionModel extends Correccion {
  const CorreccionModel({
    required super.campo,
    required super.valorSugerido,
    required super.valorFinal,
    required super.fecha,
  });

  factory CorreccionModel.fromEntity(Correccion c) => CorreccionModel(
        campo: c.campo,
        valorSugerido: c.valorSugerido,
        valorFinal: c.valorFinal,
        fecha: c.fecha,
      );

  factory CorreccionModel.fromJson(Map<String, dynamic> json) =>
      CorreccionModel(
        campo: json['campo'] as String? ?? 'desconocido',
        valorSugerido: json['valorSugerido'] as String? ?? '',
        valorFinal: json['valorFinal'] as String? ?? '',
        fecha: DateTime.parse(json['fecha'] as String),
      );

  Map<String, dynamic> toJson() => {
        'campo': campo,
        'valorSugerido': valorSugerido,
        'valorFinal': valorFinal,
        'fecha': fecha.toIso8601String(),
      };
}

class InteraccionLectorModel extends InteraccionLector {
  const InteraccionLectorModel({
    required super.lectorId,
    required super.libroId,
    required super.tipo,
    required super.fecha,
  });

  factory InteraccionLectorModel.fromEntity(InteraccionLector i) =>
      InteraccionLectorModel(
        lectorId: i.lectorId,
        libroId: i.libroId,
        tipo: i.tipo,
        fecha: i.fecha,
      );

  factory InteraccionLectorModel.fromJson(Map<String, dynamic> json) =>
      InteraccionLectorModel(
        lectorId: json['lectorId'] as String? ?? '',
        libroId: json['libroId'] as String? ?? '',
        tipo: json['tipo'] as String? ?? '',
        fecha: DateTime.parse(json['fecha'] as String),
      );

  Map<String, dynamic> toJson() => {
        'lectorId': lectorId,
        'libroId': libroId,
        'tipo': tipo,
        'fecha': fecha.toIso8601String(),
      };
}
