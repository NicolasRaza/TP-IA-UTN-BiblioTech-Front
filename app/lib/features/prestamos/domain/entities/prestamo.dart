import 'package:equatable/equatable.dart';

import '../../../lectores/domain/entities/lector.dart';

enum EstadoPrestamo {
  activo('activo', 'Activo'),
  vencido('vencido', 'Vencido'),
  devuelto('devuelto', 'Devuelto');

  const EstadoPrestamo(this.code, this.label);
  final String code;
  final String label;

  static EstadoPrestamo fromCode(String? code) =>
      EstadoPrestamo.values.firstWhere(
        (e) => e.code == code,
        orElse: () => EstadoPrestamo.activo,
      );
}

/// Préstamo de un ejemplar a un lector.
///
/// Congela las condiciones vigentes al momento de generarse
/// (`categoriaAlPrestar`, `plazoDiasAlPrestar`) para cumplir la regla de
/// transición de categoría de la spec v2 §7: si el lector cambia de categoría,
/// este préstamo conserva el plazo con el que nació.
class Prestamo extends Equatable {
  const Prestamo({
    required this.id,
    required this.lectorId,
    required this.ejemplarId,
    required this.libroId,
    required this.fechaPrestamo,
    required this.fechaVencimiento,
    this.fechaDevolucion,
    required this.estado,
    this.tardio = false,
    required this.categoriaAlPrestar,
    required this.plazoDiasAlPrestar,
    this.multaAplicada = 0,
  });

  final String id;
  final String lectorId;
  final String ejemplarId;
  final String libroId;
  final DateTime fechaPrestamo;
  final DateTime fechaVencimiento;
  final DateTime? fechaDevolucion;
  final EstadoPrestamo estado;
  final bool tardio;
  final CategoriaLector categoriaAlPrestar;
  final int plazoDiasAlPrestar;

  /// Multa ya cargada al lector por este préstamo. Evita cobrar dos veces
  /// el mismo atraso cuando se recalculan los vencimientos.
  final int multaAplicada;

  bool get estaAbierto =>
      estado == EstadoPrestamo.activo || estado == EstadoPrestamo.vencido;

  int diasRestantes(DateTime ahora) =>
      fechaVencimiento.difference(ahora).inDays;

  bool estaVencido(DateTime ahora) =>
      estaAbierto && ahora.isAfter(fechaVencimiento);

  /// Días enteros de atraso a una fecha dada. Cuenta el día empezado, que es
  /// como la spec v2 §7 calcula la multa.
  int diasDeAtraso(DateTime ahora) {
    final diff = ahora.difference(fechaVencimiento);
    return diff.inHours <= 0 ? 0 : (diff.inHours / 24).ceil();
  }

  /// Multa que todavía no se cargó al lector por este préstamo.
  ///
  /// Devolver siempre el delta y no el total es lo que hace idempotente al
  /// procesamiento de vencimientos: correrlo dos veces no cobra dos veces.
  int multaPendienteA(DateTime ahora, int multaPorDia) {
    final total = diasDeAtraso(ahora) * multaPorDia;
    final delta = total - multaAplicada;
    return delta > 0 ? delta : 0;
  }

  Prestamo copyWith({
    DateTime? fechaVencimiento,
    DateTime? fechaDevolucion,
    EstadoPrestamo? estado,
    bool? tardio,
    int? multaAplicada,
  }) =>
      Prestamo(
        id: id,
        lectorId: lectorId,
        ejemplarId: ejemplarId,
        libroId: libroId,
        fechaPrestamo: fechaPrestamo,
        fechaVencimiento: fechaVencimiento ?? this.fechaVencimiento,
        fechaDevolucion: fechaDevolucion ?? this.fechaDevolucion,
        estado: estado ?? this.estado,
        tardio: tardio ?? this.tardio,
        categoriaAlPrestar: categoriaAlPrestar,
        plazoDiasAlPrestar: plazoDiasAlPrestar,
        multaAplicada: multaAplicada ?? this.multaAplicada,
      );

  @override
  List<Object?> get props => [
        id,
        lectorId,
        ejemplarId,
        libroId,
        fechaPrestamo,
        fechaVencimiento,
        fechaDevolucion,
        estado,
        tardio,
        categoriaAlPrestar,
        plazoDiasAlPrestar,
        multaAplicada,
      ];
}

/// Indicadores agregados de la circulación, para el panel del bibliotecario.
class EstadisticasPrestamos extends Equatable {
  const EstadisticasPrestamos({
    required this.total,
    required this.activos,
    required this.vencidos,
    required this.devueltos,
    required this.tasaTardia,
  });

  final int total;
  final int activos;
  final int vencidos;
  final int devueltos;
  final double tasaTardia;

  factory EstadisticasPrestamos.desde(List<Prestamo> prestamos) {
    final tardios = prestamos.where((p) => p.tardio).length;
    return EstadisticasPrestamos(
      total: prestamos.length,
      activos:
          prestamos.where((p) => p.estado == EstadoPrestamo.activo).length,
      vencidos:
          prestamos.where((p) => p.estado == EstadoPrestamo.vencido).length,
      devueltos:
          prestamos.where((p) => p.estado == EstadoPrestamo.devuelto).length,
      tasaTardia:
          prestamos.isEmpty ? 0 : tardios * 100 / prestamos.length,
    );
  }

  @override
  List<Object?> get props => [total, activos, vencidos, devueltos, tasaTardia];
}
