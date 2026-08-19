import 'package:bibliotech/core/di/inyeccion.dart';
import 'package:bibliotech/core/services/reloj.dart';
import 'package:bibliotech/core/storage/key_value_store.dart';
import 'package:bibliotech/features/administracion/data/repositories/auditoria_repository_api.dart';
import 'package:bibliotech/features/administracion/data/repositories/configuracion_repository_api.dart';
import 'package:bibliotech/features/administracion/data/repositories/usuario_interno_repository_api.dart';
import 'package:bibliotech/features/administracion/domain/repositories/auditoria_repository.dart';
import 'package:bibliotech/features/administracion/domain/repositories/configuracion_repository.dart';
import 'package:bibliotech/features/administracion/domain/repositories/usuario_interno_repository.dart';
import 'package:bibliotech/features/agentes/data/repositories/aprendizaje_repository_api.dart';
import 'package:bibliotech/features/agentes/domain/repositories/aprendizaje_repository.dart';
import 'package:bibliotech/features/auth/data/repositories/sesion_repository_api.dart';
import 'package:bibliotech/features/auth/domain/repositories/sesion_repository.dart';
import 'package:bibliotech/features/auth/presentation/cubit/sesion_cubit.dart';
import 'package:bibliotech/features/catalogo/data/repositories/catalogo_repository_api.dart';
import 'package:bibliotech/features/catalogo/domain/repositories/catalogo_repository.dart';
import 'package:bibliotech/features/lectores/data/repositories/lector_repository_api.dart';
import 'package:bibliotech/features/lectores/domain/repositories/lector_repository.dart';
import 'package:bibliotech/features/notificaciones/data/repositories/notificacion_repository_api.dart';
import 'package:bibliotech/features/notificaciones/domain/repositories/notificacion_repository.dart';
import 'package:bibliotech/features/prestamos/data/repositories/prestamo_repository_api.dart';
import 'package:bibliotech/features/prestamos/domain/repositories/prestamo_repository.dart';
import 'package:bibliotech/features/reservas/data/repositories/reserva_repository_api.dart';
import 'package:bibliotech/features/reservas/domain/repositories/reserva_repository.dart';
import 'package:flutter_test/flutter_test.dart';

/// La app no tiene una segunda verdad guardada en el dispositivo.
///
/// El composition root es el único lugar donde eso se decide, así que se
/// verifica ahí. Si alguien vuelve a colgar una implementación local de un
/// contrato de dominio, o si el arranque vuelve a escribir datos de negocio en
/// el almacenamiento del navegador, esto se pone en rojo.
void main() {
  late MemoryStore store;

  setUp(() async {
    await sl.reset();
    store = MemoryStore();
    await configurarInyeccion(
      store: store,
      reloj: RelojFijo(DateTime(2026, 3, 10, 12)),
      generadorId: GeneradorIdSecuencial(),
    );
  });

  tearDown(() => sl.reset());

  test('todos los contratos de dominio se resuelven contra la API', () {
    expect(sl<CatalogoRepository>(), isA<CatalogoRepositoryApi>());
    expect(sl<LectorRepository>(), isA<LectorRepositoryApi>());
    expect(sl<PrestamoRepository>(), isA<PrestamoRepositoryApi>());
    expect(sl<ReservaRepository>(), isA<ReservaRepositoryApi>());
    expect(sl<UsuarioInternoRepository>(), isA<UsuarioInternoRepositoryApi>());
    expect(sl<SesionRepository>(), isA<SesionRepositoryApi>());

    // Las cuatro que hasta hace poco vivían en el navegador.
    expect(sl<NotificacionRepository>(), isA<NotificacionRepositoryApi>());
    expect(sl<AuditoriaRepository>(), isA<AuditoriaRepositoryApi>());
    expect(sl<ConfiguracionRepository>(), isA<ConfiguracionRepositoryApi>());
    expect(sl<AprendizajeRepository>(), isA<AprendizajeRepositoryApi>());
  });

  test('armar el grafo no escribe nada en el dispositivo', () {
    expect(store.keys, isEmpty,
        reason: 'no hay datos de demostración que sembrar: son del servidor');
  });

  test('abrir la app sin sesión tampoco escribe nada', () async {
    await sl<SesionCubit>().arrancar();

    expect(store.keys, isEmpty,
        reason: 'lo único que llega a guardarse es el token, y recién al '
            'iniciar sesión');
  });
}
