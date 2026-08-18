import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../core/di/inyeccion.dart';
import '../core/presentation/widgets/avisos_de_bloc.dart';
import '../core/theme/tema.dart';
import '../features/agentes/presentation/cubit/recomendaciones_cubit.dart';
import '../features/agentes/presentation/pages/seccion_recomendaciones.dart';
import '../features/auth/presentation/cubit/sesion_cubit.dart';
import '../features/catalogo/presentation/bloc/catalogo_bloc.dart';
import '../features/catalogo/presentation/pages/seccion_catalogo.dart';
import '../features/lectores/presentation/pages/seccion_perfil.dart';
import '../features/notificaciones/presentation/cubit/notificaciones_cubit.dart';
import '../features/notificaciones/presentation/cubit/push_cubit.dart';
import '../features/notificaciones/presentation/pages/seccion_notificaciones.dart';
import '../features/prestamos/presentation/bloc/prestamos_bloc.dart';
import '../features/prestamos/presentation/pages/seccion_actividad.dart';
import '../features/reservas/presentation/bloc/reservas_bloc.dart';
import 'shell_adaptativo.dart';

/// Portal del lector (spec v2 §9), portado de `lector.html`.
///
/// Las siete secciones del prototipo se agrupan en cinco destinos: préstamos,
/// reservas e historial comparten "Mi actividad" con solapas, para que la
/// barra inferior siga siendo cómoda en un celular.
///
/// Los blocs se proveen acá y no globalmente: viven mientras dura la sesión
/// del lector y se descartan al cerrarla, así no queda estado de un usuario
/// visible para el siguiente.
class PortalLector extends StatelessWidget {
  const PortalLector({super.key});

  @override
  Widget build(BuildContext context) {
    final lectorId = context.read<SesionCubit>().state.usuario!.id;

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => sl<CatalogoBloc>()..add(const CatalogoSolicitado()),
        ),
        BlocProvider(
          create: (_) => sl<RecomendacionesCubit>()..cargar(lectorId),
        ),
        BlocProvider(
          create: (_) =>
              sl<PrestamosBloc>()..add(PrestamosDeLectorSolicitados(lectorId)),
        ),
        BlocProvider(
          create: (_) =>
              sl<ReservasBloc>()..add(ReservasDeLectorSolicitadas(lectorId)),
        ),
        BlocProvider(
          create: (_) => sl<NotificacionesCubit>()..cargar(lectorId),
        ),
        BlocProvider(create: (_) => sl<PushCubit>()),
      ],
      child: MultiBlocListener(
        listeners: [
          BlocListener<ReservasBloc, ReservasState>(
            listenWhen: (a, b) =>
                a.mensajeExito != b.mensajeExito ||
                a.mensajeError != b.mensajeError,
            listener: (context, state) => mostrarAvisoDeBloc(
              context,
              mensajeExito: state.mensajeExito,
              mensajeError: state.mensajeError,
            ),
          ),
          BlocListener<PrestamosBloc, PrestamosState>(
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
        child: const _ShellDelLector(),
      ),
    );
  }
}

class _ShellDelLector extends StatelessWidget {
  const _ShellDelLector();

  @override
  Widget build(BuildContext context) {
    final noLeidas =
        context.select<NotificacionesCubit, int>((c) => c.state.noLeidas);

    return ShellAdaptativo(
      titulo: 'Portal del Lector',
      colorRol: Paleta.teal,
      destinos: [
        Destino(
          etiqueta: 'Catálogo',
          icono: Icons.search_outlined,
          iconoActivo: Icons.search,
          constructor: (_) => const SeccionCatalogo(),
        ),
        Destino(
          etiqueta: 'Para vos',
          icono: Icons.auto_awesome_outlined,
          iconoActivo: Icons.auto_awesome,
          constructor: (_) => const SeccionRecomendaciones(),
        ),
        Destino(
          etiqueta: 'Mi actividad',
          icono: Icons.menu_book_outlined,
          iconoActivo: Icons.menu_book,
          constructor: (_) => const SeccionActividad(),
        ),
        Destino(
          etiqueta: 'Avisos',
          icono: Icons.notifications_outlined,
          iconoActivo: Icons.notifications,
          contador: noLeidas,
          constructor: (_) => const SeccionNotificaciones(),
        ),
        Destino(
          etiqueta: 'Perfil',
          icono: Icons.person_outline,
          iconoActivo: Icons.person,
          constructor: (_) => const SeccionPerfil(),
        ),
      ],
    );
  }
}
