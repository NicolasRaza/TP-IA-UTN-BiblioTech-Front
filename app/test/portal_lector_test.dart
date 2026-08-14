import 'package:bibliotech/app.dart';
import 'package:bibliotech/data/repositorio.dart';
import 'package:bibliotech/data/store.dart';
import 'package:bibliotech/state/app_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

/// Tests de las pantallas del lector.
///
/// Se usa una superficie amplia para que el shell tome el layout de
/// escritorio y no haya que lidiar con la barra inferior.
void main() {
  late AppState estado;

  Future<void> abrirComoLaura(WidgetTester tester) async {
    estado = AppState(Repositorio(store: MemoryStore()))..arrancar();
    expect(estado.iniciarSesion('laura@demo.com', '1234'), isTrue);

    tester.view.physicalSize = const Size(1400, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ChangeNotifierProvider.value(value: estado, child: const BiblioTechApp()),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('el catálogo lista los libros validados', (tester) async {
    await abrirComoLaura(tester);

    expect(find.text('El Aleph'), findsAtLeastNWidgets(1));
    expect(find.text('Cien años de soledad'), findsAtLeastNWidgets(1));
    expect(find.textContaining('resultados'), findsOneWidget);
  });

  testWidgets('la búsqueda filtra el catálogo', (tester) async {
    await abrirComoLaura(tester);

    await tester.enterText(find.byType(TextField).first, 'Borges');
    await tester.pumpAndSettle();

    expect(find.text('El Aleph'), findsAtLeastNWidgets(1));
    expect(find.text('Ficciones'), findsAtLeastNWidgets(1));
    expect(find.text('1984'), findsNothing);
  });

  testWidgets('un libro sin resultados muestra el estado vacío',
      (tester) async {
    await abrirComoLaura(tester);

    await tester.enterText(find.byType(TextField).first, 'zzzz');
    await tester.pumpAndSettle();

    expect(find.text('Sin resultados'), findsOneWidget);
  });

  testWidgets('reservar desde la ficha crea la reserva', (tester) async {
    await abrirComoLaura(tester);
    final reservasAntes = estado.misReservas.length;

    await tester.tap(find.text('El Aleph').first);
    await tester.pumpAndSettle();
    expect(find.text('Sinopsis'), findsOneWidget);

    await tester.tap(find.text('Reservar'));
    await tester.pumpAndSettle();

    expect(estado.misReservas.length, reservasAntes + 1);
    expect(find.textContaining('Reserva registrada'), findsOneWidget);
  });

  testWidgets('las recomendaciones explican cómo se armó la lista',
      (tester) async {
    await abrirComoLaura(tester);

    await tester.tap(find.text('Para vos'));
    await tester.pumpAndSettle();

    // Laura tiene 3 préstamos: menos que el mínimo de 5, así que es cold start.
    expect(find.text('Todavía estamos conociéndote'), findsOneWidget);
    expect(find.textContaining('lo más leído'), findsWidgets);
  });

  testWidgets('mi actividad muestra los préstamos vigentes', (tester) async {
    await abrirComoLaura(tester);

    await tester.tap(find.text('Mi actividad'));
    await tester.pumpAndSettle();

    // Laura tiene pres-001 activo sobre "Cien años de soledad".
    expect(find.text('Cien años de soledad'), findsAtLeastNWidgets(1));
    expect(find.textContaining('Vence en'), findsOneWidget);
    expect(find.textContaining('categoría Adulto'), findsOneWidget);
  });

  testWidgets('el perfil muestra los límites de la categoría', (tester) async {
    await abrirComoLaura(tester);

    await tester.tap(find.text('Perfil'));
    await tester.pumpAndSettle();

    expect(find.text('Laura Méndez'), findsOneWidget);
    expect(find.text('Préstamos simultáneos'), findsOneWidget);
    // Adulto: límite de 3 préstamos, 1 en uso.
    expect(find.text('1 de 3'), findsNWidgets(2));
    expect(find.textContaining('Plazo de préstamo: 14 días'), findsOneWidget);
  });

  testWidgets('los avisos se pueden marcar como leídos', (tester) async {
    await abrirComoLaura(tester);
    expect(estado.misNoLeidas, greaterThan(0));

    await tester.tap(find.text('Avisos'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Marcar todo'));
    await tester.pumpAndSettle();

    expect(estado.misNoLeidas, 0);
  });
}
