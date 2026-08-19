import '../../../../core/api/mapeo_api.dart';
import '../../../../core/api/sesion_api.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/error/result.dart';
import '../../../lectores/domain/entities/lector.dart';
import '../../../lectores/domain/repositories/lector_repository.dart';
import '../../domain/entities/credenciales_api.dart';
import '../../domain/repositories/sesion_repository.dart';
import '../datasources/auth_api_datasource.dart';

/// Implementación del [SesionRepository] contra la API del backend.
///
/// La sesión es el JWT que devuelve `POST /auth/login`. Quién es su dueño lo
/// dice `GET /auth/me`, que es también lo que valida que el token siga vivo al
/// arrancar la app: un JWT vencido no se distingue de uno bueno mirándolo, sólo
/// preguntándole al servidor.
class SesionRepositoryApi implements SesionRepository {
  const SesionRepositoryApi({
    required AuthApiDataSource api,
    required SesionApi sesion,
    required LectorRepository lectores,
  })  : _api = api,
        _sesion = sesion,
        _lectores = lectores;

  final AuthApiDataSource _api;
  final SesionApi _sesion;
  final LectorRepository _lectores;

  @override
  Future<Result<Lector>> iniciarSesion({
    required String email,
    required String clave,
  }) async {
    final tokenResult = await _api.login(
      CredencialesApi(email: email, password: clave),
    );
    if (tokenResult case Fallo(:final failure)) return Fallo(failure);
    final token = tokenResult.valorONull!;

    final perfilResult = await _api.perfil(token);
    if (perfilResult case Fallo(:final failure)) return Fallo(failure);
    final perfil = perfilResult.valorONull!;

    // Se abre antes de resolver la ficha porque leerla ya necesita el token.
    _sesion.abrir(token: token, usuario: perfil);

    final usuario = await _resolver(perfil);
    if (usuario case Fallo(:final failure)) {
      // Si no se pudo armar el usuario, no queda una sesión a medias.
      _sesion.cerrar();
      return Fallo(failure);
    }

    // El backend deja entrar a un lector sin verificar —el login sólo mira
    // que la cuenta esté habilitada—, pero adentro no podría hacer nada: todo
    // préstamo y toda reserva le vuelven con un 403. Se le explica acá, en vez
    // de dejarlo chocar contra la primera operación.
    if (_estaPendiente(usuario.valorONull!)) {
      _sesion.cerrar();
      return const Fallo(CuentaPendienteFailure());
    }

    return usuario;
  }

  /// Un lector que se registró y todavía no verificó nadie. El personal nunca
  /// lo está: no tiene ficha de lector, y por lo tanto tampoco estado.
  static bool _estaPendiente(Lector usuario) =>
      !usuario.esPersonal && usuario.pendienteDeVerificacion;

  @override
  Future<Result<Lector?>> obtenerSesionActiva() async {
    final token = _sesion.token;
    if (token == null || token.isEmpty) return const Exito(null);

    final perfilResult = await _api.perfil(token);
    if (perfilResult case Fallo(:final failure)) {
      // Un token vencido o revocado no es un error que mostrarle a nadie: se
      // descarta la sesión y la app abre en el login, como si no hubiera
      // ninguna. Un corte de red, en cambio, sí se informa: la sesión podría
      // seguir siendo válida y borrarla haría perder el trabajo.
      if (failure is AutenticacionFailure) {
        _sesion.cerrar();
        return const Exito(null);
      }
      return Fallo(failure);
    }

    final perfil = perfilResult.valorONull!;
    _sesion.abrir(token: token, usuario: perfil);

    final usuario = await _resolver(perfil);
    if (usuario case Fallo(:final failure)) return Fallo(failure);

    // Una cuenta que volvió a quedar pendiente entre dos arranques no sigue
    // con la sesión abierta: se descarta y la app abre en el login, que es
    // donde el aviso tiene sentido.
    if (_estaPendiente(usuario.valorONull!)) {
      _sesion.cerrar();
      return const Exito(null);
    }

    return usuario.map<Lector?>((l) => l);
  }

  @override
  Future<Result<void>> cerrarSesion() async {
    // El JWT del backend no tiene ruta de revocación: cerrar sesión es dejar
    // de presentarlo y esperar a que expire (60 minutos, del lado del server).
    _sesion.cerrar();
    return const Exito(null);
  }

  /// Arma el [Lector] de la sesión a partir del perfil del backend.
  ///
  /// Para un bibliotecario o un administrador no hay ficha que buscar: el
  /// backend no les crea una, y el perfil ya trae todo lo que la app necesita
  /// para rutear y firmar la auditoría. Para un lector se pide la ficha, que
  /// agrega nombre, categoría y multas; si el backend la niega —todas las
  /// rutas de `/lectores` piden rol bibliotecario— se sigue con el perfil, que
  /// alcanza para entrar.
  Future<Result<Lector>> _resolver(UsuarioApi perfil) async {
    final rol = rolDesdeApi(perfil.rol);
    final lectorId = perfil.lectorId;

    if (rol != RolUsuario.lector || lectorId == null) {
      return Exito(_desdeElPerfil(perfil, rol));
    }

    final ficha = await _lectores.obtenerPorId('$lectorId');
    return Exito(ficha.valorONull ?? _desdeElPerfil(perfil, rol));
  }

  Lector _desdeElPerfil(UsuarioApi perfil, RolUsuario rol) => Lector(
        // Para el personal el id es el del usuario; para un lector, el de su
        // ficha, que es el que usan todas las rutas de circulación.
        id: '${perfil.lectorId ?? perfil.id}',
        nombre: perfil.email.split('@').first,
        apellido: '',
        email: perfil.email,
        categoria: rol == RolUsuario.lector
            ? CategoriaLector.adulto
            : CategoriaLector.personal,
        fechaAlta: DateTime.now(),
        estado: estadoLectorDesdeApi(perfil.estado),
        rol: rol,
      );
}
