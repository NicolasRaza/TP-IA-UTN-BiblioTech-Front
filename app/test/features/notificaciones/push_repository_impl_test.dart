import 'package:bibliotech/core/error/failures.dart';
import 'package:bibliotech/core/error/result.dart';
import 'package:bibliotech/core/push/servicio_push.dart';
import 'package:bibliotech/features/auth/data/datasources/auth_api_datasource.dart';
import 'package:bibliotech/features/auth/domain/entities/credenciales_api.dart';
import 'package:bibliotech/features/notificaciones/data/repositories/push_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _ApiMock extends Mock implements AuthApiDataSource {}

class _ServicioPushFalso implements ServicioPush {
  _ServicioPushFalso({this.error});

  final ExcepcionPush? error;

  @override
  bool get soportado => true;

  @override
  Future<void> inicializar() async {}

  @override
  Future<String> obtenerToken() async {
    if (error != null) throw error!;
    return 'fcm-abc';
  }

  @override
  Stream<MensajePush> get mensajesRecibidos => const Stream.empty();
}

void main() {
  late _ApiMock api;

  const credenciales =
      CredencialesApi(email: 'laura@demo.com', password: 'secreta');

  setUpAll(() => registerFallbackValue(credenciales));

  setUp(() {
    api = _ApiMock();
    when(() => api.login(any())).thenAnswer((_) async => const Exito('jwt'));
    when(() => api.registrarFirebaseToken(
          jwt: any(named: 'jwt'),
          tokenFirebase: any(named: 'tokenFirebase'),
        )).thenAnswer((_) async => const Exito(null));
  });

  test('convierte la excepción del SDK en una falla de dominio', () async {
    final repository = PushRepositoryImpl(
      servicio: _ServicioPushFalso(
        error: const ExcepcionPush('Rechazaste el permiso'),
      ),
      api: api,
    );

    final resultado = await repository.obtenerTokenDelDispositivo();

    expect(resultado.failureONull, isA<PushFailure>());
    expect(resultado.failureONull!.mensaje, 'Rechazaste el permiso');
  });

  test('se autentica antes de registrar el token', () async {
    final repository =
        PushRepositoryImpl(servicio: _ServicioPushFalso(), api: api);

    final resultado = await repository.registrarTokenEnServidor(
      token: 'fcm-abc',
      credenciales: credenciales,
    );

    expect(resultado.esExito, isTrue);
    verifyInOrder([
      () => api.login(credenciales),
      () => api.registrarFirebaseToken(jwt: 'jwt', tokenFirebase: 'fcm-abc'),
    ]);
  });

  test('si el login falla no se manda el token a ningún lado', () async {
    when(() => api.login(any())).thenAnswer(
      (_) async => const Fallo(AutenticacionFailure('Contraseña incorrecta')),
    );

    final repository =
        PushRepositoryImpl(servicio: _ServicioPushFalso(), api: api);

    final resultado = await repository.registrarTokenEnServidor(
      token: 'fcm-abc',
      credenciales: credenciales,
    );

    expect(resultado.failureONull, isA<AutenticacionFailure>());
    verifyNever(() => api.registrarFirebaseToken(
          jwt: any(named: 'jwt'),
          tokenFirebase: any(named: 'tokenFirebase'),
        ));
  });
}
