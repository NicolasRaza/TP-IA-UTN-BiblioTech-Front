import 'package:bibliotech/core/error/failures.dart';
import 'package:bibliotech/core/usecases/usecase.dart';
import 'package:bibliotech/features/auth/domain/usecases/gestionar_sesion.dart';
import 'package:bibliotech/features/lectores/domain/entities/lector.dart';
import 'package:bibliotech/features/lectores/domain/entities/solicitud_de_registro.dart';
import 'package:bibliotech/features/lectores/domain/usecases/autorregistro.dart';
import 'package:bibliotech/features/lectores/domain/usecases/gestionar_lectores.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/entorno_de_prueba.dart';

/// El circuito de alta de un lector: se registra solo, queda pendiente, no
/// entra hasta que un bibliotecario lo verifica.
void main() {
  late EntornoDePrueba entorno;

  setUp(() async {
    entorno = await EntornoDePrueba.montar();
  });

  tearDown(() => entorno.desmontar());

  SolicitudDeRegistro solicitud({
    String email = 'nuevo@demo.com',
    String documento = '44111222',
    DateTime? nacimiento,
    String tutor = '',
    bool consentimiento = true,
  }) =>
      SolicitudDeRegistro(
        nombre: 'Nadia',
        apellido: 'Ferreyra',
        documento: documento,
        email: email,
        fechaNacimiento: nacimiento ?? DateTime(1995, 4, 2),
        telefono: '11-5555-0000',
        tutorNombre: tutor,
        consentimientoDatos: consentimiento,
      );

  Future<Lector> registrar([SolicitudDeRegistro? s]) async {
    final resultado = await entorno<RegistrarseComoLector>()(
      RegistrarseComoLectorParams(s ?? solicitud()),
    );
    expect(resultado.esExito, isTrue, reason: '${resultado.failureONull}');
    return resultado.valorONull!;
  }

  test('el alta nace pendiente de verificación', () async {
    final lector = await registrar();

    expect(lector.estado, EstadoLector.pendiente);
    expect(lector.pendienteDeVerificacion, isTrue);
    expect(lector.activo, isFalse);
    // Igual que en el backend: la contraseña inicial es el documento.
    expect(lector.pin, '44111222');
  });

  test('el pendiente aparece en el padrón del bibliotecario', () async {
    final lector = await registrar();

    final padron =
        (await entorno<ObtenerLectores>()(const SinParametros())).valorONull!;

    expect(padron.map((l) => l.id), contains(lector.id));
  });

  group('validaciones', () {
    test('sin consentimiento no hay alta', () async {
      final resultado = await entorno<RegistrarseComoLector>()(
        RegistrarseComoLectorParams(solicitud(consentimiento: false)),
      );

      expect(resultado.failureONull, isA<ValidacionFailure>());
    });

    test('un menor de edad necesita declarar tutor', () async {
      final resultado = await entorno<RegistrarseComoLector>()(
        RegistrarseComoLectorParams(solicitud(
          nacimiento: entorno.ahora.subtract(const Duration(days: 365 * 12)),
        )),
      );

      expect(resultado.failureONull, isA<ValidacionFailure>());

      final conTutor = await entorno<RegistrarseComoLector>()(
        RegistrarseComoLectorParams(solicitud(
          nacimiento: entorno.ahora.subtract(const Duration(days: 365 * 12)),
          tutor: 'Marta Ferreyra',
        )),
      );

      expect(conTutor.esExito, isTrue);
    });

    test('el email no se puede repetir', () async {
      await registrar();

      final repetido = await entorno<RegistrarseComoLector>()(
        RegistrarseComoLectorParams(solicitud(documento: '44999888')),
      );

      expect(repetido.failureONull, isA<ValidacionFailure>());
    });

    test('el documento no se puede repetir', () async {
      await registrar();

      final repetido = await entorno<RegistrarseComoLector>()(
        RegistrarseComoLectorParams(solicitud(email: 'otro@demo.com')),
      );

      expect(repetido.failureONull, isA<ValidacionFailure>());
    });
  });

  group('acceso', () {
    test('un lector sin verificar no puede iniciar sesión', () async {
      await registrar();

      final sesion = await entorno<IniciarSesion>()(const IniciarSesionParams(
        email: 'nuevo@demo.com',
        clave: '44111222',
      ));

      expect(sesion.failureONull, isA<CuentaPendienteFailure>());
    });

    test('verificado, entra con su documento como clave', () async {
      final lector = await registrar();

      final verificado = await entorno<VerificarLector>()(
        VerificarLectorParams(lectorId: lector.id),
      );
      expect(verificado.valorONull!.estado, EstadoLector.activo);

      final sesion = await entorno<IniciarSesion>()(const IniciarSesionParams(
        email: 'nuevo@demo.com',
        clave: '44111222',
      ));

      expect(sesion.esExito, isTrue);
      expect(sesion.valorONull!.email, 'nuevo@demo.com');
    });

    test('verificar dos veces no vuelve a pasar', () async {
      final lector = await registrar();
      await entorno<VerificarLector>()(
        VerificarLectorParams(lectorId: lector.id),
      );

      final otraVez = await entorno<VerificarLector>()(
        VerificarLectorParams(lectorId: lector.id),
      );

      expect(otraVez.failureONull, isA<ReglaDeNegocioFailure>());
    });
  });
}
