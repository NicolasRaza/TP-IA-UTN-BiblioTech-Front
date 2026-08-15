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
    // Una sesión que apunta a un usuario borrado no es un error: se trata
    // como si no hubiera sesión.
    return Exito(lector.valorONull);
  }

  @override
  Future<Result<Lector>> iniciarSesion({
    required String email,
    required String pin,
  }) async {
    final buscado = await _lectores.obtenerPorEmail(email);
    final usuario = buscado.valorONull;

    // El mismo mensaje para email inexistente y PIN incorrecto: distinguirlos
    // permitiría averiguar qué cuentas existen.
    if (usuario == null || usuario.pin != pin) {
      return const Fallo(AutenticacionFailure('Email o PIN incorrectos'));
    }

    if (!usuario.activo && !usuario.esPersonal) {
      return const Fallo(AutenticacionFailure(
          'La cuenta está dada de baja. Acercate al mostrador.'));
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
