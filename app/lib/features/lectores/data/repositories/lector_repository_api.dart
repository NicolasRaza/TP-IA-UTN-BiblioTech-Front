import '../../../../core/api/sesion_api.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/error/result.dart';
import '../../domain/entities/lector.dart';
import '../../domain/entities/solicitud_de_registro.dart';
import '../../domain/repositories/lector_repository.dart';
import '../datasources/lector_api_datasource.dart';

/// Implementación del [LectorRepository] contra la API del backend.
///
/// El padrón vive en el servidor: altas, ediciones y búsquedas viajan por
/// `/api/v1/lectores`. La [SesionApi] entra acá por un motivo concreto: el
/// backend no expone ninguna ruta con la que un lector pueda leer su propia
/// ficha —todo `/lectores` pide rol bibliotecario—, así que para el usuario
/// autenticado se completan desde la sesión los datos que la API sí dio al
/// iniciarla (su email y su id de lector).
class LectorRepositoryApi implements LectorRepository {
  const LectorRepositoryApi({
    required LectorApiDataSource api,
    required SesionApi sesion,
  })  : _api = api,
        _sesion = sesion;

  final LectorApiDataSource _api;
  final SesionApi _sesion;

  @override
  Future<Result<List<Lector>>> obtenerUsuarios() => _api.listar();

  /// `GET /lectores` ya devuelve sólo lectores: el personal vive en la tabla
  /// de usuarios y no tiene ficha, así que no hay nada que filtrar.
  @override
  Future<Result<List<Lector>>> obtenerLectores() => _api.listar();

  @override
  Future<Result<Lector>> obtenerPorId(String lectorId) async {
    final ficha = await _api.obtener(lectorId);
    return ficha.map(_conEmailDeLaSesion);
  }

  @override
  Future<Result<Lector>> obtenerPorEmail(String email) async {
    // El email no viaja en la ficha, así que no se puede buscar por él contra
    // la API. El único caso que la app necesita resolver es "quién soy",
    // y para eso alcanza con la sesión abierta.
    final usuario = _sesion.usuario;
    if (usuario == null || usuario.email.toLowerCase() != email.toLowerCase()) {
      return const Fallo(NoEncontradoFailure(
        'El servidor no permite buscar lectores por email',
      ));
    }
    final lectorId = usuario.lectorId;
    if (lectorId == null) {
      return const Fallo(NoEncontradoFailure(
        'La cuenta no tiene ficha de lector asociada',
      ));
    }
    return obtenerPorId('$lectorId');
  }

  @override
  Future<Result<Lector>> obtenerPorQr(String qr) {
    // Igual que en local, el QR del carnet deriva del id interno.
    const prefijo = 'BTL-';
    if (!qr.startsWith(prefijo)) {
      return Future.value(const Fallo(
        NoEncontradoFailure('Ese código no corresponde a un carnet'),
      ));
    }
    return obtenerPorId(qr.substring(prefijo.length));
  }

  @override
  Future<Result<Lector>> crear(Lector lector) => _api.crear(lector);

  @override
  Future<Result<Lector>> registrar(SolicitudDeRegistro solicitud) =>
      _api.registrar(solicitud);

  @override
  Future<Result<Lector>> actualizar(Lector lector) => _api.actualizar(lector);

  @override
  Future<Result<Lector>> ajustarMultas(String lectorId, int delta) async =>
      // Las multas del backend son registros propios (`/api/v1/multas`) con su
      // motivo y su estado, no un saldo acumulado en el lector. Ajustar un
      // número desde acá no tendría a dónde ir: se paga o se condona una multa
      // concreta.
      const Fallo(ReglaDeNegocioFailure(
        'Las multas se pagan o condonan una por una desde el mostrador',
      ));

  /// El email sólo se conoce para el usuario autenticado.
  Lector _conEmailDeLaSesion(Lector lector) {
    final usuario = _sesion.usuario;
    if (usuario == null || '${usuario.lectorId}' != lector.id) return lector;
    return lector.copyWith(email: usuario.email);
  }
}
