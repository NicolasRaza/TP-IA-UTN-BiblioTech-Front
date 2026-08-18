import 'package:equatable/equatable.dart';

import '../../../catalogo/domain/entities/libro.dart';

/// Libro recomendado junto con la explicación de por qué se recomendó.
class Recomendacion extends Equatable {
  const Recomendacion({
    required this.libro,
    required this.puntaje,
    required this.motivo,
    required this.esColdStart,
  });

  final Libro libro;
  final double puntaje;
  final String motivo;

  /// `true` cuando la recomendación se basó solo en popularidad general por
  /// no haber historial suficiente del lector.
  final bool esColdStart;

  @override
  List<Object?> get props => [libro, puntaje, motivo, esColdStart];
}

/// Patrón detectado sobre las correcciones del bibliotecario.
class PatronCorreccion extends Equatable {
  const PatronCorreccion({
    required this.campo,
    required this.correcciones,
    required this.sugerencia,
  });

  final String campo;
  final int correcciones;
  final String sugerencia;

  @override
  List<Object?> get props => [campo, correcciones, sugerencia];
}

/// Informe del Agente de Aprendizaje sobre las correcciones acumuladas.
class InformeAprendizaje extends Equatable {
  const InformeAprendizaje({
    required this.patrones,
    required this.totalCorrecciones,
    required this.mejora,
  });

  final List<PatronCorreccion> patrones;
  final int totalCorrecciones;

  /// Mejora estimada de precisión respecto del primer ciclo, en puntos.
  final double mejora;

  @override
  List<Object?> get props => [patrones, totalCorrecciones, mejora];
}

/// Una corrección puntual del bibliotecario sobre un campo sugerido.
class Correccion extends Equatable {
  const Correccion({
    required this.campo,
    required this.valorSugerido,
    required this.valorFinal,
    required this.fecha,
  });

  final String campo;
  final String valorSugerido;
  final String valorFinal;
  final DateTime fecha;

  @override
  List<Object?> get props => [campo, valorSugerido, valorFinal, fecha];
}

/// Interacción de un lector con un libro (clic, reserva), insumo del
/// Agente de Aprendizaje para medir aceptación de recomendaciones.
class InteraccionLector extends Equatable {
  const InteraccionLector({
    required this.lectorId,
    required this.libroId,
    required this.tipo,
    required this.fecha,
  });

  final String lectorId;
  final String libroId;
  final String tipo;
  final DateTime fecha;

  @override
  List<Object?> get props => [lectorId, libroId, tipo, fecha];
}
