import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'data/repositorio.dart';
import 'data/store.dart';
import 'state/app_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es');

  final store = await SharedPrefsStore.abrir();
  final estado = AppState(Repositorio(store: store))..arrancar();

  runApp(
    ChangeNotifierProvider.value(value: estado, child: const BiblioTechApp()),
  );
}
