import '../../../lectores/domain/entities/lector.dart';
import '../../domain/entities/configuracion_biblioteca.dart';

/// [ConfiguracionBiblioteca] con serialización.
///
/// Los mapas por categoría se guardan usando el `code` de cada
/// [CategoriaLector], no su índice: agregar una categoría nueva no corrompe
/// la configuración ya guardada.
class ConfiguracionBibliotecaModel extends ConfiguracionBiblioteca {
  const ConfiguracionBibliotecaModel({
    super.plazoPrestamoDias,
    super.limiteEjemplares,
    super.limiteReservas,
    super.plazoRetiroReservaHoras,
    super.multaPorDiaDemora,
    super.recordatorioAntesDias,
    super.pesoHistorialRecomendacion,
    super.minPrestamosParaHistorial,
    super.edadMayoriaEdad,
  });

  factory ConfiguracionBibliotecaModel.fromEntity(ConfiguracionBiblioteca c) =>
      ConfiguracionBibliotecaModel(
        plazoPrestamoDias: c.plazoPrestamoDias,
        limiteEjemplares: c.limiteEjemplares,
        limiteReservas: c.limiteReservas,
        plazoRetiroReservaHoras: c.plazoRetiroReservaHoras,
        multaPorDiaDemora: c.multaPorDiaDemora,
        recordatorioAntesDias: c.recordatorioAntesDias,
        pesoHistorialRecomendacion: c.pesoHistorialRecomendacion,
        minPrestamosParaHistorial: c.minPrestamosParaHistorial,
        edadMayoriaEdad: c.edadMayoriaEdad,
      );

  factory ConfiguracionBibliotecaModel.fromJson(Map<String, dynamic> json) {
    const def = ConfiguracionBiblioteca();
    return ConfiguracionBibliotecaModel(
      plazoPrestamoDias: _mapFromJson(
        json['plazoPrestamoDias'] as Map<String, dynamic>?,
        def.plazoPrestamoDias,
      ),
      limiteEjemplares: _mapFromJson(
        json['limiteEjemplares'] as Map<String, dynamic>?,
        def.limiteEjemplares,
      ),
      limiteReservas: _mapFromJson(
        json['limiteReservas'] as Map<String, dynamic>?,
        def.limiteReservas,
      ),
      plazoRetiroReservaHoras:
          (json['plazoRetiroReservaHoras'] as num?)?.toInt() ?? 48,
      multaPorDiaDemora: (json['multaPorDiaDemora'] as num?)?.toInt() ?? 100,
      recordatorioAntesDias:
          (json['recordatorioAntesDias'] as num?)?.toInt() ?? 3,
      pesoHistorialRecomendacion:
          (json['pesoHistorialRecomendacion'] as num?)?.toDouble() ?? 0.7,
      minPrestamosParaHistorial:
          (json['minPrestamosParaHistorial'] as num?)?.toInt() ?? 5,
      edadMayoriaEdad: (json['edadMayoriaEdad'] as num?)?.toInt() ?? 18,
    );
  }

  Map<String, dynamic> toJson() => {
        'plazoPrestamoDias': _mapToJson(plazoPrestamoDias),
        'limiteEjemplares': _mapToJson(limiteEjemplares),
        'limiteReservas': _mapToJson(limiteReservas),
        'plazoRetiroReservaHoras': plazoRetiroReservaHoras,
        'multaPorDiaDemora': multaPorDiaDemora,
        'recordatorioAntesDias': recordatorioAntesDias,
        'pesoHistorialRecomendacion': pesoHistorialRecomendacion,
        'minPrestamosParaHistorial': minPrestamosParaHistorial,
        'edadMayoriaEdad': edadMayoriaEdad,
      };

  static Map<String, dynamic> _mapToJson(Map<CategoriaLector, int> m) =>
      m.map((k, v) => MapEntry(k.code, v));

  static Map<CategoriaLector, int> _mapFromJson(
    Map<String, dynamic>? m,
    Map<CategoriaLector, int> fallback,
  ) {
    if (m == null) return fallback;
    return m.map(
      (k, v) => MapEntry(CategoriaLector.fromCode(k), (v as num).toInt()),
    );
  }
}
