import 'package:bibliotech/core/error/failures.dart';
import 'package:bibliotech/core/error/result.dart';
import 'package:bibliotech/core/push/servicio_push.dart';
import 'package:bibliotech/features/auth/domain/entities/credenciales_api.dart';
import 'package:bibliotech/features/notificaciones/domain/repositories/push_repository.dart';
import 'package:bibliotech/features/notificaciones/domain/usecases/activar_notificaciones_push.dart';
import 'package:bibliotech/features/notificaciones/presentation/cubit/push_cubit.dart';
import 'package:bibliotech/features/notificaciones/presentation/widgets/tarjeta_push.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

/// Repositorio de mentira con las respuestas que cambian la pantalla.
class _PushRepositoryFalso implements PushRepository {
  _PushRepositoryFalso({this.soportado = true, this.falla});

  @override
  final bool soportado;

  final Failure? falla;

  CredencialesApi? credencialesRecibidas;

  @override
  Future<Result<String>> obtenerTokenDelDispositivo() async =>
      const Exito('fcm-token-de-prueba');

  @override
  Future<Result<void>> registrarTokenEnServidor({
    required String token,
    required CredencialesApi credenciales,
  }) async {
    credencialesRecibidas = credenciales;
    return falla == null ? const Exito(null) : Fallo(falla!);
  }

  @override
  Stream<MensajePush> get mensajesRecibidos => const Stream.empty();
}

void main() {
  Future<void> montar(WidgetTester tester, _PushRepositoryFalso repository) {
    return tester.pumpWidget(
      MaterialApp(
        home: BlocProvider(
          create: (_) => PushCubit(
            activarNotificacionesPush: ActivarNotificacionesPush(repository),
            repository: repository,
          ),
          child: const Scaffold(body: TarjetaPush()),
        ),
      ),
    );
  }

  testWidgets('en una plataforma sin push no ofrece el formulario',
      (tester) async {
    await montar(tester, _PushRepositoryFalso(soportado: false));

    expect(find.byType(TextField), findsNothing);
    expect(find.text('Activar notificaciones'), findsNothing);
    expect(
        find.textContaining('no puede recibir notificaciones'), findsOneWidget);
  });

  testWidgets('activar registra el dispositivo y muestra el token',
      (tester) async {
    final repository = _PushRepositoryFalso();
    await montar(tester, repository);

    await tester.enterText(find.byType(TextField).first, 'laura@demo.com');
    await tester.enterText(find.byType(TextField).last, 'secreta');
    await tester.tap(find.text('Activar notificaciones'));
    await tester.pumpAndSettle();

    expect(repository.credencialesRecibidas?.email, 'laura@demo.com');
    expect(find.text('fcm-token-de-prueba'), findsOneWidget);
    // Una vez activado, el formulario deja lugar al estado.
    expect(find.byType(TextField), findsNothing);
  });

  testWidgets(
      'si el backend rechaza las credenciales lo dice y deja reintentar',
      (tester) async {
    final repository = _PushRepositoryFalso(
      falla: const AutenticacionFailure('Usuario o contraseña incorrectos'),
    );
    await montar(tester, repository);

    await tester.enterText(find.byType(TextField).first, 'laura@demo.com');
    await tester.enterText(find.byType(TextField).last, 'mal');
    await tester.tap(find.text('Activar notificaciones'));
    await tester.pumpAndSettle();

    expect(find.text('Usuario o contraseña incorrectos'), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(2));
  });
}
