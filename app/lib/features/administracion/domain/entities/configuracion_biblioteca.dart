import 'package:equatable/equatable.dart';

import '../../../lectores/domain/entities/lector.dart';

/// Parámetros de configuración editables por el Administrador (spec v2 §3).
///
/// Es la fuente única de los plazos, límites y multas que aplican las reglas
/// de negocio. Ningún caso de uso tiene números mágicos: todos los consultan
/// acá.
class ConfiguracionBiblioteca extends Equatable {
  const ConfiguracionBiblioteca({
    this.plazoPrestamoDias = const {
      CategoriaLector.menor: 7,
      CategoriaLector.adulto: 14,
      CategoriaLector.docente: 21,
      CategoriaLector.senior: 14,
      CategoriaLector.personal: 30,
    },
    this.limiteEjemplares = const {
      CategoriaLector.menor: 2,
      CategoriaLector.adulto: 3,
      CategoriaLector.docente: 5,
      CategoriaLector.senior: 3,
      CategoriaLector.personal: 5,
    },
    this.limiteReservas = const {
      CategoriaLector.menor: 2,
      CategoriaLector.adulto: 3,
      CategoriaLector.docente: 5,
      CategoriaLector.senior: 3,
      CategoriaLector.personal: 5,
    },
    this.plazoRetiroReservaHoras = 48,
    this.multaPorDiaDemora = 100,
    this.recordatorioAntesDias = 3,
    this.pesoHistorialRecomendacion = 0.7,
    this.minPrestamosParaHistorial = 5,
    this.edadMayoriaEdad = 18,
  });

  final Map<CategoriaLector, int> plazoPrestamoDias;
  final Map<CategoriaLector, int> limiteEjemplares;
  final Map<CategoriaLector, int> limiteReservas;

  /// Spec v2 §7: el sistema retiene el libro reservado 48 hs.
  final int plazoRetiroReservaHoras;
  final int multaPorDiaDemora;
  final int recordatorioAntesDias;

  /// Spec v2 §2: 70% historial personal / 30% popularidad general.
  final double pesoHistorialRecomendacion;

  /// Debajo de este umbral el lector se considera "cold start" y la
  /// recomendación pasa a 100% popularidad.
  final int minPrestamosParaHistorial;

  final int edadMayoriaEdad;

  double get pesoPopularidadRecomendacion => 1 - pesoHistorialRecomendacion;

  int plazoPara(CategoriaLector c) => plazoPrestamoDias[c] ?? 14;
  int limiteEjemplaresPara(CategoriaLector c) => limiteEjemplares[c] ?? 3;
  int limiteReservasPara(CategoriaLector c) => limiteReservas[c] ?? 3;

  ConfiguracionBiblioteca copyWith({
    Map<CategoriaLector, int>? plazoPrestamoDias,
    Map<CategoriaLector, int>? limiteEjemplares,
    Map<CategoriaLector, int>? limiteReservas,
    int? plazoRetiroReservaHoras,
    int? multaPorDiaDemora,
    int? recordatorioAntesDias,
    double? pesoHistorialRecomendacion,
    int? minPrestamosParaHistorial,
  }) =>
      ConfiguracionBiblioteca(
        plazoPrestamoDias: plazoPrestamoDias ?? this.plazoPrestamoDias,
        limiteEjemplares: limiteEjemplares ?? this.limiteEjemplares,
        limiteReservas: limiteReservas ?? this.limiteReservas,
        plazoRetiroReservaHoras:
            plazoRetiroReservaHoras ?? this.plazoRetiroReservaHoras,
        multaPorDiaDemora: multaPorDiaDemora ?? this.multaPorDiaDemora,
        recordatorioAntesDias:
            recordatorioAntesDias ?? this.recordatorioAntesDias,
        pesoHistorialRecomendacion:
            pesoHistorialRecomendacion ?? this.pesoHistorialRecomendacion,
        minPrestamosParaHistorial:
            minPrestamosParaHistorial ?? this.minPrestamosParaHistorial,
        edadMayoriaEdad: edadMayoriaEdad,
      );

  @override
  List<Object?> get props => [
        plazoPrestamoDias,
        limiteEjemplares,
        limiteReservas,
        plazoRetiroReservaHoras,
        multaPorDiaDemora,
        recordatorioAntesDias,
        pesoHistorialRecomendacion,
        minPrestamosParaHistorial,
        edadMayoriaEdad,
      ];
}
