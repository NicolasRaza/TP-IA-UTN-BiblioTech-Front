import 'package:bibliotech/core/error/failures.dart';
import 'package:bibliotech/core/error/result.dart';
import 'package:bibliotech/core/push/servicio_push.dart';
import 'package:bibliotech/features/auth/domain/entities/credenciales_api.dart';
import 'package:bibliotech/features/notificaciones/domain/repositories/push_repository.dart';
import 'package:bibliotech/features/notificaciones/domain/usecases/activar_notificaciones_push.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _PushRepositoryMock extends Mock implements PushRepository {}

void main() {
  late _PushRepositoryMock repository;
  late ActivarNotificacionesPush activar;

  const credenciales =
      CredencialesApi(email: 'laura@demo.com', password: 'secreta');
  const tokenFcm = 'fcm-token-de-prueba';

  setUpAll(() => registerFallbackValue(credenciales));

  setUp(() {
    repository = _PushRepositoryMock();
    activar = ActivarNotificacionesPush(repository);

    when(() => repository.soportado).thenReturn(true);
    when(() => repository.mensajesRecibidos)
        .thenAnswer((_) => const Stream<MensajePush>.empty());
    when(() => repository.obtenerTokenDelDispositivo())
        .thenAnswer((_) async => const Exito(tokenFcm));
    when(() => repository.registrarTokenEnServidor(
          token: any(named: 'token'),
          credenciales: any(named: 'credenciales'),
        )).thenAnswer((_) async => const Exito(null));
  });

  test('devuelve el token FCM después de registrarlo en el backend', () async {
    final resultado = await activar(credenciales);

    expect(resultado, const Exito<String>(tokenFcm));
    verify(() => repository.registrarTokenEnServidor(
          token: tokenFcm,
          credenciales: credenciales,
        )).called(1);
  });

  test('no llama al backend si la plataforma no soporta push', () async {
    when(() => repository.soportado).thenReturn(false);

    final resultado = await activar(credenciales);

    expect(resultado.failureONull, isA<PushFailure>());
    verifyNever(() => repository.obtenerTokenDelDispositivo());
    verifyNever(() => repository.registrarTokenEnServidor(
          token: any(named: 'token'),
          credenciales: any(named: 'credenciales'),
        ));
  });

  test('no pide el token si faltan las credenciales del backend', () async {
    final resultado =
        await activar(const CredencialesApi(email: '', password: ''));

    expect(resultado.failureONull, isA<ValidacionFailure>());
    verifyNever(() => repository.obtenerTokenDelDispositivo());
  });

  test('si el usuario rechaza el permiso no se registra nada', () async {
    when(() => repository.obtenerTokenDelDispositivo()).thenAnswer(
      (_) async => const Fallo(PushFailure('Rechazaste el permiso')),
    );

    final resultado = await activar(credenciales);

    expect(resultado.failureONull, isA<PushFailure>());
    verifyNever(() => repository.registrarTokenEnServidor(
          token: any(named: 'token'),
          credenciales: any(named: 'credenciales'),
        ));
  });

  test('propaga la falla del backend en vez de dar el token por bueno',
      () async {
    when(() => repository.registrarTokenEnServidor(
          token: any(named: 'token'),
          credenciales: any(named: 'credenciales'),
        )).thenAnswer(
      (_) async => const Fallo(AutenticacionFailure('Contraseña incorrecta')),
    );

    final resultado = await activar(credenciales);

    expect(resultado.esFallo, isTrue,
        reason: 'un token que el backend no guardó no sirve para nada');
    expect(resultado.failureONull, isA<AutenticacionFailure>());
  });
}
