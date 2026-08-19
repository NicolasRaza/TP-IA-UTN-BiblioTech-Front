import 'package:bibliotech/core/di/inyeccion.dart';
import 'package:bibliotech/core/services/reloj.dart';
import 'package:bibliotech/core/storage/key_value_store.dart';
import 'package:bibliotech/features/administracion/domain/entities/configuracion_biblioteca.dart';
import 'package:bibliotech/features/administracion/domain/repositories/auditoria_repository.dart';
import 'package:bibliotech/features/administracion/domain/repositories/configuracion_repository.dart';
import 'package:bibliotech/features/administracion/domain/repositories/usuario_interno_repository.dart';
import 'package:bibliotech/features/agentes/domain/repositories/aprendizaje_repository.dart';
import 'package:bibliotech/features/agentes/domain/usecases/consultas_agentes.dart';
import 'package:bibliotech/features/agentes/domain/usecases/correr_ciclo_de_agentes.dart';
import 'package:bibliotech/features/auth/domain/repositories/sesion_repository.dart';
import 'package:bibliotech/features/catalogo/domain/repositories/catalogo_repository.dart';
import 'package:bibliotech/features/lectores/domain/repositories/lector_repository.dart';
import 'package:bibliotech/features/notificaciones/domain/repositories/notificacion_repository.dart';
import 'package:bibliotech/features/prestamos/domain/repositories/prestamo_repository.dart';
import 'package:bibliotech/features/prestamos/domain/usecases/registrar_devolucion.dart';
import 'package:bibliotech/features/prestamos/domain/usecases/registrar_prestamo.dart';
import 'package:bibliotech/features/reservas/domain/repositories/reserva_repository.dart';
import 'package:bibliotech/features/reservas/domain/usecases/cancelar_reserva.dart';
import 'package:bibliotech/features/reservas/domain/usecases/crear_reserva.dart';

import '../dobles/administracion_local_datasource.dart';
import '../dobles/aprendizaje_local_datasource.dart';
import '../dobles/aprendizaje_repository_impl.dart';
import '../dobles/auditoria_repository_impl.dart';
import '../dobles/catalogo_local_datasource.dart';
import '../dobles/catalogo_repository_impl.dart';
import '../dobles/configuracion_repository_impl.dart';
import '../dobles/lector_local_datasource.dart';
import '../dobles/lector_repository_impl.dart';
import '../dobles/notificacion_local_datasource.dart';
import '../dobles/notificacion_repository_impl.dart';
import '../dobles/prestamo_local_datasource.dart';
import '../dobles/prestamo_repository_impl.dart';
import '../dobles/reserva_local_datasource.dart';
import '../dobles/reserva_repository_impl.dart';
import '../dobles/seed_data.dart';
import '../dobles/sesion_repository_impl.dart';
import '../dobles/usuario_interno_repository_local.dart';

/// Levanta el grafo real de la aplicación con la verdad en memoria.
///
/// La app corre entera contra el backend, así que un test de reglas de negocio
/// tendría que hablarle a un servidor para decir algo. Estas reglas —los
/// plazos, los cupos, las multas y la cola de la spec §7— son del dominio y no
/// de la red: se verifican contra los mismos casos de uso que resuelve el
/// composition root, montados sobre repositorios en memoria.
///
/// El entorno arma primero el grafo real con [configurarInyeccion] y después
/// pisa dos cosas:
///
/// - los repositorios, que pasan a ser los dobles de `test/dobles`;
/// - los casos de uso que delegan en un puerto remoto (prestar, devolver,
///   reservar, cancelar), que se re-registran sin ese puerto para que corra la
///   lógica de dominio y no la llamada al servidor. Eso es exactamente lo que
///   estos tests quieren mirar.
///
/// Todo lo demás —servicios de dominio, el resto de los casos de uso, blocs y
/// cubits— es el mismo registro que corre en producción.
class EntornoDePrueba {
  EntornoDePrueba._(this.reloj, this.store);

  final RelojFijo reloj;
  final MemoryStore store;

  /// Momento actual del entorno. Avanza con [avanzar] y [fijar].
  DateTime get ahora => reloj.ahora;

  void avanzar(Duration cuanto) => reloj.avanzar(cuanto);
  void fijar(DateTime momento) => reloj.fijar(momento);

  /// Arma el entorno y siembra los datos de demostración.
  static Future<EntornoDePrueba> montar({DateTime? desde}) async {
    await sl.reset();

    final reloj = RelojFijo(desde ?? DateTime(2026, 3, 10, 12));
    final store = MemoryStore();

    await configurarInyeccion(
      store: store,
      reloj: reloj,
      generadorId: GeneradorIdSecuencial(),
    );

    _montarDobles(store, reloj);
    _sembrar(reloj);

    return EntornoDePrueba._(reloj, store);
  }

  /// Resuelve cualquier pieza del grafo: `entorno<RegistrarPrestamo>()`.
  T call<T extends Object>() => sl<T>();

  Future<void> desmontar() => sl.reset();

  // ── Dobles ────────────────────────────────────────────────────────────────

  static void _montarDobles(MemoryStore store, Reloj reloj) {
    final generadorId = sl<GeneradorId>();

    // Datasources en memoria. No están en el grafo de la app, así que se
    // registran acá y no se pisa nada.
    sl.registerLazySingleton<CatalogoLocalDataSource>(
        () => CatalogoLocalDataSourceImpl(store));
    sl.registerLazySingleton<LectorLocalDataSource>(
        () => LectorLocalDataSourceImpl(store));
    sl.registerLazySingleton<PrestamoLocalDataSource>(
        () => PrestamoLocalDataSourceImpl(store));
    sl.registerLazySingleton<ReservaLocalDataSource>(
        () => ReservaLocalDataSourceImpl(store));
    sl.registerLazySingleton<NotificacionLocalDataSource>(
        () => NotificacionLocalDataSourceImpl(store));
    sl.registerLazySingleton<AdministracionLocalDataSource>(
        () => AdministracionLocalDataSourceImpl(store));
    sl.registerLazySingleton<AprendizajeLocalDataSource>(
        () => AprendizajeLocalDataSourceImpl(store));

    _pisar<CatalogoRepository>(() => CatalogoRepositoryImpl(
          localDataSource: sl(),
          generadorId: generadorId,
        ));
    _pisar<LectorRepository>(() => LectorRepositoryImpl(
          localDataSource: sl(),
          generadorId: generadorId,
          reloj: reloj,
        ));
    _pisar<PrestamoRepository>(() => PrestamoRepositoryImpl(
          localDataSource: sl(),
          generadorId: generadorId,
        ));
    _pisar<ReservaRepository>(() => ReservaRepositoryImpl(
          localDataSource: sl(),
          generadorId: generadorId,
        ));
    _pisar<NotificacionRepository>(() => NotificacionRepositoryImpl(
          localDataSource: sl(),
          generadorId: generadorId,
        ));
    _pisar<ConfiguracionRepository>(() => ConfiguracionRepositoryImpl(sl()));
    _pisar<AuditoriaRepository>(() => AuditoriaRepositoryImpl(
          localDataSource: sl(),
          generadorId: generadorId,
          reloj: reloj,
        ));
    _pisar<AprendizajeRepository>(() => AprendizajeRepositoryImpl(sl()));
    _pisar<UsuarioInternoRepository>(() => UsuarioInternoRepositorioLocal(
          lectorRepository: sl(),
          reloj: reloj,
        ));
    _pisar<SesionRepository>(() => SesionRepositoryImpl(
          store: store,
          lectorRepository: sl(),
        ));

    // Los cuatro casos de uso que en producción delegan la transacción entera
    // en el servidor. Sin el puerto remoto corre la lógica de dominio, que es
    // la que estos tests describen.
    _pisar(() => RegistrarPrestamo(
          prestamoRepository: sl(),
          lectorRepository: sl(),
          catalogoRepository: sl(),
          reservaRepository: sl(),
          notificacionRepository: sl(),
          configuracionRepository: sl(),
          auditoriaRepository: sl(),
          reloj: reloj,
        ));
    _pisar(() => RegistrarDevolucion(
          prestamoRepository: sl(),
          lectorRepository: sl(),
          catalogoRepository: sl(),
          configuracionRepository: sl(),
          auditoriaRepository: sl(),
          asignadorDeCola: sl(),
          reloj: reloj,
        ));
    _pisar(() => CrearReserva(
          reservaRepository: sl(),
          lectorRepository: sl(),
          prestamoRepository: sl(),
          catalogoRepository: sl(),
          configuracionRepository: sl(),
          aprendizajeRepository: sl(),
          asignadorDeCola: sl(),
          reloj: reloj,
        ));
    _pisar(() => CancelarReserva(
          reservaRepository: sl(),
          catalogoRepository: sl(),
          asignadorDeCola: sl(),
        ));

    // Sin servidor que corra el scheduler, el ciclo de agentes ejecuta sus
    // propias decisiones: es lo que verifican los tests de vencimientos.
    _pisar(() => CorrerCicloDeAgentes(
          procesarVencimientos: sl(),
          observador: sl(),
          evaluador: sl(),
          planificador: sl(),
          ejecutarAcciones: true,
        ));
    _pisar(() => ObtenerRecomendaciones(
          observador: sl(),
          evaluador: sl(),
        ));
  }

  static void _pisar<T extends Object>(T Function() fabrica) {
    if (sl.isRegistered<T>()) sl.unregister<T>();
    sl.registerLazySingleton<T>(fabrica);
  }

  // ── Semilla ───────────────────────────────────────────────────────────────

  static void _sembrar(Reloj reloj) {
    final seed = SeedData(reloj.ahora);
    sl<CatalogoLocalDataSource>().guardar(seed.libros());
    sl<LectorLocalDataSource>().guardar(seed.lectores());
    sl<PrestamoLocalDataSource>().guardar(seed.prestamos());
    sl<ReservaLocalDataSource>().guardar(seed.reservas());
    sl<NotificacionLocalDataSource>().guardar(seed.notificaciones());
    sl<AdministracionLocalDataSource>().guardarAuditoria(seed.auditoria());
    sl<AdministracionLocalDataSource>()
        .guardarConfiguracion(const ConfiguracionBiblioteca());
    sl<AprendizajeLocalDataSource>().guardarCorrecciones(const []);
    sl<AprendizajeLocalDataSource>().guardarInteracciones(const []);
  }
}
