import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app/app.dart';
import 'core/di/inyeccion.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es');

  // Composition root: se arma el grafo de dependencias antes de levantar la
  // interfaz. A partir de acá nada resuelve dependencias por su cuenta.
  await configurarInyeccion();

  runApp(const BiblioTechApp());
}
