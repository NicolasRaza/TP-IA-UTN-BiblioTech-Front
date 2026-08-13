import 'package:bibliotech/app.dart';
import 'package:bibliotech/data/repositorio.dart';
import 'package:bibliotech/data/store.dart';
import 'package:bibliotech/state/app_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('sin sesión se muestra la pantalla de elección de rol',
      (tester) async {
    final estado = AppState(Repositorio(store: MemoryStore()))..arrancar();

    await tester.pumpWidget(
      ChangeNotifierProvider.value(value: estado, child: const BiblioTechApp()),
    );
    await tester.pump();

    expect(find.text('BiblioTech'), findsOneWidget);
    expect(find.text('Lector'), findsOneWidget);
    expect(find.text('Bibliotecario'), findsOneWidget);
    expect(find.text('Administrador'), findsOneWidget);
  });

  testWidgets('al iniciar sesión como lector se abre el portal',
      (tester) async {
    final estado = AppState(Repositorio(store: MemoryStore()))..arrancar();
    expect(estado.iniciarSesion('laura@demo.com', '1234'), isTrue);

    await tester.pumpWidget(
      ChangeNotifierProvider.value(value: estado, child: const BiblioTechApp()),
    );
    await tester.pump();

    expect(find.text('Catálogo'), findsWidgets);
  });
}
