import 'package:bibliotech/app.dart';
import 'package:bibliotech/data/repositorio.dart';
import 'package:bibliotech/data/store.dart';
import 'package:bibliotech/state/app_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

/// Tests de los paneles de bibliotecario y administrador.
void main() {
  late AppState estado;

  Future<void> abrirComo(WidgetTester tester, String email, String pin) async {
    estado = AppState(Repositorio(store: MemoryStore()))..arrancar();
    expect(estado.iniciarSesion(email, pin), isTrue);

    tester.view.physicalSize = const Size(1500, 2200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ChangeNotifierProvider.value(value: estado, child: const BiblioTechApp()),
    );
    await tester.pumpAndSettle();
  }

  Future<void> abrirBibliotecario(WidgetTester tester) =>
      abrirComo(tester, 'bibliotecario@demo.com', '0000');

  Future<void> abrirAdmin(WidgetTester tester) =>
      abrirComo(tester, 'admin@demo.com', '9999');

  group('Panel del bibliotecario', () {
    testWidgets('el dashboard muestra las decisiones del Evaluador',
        (tester) async {
      await abrirBibliotecario(tester);

      expect(find.text('Dashboard'), findsWidgets);
      expect(find.text('Decisiones del Agente Evaluador'), findsOneWidget);
      expect(
        find.text(
            'El Evaluador decide qué corresponde hacer; el Planificador lo ejecuta.'),
        findsOneWidget,
      );
    });

    testWidgets('el alta analiza el texto y propone la ficha', (tester) async {
      await abrirBibliotecario(tester);

      await tester.tap(find.text('Alta de libro'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Usar ejemplo'));
      await tester.pumpAndSettle();

      expect(find.text('Ficha sugerida'), findsOneWidget);
      // El analizador reconoce el ISBN con confianza alta.
      expect(find.text('Confianza alta'), findsWidgets);
      // El título por OCR queda marcado para revisión (spec v2 §4.2).
      expect(find.text('Confianza baja'), findsWidgets);
    });

    testWidgets('guardar sin publicar deja el libro fuera del catálogo',
        (tester) async {
      await abrirBibliotecario(tester);
      final publicadosAntes = estado.repo.catalogoPublico.length;

      await tester.tap(find.text('Alta de libro'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Usar ejemplo'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Guardar sin publicar'));
      await tester.pumpAndSettle();

      expect(estado.repo.catalogoPublico.length, publicadosAntes,
          reason: 'sin confirmación el libro no entra al catálogo público');
      expect(estado.repo.pendientesValidacion, isNotEmpty);
    });

    testWidgets('confirmar y publicar lo suma al catálogo', (tester) async {
      await abrirBibliotecario(tester);
      final publicadosAntes = estado.repo.catalogoPublico.length;

      await tester.tap(find.text('Alta de libro'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Usar ejemplo'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Confirmar y publicar'));
      await tester.pumpAndSettle();

      expect(estado.repo.catalogoPublico.length, publicadosAntes + 1);
      expect(
        estado.repo.catalogoPublico
            .any((l) => l.titulo == 'El nombre de la rosa'),
        isTrue,
      );
    });

    testWidgets('la devolución libera el ejemplar', (tester) async {
      await abrirBibliotecario(tester);
      final abiertosAntes =
          estado.repo.prestamos.where((p) => p.estaAbierto).length;

      await tester.tap(find.text('Devolución'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Devolver').first);
      await tester.pumpAndSettle();

      expect(estado.repo.prestamos.where((p) => p.estaAbierto).length,
          abiertosAntes - 1);
    });

    testWidgets('las alertas agrupan las decisiones por tipo', (tester) async {
      await abrirBibliotecario(tester);

      await tester.tap(find.text('Alertas'));
      await tester.pumpAndSettle();

      // La semilla trae un préstamo vencido y un lector con multa.
      expect(find.text('Préstamos vencidos'), findsOneWidget);
      expect(find.text('Multas impagas'), findsOneWidget);
    });

    testWidgets('el cambio de categoría avisa que lo vigente no se toca',
        (tester) async {
      await abrirBibliotecario(tester);

      await tester.tap(find.text('Lectores'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Sofía Torres'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cambiar categoría'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('conservan el plazo y los límites'),
        findsOneWidget,
      );
    });
  });

  group('Panel de administración', () {
    testWidgets('los reportes muestran los indicadores', (tester) async {
      await abrirAdmin(tester);

      expect(find.text('Préstamos totales'), findsOneWidget);
      expect(find.text('Préstamos por mes'), findsOneWidget);
      expect(find.text('Títulos más prestados'), findsOneWidget);
    });

    testWidgets('los parámetros exponen la ponderación 70/30', (tester) async {
      await abrirAdmin(tester);

      await tester.tap(find.text('Parámetros'));
      await tester.pumpAndSettle();

      expect(find.text('Motor de recomendaciones'), findsOneWidget);
      expect(find.text('70% historial / 30% popularidad'), findsOneWidget);
    });

    testWidgets('cambiar un parámetro lo persiste al guardar', (tester) async {
      await abrirAdmin(tester);
      await tester.tap(find.text('Parámetros'));
      await tester.pumpAndSettle();

      final multaAntes = estado.repo.config.multaPorDiaDemora;

      // El "+" de la fila de la multa, no cualquier otro del formulario.
      await tester.tap(find.descendant(
        of: find.byKey(const ValueKey('parametro-Multa por día de demora')),
        matching: find.byIcon(Icons.add_circle_outline),
      ));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();

      // La multa se mueve de a 50.
      expect(estado.repo.config.multaPorDiaDemora, multaAntes + 50);
    });

    testWidgets('la auditoría lista los eventos registrados', (tester) async {
      await abrirAdmin(tester);

      await tester.tap(find.text('Auditoría'));
      await tester.pumpAndSettle();

      expect(find.textContaining('eventos registrados'), findsOneWidget);
      expect(find.text('Reimpresiones QR'), findsOneWidget);
    });

    testWidgets('acerca de describe la red de agentes', (tester) async {
      await abrirAdmin(tester);

      await tester.tap(find.text('Acerca de'));
      await tester.pumpAndSettle();

      expect(find.text('Red de agentes'), findsOneWidget);
      expect(find.text('Agente Evaluador'), findsOneWidget);
      expect(find.text('Agente Planificador'), findsOneWidget);
    });
  });
}
