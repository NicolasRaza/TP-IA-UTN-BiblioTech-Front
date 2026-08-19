import '../../../../core/error/failures.dart';
import '../../../../core/error/result.dart';
import '../../../../core/services/reloj.dart';
import '../../domain/entities/lector.dart';
import '../../domain/entities/solicitud_de_registro.dart';
import '../../domain/repositories/lector_repository.dart';
import '../datasources/lector_local_datasource.dart';

/// Implementación del [LectorRepository] sobre el almacenamiento local.
class LectorRepositoryImpl implements LectorRepository {
  const LectorRepositoryImpl({
    required LectorLocalDataSource localDataSource,
    required GeneradorId generadorId,
    required Reloj reloj,
  })  : _local = localDataSource,
        _generadorId = generadorId,
        _reloj = reloj;

  final LectorLocalDataSource _local;
  final GeneradorId _generadorId;
  final Reloj _reloj;

  @override
  Future<Result<List<Lector>>> obtenerUsuarios() async =>
      _local.leer().map((l) => l.cast<Lector>());

  @override
  Future<Result<List<Lector>>> obtenerLectores() async => _local.leer().map(
        (usuarios) =>
            usuarios.where((u) => !u.esPersonal).cast<Lector>().toList(),
      );

  @override
  Future<Result<Lector>> obtenerPorId(String lectorId) =>
      _buscar((l) => l.id == lectorId, 'Lector no encontrado');

  @override
  Future<Result<Lector>> obtenerPorEmail(String email) => _buscar(
        (l) => l.email.toLowerCase() == email.toLowerCase(),
        'No hay ninguna cuenta con ese email',
      );

  @override
  Future<Result<Lector>> obtenerPorQr(String qr) => _buscar(
        (l) => l.qr == qr,
        'Ninguna credencial coincide con ese código',
      );

  @override
  Future<Result<Lector>> crear(Lector lector) async {
    final leidos = _local.leer();
    if (leidos case Fallo(:final failure)) return Fallo(failure);

    final nuevo = lector.id.isEmpty
        ? _conId(lector, 'lec-${_generadorId.generar()}')
        : lector;

    final guardado = _local.guardar([...leidos.valorONull!, nuevo]);
    if (guardado case Fallo(:final failure)) return Fallo(failure);

    return Exito(nuevo);
  }

  /// Autorregistro sobre el padrón del dispositivo.
  ///
  /// Espeja lo que hace el backend: documento y email únicos, contraseña
  /// inicial igual al documento —acá, el PIN— y estado pendiente hasta que un
  /// bibliotecario verifique los datos.
  @override
  Future<Result<Lector>> registrar(SolicitudDeRegistro solicitud) async {
    final leidos = _local.leer();
    if (leidos case Fallo(:final failure)) return Fallo(failure);

    final padron = leidos.valorONull!;
    final email = solicitud.email.trim().toLowerCase();
    if (padron.any((l) => l.email.toLowerCase() == email)) {
      return const Fallo(ValidacionFailure('Ya hay una cuenta con ese email'));
    }
    if (padron.any((l) => l.dni.isNotEmpty && l.dni == solicitud.documento)) {
      return const Fallo(
          ValidacionFailure('Ya hay una cuenta con ese documento'));
    }

    return crear(Lector(
      id: '',
      nombre: solicitud.nombre,
      apellido: solicitud.apellido,
      email: solicitud.email.trim(),
      dni: solicitud.documento,
      telefono: solicitud.telefono,
      categoria: solicitud.categoria,
      tutor: solicitud.tutorNombre.isEmpty ? null : solicitud.tutorNombre,
      fechaAlta: _reloj.ahora,
      estado: EstadoLector.pendiente,
      pin: solicitud.documento,
      fechaNacimiento: solicitud.fechaNacimiento,
    ));
  }

  @override
  Future<Result<Lector>> actualizar(Lector lector) async {
    final leidos = _local.leer();
    if (leidos case Fallo(:final failure)) return Fallo(failure);

    final lista = leidos.valorONull!.cast<Lector>().toList();
    final i = lista.indexWhere((l) => l.id == lector.id);
    if (i < 0) return const Fallo(NoEncontradoFailure('Lector no encontrado'));

    lista[i] = lector;
    final guardado = _local.guardar(lista);
    if (guardado case Fallo(:final failure)) return Fallo(failure);

    return Exito(lector);
  }

  @override
  Future<Result<Lector>> ajustarMultas(String lectorId, int delta) async {
    final leidos = _local.leer();
    if (leidos case Fallo(:final failure)) return Fallo(failure);

    final lista = leidos.valorONull!.cast<Lector>().toList();
    final i = lista.indexWhere((l) => l.id == lectorId);
    if (i < 0) return const Fallo(NoEncontradoFailure('Lector no encontrado'));

    // El saldo se lee y se reescribe dentro de la misma operación, para que
    // dos ajustes seguidos no se pisen entre sí.
    final saldo = lista[i].multasPendientes + delta;
    lista[i] = lista[i].copyWith(multasPendientes: saldo < 0 ? 0 : saldo);

    final guardado = _local.guardar(lista);
    if (guardado case Fallo(:final failure)) return Fallo(failure);

    return Exito(lista[i]);
  }

  Future<Result<Lector>> _buscar(
    bool Function(Lector) criterio,
    String mensajeSiNoEsta,
  ) async {
    final leidos = _local.leer();
    if (leidos case Fallo(:final failure)) return Fallo(failure);

    for (final l in leidos.valorONull!) {
      if (criterio(l)) return Exito(l);
    }
    return Fallo(NoEncontradoFailure(mensajeSiNoEsta));
  }

  Lector _conId(Lector l, String id) => Lector(
        id: id,
        nombre: l.nombre,
        apellido: l.apellido,
        email: l.email,
        dni: l.dni,
        telefono: l.telefono,
        categoria: l.categoria,
        tutor: l.tutor,
        fechaAlta: l.fechaAlta,
        estado: l.estado,
        pin: l.pin,
        generosInteres: l.generosInteres,
        multasPendientes: l.multasPendientes,
        rol: l.rol,
        fechaNacimiento: l.fechaNacimiento,
      );
}
