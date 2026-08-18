part of 'push_cubit.dart';

class PushState extends Equatable {
  const PushState({
    this.estado = EstadoCarga.inicial,
    this.soportado = false,
    this.token,
    this.mensajeError,
    this.ultimoAviso,
  });

  final EstadoCarga estado;

  /// `false` en un navegador sin push o en un dispositivo sin Firebase.
  final bool soportado;

  /// Token FCM de este dispositivo, ya registrado en el backend.
  final String? token;

  final String? mensajeError;

  /// Título del último aviso recibido con la app abierta.
  final String? ultimoAviso;

  bool get activo => token != null;

  PushState copyWith({
    EstadoCarga? estado,
    bool? soportado,
    String? token,
    String? mensajeError,
    String? ultimoAviso,
  }) =>
      PushState(
        estado: estado ?? this.estado,
        soportado: soportado ?? this.soportado,
        token: token ?? this.token,
        // El error es de la última operación: no se arrastra al siguiente
        // intento, igual que en el resto de los estados de la app.
        mensajeError: mensajeError,
        ultimoAviso: ultimoAviso ?? this.ultimoAviso,
      );

  @override
  List<Object?> get props =>
      [estado, soportado, token, mensajeError, ultimoAviso];
}
