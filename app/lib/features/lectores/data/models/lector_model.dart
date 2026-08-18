import '../../domain/entities/lector.dart';

/// [Lector] con serialización.
class LectorModel extends Lector {
  const LectorModel({
    required super.id,
    required super.nombre,
    required super.apellido,
    required super.email,
    super.dni,
    super.telefono,
    required super.categoria,
    super.tutor,
    required super.fechaAlta,
    super.activo,
    super.pin,
    super.generosInteres,
    super.multasPendientes,
    super.rol,
    super.fechaNacimiento,
  });

  factory LectorModel.fromEntity(Lector l) => LectorModel(
        id: l.id,
        nombre: l.nombre,
        apellido: l.apellido,
        email: l.email,
        dni: l.dni,
        telefono: l.telefono,
        categoria: l.categoria,
        tutor: l.tutor,
        fechaAlta: l.fechaAlta,
        activo: l.activo,
        pin: l.pin,
        generosInteres: l.generosInteres,
        multasPendientes: l.multasPendientes,
        rol: l.rol,
        fechaNacimiento: l.fechaNacimiento,
      );

  factory LectorModel.fromJson(Map<String, dynamic> json) => LectorModel(
        id: json['id'] as String,
        nombre: json['nombre'] as String? ?? '',
        apellido: json['apellido'] as String? ?? '',
        email: json['email'] as String? ?? '',
        dni: json['dni'] as String? ?? '',
        telefono: json['telefono'] as String? ?? '',
        categoria: CategoriaLector.fromCode(json['categoria'] as String?),
        tutor: json['tutor'] as String?,
        fechaAlta: DateTime.parse(json['fechaAlta'] as String),
        activo: json['activo'] as bool? ?? true,
        pin: json['pin'] as String? ?? '',
        generosInteres:
            (json['generosInteres'] as List<dynamic>? ?? []).cast<String>(),
        multasPendientes: (json['multasPendientes'] as num?)?.toInt() ?? 0,
        rol: RolUsuario.fromCode(json['rol'] as String?),
        fechaNacimiento: json['fechaNacimiento'] == null
            ? null
            : DateTime.parse(json['fechaNacimiento'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'nombre': nombre,
        'apellido': apellido,
        'email': email,
        'dni': dni,
        'telefono': telefono,
        'categoria': categoria.code,
        'tutor': tutor,
        'fechaAlta': fechaAlta.toIso8601String(),
        'activo': activo,
        'pin': pin,
        'generosInteres': generosInteres,
        'multasPendientes': multasPendientes,
        'rol': rol.code,
        'fechaNacimiento': fechaNacimiento?.toIso8601String(),
      };
}
