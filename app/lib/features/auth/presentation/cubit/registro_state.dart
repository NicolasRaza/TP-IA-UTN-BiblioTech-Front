part of 'registro_cubit.dart';

class RegistroState extends Equatable {
  const RegistroState({
    this.estado = EstadoCarga.inicial,
    this.registrado,
    this.mensajeError,
  });

  final EstadoCarga estado;

  /// Lector recién dado de alta. Queda pendiente de verificación: existe en el
  /// padrón, pero todavía no puede entrar.
  final Lector? registrado;

  final String? mensajeError;

  bool get seRegistro => registrado != null;

  @override
  List<Object?> get props => [estado, registrado, mensajeError];
}
