import 'package:bibliotech/core/di/inyeccion.dart';
import 'package:bibliotech/core/services/reloj.dart';
import 'package:bibliotech/core/storage/key_value_store.dart';
import 'package:bibliotech/core/usecases/usecase.dart';
import 'package:bibliotech/features/administracion/data/repositories/usuario_interno_repository_api.dart';
import 'package:bibliotech/features/administracion/domain/repositories/usuario_interno_repository.dart';
import 'package:bibliotech/features/administracion/domain/usecases/gestionar_configuracion.dart';
import 'package:bibliotech/features/auth/data/repositories/sesion_repository_api.dart';
import 'package:bibliotech/features/auth/domain/repositories/sesion_repository.dart';
import 'package:bibliotech/features/catalogo/data/repositories/catalogo_repository_api.dart';
import 'package:bibliotech/features/catalogo/domain/repositories/catalogo_repository.dart';
import 'package:bibliotech/features/lectores/data/repositories/lector_repository_api.dart';
import 'package:bibliotech/features/lectores/domain/repositories/lector_repository.dart';
import 'package:bibliotech/features/prestamos/data/repositories/prestamo_repository_api.dart';
import 'package:bibliotech/features/prestamos/domain/repositories/prestamo_repository.dart';
import 'package:bibliotech/features/reservas/data/repositories/reserva_repository_api.dart';
import 'package:bibliotech/features/reservas/domain/repositories/reserva_repository.dart';
import 'package:flutter_test/flutter_test.dart';

/// En modo backend ningún agregado de negocio puede salir del almacenamiento
/// del dispositivo.
///
/// El composition root es el único lugar donde se decide eso, así que se
/// verifica ahí: qué implementación queda atada a cada contrato y qué se
/// escribe en el store al arrancar. Si alguien vuelve a colgar un repositorio
/// local de un contrato que el servidor cubre, o si vuelve a sembrarse el
/// catálogo de demostración con el backend activo, esto se pone en rojo.
void main() {
  late MemoryStore store;

  Future<void> montar({required bool usarBackend}) async {
    await sl.reset();
    store = MemoryStore();
    await configurarInyeccion(
      store: store,
      reloj: RelojFijo(DateTime(2026, 3, 10, 12)),
      generadorId: GeneradorIdSecuencial(),
      usarBackend: usarBackend,
    );
  }

  tearDown(() => sl.reset());

  group('modo backend', () {
    setUp(() => montar(usarBackend: true));

    test('los agregados del negocio se resuelven contra la API', () {
      expect(sl<CatalogoRepository>(), isA<CatalogoRepositoryApi>());
      expect(sl<LectorRepository>(), isA<LectorRepositoryApi>());
      expect(sl<PrestamoRepository>(), isA<PrestamoRepositoryApi>());
      expect(sl<ReservaRepository>(), isA<ReservaRepositoryApi>());
      expect(sl<UsuarioInternoRepository>(), isA<UsuarioInternoRepositoryApi>());
      expect(sl<SesionRepository>(), isA<SesionRepositoryApi>());
    });

    test('arrancar no siembra datos de demostración en el dispositivo',
        () async {
      await sl<InicializarDatos>()(const SinParametros());

      const deNegocio = [
        ClavesAlmacenamiento.libros,
        ClavesAlmacenamiento.lectores,
        ClavesAlmacenamiento.prestamos,
        ClavesAlmacenamiento.reservas,
        ClavesAlmacenamiento.notificaciones,
        ClavesAlmacenamiento.auditoria,
      ];

      for (final clave in deNegocio) {
        expect(store.read(clave), isNull,
            reason: '"$clave" es del servidor: sembrarla dejaría un juego de '
                'datos paralelo que la app no lee');
      }
    });

    test(
        'lo único que queda en el dispositivo son las features que la API no '
        'cubre', () async {
      await sl<InicializarDatos>()(const SinParametros());

      // Inventario explícito de lo que todavía no es del servidor:
      // configuración de parámetros y registro de aprendizaje, ambos sembrados
      // vacíos. Si el backend llega a exponer rutas para alguna de las dos,
      // esta lista es lo que hay que achicar.
      expect(
        store.keys.toSet(),
        {
          ClavesAlmacenamiento.config,
          ClavesAlmacenamiento.aprendizaje,
          ClavesAlmacenamiento.inicializado,
        },
        reason: 'cualquier clave nueva acá es almacenamiento local que se '
            'coló en el modo backend',
      );
    });
  });

  group('modo local', () {
    setUp(() => montar(usarBackend: false));

    test('el interruptor cambia de verdad la implementación montada', () {
      expect(sl<CatalogoRepository>(), isNot(isA<CatalogoRepositoryApi>()));
      expect(sl<LectorRepository>(), isNot(isA<LectorRepositoryApi>()));
      expect(sl<PrestamoRepository>(), isNot(isA<PrestamoRepositoryApi>()));
      expect(sl<ReservaRepository>(), isNot(isA<ReservaRepositoryApi>()));
    });

    test('y ahí sí se siembran los datos de la demo', () async {
      await sl<InicializarDatos>()(const SinParametros());

      expect(store.read(ClavesAlmacenamiento.libros), isNotNull);
      expect(store.read(ClavesAlmacenamiento.lectores), isNotNull);
    });
  });
}
