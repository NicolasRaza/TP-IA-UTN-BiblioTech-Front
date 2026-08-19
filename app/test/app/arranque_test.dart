import 'package:bibliotech/app/app.dart';
import 'package:bibliotech/features/auth/presentation/cubit/sesion_cubit.dart';
import 'package:bibliotech/features/auth/presentation/pages/pantalla_login.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/entorno_de_prueba.dart';

/// Test de humo del arranque.
///
/// Comprueba que el composition root levanta la app entera —inyección,
/// siembra de datos y ruteo por rol— sin que la pantalla tenga que saber nada
/// del grafo de dependencias.
void main() {
  late EntornoDePrueba entorno;

  setUp(() async {
    entorno = await EntornoDePrueba.montar();
  });

  tearDown(() => entorno.desmontar());

  testWidgets('sin sesión activa la app abre en el login', (tester) async {
    await tester.pumpWidget(const BiblioTechApp());
    await tester.pumpAndSettle();

    expect(find.byType(PantallaLogin), findsOneWidget);
    expect(find.text('BiblioTech'), findsWidgets);
  });

  testWidgets('el composition root deja la sesión lista para el ruteo',
      (tester) async {
    await tester.pumpWidget(const BiblioTechApp());
    await tester.pumpAndSettle();

    final sesion = entorno<SesionCubit>();
    expect(sesion.state.haySesion, isFalse);

    await sesion.iniciarSesion(email: 'laura@demo.com', clave: '1234');
    expect(sesion.state.haySesion, isTrue,
        reason: 'la raíz de la app rutea a partir de este estado');
  });

  testWidgets('la app se levanta con el tema oscuro de BiblioTech',
      (tester) async {
    await tester.pumpWidget(const BiblioTechApp());
    await tester.pumpAndSettle();

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.theme?.brightness, Brightness.dark);
    expect(app.debugShowCheckedModeBanner, isFalse);
  });
}
