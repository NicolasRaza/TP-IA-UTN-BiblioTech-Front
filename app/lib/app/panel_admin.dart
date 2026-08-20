import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../core/di/inyeccion.dart';
import '../core/presentation/widgets/avisos_de_bloc.dart';
import '../core/theme/tema.dart';
import '../features/administracion/presentation/cubit/administracion_cubit.dart';
import '../features/administracion/presentation/cubit/usuarios_internos_cubit.dart';
import '../features/administracion/presentation/pages/seccion_parametros.dart';
import '../features/administracion/presentation/pages/seccion_reportes.dart';
import '../features/administracion/presentation/pages/seccion_usuarios.dart';
import '../features/administracion/presentation/pages/secciones_varias.dart';
import '../features/agentes/presentation/bloc/agentes_bloc.dart';
import 'shell_adaptativo.dart';

/// Panel de administración (spec v2 §9).
class PanelAdmin extends StatelessWidget {
  const PanelAdmin({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => sl<AdministracionCubit>()..cargar()),
        BlocProvider(
          create: (_) =>
              sl<AgentesBloc>()..add(const DecisionesPendientesSolicitadas()),
        ),
        BlocProvider(create: (_) => sl<UsuariosInternosCubit>()..cargar()),
      ],
      child: MultiBlocListener(
        listeners: [
          BlocListener<AdministracionCubit, AdministracionState>(
            listenWhen: (a, b) =>
                a.mensajeExito != b.mensajeExito ||
                a.mensajeError != b.mensajeError,
            listener: (context, state) => mostrarAvisoDeBloc(
              context,
              mensajeExito: state.mensajeExito,
              mensajeError: state.mensajeError,
            ),
          ),
          BlocListener<UsuariosInternosCubit, UsuariosInternosState>(
            listenWhen: (a, b) =>
                a.mensajeExito != b.mensajeExito ||
                a.mensajeError != b.mensajeError,
            listener: (context, state) => mostrarAvisoDeBloc(
              context,
              mensajeExito: state.mensajeExito,
              mensajeError: state.mensajeError,
            ),
          ),
        ],
        child: const _ShellDelAdmin(),
      ),
    );
  }
}

class _ShellDelAdmin extends StatelessWidget {
  const _ShellDelAdmin();

  @override
  Widget build(BuildContext context) {
    return ShellAdaptativo(
      titulo: 'Administración',
      colorRol: Paleta.pink,
      destinos: [
        Destino(
          etiqueta: 'Reportes',
          icono: Icons.insights_outlined,
          iconoActivo: Icons.insights,
          constructor: (_) => const SeccionReportes(),
          alSeleccionar: () => context.read<AdministracionCubit>().cargar(),
        ),
        Destino(
          etiqueta: 'Parámetros',
          icono: Icons.tune_outlined,
          iconoActivo: Icons.tune,
          constructor: (_) => const SeccionParametros(),
          alSeleccionar: () => context.read<AdministracionCubit>().cargar(),
        ),
        Destino(
          etiqueta: 'Usuarios',
          icono: Icons.manage_accounts_outlined,
          iconoActivo: Icons.manage_accounts,
          constructor: (_) => const SeccionUsuarios(),
          alSeleccionar: () => context.read<UsuariosInternosCubit>().cargar(),
        ),
        Destino(
          etiqueta: 'Auditoría',
          icono: Icons.receipt_long_outlined,
          iconoActivo: Icons.receipt_long,
          constructor: (_) => const SeccionAuditoria(),
          alSeleccionar: () => context.read<AdministracionCubit>().cargar(),
        ),
        Destino(
          etiqueta: 'Aprendizaje',
          icono: Icons.psychology_outlined,
          iconoActivo: Icons.psychology,
          constructor: (_) => const SeccionAprendizaje(),
          alSeleccionar: () => context.read<AdministracionCubit>().cargar(),
        ),
        Destino(
          etiqueta: 'Sugerencias',
          icono: Icons.lightbulb_outline,
          iconoActivo: Icons.lightbulb,
          constructor: (_) => const SeccionSugerencias(),
          alSeleccionar: () => context.read<AdministracionCubit>().cargar(),
        ),
        Destino(
          etiqueta: 'Acerca de',
          icono: Icons.info_outline,
          iconoActivo: Icons.info,
          constructor: (_) => const SeccionAcerca(),
        ),
      ],
    );
  }
}
