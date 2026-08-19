import 'package:equatable/equatable.dart';

import '../../../lectores/domain/entities/lector.dart';

/// Cuenta del personal de la biblioteca: bibliotecario o administrador.
///
/// No es un [Lector]. El backend guarda las dos cosas por separado —un
/// `Usuario` con rol, y opcionalmente una ficha de `Lector` asociada—, y el
/// personal existe sólo como usuario: no tiene categoría, ni carnet, ni
/// préstamos. Modelarlo como un lector con rol distinto obligaría a inventar
/// media ficha vacía en cada alta.
class UsuarioInterno extends Equatable {
  const UsuarioInterno({
    required this.id,
    required this.email,
    required this.rol,
    required this.creadoEn,
    this.activo = true,
  });

  final String id;
  final String email;
  final RolUsuario rol;
  final DateTime creadoEn;

  /// Una baja es lógica: la cuenta queda sin poder iniciar sesión, pero sus
  /// acciones siguen figurando en la auditoría.
  final bool activo;

  String get etiquetaRol => switch (rol) {
        RolUsuario.administrador => 'Administrador',
        RolUsuario.bibliotecario => 'Bibliotecario',
        RolUsuario.lector => 'Lector',
      };

  @override
  List<Object?> get props => [id, email, rol, creadoEn, activo];
}
