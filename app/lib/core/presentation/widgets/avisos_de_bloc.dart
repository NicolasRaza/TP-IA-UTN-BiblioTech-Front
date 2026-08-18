import 'package:flutter/material.dart';

import 'comunes.dart';

/// Muestra el mensaje de resultado de una operación, si lo hay.
///
/// Los blocs dejan `mensajeExito` / `mensajeError` en su estado en lugar de
/// mostrar el aviso ellos mismos: la capa de presentación no debe depender de
/// un `BuildContext` para poder reportar lo que pasó. Este helper es el puente
/// entre ese dato y la SnackBar, y se usa desde los `BlocListener` de cada
/// shell para que ninguna pantalla tenga que repetir la misma cañería.
void mostrarAvisoDeBloc(
  BuildContext context, {
  String? mensajeExito,
  String? mensajeError,
}) {
  if (mensajeError != null) {
    avisar(context, mensajeError, esError: true);
    return;
  }
  if (mensajeExito != null) {
    avisar(context, mensajeExito);
  }
}
