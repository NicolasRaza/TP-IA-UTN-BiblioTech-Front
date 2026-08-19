import 'dart:convert';

import 'package:bibliotech/core/api/sesion_api.dart';
import 'package:bibliotech/core/error/failures.dart';
import 'package:bibliotech/core/error/result.dart';
import 'package:bibliotech/core/storage/key_value_store.dart';
import 'package:bibliotech/features/auth/data/datasources/auth_api_datasource.dart';
import 'package:bibliotech/features/auth/data/repositories/sesion_repository_api.dart';
import 'package:bibliotech/features/lectores/domain/entities/lector.dart';
import 'package:bibliotech/features/lectores/domain/repositories/lector_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// La sesión contra el backend: `POST /auth/login` para el JWT y
/// `GET /auth/me` para saber de quién es.
void main() {
  late MemoryStore store;
  late SesionApi sesion;

  setUp(() {
    store = MemoryStore();
    sesion = SesionApi(store);
  });

  /// Responde el login y el perfil según la ruta pedida.
  AuthApiDataSourceHttp autenticacion({
    int statusLogin = 200,
    Map<String, Object?>? perfil,
    int statusPerfil = 200,
  }) =>
      AuthApiDataSourceHttp(
        baseUrl: 'https://backend.test',
        cliente: MockClient((peticion) async {
          if (peticion.url.path.endsWith('/login')) {
            return http.Response(
              jsonEncode({'access_token': 'jwt-nuevo', 'rol': 'lector'}),
              statusLogin,
            );
          }
          return http.Response(
            jsonEncode(perfil ??
                {
                  'id': 5,
                  'email': 'laura@demo.com',
                  'rol': 'lector',
                  'lector_id': 3
                }),
            statusPerfil,
          );
        }),
      );

  SesionRepositoryApi construir(
    AuthApiDataSourceHttp api, {
    LectorRepository? lectores,
  }) =>
      SesionRepositoryApi(
        api: api,
        sesion: sesion,
        lectores: lectores ?? _PadronVacio(),
      );

  test('el login guarda el JWT y resuelve quién entró', () async {
    final repo = construir(autenticacion());

    final resultado =
        await repo.iniciarSesion(email: 'laura@demo.com', clave: 'secreta');

    expect(resultado.esExito, isTrue);
    expect(sesion.token, 'jwt-nuevo');
    expect(sesion.usuario!.lectorId, 3);
    // El id del lector es el de su ficha, que es el que usan las rutas de
    // circulación, no el del usuario de la app.
    expect(resultado.valorONull!.id, '3');
    expect(resultado.valorONull!.rol, RolUsuario.lector);
  });

  test('con la ficha disponible, la sesión trae los datos del padrón',
      () async {
    final repo = construir(
      autenticacion(),
      lectores: _PadronCon(Lector(
        id: '3',
        nombre: 'Laura',
        apellido: 'Gómez',
        email: '',
        categoria: CategoriaLector.docente,
        fechaAlta: DateTime(2026),
      )),
    );

    final usuario =
        (await repo.iniciarSesion(email: 'laura@demo.com', clave: 'x'))
            .valorONull!;

    expect(usuario.nombreCompleto, 'Laura Gómez');
    expect(usuario.categoria, CategoriaLector.docente);
  });

  test('un bibliotecario entra sin ficha de lector', () async {
    // El backend no le crea ficha al personal: `lector_id` viene en null y el
    // perfil ya alcanza para rutear y firmar la auditoría.
    final repo = construir(autenticacion(perfil: {
      'id': 1,
      'email': 'bibliotecario@demo.com',
      'rol': 'bibliotecario',
      'lector_id': null,
    }));

    final usuario =
        (await repo.iniciarSesion(email: 'bibliotecario@demo.com', clave: 'x'))
            .valorONull!;

    expect(usuario.rol, RolUsuario.bibliotecario);
    expect(usuario.id, '1');
    expect(usuario.email, 'bibliotecario@demo.com');
  });

  test('credenciales rechazadas no dejan sesión abierta', () async {
    final repo = construir(autenticacion(statusLogin: 401));

    final resultado =
        await repo.iniciarSesion(email: 'laura@demo.com', clave: 'mala');

    expect(resultado.failureONull, isA<AutenticacionFailure>());
    expect(sesion.hayToken, isFalse);
  });

  test('sin token guardado no hay sesión que recuperar', () async {
    expect((await construir(autenticacion()).obtenerSesionActiva()).valorONull,
        isNull);
  });

  test('al arrancar se revalida el token contra el servidor', () async {
    await construir(autenticacion())
        .iniciarSesion(email: 'laura@demo.com', clave: 'x');

    // Una instancia nueva sobre el mismo almacenamiento: es lo que pasa al
    // recargar la página.
    final recuperada = await SesionRepositoryApi(
      api: autenticacion(),
      sesion: SesionApi(store),
      lectores: _PadronVacio(),
    ).obtenerSesionActiva();

    expect(recuperada.valorONull, isNotNull);
    expect(recuperada.valorONull!.id, '3');
  });

  test('un token vencido abre en el login, sin mostrar ningún error', () async {
    await construir(autenticacion())
        .iniciarSesion(email: 'laura@demo.com', clave: 'x');

    final sesionGuardada = SesionApi(store);
    final recuperada = await SesionRepositoryApi(
      api: autenticacion(statusPerfil: 401),
      sesion: sesionGuardada,
      lectores: _PadronVacio(),
    ).obtenerSesionActiva();

    expect(recuperada.esExito, isTrue);
    expect(recuperada.valorONull, isNull);
    expect(sesionGuardada.hayToken, isFalse);
  });

  test('un corte de red no borra la sesión guardada', () async {
    // El token podría seguir siendo válido: descartarlo haría perder el
    // trabajo por un problema de conexión.
    await construir(autenticacion())
        .iniciarSesion(email: 'laura@demo.com', clave: 'x');

    final sesionGuardada = SesionApi(store);
    final recuperada = await SesionRepositoryApi(
      api: AuthApiDataSourceHttp(
        baseUrl: 'https://backend.test',
        cliente: MockClient((_) async => throw const _CorteDeRed()),
      ),
      sesion: sesionGuardada,
      lectores: _PadronVacio(),
    ).obtenerSesionActiva();

    expect(recuperada.failureONull, isA<RedFailure>());
    expect(sesionGuardada.hayToken, isTrue);
  });

  test('cerrar sesión descarta el token', () async {
    final repo = construir(autenticacion());
    await repo.iniciarSesion(email: 'laura@demo.com', clave: 'x');

    await repo.cerrarSesion();

    expect(sesion.hayToken, isFalse);
    expect(SesionApi(store).hayToken, isFalse);
  });
}

class _CorteDeRed implements Exception {
  const _CorteDeRed();
}

/// El backend le niega `/lectores` a un lector: la sesión se arma igual.
class _PadronVacio implements LectorRepository {
  @override
  Future<Result<Lector>> obtenerPorId(String id) async =>
      const Fallo(AutenticacionFailure('Se requiere rol de bibliotecario'));

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _PadronCon implements LectorRepository {
  _PadronCon(this.lector);
  final Lector lector;

  @override
  Future<Result<Lector>> obtenerPorId(String id) async => Exito(lector);

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
