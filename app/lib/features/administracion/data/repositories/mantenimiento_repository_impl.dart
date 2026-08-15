import '../../../../core/error/result.dart';
import '../../../../core/services/reloj.dart';
import '../../../../core/storage/key_value_store.dart';
import '../../../agentes/data/datasources/aprendizaje_local_datasource.dart';
import '../../../catalogo/data/datasources/catalogo_local_datasource.dart';
import '../../../lectores/data/datasources/lector_local_datasource.dart';
import '../../../notificaciones/data/datasources/notificacion_local_datasource.dart';
import '../../../prestamos/data/datasources/prestamo_local_datasource.dart';
import '../../../reservas/data/datasources/reserva_local_datasource.dart';
import '../../domain/entities/configuracion_biblioteca.dart';
import '../../domain/repositories/mantenimiento_repository.dart';
import '../datasources/administracion_local_datasource.dart';
import '../datasources/seed_data.dart';

/// Siembra y reinicio de los datos de demostración.
///
/// Es el único lugar de la app que escribe sobre todos los datasources a la
/// vez, y por eso vive en `administracion`: es una tarea de mantenimiento del
/// sistema, no una operación de negocio de ningún feature en particular.
class MantenimientoRepositoryImpl implements MantenimientoRepository {
  const MantenimientoRepositoryImpl({
    required KeyValueStore store,
    required CatalogoLocalDataSource catalogoDataSource,
    required LectorLocalDataSource lectorDataSource,
    required PrestamoLocalDataSource prestamoDataSource,
    required ReservaLocalDataSource reservaDataSource,
    required NotificacionLocalDataSource notificacionDataSource,
    required AdministracionLocalDataSource administracionDataSource,
    required AprendizajeLocalDataSource aprendizajeDataSource,
    required Reloj reloj,
  })  : _store = store,
        _catalogo = catalogoDataSource,
        _lectores = lectorDataSource,
        _prestamos = prestamoDataSource,
        _reservas = reservaDataSource,
        _notificaciones = notificacionDataSource,
        _administracion = administracionDataSource,
        _aprendizaje = aprendizajeDataSource,
        _reloj = reloj;

  final KeyValueStore _store;
  final CatalogoLocalDataSource _catalogo;
  final LectorLocalDataSource _lectores;
  final PrestamoLocalDataSource _prestamos;
  final ReservaLocalDataSource _reservas;
  final NotificacionLocalDataSource _notificaciones;
  final AdministracionLocalDataSource _administracion;
  final AprendizajeLocalDataSource _aprendizaje;
  final Reloj _reloj;

  @override
  Future<Result<void>> inicializarSiHaceFalta() async {
    if (_store.read(ClavesAlmacenamiento.inicializado) == 'true') {
      return const Exito(null);
    }
    return _sembrar();
  }

  @override
  Future<Result<void>> reiniciar() async {
    for (final clave in ClavesAlmacenamiento.todas) {
      _store.remove(clave);
    }
    return _sembrar();
  }

  Result<void> _sembrar() {
    final seed = SeedData(_reloj.ahora);

    final pasos = <Result<void>>[
      _catalogo.guardar(seed.libros()),
      _lectores.guardar(seed.lectores()),
      _prestamos.guardar(seed.prestamos()),
      _reservas.guardar(seed.reservas()),
      _notificaciones.guardar(seed.notificaciones()),
      _administracion.guardarAuditoria(seed.auditoria()),
      _administracion.guardarConfiguracion(const ConfiguracionBiblioteca()),
      _aprendizaje.guardarCorrecciones(const []),
      _aprendizaje.guardarInteracciones(const []),
    ];

    for (final paso in pasos) {
      if (paso case Fallo(:final failure)) return Fallo(failure);
    }

    _store.write(ClavesAlmacenamiento.inicializado, 'true');
    return const Exito(null);
  }
}
