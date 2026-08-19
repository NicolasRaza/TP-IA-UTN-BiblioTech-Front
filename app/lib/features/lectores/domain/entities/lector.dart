import 'package:equatable/equatable.dart';

enum RolUsuario {
  lector('lector'),
  bibliotecario('bibliotecario'),
  administrador('administrador');

  const RolUsuario(this.code);
  final String code;

  static RolUsuario fromCode(String? code) => RolUsuario.values.firstWhere(
        (r) => r.code == code,
        orElse: () => RolUsuario.lector,
      );
}

/// Situación del lector en el padrón. Espeja `EstadoUsuario` del backend.
///
/// [pendiente] es el estado con el que nace toda alta nueva —venga del
/// autorregistro o del mostrador—: la persona existe y puede entrar a la app,
/// pero no opera hasta que un bibliotecario verifica sus datos y la pasa a
/// [activo].
enum EstadoLector {
  pendiente('pendiente', 'Pendiente de verificación'),
  activo('activo', 'Activo'),
  suspendido('suspendido', 'Suspendido'),
  baja('baja', 'De baja');

  const EstadoLector(this.code, this.label);
  final String code;
  final String label;

  static EstadoLector fromCode(String? code) => EstadoLector.values.firstWhere(
        (e) => e.code == code,
        orElse: () => EstadoLector.activo,
      );
}

/// Categoría de lector. Determina plazos y límites (spec v2 §7).
enum CategoriaLector {
  menor('menor', 'Menor'),
  adulto('adulto', 'Adulto'),
  docente('docente', 'Docente'),
  senior('senior', 'Senior'),
  personal('personal', 'Personal');

  const CategoriaLector(this.code, this.label);
  final String code;
  final String label;

  static CategoriaLector fromCode(String? code) =>
      CategoriaLector.values.firstWhere(
        (c) => c.code == code,
        orElse: () => CategoriaLector.adulto,
      );
}

/// Persona registrada en la biblioteca: lector, bibliotecario o administrador.
class Lector extends Equatable {
  const Lector({
    required this.id,
    required this.nombre,
    required this.apellido,
    required this.email,
    this.dni = '',
    this.telefono = '',
    required this.categoria,
    this.tutor,
    required this.fechaAlta,
    this.estado = EstadoLector.activo,
    this.pin = '',
    this.generosInteres = const [],
    this.multasPendientes = 0,
    this.rol = RolUsuario.lector,
    this.fechaNacimiento,
  });

  final String id;
  final String nombre;
  final String apellido;
  final String email;
  final String dni;
  final String telefono;

  /// Categoría vigente. Los préstamos y reservas ya generados conservan la
  /// categoría con la que nacieron (spec v2 §7), por eso este campo solo
  /// afecta a operaciones nuevas.
  final CategoriaLector categoria;

  /// Requerido para lectores menores de edad.
  final String? tutor;

  final DateTime fechaAlta;
  final EstadoLector estado;
  final String pin;
  final List<String> generosInteres;
  final int multasPendientes;
  final RolUsuario rol;
  final DateTime? fechaNacimiento;

  String get nombreCompleto => '$nombre $apellido';

  String get iniciales {
    final n = nombre.isNotEmpty ? nombre[0] : '';
    final a = apellido.isNotEmpty ? apellido[0] : '';
    return '$n$a'.toUpperCase();
  }

  /// El QR del lector también deriva del ID interno e inmutable.
  String get qr => 'BTL-$id';

  /// Puede operar: sacar préstamos y reservar. Es la pregunta que hacen las
  /// políticas de la spec §7, y por eso sigue siendo un booleano aunque el
  /// padrón guarde ahora los cuatro estados.
  bool get activo => estado == EstadoLector.activo;

  /// Se registró pero todavía no lo verificó nadie del personal.
  bool get pendienteDeVerificacion => estado == EstadoLector.pendiente;

  bool get esPersonal => rol != RolUsuario.lector;

  bool get tieneMultas => multasPendientes > 0;

  /// Edad cumplida a una fecha dada.
  int edadA(DateTime momento) {
    final nacimiento = fechaNacimiento;
    if (nacimiento == null) return 0;
    var edad = momento.year - nacimiento.year;
    final cumpleEsteAnio =
        DateTime(momento.year, nacimiento.month, nacimiento.day);
    if (momento.isBefore(cumpleEsteAnio)) edad--;
    return edad;
  }

  Lector copyWith({
    String? nombre,
    String? apellido,
    String? email,
    String? dni,
    String? telefono,
    CategoriaLector? categoria,
    String? tutor,
    EstadoLector? estado,
    String? pin,
    List<String>? generosInteres,
    int? multasPendientes,
    RolUsuario? rol,
    DateTime? fechaNacimiento,
  }) =>
      Lector(
        id: id,
        nombre: nombre ?? this.nombre,
        apellido: apellido ?? this.apellido,
        email: email ?? this.email,
        dni: dni ?? this.dni,
        telefono: telefono ?? this.telefono,
        categoria: categoria ?? this.categoria,
        tutor: tutor ?? this.tutor,
        fechaAlta: fechaAlta,
        estado: estado ?? this.estado,
        pin: pin ?? this.pin,
        generosInteres: generosInteres ?? this.generosInteres,
        multasPendientes: multasPendientes ?? this.multasPendientes,
        rol: rol ?? this.rol,
        fechaNacimiento: fechaNacimiento ?? this.fechaNacimiento,
      );

  @override
  List<Object?> get props => [
        id,
        nombre,
        apellido,
        email,
        dni,
        telefono,
        categoria,
        tutor,
        fechaAlta,
        estado,
        pin,
        generosInteres,
        multasPendientes,
        rol,
        fechaNacimiento,
      ];
}
