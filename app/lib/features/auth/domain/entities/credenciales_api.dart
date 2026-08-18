import 'package:equatable/equatable.dart';

import '../../../../core/config/entorno.dart';

/// Usuario y contraseña de una cuenta del backend (`POST /api/v1/auth/login`).
///
/// Son distintas de las credenciales del login local de la app: el padrón de
/// lectores que maneja la app vive en el dispositivo, mientras que el token de
/// notificaciones se guarda contra la cuenta del backend que lo registró. Por
/// eso el lector tiene que identificarse una vez más al activar los avisos:
/// es la cuenta a la que el Agente Planificador le va a mandar los push.
class CredencialesApi extends Equatable {
  const CredencialesApi({required this.email, required this.password});

  /// Las que vengan precargadas en el build, o vacías si no se pasó ninguna.
  const CredencialesApi.delEntorno()
      : email = Entorno.apiEmail,
        password = Entorno.apiPassword;

  final String email;
  final String password;

  bool get completas => email.isNotEmpty && password.isNotEmpty;

  @override
  List<Object?> get props => [email, password];

  /// Nunca imprime la contraseña: estos objetos terminan en logs de error.
  @override
  String toString() => 'CredencialesApi($email)';
}
