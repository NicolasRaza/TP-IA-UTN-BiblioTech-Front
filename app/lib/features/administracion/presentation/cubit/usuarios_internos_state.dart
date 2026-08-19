part of 'usuarios_internos_cubit.dart';

class UsuariosInternosState extends Equatable {
  const UsuariosInternosState({
    this.estado = EstadoCarga.inicial,
    this.usuarios = const [],
    this.guardando = false,
    this.mensajeError,
    this.mensajeExito,
  });

  final EstadoCarga estado;
  final List<UsuarioInterno> usuarios;

  /// Hay un alta o un cambio de estado en curso: la pantalla deshabilita los
  /// botones para que no se dispare dos veces la misma operación.
  final bool guardando;

  final String? mensajeError;
  final String? mensajeExito;

  List<UsuarioInterno> get activos => usuarios.where((u) => u.activo).toList();

  List<UsuarioInterno> get dadosDeBaja =>
      usuarios.where((u) => !u.activo).toList();

  UsuariosInternosState copyWith({
    EstadoCarga? estado,
    List<UsuarioInterno>? usuarios,
    bool? guardando,
    String? mensajeError,
    String? mensajeExito,
    bool limpiarMensajes = false,
  }) =>
      UsuariosInternosState(
        estado: estado ?? this.estado,
        usuarios: usuarios ?? this.usuarios,
        guardando: guardando ?? this.guardando,
        mensajeError: limpiarMensajes ? null : mensajeError,
        mensajeExito: limpiarMensajes ? null : mensajeExito,
      );

  @override
  List<Object?> get props =>
      [estado, usuarios, guardando, mensajeError, mensajeExito];
}
