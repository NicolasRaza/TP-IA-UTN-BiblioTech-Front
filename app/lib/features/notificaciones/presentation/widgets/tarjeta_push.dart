import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/config/entorno.dart';
import '../../../../core/theme/tema.dart';
import '../cubit/push_cubit.dart';

/// Activación de los avisos push en este dispositivo.
///
/// El permiso del navegador sólo se puede pedir desde un gesto del usuario
/// —Chrome bloquea los pedidos automáticos al cargar la página—, así que el
/// flujo arranca con este botón y no al iniciar la app.
class TarjetaPush extends StatefulWidget {
  const TarjetaPush({super.key});

  @override
  State<TarjetaPush> createState() => _TarjetaPushState();
}

class _TarjetaPushState extends State<TarjetaPush> {
  late final _email = TextEditingController(text: Entorno.apiEmail);
  late final _password = TextEditingController(text: Entorno.apiPassword);

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _activar() => context.read<PushCubit>().activar(
        email: _email.text.trim(),
        password: _password.text,
      );

  @override
  Widget build(BuildContext context) {
    final estado = context.watch<PushCubit>().state;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  estado.activo
                      ? Icons.notifications_active
                      : Icons.notifications_none,
                  size: 19,
                  color: estado.activo ? Paleta.success : Paleta.teal,
                ),
                const SizedBox(width: 9),
                const Expanded(
                  child: Text(
                    'Avisos en este dispositivo',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: Paleta.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _explicacion(estado),
              style: const TextStyle(
                  color: Paleta.textSecondary, fontSize: 13, height: 1.45),
            ),
            if (estado.soportado && !estado.activo) ...[
              const SizedBox(height: 14),
              TextField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                decoration: const InputDecoration(
                  labelText: 'Email de tu cuenta',
                  prefixIcon: Icon(Icons.alternate_email, size: 18),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _password,
                obscureText: true,
                onSubmitted: (_) => _activar(),
                decoration: const InputDecoration(
                  labelText: 'Contraseña',
                  prefixIcon: Icon(Icons.lock_outline, size: 18),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: estado.estado.estaCargando ? null : _activar,
                  icon: estado.estado.estaCargando
                      ? const SizedBox(
                          width: 15,
                          height: 15,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.notifications_active_outlined,
                          size: 18),
                  label: Text(estado.estado.estaCargando
                      ? 'Registrando…'
                      : 'Activar notificaciones'),
                ),
              ),
            ],
            if (estado.token != null) ...[
              const SizedBox(height: 12),
              _Token(estado.token!),
            ],
            if (estado.mensajeError != null) ...[
              const SizedBox(height: 12),
              _Aviso(
                icono: Icons.error_outline,
                color: Paleta.danger,
                texto: estado.mensajeError!,
              ),
            ],
            if (estado.ultimoAviso != null) ...[
              const SizedBox(height: 12),
              _Aviso(
                icono: Icons.campaign_outlined,
                color: Paleta.info,
                texto: 'Último push recibido: ${estado.ultimoAviso}',
              ),
            ],
          ],
        ),
      ),
    );
  }

  static String _explicacion(PushState estado) {
    if (!estado.soportado) {
      return 'Este navegador o dispositivo no puede recibir notificaciones '
          'push. En iPhone hay que agregar el sitio a la pantalla de inicio; '
          'en escritorio, usar Chrome, Edge o Firefox.';
    }
    if (estado.activo) {
      return 'Listo: el Agente Planificador ya puede avisarte acá cuando se '
          'venza un préstamo o se libere una reserva tuya.';
    }
    return 'Registrá este dispositivo para recibir los vencimientos y las '
        'reservas disponibles aunque no tengas la app abierta. Se identifica '
        'con tu cuenta del sistema, que es donde queda guardado el token.';
  }
}

/// El token FCM a la vista: durante la demo permite comparar contra el que
/// muestra la consola de Firebase y contra el que guardó el backend.
class _Token extends StatelessWidget {
  const _Token(this.token);

  final String token;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: Paleta.bgInput,
        borderRadius: BorderRadius.circular(Radios.base),
        border: Border.all(color: Paleta.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Token del dispositivo',
            style: TextStyle(color: Paleta.textMuted, fontSize: 11),
          ),
          const SizedBox(height: 4),
          SelectableText(
            token,
            maxLines: 2,
            style: const TextStyle(
              color: Paleta.textSecondary,
              fontSize: 11.5,
              fontFamily: 'monospace',
            ),
          ),
        ],
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icono, size: 16, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            texto,
            style: TextStyle(color: color, fontSize: 12.5, height: 1.4),
          ),
        ),
      ],
    );
  }
}
