import 'package:bibliotech/core/error/failures.dart';
import 'package:bibliotech/core/error/result.dart';
import 'package:bibliotech/core/services/reloj.dart';
import 'package:bibliotech/features/lectores/domain/entities/lector.dart';
import 'package:bibliotech/features/lectores/domain/repositories/lector_repository.dart';
import 'package:bibliotech/features/administracion/domain/entities/usuario_interno.dart';
import 'package:bibliotech/features/administracion/domain/repositories/usuario_interno_repository.dart';

/// Implementación del [UsuarioInternoRepository] sobre el padrón local.
///
/// Sin backend no hay una tabla de usuarios aparte: el personal vive en el
/// mismo padrón que los lectores, distinguido por su [RolUsuario] —así están
/// sembrados el bibliotecario y el administrador de la demo—. Este repositorio
/// traduce entre esa forma de guardarlo y la entidad que ve el panel, para que
/// la pantalla sea la misma con backend y sin él.
class UsuarioInternoRepositorioLocal implements UsuarioInternoRepository {
  const UsuarioInternoRepositorioLocal({
    required LectorRepository lectorRepository,
    required Reloj reloj,
  })  : _lectores = lectorRepository,
        _reloj = reloj;

  final LectorRepository _lectores;
  final Reloj _reloj;

  @override
  Future<Result<List<UsuarioInterno>>> obtenerTodos() async {
    final usuarios = await _lectores.obtenerUsuarios();
    return usuarios.map(
      (lista) => lista.where((u) => u.esPersonal).map(_desdeLector).toList()
        ..sort((a, b) => a.email.compareTo(b.email)),
    );
  }

  @override
  Future<Result<UsuarioInterno>> crear({
    required String email,
    required String password,
    required RolUsuario rol,
  }) async {
    final existente = await _lectores.obtenerPorEmail(email);
    if (existente.esExito) {
      return const Fallo(ValidacionFailure('Ya hay una cuenta con ese email'));
    }

    final ahora = _reloj.ahora;
    final creado = await _lectores.crear(Lector(
      id: '',
      nombre: email.split('@').first,
      apellido: '',
      email: email,
      // El personal no toma préstamos: la categoría existe sólo porque la
      // entidad la pide.
      categoria: CategoriaLector.personal,
      fechaAlta: ahora,
      pin: password,
      rol: rol,
    ));

    return creado.map(_desdeLector);
  }

  @override
  Future<Result<void>> darDeBaja(String usuarioId) =>
      _cambiarEstado(usuarioId, EstadoLector.baja);

  @override
  Future<Result<void>> reactivar(String usuarioId) =>
      _cambiarEstado(usuarioId, EstadoLector.activo);

  Future<Result<void>> _cambiarEstado(String id, EstadoLector estado) async {
    final buscado = await _lectores.obtenerPorId(id);
    if (buscado case Fallo(:final failure)) return Fallo(failure);

    final actualizado = await _lectores
        .actualizar(buscado.valorONull!.copyWith(estado: estado));
    return actualizado.map<void>((_) {});
  }

  UsuarioInterno _desdeLector(Lector l) => UsuarioInterno(
        id: l.id,
        email: l.email,
        rol: l.rol,
        creadoEn: l.fechaAlta,
        activo: l.activo,
      );
}
