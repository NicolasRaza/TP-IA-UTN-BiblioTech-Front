import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/inyeccion.dart';
import '../../../../core/theme/tema.dart';
import '../../../../core/utils/formato.dart';
import '../../../lectores/domain/entities/lector.dart';
import '../../../lectores/domain/entities/solicitud_de_registro.dart';
import '../cubit/registro_cubit.dart';

/// Alta de lector hecha por la propia persona, desde la pantalla de acceso.
///
/// El alta no habilita nada por sí sola: el lector queda pendiente hasta que
/// un bibliotecario verifica los datos. La pantalla lo dice antes de que la
/// persona empiece a completar, y lo repite al confirmar.
class PantallaRegistro extends StatelessWidget {
  const PantallaRegistro({super.key});

  static Route<void> ruta() => MaterialPageRoute(
        builder: (_) => const PantallaRegistro(),
      );

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<RegistroCubit>(),
      child: Scaffold(
        appBar: AppBar(title: const Text('Registrarme como lector')),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 620),
                child: BlocBuilder<RegistroCubit, RegistroState>(
                  builder: (context, estado) => estado.seRegistro
                      ? _Confirmacion(lector: estado.registrado!)
                      : const _Formulario(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Formulario extends StatefulWidget {
  const _Formulario();

  @override
  State<_Formulario> createState() => _FormularioState();
}

class _FormularioState extends State<_Formulario> {
  final _form = GlobalKey<FormState>();
  final _nombre = TextEditingController();
  final _apellido = TextEditingController();
  final _documento = TextEditingController();
  final _email = TextEditingController();
  final _telefono = TextEditingController();
  final _domicilio = TextEditingController();
  final _tutorNombre = TextEditingController();
  final _tutorTelefono = TextEditingController();

  DateTime? _nacimiento;

  /// Categoría declarada. `menor` no está en la lista: la decide la fecha de
  /// nacimiento, no la persona.
  CategoriaLector _categoria = CategoriaLector.adulto;
  bool _consentimiento = false;
  bool _intentoEnviar = false;

  static const _categoriasDeclarables = [
    CategoriaLector.adulto,
    CategoriaLector.docente,
    CategoriaLector.senior,
  ];

  @override
  void dispose() {
    _nombre.dispose();
    _apellido.dispose();
    _documento.dispose();
    _email.dispose();
    _telefono.dispose();
    _domicilio.dispose();
    _tutorNombre.dispose();
    _tutorTelefono.dispose();
    super.dispose();
  }

  bool get _esMenor {
    final nacimiento = _nacimiento;
    if (nacimiento == null) return false;
    final ahora = DateTime.now();
    var edad = ahora.year - nacimiento.year;
    final cumple = DateTime(ahora.year, nacimiento.month, nacimiento.day);
    if (ahora.isBefore(cumple)) edad--;
    return edad < 18;
  }

  Future<void> _elegirFecha() async {
    final ahora = DateTime.now();
    final elegida = await showDatePicker(
      context: context,
      initialDate:
          _nacimiento ?? DateTime(ahora.year - 25, ahora.month, ahora.day),
      firstDate: DateTime(1900),
      lastDate: ahora,
      helpText: 'Fecha de nacimiento',
    );
    if (elegida != null) setState(() => _nacimiento = elegida);
  }

  void _enviar() {
    setState(() => _intentoEnviar = true);
    if (!_form.currentState!.validate()) return;
    if (_nacimiento == null) return;

    context.read<RegistroCubit>().registrar(SolicitudDeRegistro(
          nombre: _nombre.text.trim(),
          apellido: _apellido.text.trim(),
          documento: _documento.text.trim(),
          email: _email.text.trim(),
          fechaNacimiento: _nacimiento!,
          telefono: _telefono.text.trim(),
          domicilio: _domicilio.text.trim(),
          categoria: _esMenor ? CategoriaLector.menor : _categoria,
          tutorNombre: _tutorNombre.text.trim(),
          tutorTelefono: _tutorTelefono.text.trim(),
          consentimientoDatos: _consentimiento,
        ));
  }

  @override
  Widget build(BuildContext context) {
    final estado = context.watch<RegistroCubit>().state;
    final cargando = estado.estado.estaCargando;

    return Form(
      key: _form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Aviso(
            icono: Icons.info_outline,
            color: Paleta.info,
            texto: 'Al registrarte, tu cuenta queda pendiente de verificación. '
                'Un bibliotecario confirma tus datos y recién ahí vas a poder '
                'ingresar y pedir préstamos.',
          ),
          const SizedBox(height: 20),
          _campo(_nombre, 'Nombre', obligatorio: true),
          _campo(_apellido, 'Apellido', obligatorio: true),
          _campo(
            _documento,
            'Documento',
            obligatorio: true,
            teclado: TextInputType.number,
            ayuda: 'Va a ser tu contraseña la primera vez que entres.',
          ),
          _campo(
            _email,
            'Email',
            obligatorio: true,
            teclado: TextInputType.emailAddress,
            validador: (v) => (v == null || !v.contains('@'))
                ? 'Escribí un email válido'
                : null,
          ),
          const SizedBox(height: 6),
          _SelectorDeFecha(
            fecha: _nacimiento,
            faltante: _intentoEnviar && _nacimiento == null,
            alTocar: _elegirFecha,
          ),
          const SizedBox(height: 14),
          _campo(_telefono, 'Teléfono', teclado: TextInputType.phone),
          _campo(_domicilio, 'Domicilio'),
          if (_esMenor) ...[
            const _Aviso(
              icono: Icons.family_restroom_outlined,
              color: Paleta.warning,
              texto: 'Sos menor de edad: hace falta que declares un tutor '
                  'responsable.',
            ),
            const SizedBox(height: 14),
            _campo(_tutorNombre, 'Nombre del tutor', obligatorio: true),
            _campo(_tutorTelefono, 'Teléfono del tutor',
                teclado: TextInputType.phone),
          ] else
            DropdownButtonFormField<CategoriaLector>(
              value: _categoria,
              decoration: const InputDecoration(labelText: 'Categoría'),
              items: [
                for (final c in _categoriasDeclarables)
                  DropdownMenuItem(value: c, child: Text(c.label)),
              ],
              onChanged: (c) => setState(() => _categoria = c ?? _categoria),
            ),
          const SizedBox(height: 10),
          CheckboxListTile(
            value: _consentimiento,
            onChanged: (v) => setState(() => _consentimiento = v ?? false),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            title: const Text(
              'Acepto que la biblioteca trate mis datos personales para '
              'gestionar mi cuenta y mis préstamos.',
              style: TextStyle(fontSize: 13, height: 1.4),
            ),
          ),
          if (_intentoEnviar && !_consentimiento)
            const Padding(
              padding: EdgeInsets.only(left: 4, bottom: 6),
              child: Text(
                'Sin el consentimiento no se puede completar el registro.',
                style: TextStyle(color: Paleta.danger, fontSize: 12.5),
              ),
            ),
          if (estado.mensajeError != null) ...[
            const SizedBox(height: 10),
            _Aviso(
              icono: Icons.error_outline,
              color: Paleta.danger,
              texto: estado.mensajeError!,
            ),
          ],
          const SizedBox(height: 20),
          Row(
            children: [
              TextButton(
                onPressed:
                    cargando ? null : () => Navigator.of(context).maybePop(),
                child: const Text('Cancelar'),
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: cargando ? null : _enviar,
                icon: cargando
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.person_add_alt, size: 18),
                label: Text(cargando ? 'Enviando…' : 'Crear mi cuenta'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _campo(
    TextEditingController controlador,
    String etiqueta, {
    bool obligatorio = false,
    TextInputType? teclado,
    String? ayuda,
    String? Function(String?)? validador,
  }) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: TextFormField(
          controller: controlador,
          keyboardType: teclado,
          decoration: InputDecoration(
            labelText: obligatorio ? '$etiqueta *' : etiqueta,
            helperText: ayuda,
          ),
          validator: (v) {
            if (obligatorio && (v == null || v.trim().isEmpty)) {
              return 'Completá $etiqueta'.toLowerCase();
            }
            return validador?.call(v);
          },
        ),
      );
}

class _SelectorDeFecha extends StatelessWidget {
  const _SelectorDeFecha({
    required this.fecha,
    required this.faltante,
    required this.alTocar,
  });

  final DateTime? fecha;
  final bool faltante;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OutlinedButton.icon(
          onPressed: alTocar,
          icon: const Icon(Icons.event_outlined, size: 18),
          label: Text(fecha == null
              ? 'Elegir fecha de nacimiento *'
              : 'Nacimiento: ${Formato.fecha(fecha!)}'),
        ),
        if (faltante)
          const Padding(
            padding: EdgeInsets.only(top: 6, left: 4),
            child: Text(
              'Falta la fecha de nacimiento.',
              style: TextStyle(color: Paleta.danger, fontSize: 12.5),
            ),
          ),
      ],
    );
  }
}

class _Confirmacion extends StatelessWidget {
  const _Confirmacion({required this.lector});

  final Lector lector;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(26),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(11),
                  decoration: BoxDecoration(
                    color: Paleta.success.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(Radios.base),
                  ),
                  child: const Icon(Icons.mark_email_read_outlined,
                      color: Paleta.success, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text('Registro enviado',
                      style: Theme.of(context).textTheme.titleLarge),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              '${lector.nombreCompleto}, tus datos quedaron cargados y '
              'esperan la verificación de un bibliotecario. Hasta que la '
              'confirmen no vas a poder ingresar.',
              style: const TextStyle(
                  color: Paleta.textSecondary, fontSize: 13.5, height: 1.5),
            ),
            const SizedBox(height: 14),
            const Text(
              'Cuando esté lista, entrá con tu email y tu número de documento '
              'como contraseña.',
              style: TextStyle(
                  color: Paleta.textMuted, fontSize: 12.5, height: 1.5),
            ),
            const SizedBox(height: 22),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: () => Navigator.of(context).maybePop(),
                child: const Text('Volver al inicio'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Aviso extends StatelessWidget {
  const _Aviso({
    required this.icono,
    required this.color,
    required this.texto,
  });

  final IconData icono;
  final Color color;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.09),
        borderRadius: BorderRadius.circular(Radios.base),
        border: Border.all(color: color.withOpacity(0.28)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icono, size: 17, color: color),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              texto,
              style: const TextStyle(
                  color: Paleta.textSecondary, fontSize: 12.5, height: 1.45),
            ),
          ),
        ],
      ),
    );
  }
}
