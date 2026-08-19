import '../../../../core/error/failures.dart';
import '../../../../core/error/result.dart';
import '../../../../core/storage/key_value_store.dart';
import '../../../lectores/domain/entities/lector.dart';
import '../../../lectores/domain/repositories/lector_repository.dart';
import '../../domain/repositories/sesion_repository.dart';

/// Implementación del [SesionRepository].
///
/// La sesión se guarda como el id del usuario logueado; los datos de la
/// persona se resuelven contra el [LectorRepository]. Así no hay una copia
/// del lector conviviendo con el padrón y quedándose desactualizada.
class SesionRepositoryImpl implements SesionRepository {
  const SesionRepositoryImpl({
    required KeyValueStore store,
    required LectorRepository lectorRepository,
  })  : _store = store,
        _lectores = lectorRepository;

  final KeyValueStore _store;
  final LectorRepository _lectores;

  @override
  Future<Result<Lector?>> obtenerSesionActiva() async {
    final id = _store.read(ClavesAlmacenamiento.sesion);
    if (id == null || id.isEmpty) return const Exito(null);

    final lector = await _lectores.obtenerPorId(id);
    final usuario = lector.valorONull;

    // Una sesión que apunta a un usuario borrado no es un error: se trata
    // como si no hubiera sesión. Lo mismo con una cuenta que volvió a quedar
    // pendiente de verificación.
    if (usuario != null &&
        !usuario.esPersonal &&
        usuario.pendienteDeVerificacion) {
      _store.remove(ClavesAlmacenamiento.sesion);
      return const Exito(null);
    }
    return Exito(usuario);
  }

  @override
  Future<Result<Lector>> iniciarSesion({
    required String email,
    required String clave,
  }) async {
    final buscado = await _lectores.obtenerPorEmail(email);
    final usuario = buscado.valorONull;

    // El mismo mensaje para email inexistente y PIN incorrecto: distinguirlos
    // permitiría averiguar qué cuentas existen.
    if (usuario == null || usuario.pin != clave) {
      return const Fallo(AutenticacionFailure('Email o PIN incorrectos'));
    }

    // Sólo un lector puede estar pendiente: el personal no se autorregistra.
    if (usuario.pendienteDeVerificacion) {
      return const Fallo(CuentaPendienteFailure());
    }
    if (!usuario.activo) {
      return Fallo(AutenticacionFailure(
        usuario.esPersonal
            ? 'La cuenta fue dada de baja por un administrador.'
            : 'La cuenta está dada de baja. Acercate al mostrador.',
      ));
    }

    _store.write(ClavesAlmacenamiento.sesion, usuario.id);
    return Exito(usuario);
  }

  @override
  Future<Result<void>> cerrarSesion() async {
    _store.remove(ClavesAlmacenamiento.sesion);
    return const Exito(null);
  }
}
