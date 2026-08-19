import '../../domain/entities/ejemplar.dart';

/// [Ejemplar] con serialización.
///
/// El modelo extiende a la entidad en lugar de duplicarla: la capa de dominio
/// no sabe que existe JSON, y `data` no necesita mapear campo por campo entre
/// dos clases gemelas.
class EjemplarModel extends Ejemplar {
  const EjemplarModel({
    required super.id,
    required super.libroId,
    required super.condicion,
    required super.estado,
    super.ubicacion,
    super.reimpresionesQr,
  });

  factory EjemplarModel.fromEntity(Ejemplar e) => EjemplarModel(
        id: e.id,
        libroId: e.libroId,
        condicion: e.condicion,
        estado: e.estado,
        ubicacion: e.ubicacion,
        reimpresionesQr: e.reimpresionesQr,
      );

  factory EjemplarModel.fromJson(Map<String, dynamic> json) => EjemplarModel(
        id: json['id'] as String,
        libroId: json['libroId'] as String,
        condicion: CondicionEjemplar.fromCode(json['condicion'] as String?),
        estado: EstadoEjemplar.fromCode(json['estado'] as String?),
        ubicacion: json['ubicacion_fisica'] as String? ?? 'Sin asignar',
        reimpresionesQr: (json['reimpresionesQr'] as num?)?.toInt() ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'libroId': libroId,
        'condicion': condicion.code,
        'estado': estado.code,
        'ubicacion_fisica': ubicacion,
        'reimpresionesQr': reimpresionesQr,
      };
}
