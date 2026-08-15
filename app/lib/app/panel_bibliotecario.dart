import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../core/di/inyeccion.dart';
import '../core/presentation/widgets/avisos_de_bloc.dart';
import '../core/theme/tema.dart';
import '../features/agentes/presentation/bloc/agentes_bloc.dart';
import '../features/agentes/presentation/pages/seccion_alertas.dart';
import '../features/agentes/presentation/pages/seccion_dashboard.dart';
import '../features/catalogo/presentation/bloc/catalogo_bloc.dart';
import '../features/catalogo/presentation/cubit/alta_libro_cubit.dart';
import '../features/catalogo/presentation/pages/seccion_alta_libro.dart';
import '../features/catalogo/presentation/pages/seccion_inventario.dart';
import '../features/lectores/presentation/bloc/lectores_bloc.dart';
import '../features/lectores/presentation/pages/seccion_lectores.dart';
import '../features/prestamos/presentation/bloc/prestamos_bloc.dart';
import '../features/prestamos/presentation/pages/seccion_mostrador.dart';
import '../features/reservas/presentation/bloc/reservas_bloc.dart';
import 'shell_adaptativo.dart';

/// Panel del bibliotecario (spec v2 §9), portado de `bibliotecario.html`.
class PanelBibliotecario extends StatelessWidget {
  const PanelBibliotecario({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => sl<CatalogoBloc>()..add(const CatalogoSolicitado()),
        ),
        BlocProvider(create: (_) => sl<AltaLibroCubit>()),
        BlocProvider(
          create: (_) =>
              sl<PrestamosBloc>()..add(const TodosLosPrestamosSolicitados()),
        ),
        BlocProvider(
          create: (_) =>
              sl<ReservasBloc>()..add(const TodasLasReservasSolicitadas()),
        ),
        BlocProvider(
          create: (_) => sl<LectoresBloc>()..add(const LectoresSolicitados()),
        ),
        // El ciclo de agentes corre al abrir el panel: es el momento en que
        // el sistema se pone al día y genera los avisos del día.
        BlocProvider(
          create: (_) =>
              sl<AgentesBloc>()..add(const CicloDeAgentesSolicitado()),
        ),
      ],
      child: MultiBlocListener(
        listeners: [
          BlocListener<CatalogoBloc, CatalogoState>(
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
          BlocListener<LectoresBloc, LectoresState>(
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
        child: const _ShellDelBibliotecario(),
      ),
    );
  }
}

class _ShellDelBibliotecario extends StatelessWidget {
  const _ShellDelBibliotecario();

  @override
  Widget build(BuildContext context) {
    final alertas = context.select<AgentesBloc, int>(
      (b) => b.state.prestamosVencidos + b.state.multasPendientes,
    );

    return ShellAdaptativo(
      titulo: 'Panel del Bibliotecario',
      colorRol: Paleta.primary,
      destinos: [
        Destino(
          etiqueta: 'Dashboard',
          icono: Icons.dashboard_outlined,
          iconoActivo: Icons.dashboard,
          constructor: (_) => const SeccionDashboard(),
        ),
        Destino(
          etiqueta: 'Alta de libro',
          icono: Icons.add_photo_alternate_outlined,
          iconoActivo: Icons.add_photo_alternate,
          constructor: (_) => const SeccionAltaLibro(),
        ),
        Destino(
          etiqueta: 'Catálogo',
          icono: Icons.inventory_2_outlined,
          iconoActivo: Icons.inventory_2,
          constructor: (_) => const SeccionInventario(),
        ),
        Destino(
          etiqueta: 'Préstamo',
          icono: Icons.output_outlined,
          iconoActivo: Icons.output,
          constructor: (_) => const SeccionPrestamo(),
        ),
        Destino(
          etiqueta: 'Devolución',
          icono: Icons.input_outlined,
          iconoActivo: Icons.input,
          constructor: (_) => const SeccionDevolucion(),
        ),
        Destino(
          etiqueta: 'Lectores',
          icono: Icons.people_outline,
          iconoActivo: Icons.people,
          constructor: (_) => const SeccionLectores(),
        ),
        Destino(
          etiqueta: 'Alertas',
          icono: Icons.warning_amber_outlined,
          iconoActivo: Icons.warning_amber,
          contador: alertas,
          constructor: (_) => const SeccionAlertas(),
        ),
      ],
    );
  }
}
