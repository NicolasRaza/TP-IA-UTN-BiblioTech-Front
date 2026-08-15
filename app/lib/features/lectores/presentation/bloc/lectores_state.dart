part of 'lectores_bloc.dart';

class LectoresState extends Equatable {
  const LectoresState({
    this.estado = EstadoCarga.inicial,
    this.lectores = const [],
    this.categoriasDesactualizadas = const [],
    this.seleccionado,
    this.mensajeError,
    this.mensajeExito,
  });

  final EstadoCarga estado;
  final List<Lector> lectores;

  /// Lectores cuya categoría quedó desfasada respecto de su edad. El sistema
  /// sólo lo sugiere: el cambio lo hace una persona (spec v2 §7).
  final List<Lector> categoriasDesactualizadas;

  /// Lector identificado en el mostrador.
  final Lector? seleccionado;

  final String? mensajeError;
  final String? mensajeExito;

  List<Lector> get conMultas => lectores.where((l) => l.tieneMultas).toList();

  LectoresState copyWith({
    EstadoCarga? estado,
    List<Lector>? lectores,
    List<Lector>? categoriasDesactualizadas,
    Lector? seleccionado,
    String? mensajeError,
    String? mensajeExito,
    bool limpiarSeleccionado = false,
    bool limpiarMensajes = false,
  }) =>
      LectoresState(
        estado: estado ?? this.estado,
        lectores: lectores ?? this.lectores,
        categoriasDesactualizadas:
            categoriasDesactualizadas ?? this.categoriasDesactualizadas,
        seleccionado:
            limpiarSeleccionado ? null : (seleccionado ?? this.seleccionado),
        mensajeError: limpiarMensajes ? null : mensajeError,
        mensajeExito: limpiarMensajes ? null : mensajeExito,
      );

  @override
  List<Object?> get props => [
        estado,
        lectores,
        categoriasDesactualizadas,
        seleccionado,
        mensajeError,
        mensajeExito,
      ];
}
