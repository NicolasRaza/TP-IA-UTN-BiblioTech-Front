import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/responsive.dart';
import '../../core/tema.dart';
import '../../state/app_state.dart';
import 'comunes.dart';

/// Una sección navegable del panel.
class Destino {
  const Destino({
    required this.etiqueta,
    required this.icono,
    required this.iconoActivo,
    required this.constructor,
    this.contador = 0,
  });

  final String etiqueta;
  final IconData icono;
  final IconData iconoActivo;
  final WidgetBuilder constructor;

  /// Número que se muestra como globo sobre el icono (ej. no leídas).
  final int contador;
}

/// Scaffold que adapta la navegación al tamaño de pantalla.
///
/// - Celular: barra inferior.
/// - Tablet: riel lateral con iconos.
/// - Escritorio: sidebar expandido con etiquetas.
///
/// Es el mismo árbol de widgets en las tres plataformas; solo cambia el
/// contenedor de navegación.
class ShellAdaptativo extends StatefulWidget {
  const ShellAdaptativo({
    super.key,
    required this.titulo,
    required this.destinos,
    required this.colorRol,
    this.acciones = const [],
  });

  final String titulo;
  final List<Destino> destinos;
  final Color colorRol;
  final List<Widget> acciones;

  @override
  State<ShellAdaptativo> createState() => _ShellAdaptativoState();
}

class _ShellAdaptativoState extends State<ShellAdaptativo> {
  int _indice = 0;

  @override
  void didUpdateWidget(covariant ShellAdaptativo old) {
    super.didUpdateWidget(old);
    if (_indice >= widget.destinos.length) _indice = 0;
  }

  @override
  Widget build(BuildContext context) {
    final bp = context.breakpoint;
    final destino = widget.destinos[_indice];
    final contenido = Builder(builder: destino.constructor);

    if (bp == Breakpoint.compacto) {
      return Scaffold(
        appBar: _barra(context),
        body: SafeArea(child: contenido),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _indice,
          onDestinationSelected: (i) => setState(() => _indice = i),
          destinations: [
            for (final d in widget.destinos)
              NavigationDestination(
                icon: _ConGlobo(contador: d.contador, child: Icon(d.icono)),
                selectedIcon:
                    _ConGlobo(contador: d.contador, child: Icon(d.iconoActivo)),
                label: d.etiqueta,
              ),
          ],
        ),
      );
    }

    final extendido = bp == Breakpoint.amplio;
    return Scaffold(
      appBar: _barra(context),
      body: SafeArea(
        child: Row(
          children: [
            NavigationRail(
              extended: extendido,
              minExtendedWidth: 232,
              selectedIndex: _indice,
              onDestinationSelected: (i) => setState(() => _indice = i),
              leading: extendido ? null : const SizedBox(height: 8),
              destinations: [
                for (final d in widget.destinos)
                  NavigationRailDestination(
                    icon: _ConGlobo(contador: d.contador, child: Icon(d.icono)),
                    selectedIcon: _ConGlobo(
                        contador: d.contador, child: Icon(d.iconoActivo)),
                    label: Text(d.etiqueta),
                  ),
              ],
            ),
            const VerticalDivider(width: 1, color: Paleta.border),
            Expanded(child: contenido),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _barra(BuildContext context) {
    final estado = context.watch<AppState>();
    final usuario = estado.usuario;

    return AppBar(
      titleSpacing: 16,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [widget.colorRol, widget.colorRol.withOpacity(0.55)],
              ),
              borderRadius: BorderRadius.circular(Radios.sm),
            ),
            child: const Icon(Icons.auto_stories_outlined,
                size: 16, color: Colors.white),
          ),
          const SizedBox(width: 11),
          Flexible(
            child: Text(
              context.esCompacto ? widget.titulo : 'BiblioTech · ${widget.titulo}',
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
      actions: [
        ...widget.acciones,
        if (usuario != null)
          PopupMenuButton<String>(
            tooltip: 'Cuenta',
            offset: const Offset(0, 46),
            onSelected: (v) {
              if (v == 'salir') context.read<AppState>().cerrarSesion();
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                enabled: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(usuario.nombreCompleto,
                        style: const TextStyle(
                            color: Paleta.textPrimary,
                            fontWeight: FontWeight.w600)),
                    Text(usuario.email,
                        style: const TextStyle(
                            color: Paleta.textMuted, fontSize: 12)),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'salir',
                child: Row(
                  children: [
                    Icon(Icons.logout, size: 17),
                    SizedBox(width: 10),
                    Text('Cerrar sesión'),
                  ],
                ),
              ),
            ],
            child: Padding(
              padding: const EdgeInsets.only(right: 14, left: 6),
              child: AvatarLector(usuario, radio: 16),
            ),
          ),
      ],
    );
  }
}

/// Icono con globo de notificaciones.
class _ConGlobo extends StatelessWidget {
  const _ConGlobo({required this.contador, required this.child});

  final int contador;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (contador <= 0) return child;
    return Badge.count(
      count: contador,
      backgroundColor: Paleta.danger,
      textColor: Colors.white,
      child: child,
    );
  }
}

/// Contenedor con ancho máximo y scroll, usado por todas las secciones.
class Seccion extends StatelessWidget {
  const Seccion({super.key, required this.children, this.anchoMaximo = 1180});

  final List<Widget> children;
  final double anchoMaximo;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: anchoMaximo),
        child: ListView(
          padding: EdgeInsets.fromLTRB(
              context.esCompacto ? 16 : 28, 22, context.esCompacto ? 16 : 28, 40),
          children: children,
        ),
      ),
    );
  }
}
