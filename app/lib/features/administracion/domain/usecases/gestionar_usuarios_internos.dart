/// ABM de las cuentas del personal de la biblioteca.
library;

import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/error/result.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../lectores/domain/entities/lector.dart';
import '../entities/evento_auditoria.dart';
import '../entities/usuario_interno.dart';
import '../repositories/auditoria_repository.dart';
import '../repositories/usuario_interno_repository.dart';

class ObtenerUsuariosInternos
    implements UseCase<List<UsuarioInterno>, SinParametros> {
  const ObtenerUsuariosInternos(this._repository);

  final UsuarioInternoRepository _repository;

  @override
  Future<Result<List<UsuarioInterno>>> call(SinParametros params) =>
      _repository.obtenerTodos();
}

class RegistrarUsuarioInternoParams extends Equatable {
  const RegistrarUsuarioInternoParams({
    required this.email,
    required this.password,
    required this.rol,
    this.usuarioId,
  });

  final String email;
  final String password;
  final RolUsuario rol;

  /// Administrador que da el alta, para la traza de auditoría.
  final String? usuarioId;

  @override
  List<Object?> get props => [email, password, rol, usuarioId];
}

/// Da de alta una cuenta de bibliotecario o administrador.
///
/// Es la única vía por la que aparece personal nuevo en el sistema, y sólo la
/// ejerce un administrador: el backend lo exige y el panel no la ofrece en
/// ningún otro lado.
class RegistrarUsuarioInterno
    implements UseCase<UsuarioInterno, RegistrarUsuarioInternoParams> {
  const RegistrarUsuarioInterno({
    required UsuarioInternoRepository usuarioRepository,
    required AuditoriaRepository auditoriaRepository,
  })  : _usuarios = usuarioRepository,
        _auditoria = auditoriaRepository;

  /// Mínimo que valida el backend (`BibliotecarioCreate.password_minima`).
  static const largoMinimoDeClave = 6;

  final UsuarioInternoRepository _usuarios;
  final AuditoriaRepository _auditoria;

  @override
  Future<Result<UsuarioInterno>> call(
      RegistrarUsuarioInternoParams params) async {
    final email = params.email.trim();

    if (!email.contains('@') || email.length < 3) {
      return const Fallo(ValidacionFailure('Revisá el email: no es válido'));
    }
    if (params.password.length < largoMinimoDeClave) {
      return const Fallo(ValidacionFailure(
        'La contraseña tiene que tener al menos '
        '$largoMinimoDeClave caracteres',
      ));
    }
    if (params.rol == RolUsuario.lector) {
      return const Fallo(ValidacionFailure(
        'Esta alta es para personal: el rol tiene que ser bibliotecario o '
        'administrador',
      ));
    }

    final creado = await _usuarios.crear(
      email: email,
      password: params.password,
      rol: params.rol,
    );
    if (creado case Fallo(:final failure)) return Fallo(failure);

    await _auditoria.registrar(
      tipo: TipoEventoAuditoria.altaUsuarioInterno,
      descripcion: 'Alta de ${creado.valorONull!.etiquetaRol.toLowerCase()} '
          '$email',
      usuarioId: params.usuarioId,
    );

    return creado;
  }
}

class CambiarEstadoUsuarioInternoParams extends Equatable {
  const CambiarEstadoUsuarioInternoParams({
    required this.usuario,
    required this.activar,
    this.usuarioId,
  });

  final UsuarioInterno usuario;

  /// `true` reactiva la cuenta; `false` es la baja lógica.
  final bool activar;

  final String? usuarioId;

  @override
  List<Object?> get props => [usuario, activar, usuarioId];
}

/// Da de baja o reactiva una cuenta del personal.
class CambiarEstadoUsuarioInterno
    implements UseCase<void, CambiarEstadoUsuarioInternoParams> {
  const CambiarEstadoUsuarioInterno({
    required UsuarioInternoRepository usuarioRepository,
    required AuditoriaRepository auditoriaRepository,
  })  : _usuarios = usuarioRepository,
        _auditoria = auditoriaRepository;

  final UsuarioInternoRepository _usuarios;
  final AuditoriaRepository _auditoria;

  @override
  Future<Result<void>> call(CambiarEstadoUsuarioInternoParams params) async {
    // Darse de baja a uno mismo dejaría la sesión abierta contra una cuenta
    // que ya no puede volver a entrar, y podría dejar al sistema sin ningún
    // administrador.
    if (!params.activar && params.usuario.id == params.usuarioId) {
      return const Fallo(ReglaDeNegocioFailure(
        'No podés dar de baja tu propia cuenta',
      ));
    }

    final resultado = params.activar
        ? await _usuarios.reactivar(params.usuario.id)
        : await _usuarios.darDeBaja(params.usuario.id);
    if (resultado case Fallo(:final failure)) return Fallo(failure);

    await _auditoria.registrar(
      tipo: params.activar
          ? TipoEventoAuditoria.altaUsuarioInterno
          : TipoEventoAuditoria.bajaUsuarioInterno,
      descripcion: '${params.activar ? 'Reactivación' : 'Baja'} de '
          '${params.usuario.email}',
      usuarioId: params.usuarioId,
    );

    return const Exito(null);
  }
}
