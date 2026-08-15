part of 'sesion_cubit.dart';

/// Estado de la sesión del usuario.
class SesionState extends Equatable {
  const SesionState({
    this.estado = EstadoCarga.inicial,
    this.usuario,
    this.mensajeError,
  });

  final EstadoCarga estado;

  /// Usuario logueado, o `null` si no hay sesión.
  final Lector? usuario;

  final String? mensajeError;

  bool get haySesion => usuario != null;

  /// Rol del usuario logueado. La raíz de la app rutea con esto.
  RolUsuario? get rol => usuario?.rol;

  SesionState copyWith({
    EstadoCarga? estado,
    Lector? usuario,
    String? mensajeError,
    bool limpiarUsuario = false,
    bool limpiarError = false,
  }) =>
      SesionState(
        estado: estado ?? this.estado,
        usuario: limpiarUsuario ? null : (usuario ?? this.usuario),
        mensajeError: limpiarError ? null : (mensajeError ?? this.mensajeError),
      );

  @override
  List<Object?> get props => [estado, usuario, mensajeError];
}
