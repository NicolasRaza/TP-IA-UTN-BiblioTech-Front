import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/config/entorno.dart';
import '../../../../core/presentation/widgets/comunes.dart';
import '../../../../core/theme/tema.dart';
import '../../../../core/utils/responsive.dart';
import '../../../lectores/domain/entities/lector.dart';
import '../cubit/sesion_cubit.dart';

/// Pantalla de acceso: elección de rol y login, portada de `index.html`.
class PantallaLogin extends StatelessWidget {
  const PantallaLogin({super.key});

  @override
  Widget build(BuildContext context) {
    final compacto = context.esCompacto;

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.7),
            radius: 1.2,
            colors: [Color(0xFF141B2D), Paleta.bgBase],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1000),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const _Marca(),
                    const SizedBox(height: 40),
                    Text(
                      '¿Cómo querés ingresar?',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 22),
                    if (compacto)
                      Column(
                        children: [
                          for (final r in _TarjetaRol.roles) ...[
                            _TarjetaRol(rol: r),
                            const SizedBox(height: 14),
                          ],
                        ],
                      )
                    else
                      // IntrinsicHeight acota la altura del Row: sin esto, el
                      // stretch no tiene contra qué medirse dentro del scroll.
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            for (final r in _TarjetaRol.roles) ...[
                              Expanded(child: _TarjetaRol(rol: r)),
                              if (r != _TarjetaRol.roles.last)
                                const SizedBox(width: 16),
                            ],
                          ],
                        ),
                      ),
                    const SizedBox(height: 34),
                    const _NotaDemo(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Marca extends StatelessWidget {
  const _Marca();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Paleta.primary, Paleta.teal],
            ),
            borderRadius: BorderRadius.circular(Radios.lg),
          ),
          child: const Icon(Icons.auto_stories_outlined,
              size: 40, color: Colors.white),
        ),
        const SizedBox(height: 18),
        Text(
          'BiblioTech',
          style: Theme.of(context)
              .textTheme
              .displaySmall
              ?.copyWith(fontSize: 38, letterSpacing: -1),
        ),
        const SizedBox(height: 6),
        const Text(
          'Sistema de Gestión de Bibliotecas',
          style: TextStyle(color: Paleta.textSecondary, fontSize: 15),
        ),
      ],
    );
  }
}

class _DatosRol {
  const _DatosRol(this.rol, this.nombre, this.descripcion, this.icono,
      this.color, this.emailDemo, this.pinDemo);

  final RolUsuario rol;
  final String nombre;
  final String descripcion;
  final IconData icono;
  final Color color;
  final String emailDemo;
  final String pinDemo;

  /// Con el backend montado, las credenciales de la demo local no existen: las
  /// cuentas viven en el servidor. Se deja el formulario vacío en vez de
  /// prellenarlo con un usuario que no va a entrar.
  String get emailInicial => Entorno.usarBackend ? '' : emailDemo;
  String get claveInicial => Entorno.usarBackend ? '' : pinDemo;
}

class _TarjetaRol extends StatelessWidget {
  const _TarjetaRol({required this.rol});

  final _DatosRol rol;

  static const roles = <_DatosRol>[
    _DatosRol(
      RolUsuario.lector,
      'Lector',
      'Buscá libros, reservá y seguí tus préstamos',
      Icons.person_outline,
      Paleta.teal,
      'laura@demo.com',
      '1234',
    ),
    _DatosRol(
      RolUsuario.bibliotecario,
      'Bibliotecario',
      'Cargá libros, prestá y gestioná el inventario',
      Icons.local_library_outlined,
      Paleta.primary,
      'bibliotecario@demo.com',
      '0000',
    ),
    _DatosRol(
      RolUsuario.administrador,
      'Administrador',
      'Indicadores, parámetros y auditoría',
      Icons.insights_outlined,
      Paleta.pink,
      'admin@demo.com',
      '9999',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(Radios.md),
        onTap: () => _abrirLogin(context, rol),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: rol.color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(Radios.md),
                ),
                child: Icon(rol.icono, size: 28, color: rol.color),
              ),
              const SizedBox(height: 16),
              Text(rol.nombre, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(
                rol.descripcion,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Paleta.textMuted, fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 18),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 11),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: rol.color.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(Radios.base),
                ),
                child: Text(
                  'Ingresar',
                  style:
                      TextStyle(color: rol.color, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static void _abrirLogin(BuildContext context, _DatosRol rol) {
    showDialog<void>(
      context: context,
      builder: (_) => _DialogoLogin(rol: rol),
    );
  }
}

class _DialogoLogin extends StatefulWidget {
  const _DialogoLogin({required this.rol});

  final _DatosRol rol;

  @override
  State<_DialogoLogin> createState() => _DialogoLoginState();
}

/// "Contraseña" contra el backend, "PIN" contra el padrón local.
const _etiquetaClave = Entorno.usarBackend ? 'Contraseña' : 'PIN';

class _DialogoLoginState extends State<_DialogoLogin> {
  late final _email = TextEditingController(text: widget.rol.emailInicial);
  late final _clave = TextEditingController(text: widget.rol.claveInicial);
  final _form = GlobalKey<FormState>();
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _clave.dispose();
    super.dispose();
  }

  Future<void> _entrar() async {
    if (!_form.currentState!.validate()) return;

    final sesion = context.read<SesionCubit>();
    await sesion.iniciarSesion(
      email: _email.text.trim(),
      clave: _clave.text.trim(),
    );
    if (!mounted) return;

    // La raíz de la app rutea sola al ver la sesión abierta; acá sólo hay que
    // cerrar el diálogo o mostrar por qué no entró.
    final estado = sesion.state;
    if (estado.haySesion) {
      Navigator.of(context).pop();
    } else {
      setState(() => _error =
          estado.mensajeError ?? 'Email o $_etiquetaClave incorrectos');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: widget.rol.color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(Radios.base),
            ),
            child: Icon(widget.rol.icono, color: widget.rol.color, size: 20),
          ),
          const SizedBox(width: 12),
          Text('Ingresar como ${widget.rol.nombre}',
              style: const TextStyle(fontSize: 17)),
        ],
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _email,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Ingresá tu email' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _clave,
                decoration: const InputDecoration(labelText: _etiquetaClave),
                obscureText: true,
                // Contra el backend la credencial es una contraseña y puede
                // tener cualquier carácter; el PIN local es sólo numérico.
                keyboardType: Entorno.usarBackend
                    ? TextInputType.text
                    : TextInputType.number,
                autofillHints: const [AutofillHints.password],
                onFieldSubmitted: (_) => _entrar(),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Ingresá tu $_etiquetaClave'.toLowerCase()
                    : null,
              ),
              if (_error != null) ...[
                const SizedBox(height: 14),
                Row(
                  children: [
                    const Icon(Icons.error_outline,
                        color: Paleta.danger, size: 17),
                    const SizedBox(width: 8),
                    Text(_error!,
                        style: const TextStyle(
                            color: Paleta.danger, fontSize: 13)),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(onPressed: _entrar, child: const Text('Entrar')),
      ],
    );
  }
}

class _NotaDemo extends StatelessWidget {
  const _NotaDemo();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Paleta.bgCard.withOpacity(0.6),
        borderRadius: BorderRadius.circular(Radios.base),
        border: Border.all(color: Paleta.border),
      ),
      child: const Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.info_outline, size: 15, color: Paleta.textMuted),
              SizedBox(width: 7),
              Text(
                'Entorno de demostración',
                style: TextStyle(
                    color: Paleta.textSecondary,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600),
              ),
            ],
          ),
          SizedBox(height: 6),
          Text(
            'Los datos se guardan en este dispositivo. Las credenciales vienen precargadas en cada rol.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Paleta.textMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

/// Reexportado para que los paneles puedan mostrar el aviso de sesión cerrada.
void cerrarSesionConAviso(BuildContext context) {
  context.read<SesionCubit>().cerrarSesion();
  avisar(context, 'Sesión cerrada');
}
