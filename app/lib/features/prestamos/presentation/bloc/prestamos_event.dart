part of 'prestamos_bloc.dart';

sealed class PrestamosEvent extends Equatable {
  const PrestamosEvent();

  @override
  List<Object?> get props => const [];
}

/// Carga los préstamos activos y el historial de un lector.
class PrestamosDeLectorSolicitados extends PrestamosEvent {
  const PrestamosDeLectorSolicitados(this.lectorId);

  final String lectorId;

  @override
  List<Object?> get props => [lectorId];
}

/// Carga toda la circulación, para los paneles de gestión.
class TodosLosPrestamosSolicitados extends PrestamosEvent {
  const TodosLosPrestamosSolicitados();
}

/// El bibliotecario entrega un ejemplar en el mostrador.
class PrestamoRegistrado extends PrestamosEvent {
  const PrestamoRegistrado({
    required this.lectorId,
    required this.libroId,
    this.ejemplarId,
    this.qrEjemplar,
  });

  final String lectorId;
  final String libroId;

  /// Ejemplar puntual. Si es `null`, se toma el primero disponible.
  final String? ejemplarId;

  /// Etiqueta escaneada. Es como el backend identifica al ejemplar.
  final String? qrEjemplar;

  @override
  List<Object?> get props => [lectorId, libroId, ejemplarId, qrEjemplar];
}

/// El lector devuelve un ejemplar.
class DevolucionRegistrada extends PrestamosEvent {
  const DevolucionRegistrada(this.prestamoId, {this.qrEjemplar});

  final String prestamoId;

  /// Etiqueta escaneada al recibir el libro. Es como el backend identifica la
  /// devolución; con el almacenamiento local alcanza con [prestamoId].
  final String? qrEjemplar;

  @override
  List<Object?> get props => [prestamoId, qrEjemplar];
}

class MensajePrestamosDescartado extends PrestamosEvent {
  const MensajePrestamosDescartado();
}
