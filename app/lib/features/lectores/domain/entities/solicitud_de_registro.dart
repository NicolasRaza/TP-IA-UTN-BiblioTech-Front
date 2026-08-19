import 'package:equatable/equatable.dart';

import 'lector.dart';

/// Datos que carga una persona al registrarse por su cuenta.
///
/// No es un [Lector]: es lo que la persona declara antes de que exista ficha
/// alguna. El id, la fecha de alta y el estado los pone el sistema, y la
/// contraseña inicial es el propio documento, así que ninguno de los cuatro
/// viaja acá.
class SolicitudDeRegistro extends Equatable {
  const SolicitudDeRegistro({
    required this.nombre,
    required this.apellido,
    required this.documento,
    required this.email,
    required this.fechaNacimiento,
    this.telefono = '',
    this.domicilio = '',
    this.categoria = CategoriaLector.adulto,
    this.tutorNombre = '',
    this.tutorTelefono = '',
    this.consentimientoDatos = false,
  });

  final String nombre;
  final String apellido;
  final String documento;
  final String email;
  final DateTime fechaNacimiento;
  final String telefono;
  final String domicilio;
  final CategoriaLector categoria;
  final String tutorNombre;
  final String tutorTelefono;

  /// Consentimiento para el tratamiento de los datos personales. El backend
  /// rechaza el alta si llega en `false`.
  final bool consentimientoDatos;

  String get nombreCompleto => '$nombre $apellido';

  /// Edad cumplida a una fecha dada.
  int edadA(DateTime momento) {
    var edad = momento.year - fechaNacimiento.year;
    final cumpleEsteAnio = DateTime(
      momento.year,
      fechaNacimiento.month,
      fechaNacimiento.day,
    );
    if (momento.isBefore(cumpleEsteAnio)) edad--;
    return edad;
  }

  /// Mayoría de edad en Argentina. El backend valida lo mismo del otro lado.
  bool esMenorDeEdad(DateTime momento) => edadA(momento) < 18;

  @override
  List<Object?> get props => [
        nombre,
        apellido,
        documento,
        email,
        fechaNacimiento,
        telefono,
        domicilio,
        categoria,
        tutorNombre,
        tutorTelefono,
        consentimientoDatos,
      ];
}
