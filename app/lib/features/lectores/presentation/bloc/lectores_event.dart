part of 'lectores_bloc.dart';

sealed class LectoresEvent extends Equatable {
  const LectoresEvent();

  @override
  List<Object?> get props => const [];
}

class LectoresSolicitados extends LectoresEvent {
  const LectoresSolicitados();
}

class LectorRegistrado extends LectoresEvent {
  const LectorRegistrado(this.lector);

  final Lector lector;

  @override
  List<Object?> get props => [lector];
}

class LectorActualizado extends LectoresEvent {
  const LectorActualizado(this.lector);

  final Lector lector;

  @override
  List<Object?> get props => [lector];
}

class CategoriaCambiada extends LectoresEvent {
  const CategoriaCambiada({required this.lectorId, required this.categoria});

  final String lectorId;
  final CategoriaLector categoria;

  @override
  List<Object?> get props => [lectorId, categoria];
}

/// El bibliotecario escaneó la credencial de un lector en el mostrador.
class LectorBuscadoPorQr extends LectoresEvent {
  const LectorBuscadoPorQr(this.qr);

  final String qr;

  @override
  List<Object?> get props => [qr];
}

class SeleccionDeLectorLimpiada extends LectoresEvent {
  const SeleccionDeLectorLimpiada();
}

class MensajeLectoresDescartado extends LectoresEvent {
  const MensajeLectoresDescartado();
}
