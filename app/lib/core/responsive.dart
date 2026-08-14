import 'package:flutter/widgets.dart';

/// Tamaño de pantalla, para decidir el layout.
///
/// La app corre en web y en mobile con el mismo código: [Breakpoint] decide
/// si la navegación va como barra inferior (celular), riel lateral (tablet) o
/// sidebar expandido (escritorio).
enum Breakpoint { compacto, medio, amplio }

extension BreakpointX on BuildContext {
  Breakpoint get breakpoint {
    final w = MediaQuery.sizeOf(this).width;
    if (w < 720) return Breakpoint.compacto;
    if (w < 1100) return Breakpoint.medio;
    return Breakpoint.amplio;
  }

  bool get esCompacto => breakpoint == Breakpoint.compacto;
  bool get esAmplio => breakpoint == Breakpoint.amplio;

  /// Cantidad de columnas para las grillas de tarjetas.
  int columnasGrilla({double anchoMinimo = 260}) {
    final w = MediaQuery.sizeOf(this).width;
    final disponible = esCompacto ? w - 32 : w - 320;
    final n = (disponible / anchoMinimo).floor();
    return n < 1 ? 1 : (n > 6 ? 6 : n);
  }
}
