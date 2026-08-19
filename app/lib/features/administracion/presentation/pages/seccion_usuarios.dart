import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/presentation/widgets/comunes.dart';
import '../../../../core/theme/tema.dart';
import '../../../../core/utils/formato.dart';
import '../../../lectores/domain/entities/lector.dart';
import '../../domain/entities/usuario_interno.dart';
import '../../domain/usecases/gestionar_usuarios_internos.dart';
import '../cubit/usuarios_internos_cubit.dart';

/// Alta y baja de las cuentas del personal.
///
/// Vive sólo en el panel del administrador: el backend rechaza estas rutas con
/// cualquier otro rol, así que ofrecerlas en el panel del bibliotecario sería
/// mostrar botones que siempre devuelven 403.
class SeccionUsuarios extends StatelessWidget {
  const SeccionUsuarios({super.key});

  @override
  Widget build(BuildContext context) {
    final estado = context.watch<UsuariosInternosCubit>().state;

    return Seccion(
      children: [
        EncabezadoSeccion(
          'Usuarios del sistema',
          subtitulo: '${estado.activos.length} con acceso · '
              '${estado.dadosDeBaja.length} dados de baja',
          accion: FilledButton.icon(
            onPressed: estado.guardando ? null : () => _abrirAlta(context),
            icon: const Icon(Icons.person_add_alt, size: 18),
            label: const Text('Nueva cuenta'),
          ),
        ),
        if (estado.estado.sinDatosAun)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (estado.usuarios.isEmpty)
          const EstadoVacio(
            icono: Icons.badge_outlined,
            titulo: 'No hay cuentas de personal',
            detalle: 'Las altas de bibliotecarios y administradores se hacen '
                'desde acá.',
          )
        else
          for (final u in estado.usuarios)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _FilaUsuario(usuario: u),
            ),
      ],
    );
  }

  static Future<void> _abrirAlta(BuildContext context) {
    final cubit = context.read<UsuariosInternosCubit>();
    return showDialog<void>(
      context: context,
      builder: (_) => BlocProvider.value(
        value: cubit,
        child: const _DialogoAlta(),
      ),
    );
  }
}

class _FilaUsuario extends StatelessWidget {
  const _FilaUsuario({required this.usuario});

  final UsuarioInterno usuario;

  @override
  Widget build(BuildContext context) {
    final estado = context.watch<UsuariosInternosCubit>().state;
    final esAdmin = usuario.rol == RolUsuario.administrador;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Wrap(
          spacing: 14,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          alignment: WrapAlignment.spaceBetween,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: (esAdmin ? Paleta.pink : Paleta.primary)
                        .withOpacity(0.15),
                    borderRadius: BorderRadius.circular(Radios.base),
                  ),
                  child: Icon(
                    esAdmin
                        ? Icons.insights_outlined
                        : Icons.local_library_outlined,
                    size: 19,
                    color: esAdmin ? Paleta.pink : Paleta.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(usuario.email,
                        style: const TextStyle(
                            fontSize: 13.5, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 3),
                    Text(
                      '${usuario.etiquetaRol} · desde '
                      '${Formato.fecha(usuario.creadoEn)}',
                      style: const TextStyle(
                          fontSize: 11.5, color: Paleta.textMuted),
                    ),
                  ],
                ),
              ],
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Insignia(
                  usuario.activo ? 'Con acceso' : 'Dado de baja',
                  color: usuario.activo ? Paleta.success : Paleta.textMuted,
                ),
                const SizedBox(width: 12),
                if (usuario.activo)
                  OutlinedButton.icon(
                    onPressed: estado.guardando
                        ? null
                        : () => context
                            .read<UsuariosInternosCubit>()
                            .cambiarEstado(usuario, activar: false),
                    icon: const Icon(Icons.block, size: 16),
                    label: const Text('Dar de baja'),
                  )
                else
                  FilledButton.icon(
                    onPressed: estado.guardando
                        ? null
                        : () => context
                            .read<UsuariosInternosCubit>()
                            .cambiarEstado(usuario, activar: true),
                    icon: const Icon(Icons.restart_alt, size: 16),
                    label: const Text('Reactivar'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DialogoAlta extends StatefulWidget {
  const _DialogoAlta();

  @override
  State<_DialogoAlta> createState() => _DialogoAltaState();
}

class _DialogoAltaState extends State<_DialogoAlta> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _clave = TextEditingController();
  RolUsuario _rol = RolUsuario.bibliotecario;

  @override
  void dispose() {
    _email.dispose();
    _clave.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_form.currentState!.validate()) return;

    final cubit = context.read<UsuariosInternosCubit>();
    await cubit.registrar(
      email: _email.text.trim(),
      password: _clave.text,
      rol: _rol,
    );
    if (!mounted) return;

    // El diálogo se cierra sólo si el alta salió bien; si falló, el mensaje
    // queda a la vista para corregir el formulario.
    if (cubit.state.mensajeError == null) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final estado = context.watch<UsuariosInternosCubit>().state;

    return AlertDialog(
      title: const Text('Nueva cuenta de personal',
          style: TextStyle(fontSize: 17)),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _email,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                validator: (v) => (v == null || !v.contains('@'))
                    ? 'Escribí un email válido'
                    : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _clave,
                decoration: const InputDecoration(
                  labelText: 'Contraseña inicial',
                  helperText: 'Al menos 6 caracteres.',
                ),
                obscureText: true,
                validator: (v) => (v == null ||
                        v.length < RegistrarUsuarioInterno.largoMinimoDeClave)
                    ? 'Mínimo '
                        '${RegistrarUsuarioInterno.largoMinimoDeClave} '
                        'caracteres'
                    : null,
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<RolUsuario>(
                value: _rol,
                decoration: const InputDecoration(labelText: 'Rol'),
                items: const [
                  DropdownMenuItem(
                    value: RolUsuario.bibliotecario,
                    child: Text('Bibliotecario'),
                  ),
                  DropdownMenuItem(
                    value: RolUsuario.administrador,
                    child: Text('Administrador'),
                  ),
                ],
                onChanged: (r) => setState(() => _rol = r ?? _rol),
              ),
              if (estado.mensajeError != null) ...[
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.error_outline,
                        color: Paleta.danger, size: 17),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        estado.mensajeError!,
                        style: const TextStyle(
                            color: Paleta.danger, fontSize: 13, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed:
              estado.guardando ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: estado.guardando ? null : _guardar,
          child: Text(estado.guardando ? 'Creando…' : 'Crear cuenta'),
        ),
      ],
    );
  }
}
