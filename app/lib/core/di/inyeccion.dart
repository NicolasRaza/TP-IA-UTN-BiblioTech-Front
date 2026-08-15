import 'package:get_it/get_it.dart';

import '../../features/administracion/data/datasources/administracion_local_datasource.dart';
import '../../features/administracion/data/repositories/auditoria_repository_impl.dart';
import '../../features/administracion/data/repositories/configuracion_repository_impl.dart';
import '../../features/administracion/data/repositories/mantenimiento_repository_impl.dart';
import '../../features/administracion/domain/repositories/auditoria_repository.dart';
import '../../features/administracion/domain/repositories/configuracion_repository.dart';
import '../../features/administracion/domain/repositories/mantenimiento_repository.dart';
import '../../features/administracion/domain/usecases/gestionar_configuracion.dart';
import '../../features/administracion/presentation/cubit/administracion_cubit.dart';
import '../../features/agentes/data/datasources/aprendizaje_local_datasource.dart';
import '../../features/agentes/data/repositories/aprendizaje_repository_impl.dart';
import '../../features/agentes/domain/repositories/aprendizaje_repository.dart';
import '../../features/agentes/domain/services/agente_analizador.dart';
import '../../features/agentes/domain/services/agente_aprendizaje.dart';
import '../../features/agentes/domain/services/agente_evaluador.dart';
import '../../features/agentes/domain/services/agente_planificador.dart';
import '../../features/agentes/domain/services/observador_del_sistema.dart';
import '../../features/agentes/domain/usecases/consultas_agentes.dart';
import '../../features/agentes/domain/usecases/correr_ciclo_de_agentes.dart';
import '../../features/agentes/domain/usecases/procesar_vencimientos.dart';
import '../../features/agentes/presentation/bloc/agentes_bloc.dart';
import '../../features/agentes/presentation/cubit/recomendaciones_cubit.dart';
import '../../features/auth/data/repositories/sesion_repository_impl.dart';
import '../../features/auth/domain/repositories/sesion_repository.dart';
import '../../features/auth/domain/usecases/gestionar_sesion.dart';
import '../../features/auth/presentation/cubit/sesion_cubit.dart';
import '../../features/catalogo/data/datasources/catalogo_local_datasource.dart';
import '../../features/catalogo/data/repositories/catalogo_repository_impl.dart';
import '../../features/catalogo/domain/repositories/catalogo_repository.dart';
import '../../features/catalogo/domain/usecases/agregar_ejemplar.dart';
import '../../features/catalogo/domain/usecases/buscar_libros.dart';
import '../../features/catalogo/domain/usecases/consultas_catalogo.dart';
import '../../features/catalogo/domain/usecases/obtener_catalogo.dart';
import '../../features/catalogo/domain/usecases/registrar_libro.dart';
import '../../features/catalogo/domain/usecases/reimprimir_etiqueta.dart';
import '../../features/catalogo/domain/usecases/validar_libro.dart';
import '../../features/catalogo/presentation/bloc/catalogo_bloc.dart';
import '../../features/catalogo/presentation/cubit/alta_libro_cubit.dart';
import '../../features/lectores/data/datasources/lector_local_datasource.dart';
import '../../features/lectores/data/repositories/lector_repository_impl.dart';
import '../../features/lectores/domain/repositories/lector_repository.dart';
import '../../features/lectores/domain/usecases/cambiar_categoria.dart';
import '../../features/lectores/domain/usecases/gestionar_lectores.dart';
import '../../features/lectores/presentation/bloc/lectores_bloc.dart';
import '../../features/notificaciones/data/datasources/notificacion_local_datasource.dart';
import '../../features/notificaciones/data/repositories/notificacion_repository_impl.dart';
import '../../features/notificaciones/domain/repositories/notificacion_repository.dart';
import '../../features/notificaciones/domain/usecases/gestionar_notificaciones.dart';
import '../../features/notificaciones/presentation/cubit/notificaciones_cubit.dart';
import '../../features/prestamos/data/datasources/prestamo_local_datasource.dart';
import '../../features/prestamos/data/repositories/prestamo_repository_impl.dart';
import '../../features/prestamos/domain/repositories/prestamo_repository.dart';
import '../../features/prestamos/domain/usecases/consultas_prestamos.dart';
import '../../features/prestamos/domain/usecases/registrar_devolucion.dart';
import '../../features/prestamos/domain/usecases/registrar_prestamo.dart';
import '../../features/prestamos/presentation/bloc/prestamos_bloc.dart';
import '../../features/reservas/data/datasources/reserva_local_datasource.dart';
import '../../features/reservas/data/repositories/reserva_repository_impl.dart';
import '../../features/reservas/domain/repositories/reserva_repository.dart';
import '../../features/reservas/domain/services/asignador_de_cola.dart';
import '../../features/reservas/domain/usecases/cancelar_reserva.dart';
import '../../features/reservas/domain/usecases/consultas_reservas.dart';
import '../../features/reservas/domain/usecases/crear_reserva.dart';
import '../../features/reservas/presentation/bloc/reservas_bloc.dart';
import '../services/reloj.dart';
import '../storage/key_value_store.dart';

/// Service locator de la aplicación.
final sl = GetIt.instance;

/// Arma el grafo de dependencias.
///
/// Es el **composition root**: el único lugar de la app donde una interfaz se
/// ata a su implementación concreta. Todo lo demás —casos de uso, servicios de
/// dominio, blocs— recibe sus colaboradores por constructor y nunca resuelve
/// nada por su cuenta. Por eso los tests pueden construir cualquier pieza a
/// mano, con dobles, sin tocar este archivo.
///
/// El registro va de adentro hacia afuera: infraestructura → datasources →
/// repositorios → servicios de dominio → casos de uso → presentación.
///
/// Los tres parámetros existen para los tests: pasando un [MemoryStore], un
/// [RelojFijo] y un [GeneradorIdSecuencial] se obtiene el grafo real de la
/// app —los mismos casos de uso y repositorios que corren en producción— pero
/// determinista y sin plugins de Flutter.
Future<void> configurarInyeccion({
  KeyValueStore? store,
  Reloj? reloj,
  GeneradorId? generadorId,
}) async {
  // ─────────────────────────── Infraestructura ───────────────────────────

  sl.registerSingleton<KeyValueStore>(store ?? await SharedPrefsStore.abrir());
  sl.registerLazySingleton<Reloj>(() => reloj ?? const RelojDelSistema());
  sl.registerLazySingleton<GeneradorId>(
      () => generadorId ?? GeneradorIdPorTiempo(sl()));

  _registrarDataSources();
  _registrarRepositorios();
  _registrarServiciosDeDominio();
  _registrarCasosDeUso();
  _registrarPresentacion();
}

void _registrarDataSources() {
  sl.registerLazySingleton<CatalogoLocalDataSource>(
      () => CatalogoLocalDataSourceImpl(sl()));
  sl.registerLazySingleton<LectorLocalDataSource>(
      () => LectorLocalDataSourceImpl(sl()));
  sl.registerLazySingleton<PrestamoLocalDataSource>(
      () => PrestamoLocalDataSourceImpl(sl()));
  sl.registerLazySingleton<ReservaLocalDataSource>(
      () => ReservaLocalDataSourceImpl(sl()));
  sl.registerLazySingleton<NotificacionLocalDataSource>(
      () => NotificacionLocalDataSourceImpl(sl()));
  sl.registerLazySingleton<AdministracionLocalDataSource>(
      () => AdministracionLocalDataSourceImpl(sl()));
  sl.registerLazySingleton<AprendizajeLocalDataSource>(
      () => AprendizajeLocalDataSourceImpl(sl()));
}

void _registrarRepositorios() {
  sl.registerLazySingleton<CatalogoRepository>(() => CatalogoRepositoryImpl(
        localDataSource: sl(),
        generadorId: sl(),
      ));

  sl.registerLazySingleton<LectorRepository>(() => LectorRepositoryImpl(
        localDataSource: sl(),
        generadorId: sl(),
      ));

  sl.registerLazySingleton<PrestamoRepository>(() => PrestamoRepositoryImpl(
        localDataSource: sl(),
        generadorId: sl(),
      ));

  sl.registerLazySingleton<ReservaRepository>(() => ReservaRepositoryImpl(
        localDataSource: sl(),
        generadorId: sl(),
      ));

  sl.registerLazySingleton<NotificacionRepository>(
      () => NotificacionRepositoryImpl(
            localDataSource: sl(),
            generadorId: sl(),
          ));

  sl.registerLazySingleton<ConfiguracionRepository>(
      () => ConfiguracionRepositoryImpl(sl()));

  sl.registerLazySingleton<AuditoriaRepository>(() => AuditoriaRepositoryImpl(
        localDataSource: sl(),
        generadorId: sl(),
        reloj: sl(),
      ));

  sl.registerLazySingleton<AprendizajeRepository>(
      () => AprendizajeRepositoryImpl(sl()));

  sl.registerLazySingleton<SesionRepository>(() => SesionRepositoryImpl(
        store: sl(),
        lectorRepository: sl(),
      ));

  sl.registerLazySingleton<MantenimientoRepository>(
      () => MantenimientoRepositoryImpl(
            store: sl(),
            catalogoDataSource: sl(),
            lectorDataSource: sl(),
            prestamoDataSource: sl(),
            reservaDataSource: sl(),
            notificacionDataSource: sl(),
            administracionDataSource: sl(),
            aprendizajeDataSource: sl(),
            reloj: sl(),
          ));
}

void _registrarServiciosDeDominio() {
  sl.registerLazySingleton(() => AsignadorDeCola(
        reservaRepository: sl(),
        catalogoRepository: sl(),
        notificacionRepository: sl(),
        reloj: sl(),
      ));

  sl.registerLazySingleton(() => ObservadorDelSistema(
        catalogoRepository: sl(),
        lectorRepository: sl(),
        prestamoRepository: sl(),
        reservaRepository: sl(),
        configuracionRepository: sl(),
        reloj: sl(),
      ));

  // Los cuatro agentes con lógica pura no necesitan nada inyectado.
  sl.registerLazySingleton(() => const AgenteEvaluador());
  sl.registerLazySingleton(() => const AgenteAnalizador());
  sl.registerLazySingleton(() => const AgenteAprendizaje());

  sl.registerLazySingleton(() => AgentePlanificador(
        notificacionRepository: sl(),
        asignadorDeCola: sl(),
        reloj: sl(),
      ));
}

void _registrarCasosDeUso() {
  // ── Catálogo ──
  sl.registerLazySingleton(() => ObtenerCatalogo(sl()));
  sl.registerLazySingleton(() => BuscarLibros(sl()));
  sl.registerLazySingleton(() => ObtenerGeneros(sl()));
  sl.registerLazySingleton(() => ObtenerPendientesValidacion(sl()));
  sl.registerLazySingleton(() => ObtenerLibro(sl()));
  sl.registerLazySingleton(() => BuscarEjemplarPorQr(sl()));
  sl.registerLazySingleton(() => RegistrarLibro(
        catalogoRepository: sl(),
        auditoriaRepository: sl(),
      ));
  sl.registerLazySingleton(() => ValidarLibro(
        catalogoRepository: sl(),
        auditoriaRepository: sl(),
      ));
  sl.registerLazySingleton(() => AgregarEjemplar(
        catalogoRepository: sl(),
        generadorId: sl(),
      ));
  sl.registerLazySingleton(() => ReimprimirEtiqueta(
        catalogoRepository: sl(),
        auditoriaRepository: sl(),
      ));

  // ── Lectores ──
  sl.registerLazySingleton(() => ObtenerLectores(sl()));
  sl.registerLazySingleton(() => ObtenerUsuarios(sl()));
  sl.registerLazySingleton(() => ObtenerLector(sl()));
  sl.registerLazySingleton(() => BuscarLectorPorQr(sl()));
  sl.registerLazySingleton(() => RegistrarLector(
        lectorRepository: sl(),
        auditoriaRepository: sl(),
      ));
  sl.registerLazySingleton(() => ActualizarLector(
        lectorRepository: sl(),
        auditoriaRepository: sl(),
      ));
  sl.registerLazySingleton(() => CambiarCategoria(
        lectorRepository: sl(),
        auditoriaRepository: sl(),
      ));
  sl.registerLazySingleton(() => ObtenerLectoresConCategoriaDesactualizada(
        lectorRepository: sl(),
        configuracionRepository: sl(),
        reloj: sl(),
      ));

  // ── Préstamos ──
  sl.registerLazySingleton(() => ObtenerPrestamosActivos(sl()));
  sl.registerLazySingleton(() => ObtenerHistorialPrestamos(sl()));
  sl.registerLazySingleton(() => ObtenerTodosLosPrestamos(sl()));
  sl.registerLazySingleton(() => ObtenerEstadisticasPrestamos(sl()));
  sl.registerLazySingleton(() => RegistrarPrestamo(
        prestamoRepository: sl(),
        lectorRepository: sl(),
        catalogoRepository: sl(),
        reservaRepository: sl(),
        notificacionRepository: sl(),
        configuracionRepository: sl(),
        auditoriaRepository: sl(),
        reloj: sl(),
      ));
  sl.registerLazySingleton(() => RegistrarDevolucion(
        prestamoRepository: sl(),
        lectorRepository: sl(),
        catalogoRepository: sl(),
        configuracionRepository: sl(),
        auditoriaRepository: sl(),
        asignadorDeCola: sl(),
        reloj: sl(),
      ));

  // ── Reservas ──
  sl.registerLazySingleton(() => ObtenerReservasDeLector(sl()));
  sl.registerLazySingleton(() => ObtenerColaDeReservas(sl()));
  sl.registerLazySingleton(() => ObtenerTodasLasReservas(sl()));
  sl.registerLazySingleton(() => CrearReserva(
        reservaRepository: sl(),
        lectorRepository: sl(),
        prestamoRepository: sl(),
        catalogoRepository: sl(),
        configuracionRepository: sl(),
        aprendizajeRepository: sl(),
        asignadorDeCola: sl(),
        reloj: sl(),
      ));
  sl.registerLazySingleton(() => CancelarReserva(
        reservaRepository: sl(),
        catalogoRepository: sl(),
        asignadorDeCola: sl(),
      ));

  // ── Notificaciones ──
  sl.registerLazySingleton(() => ObtenerNotificaciones(sl()));
  sl.registerLazySingleton(() => ContarNoLeidas(sl()));
  sl.registerLazySingleton(() => MarcarNotificacionLeida(sl()));
  sl.registerLazySingleton(() => MarcarTodasLeidas(sl()));

  // ── Sesión ──
  sl.registerLazySingleton(() => IniciarSesion(sl()));
  sl.registerLazySingleton(() => CerrarSesion(sl()));
  sl.registerLazySingleton(() => ObtenerSesionActiva(sl()));

  // ── Administración ──
  sl.registerLazySingleton(() => ObtenerConfiguracion(sl()));
  sl.registerLazySingleton(() => GuardarConfiguracion(
        configuracionRepository: sl(),
        auditoriaRepository: sl(),
      ));
  sl.registerLazySingleton(() => ObtenerAuditoria(sl()));
  sl.registerLazySingleton(() => ReiniciarDatos(sl()));
  sl.registerLazySingleton(() => InicializarDatos(sl()));

  // ── Agentes ──
  sl.registerLazySingleton(() => ProcesarVencimientos(
        prestamoRepository: sl(),
        reservaRepository: sl(),
        lectorRepository: sl(),
        catalogoRepository: sl(),
        notificacionRepository: sl(),
        configuracionRepository: sl(),
        asignadorDeCola: sl(),
        reloj: sl(),
      ));
  sl.registerLazySingleton(() => CorrerCicloDeAgentes(
        procesarVencimientos: sl(),
        observador: sl(),
        evaluador: sl(),
        planificador: sl(),
      ));
  sl.registerLazySingleton(() => ObtenerRecomendaciones(
        observador: sl(),
        evaluador: sl(),
      ));
  sl.registerLazySingleton(() => ObtenerIndicadores(
        observador: sl(),
        evaluador: sl(),
      ));
  sl.registerLazySingleton(() => ObtenerSugerencias(
        observador: sl(),
        evaluador: sl(),
      ));
  sl.registerLazySingleton(() => ObtenerDecisionesPendientes(
        observador: sl(),
        evaluador: sl(),
      ));
  sl.registerLazySingleton(() => ObtenerReporteAprendizaje(
        aprendizajeRepository: sl(),
        catalogoRepository: sl(),
        agente: sl(),
      ));
  sl.registerLazySingleton(() => RegistrarCorreccion(
        aprendizajeRepository: sl(),
        ahora: () => sl<Reloj>().ahora,
      ));
}

void _registrarPresentacion() {
  // La sesión es singleton porque toda la app rutea según ella y varios blocs
  // necesitan saber quién está operando.
  sl.registerLazySingleton(() => SesionCubit(
        iniciarSesion: sl(),
        cerrarSesion: sl(),
        obtenerSesionActiva: sl(),
        inicializarDatos: sl(),
      ));

  // Quién opera, para la traza de auditoría. Se pasa como función y no como
  // dependencia directa del SesionCubit: así los blocs de cada feature no
  // quedan atados al feature de autenticación.
  String? usuarioActualId() => sl<SesionCubit>().state.usuario?.id;

  sl.registerFactory(() => CatalogoBloc(
        obtenerCatalogo: sl(),
        buscarLibros: sl(),
        obtenerGeneros: sl(),
        obtenerPendientesValidacion: sl(),
        registrarLibro: sl(),
        validarLibro: sl(),
        agregarEjemplar: sl(),
        reimprimirEtiqueta: sl(),
        usuarioActualId: usuarioActualId,
      ));

  sl.registerFactory(() => PrestamosBloc(
        obtenerActivos: sl(),
        obtenerHistorial: sl(),
        obtenerTodos: sl(),
        obtenerEstadisticas: sl(),
        registrarPrestamo: sl(),
        registrarDevolucion: sl(),
        usuarioActualId: usuarioActualId,
      ));

  sl.registerFactory(() => ReservasBloc(
        obtenerDeLector: sl(),
        obtenerTodas: sl(),
        crearReserva: sl(),
        cancelarReserva: sl(),
      ));

  sl.registerFactory(() => LectoresBloc(
        obtenerLectores: sl(),
        registrarLector: sl(),
        actualizarLector: sl(),
        cambiarCategoria: sl(),
        obtenerDesactualizados: sl(),
        buscarPorQr: sl(),
        usuarioActualId: usuarioActualId,
      ));

  sl.registerFactory(() => NotificacionesCubit(
        obtenerNotificaciones: sl(),
        contarNoLeidas: sl(),
        marcarLeida: sl(),
        marcarTodasLeidas: sl(),
      ));

  sl.registerFactory(() => RecomendacionesCubit(
        obtenerRecomendaciones: sl(),
        obtenerConfiguracion: sl(),
      ));

  sl.registerFactory(() => AgentesBloc(
        correrCiclo: sl(),
        obtenerDecisiones: sl(),
        obtenerIndicadores: sl(),
        obtenerConfiguracion: sl(),
        reloj: sl(),
      ));

  sl.registerFactory(() => AdministracionCubit(
        obtenerConfiguracion: sl(),
        guardarConfiguracion: sl(),
        obtenerAuditoria: sl(),
        reiniciarDatos: sl(),
        obtenerIndicadores: sl(),
        obtenerSugerencias: sl(),
        obtenerReporteAprendizaje: sl(),
        obtenerEstadisticas: sl(),
        obtenerUsuarios: sl(),
        usuarioActualId: usuarioActualId,
      ));

  sl.registerFactory(() => AltaLibroCubit(
        registrarLibro: sl(),
        validarLibro: sl(),
        agregarEjemplar: sl(),
        registrarCorreccion: sl(),
        reloj: sl(),
        usuarioActualId: usuarioActualId,
        analizador: sl(),
      ));
}
