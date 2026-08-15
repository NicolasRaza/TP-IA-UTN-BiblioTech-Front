import 'package:equatable/equatable.dart';

import '../../../administracion/domain/entities/configuracion_biblioteca.dart';
import '../../../catalogo/domain/entities/libro.dart';
import '../../../lectores/domain/entities/lector.dart';
import '../../../prestamos/domain/entities/prestamo.dart';
import '../../../reservas/domain/entities/reserva.dart';

/// Fotografía completa del sistema en un instante.
///
/// Es la salida de la fase de **Observación** del ciclo de la spec v2 §5, y
/// existe para que el Agente Evaluador pueda ser una función pura: recibe este
/// objeto y devuelve decisiones, sin tocar un repositorio ni el reloj.
///
/// Esa separación es lo que hace testeable al agente. Antes había que montar
/// un almacenamiento entero para verificar una regla de decisión; ahora se
/// construye el estado a mano y se comprueba la salida.
class EstadoDelSistema extends Equatable {
  EstadoDelSistema({
    required this.momento,
    required this.configuracion,
    required this.libros,
    required this.lectores,
    required this.prestamos,
    required this.reservas,
  })  : _librosPorId = {for (final l in libros) l.id: l},
        _lectoresPorId = {for (final l in lectores) l.id: l};

  /// Instante en que se tomó la fotografía. Todas las comparaciones de fecha
  /// del Evaluador usan éste y no `DateTime.now()`.
  final DateTime momento;

  final ConfiguracionBiblioteca configuracion;

  /// Todos los libros, validados o no.
  final List<Libro> libros;

  /// Lectores, sin el personal de la biblioteca.
  final List<Lector> lectores;

  final List<Prestamo> prestamos;
  final List<Reserva> reservas;

  final Map<String, Libro> _librosPorId;
  final Map<String, Lector> _lectoresPorId;

  /// Catálogo visible para el lector (spec v2 §7).
  List<Libro> get catalogoPublico =>
      libros.where((l) => l.validado).toList();

  Libro? libro(String id) => _librosPorId[id];
  Lector? lector(String id) => _lectoresPorId[id];

  List<Prestamo> get prestamosAbiertos =>
      prestamos.where((p) => p.estaAbierto).toList();

  List<Prestamo> prestamosDe(String lectorId) =>
      prestamos.where((p) => p.lectorId == lectorId).toList();

  List<Reserva> reservasDe(String lectorId) =>
      reservas.where((r) => r.lectorId == lectorId).toList();

  /// Cola de espera de un título, en orden cronológico estricto.
  List<Reserva> colaDe(String libroId) {
    final cola = reservas
        .where((r) => r.libroId == libroId && r.esActiva)
        .toList()
      ..sort((a, b) => a.fechaReserva.compareTo(b.fechaReserva));
    return cola;
  }

  @override
  List<Object?> get props =>
      [momento, configuracion, libros, lectores, prestamos, reservas];
}
