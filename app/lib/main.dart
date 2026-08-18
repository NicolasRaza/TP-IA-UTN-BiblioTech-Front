import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app/app.dart';
import 'core/di/inyeccion.dart';
import 'core/push/servicio_push.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es');

  // Composition root: se arma el grafo de dependencias antes de levantar la
  // interfaz. A partir de acá nada resuelve dependencias por su cuenta.
  await configurarInyeccion();

  // Firebase se levanta acá pero no bloquea el arranque: si falla —un APK sin
  // google-services.json, un navegador sin push, la consola caída— la app
  // sigue funcionando y sólo se apaga la tarjeta de notificaciones. El permiso
  // del sistema no se pide todavía: eso arranca con un gesto del usuario.
  await sl<ServicioPush>().inicializar();

  runApp(const BiblioTechApp());
}
