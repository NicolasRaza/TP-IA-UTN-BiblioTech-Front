import 'package:bibliotech/app/app.dart';
import 'package:bibliotech/features/auth/presentation/cubit/sesion_cubit.dart';
import 'package:bibliotech/features/catalogo/presentation/widgets/libro_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/entorno_de_prueba.dart';

/// La ficha de libro se abre en el Navigator raíz, por encima de los
/// `BlocProvider` del portal. Este test fija que la ficha siga encontrando
/// esos blocs: antes fallaba con `ProviderNotFoundException` y el lector veía
/// la pantalla en blanco al tocar un libro del catálogo.
void main() {
  late EntornoDePrueba entorno;

  setUp(() async {
    entorno = await EntornoDePrueba.montar();
  });

  tearDown(() => entorno.desmontar());

  testWidgets('tocar un libro del catálogo abre la ficha con el detalle',
      (tester) async {
    await tester.pumpWidget(const BiblioTechApp());
    await tester.pumpAndSettle();

    await entorno<SesionCubit>()
        .iniciarSesion(email: 'laura@demo.com', clave: '1234');
    await tester.pumpAndSettle();

    final tarjetas = find.byType(TarjetaLibro);
    expect(tarjetas, findsWidgets,
        reason: 'el portal del lector abre en el catálogo');

    final libro = tester.widget<TarjetaLibro>(tarjetas.first).libro;
    await tester.ensureVisible(tarjetas.first);
    await tester.pumpAndSettle();
    await tester.tap(tarjetas.first);
    await tester.pumpAndSettle();

    expect(find.byType(Dialog), findsOneWidget);
    expect(find.text(libro.titulo), findsWidgets);
    expect(find.text('Cerrar'), findsOneWidget);
    expect(
      find.text('Reservar').evaluate().isNotEmpty ||
          find.text('Ya reservado').evaluate().isNotEmpty,
      isTrue,
      reason: 'la ficha ofrece la acción de reservar',
    );
  });
}
