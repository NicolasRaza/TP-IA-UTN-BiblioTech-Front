import '../../../../core/api/cliente_api.dart';
import '../../../../core/api/mapeo_api.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/error/result.dart';
import '../../domain/entities/lector.dart';

/// Acceso al padrón del backend SGB (`/api/v1/lectores`).
///
/// Todas las rutas de este grupo exigen rol bibliotecario o administrador: un
/// lector autenticado recibe 403, que el [ClienteApi] traduce a
/// [AutenticacionFailure]. Es el propio backend el que define ese límite.
abstract interface class LectorApiDataSource {
  Future<Result<List<Lector>>> listar({String nombre, String documento});

  /// `GET /lectores/{id}` — ficha con préstamos activos y multas pendientes.
  Future<Result<Lector>> obtener(String lectorId);

  /// `POST /lectores/` — el backend crea también el usuario de la app y le
  /// asigna el documento como contraseña inicial.
  Future<Result<Lector>> crear(Lector lector);

  Future<Result<Lector>> actualizar(Lector lector);
}

class LectorApiDataSourceHttp implements LectorApiDataSource {
  const LectorApiDataSourceHttp(this._api);

  final ClienteApi _api;

  @override
  Future<Result<List<Lector>>> listar({
    String nombre = '',
    String documento = '',
  }) =>
      _api.get<List<Lector>>(
        '/api/v1/lectores/',
        query: {
          if (nombre.trim().isNotEmpty) 'nombre': nombre.trim(),
          if (documento.trim().isNotEmpty) 'documento': documento.trim(),
        },
        leer: (json) => (json as List<Object?>? ?? const [])
            .map((e) => lectorDesdeApi(e as Map<String, dynamic>))
            .toList(),
      );

  @override
  Future<Result<Lector>> obtener(String lectorId) {
    final id = idHaciaApi(lectorId);
    if (id == null) return _sinIdRemoto();
    return _api.get<Lector>('/api/v1/lectores/$id', leer: _leerLector);
  }

  @override
  Future<Result<Lector>> crear(Lector lector) => _api.post<Lector>(
        '/api/v1/lectores/',
        cuerpo: {
          'nombre': lector.nombre,
          'apellido': lector.apellido,
          'documento': lector.dni,
          // `fecha_nacimiento` es obligatoria del otro lado; sin ella el
          // backend no puede decidir si el lector necesita tutor.
          'fecha_nacimiento':
              fechaHaciaApi(lector.fechaNacimiento ?? lector.fechaAlta),
          'email': lector.email,
          if (lector.telefono.isNotEmpty) 'telefono': lector.telefono,
          'categoria': categoriaHaciaApi(lector.categoria),
          if (lector.tutor != null && lector.tutor!.isNotEmpty)
            'tutor_nombre': lector.tutor,
          // El alta por API sólo ocurre con el consentimiento ya prestado en
          // el mostrador: el backend rechaza el alta si llega en `false`.
          'consentimiento_datos': true,
        },
        leer: _leerLector,
      );

  @override
  Future<Result<Lector>> actualizar(Lector lector) {
    final id = idHaciaApi(lector.id);
    if (id == null) return _sinIdRemoto();
    return _api.patch<Lector>(
      '/api/v1/lectores/$id',
      cuerpo: {
        'nombre': lector.nombre,
        'apellido': lector.apellido,
        if (lector.telefono.isNotEmpty) 'telefono': lector.telefono,
        'categoria': categoriaHaciaApi(lector.categoria),
        'estado': lector.activo ? 'activo' : 'baja',
        if (lector.tutor != null && lector.tutor!.isNotEmpty)
          'tutor_nombre': lector.tutor,
      },
      leer: _leerLector,
    );
  }

  static Lector _leerLector(Object? json) =>
      lectorDesdeApi(json as Map<String, dynamic>);

  static Future<Result<Lector>> _sinIdRemoto() async => const Fallo(
        NoEncontradoFailure('Ese lector no existe en el servidor'),
      );
}

/// Traduce un `LectorResponse` (o `LectorFichaResponse`) del backend.
///
/// Dos campos del dominio no viajan en esa respuesta y quedan vacíos a
/// propósito, en vez de rellenarse con algo verosímil:
///
/// - **email**: el backend lo guarda en `Usuario`, no en `Lector`, y no lo
///   incluye en la ficha. Sólo se conoce el del usuario autenticado, por
///   `GET /auth/me`.
/// - **pin**: no existe del otro lado. La API autentica con contraseña contra
///   `POST /auth/login`, así que no hay ningún PIN que traer.
Lector lectorDesdeApi(Map<String, dynamic> json, {String email = ''}) {
  final fechaAlta = fechaDesdeApi(json['fecha_alta'], DateTime.now());
  return Lector(
    id: idDesdeApi(json['id']),
    nombre: json['nombre'] as String? ?? '',
    apellido: json['apellido'] as String? ?? '',
    email: email,
    dni: json['documento'] as String? ?? '',
    categoria: categoriaDesdeApi(json['categoria'] as String?),
    tutor: json['tutor_nombre'] as String?,
    fechaAlta: fechaAlta,
    activo: lectorActivoDesdeApi(json['estado'] as String?),
    // `multas_pendientes` es un conteo, no un importe: sólo viene en la ficha
    // (`GET /lectores/{id}`) y en el listado llega en cero.
    multasPendientes: (json['multas_pendientes'] as num?)?.toInt() ?? 0,
    fechaNacimiento: fechaOpcionalDesdeApi(json['fecha_nacimiento']),
  );
}
