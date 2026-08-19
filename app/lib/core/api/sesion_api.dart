import 'dart:convert';

import '../storage/key_value_store.dart';

/// Usuario tal como lo describe el backend en `GET /api/v1/auth/me`.
///
/// No es la entidad de dominio [Lector]: es lo poco que la API cuenta sobre
/// quién está autenticado. El `lectorId` viene en `null` para bibliotecarios y
/// administradores, que no tienen ficha de lector.
///
/// [estado] es el de la ficha de lector y es la única vía por la que la app
/// puede saber si su propia cuenta está verificada: `/lectores/{id}` exige rol
/// bibliotecario, así que un lector no puede leerse a sí mismo. Viaja como
/// opcional porque una versión del backend que todavía no lo incluya no debe
/// romper el login: sin el campo, la cuenta se toma como verificada y el
/// bloqueo queda del lado del servidor, que igual responde 403 al primer
/// préstamo o reserva.
class UsuarioApi {
  const UsuarioApi({
    required this.id,
    required this.email,
    required this.rol,
    this.lectorId,
    this.estado,
  });

  final int id;
  final String email;
  final String rol;
  final int? lectorId;
  final String? estado;

  factory UsuarioApi.fromJson(Map<String, dynamic> json) => UsuarioApi(
        id: (json['id'] as num).toInt(),
        email: json['email'] as String? ?? '',
        rol: json['rol'] as String? ?? 'lector',
        lectorId: (json['lector_id'] as num?)?.toInt(),
        estado: json['estado'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'rol': rol,
        'lector_id': lectorId,
        'estado': estado,
      };
}

/// Sesión abierta contra el backend: el JWT y quién es su dueño.
///
/// Vive en el core y no en el feature de auth porque todos los datasources
/// remotos dependen de ella —el [ClienteApi] le pide el token en cada
/// request—, y hacerla parte de `features/auth` obligaría a que catálogo,
/// lectores y circulación importaran ese feature.
///
/// El token se persiste para que recargar la página no cierre la sesión. En
/// web eso significa `localStorage`, que es legible por cualquier script de la
/// misma página: es la contrapartida conocida de no poder usar una cookie
/// `HttpOnly` contra una API que vive en otro dominio. El backend acota el
/// daño con un JWT de 60 minutos.
class SesionApi {
  SesionApi(this._store) {
    _token = _store.read(_claveToken);
    final crudo = _store.read(_claveUsuario);
    if (crudo != null && crudo.isNotEmpty) {
      try {
        _usuario =
            UsuarioApi.fromJson(jsonDecode(crudo) as Map<String, dynamic>);
      } on Object {
        // Un JSON viejo o corrupto no debe impedir arrancar: se descarta y la
        // app queda como si no hubiera sesión.
        _usuario = null;
      }
    }
  }

  static const _claveToken = 'bt_api_token';
  static const _claveUsuario = 'bt_api_usuario';

  final KeyValueStore _store;

  String? _token;
  UsuarioApi? _usuario;

  String? get token => _token;
  UsuarioApi? get usuario => _usuario;
  bool get hayToken => _token != null && _token!.isNotEmpty;

  void abrir({required String token, required UsuarioApi usuario}) {
    _token = token;
    _usuario = usuario;
    _store.write(_claveToken, token);
    _store.write(_claveUsuario, jsonEncode(usuario.toJson()));
  }

  void cerrar() {
    _token = null;
    _usuario = null;
    _store.remove(_claveToken);
    _store.remove(_claveUsuario);
  }
}
