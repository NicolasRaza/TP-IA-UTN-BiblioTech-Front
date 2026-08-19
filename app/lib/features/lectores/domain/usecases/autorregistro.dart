/// Alta que hace la propia persona desde la pantalla de acceso.
library;

import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/error/result.dart';
import '../../../../core/services/reloj.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/lector.dart';
import '../entities/solicitud_de_registro.dart';
import '../repositories/lector_repository.dart';

class RegistrarseComoLectorParams extends Equatable {
  const RegistrarseComoLectorParams(this.solicitud);

  final SolicitudDeRegistro solicitud;

  @override
  List<Object?> get props => [solicitud];
}

/// Registra a un lector nuevo sin sesión abierta.
///
/// Las mismas validaciones corren del otro lado —el backend rechaza el alta
/// sin consentimiento, sin tutor para un menor o con un documento repetido—,
/// pero se hacen también acá para que el formulario responda sin ida y vuelta
/// y para que el autorregistro local se comporte igual que el remoto.
///
/// El lector queda en [EstadoLector.pendiente]: puede existir, pero no opera
/// hasta que un bibliotecario lo verifica.
class RegistrarseComoLector
    implements UseCase<Lector, RegistrarseComoLectorParams> {
  const RegistrarseComoLector({
    required LectorRepository lectorRepository,
    required Reloj reloj,
  })  : _lectores = lectorRepository,
        _reloj = reloj;

  final LectorRepository _lectores;
  final Reloj _reloj;

  @override
  Future<Result<Lector>> call(RegistrarseComoLectorParams params) async {
    final s = params.solicitud;

    if (s.nombre.trim().isEmpty || s.apellido.trim().isEmpty) {
      return const Fallo(
          ValidacionFailure('Nombre y apellido son obligatorios'));
    }
    if (s.documento.trim().isEmpty) {
      return const Fallo(ValidacionFailure('El documento es obligatorio'));
    }
    if (!s.email.contains('@') || s.email.trim().length < 3) {
      return const Fallo(ValidacionFailure('Revisá el email: no es válido'));
    }
    if (s.fechaNacimiento.isAfter(_reloj.ahora)) {
      return const Fallo(
          ValidacionFailure('La fecha de nacimiento no puede ser futura'));
    }
    if (s.esMenorDeEdad(_reloj.ahora) && s.tutorNombre.trim().isEmpty) {
      return const Fallo(ValidacionFailure(
          'Un lector menor de edad necesita declarar un tutor'));
    }
    if (!s.consentimientoDatos) {
      return const Fallo(ValidacionFailure(
          'Hay que aceptar el tratamiento de los datos para registrarse'));
    }

    // La traza de auditoría la escribe el backend dentro de la misma
    // transacción: el alta es pública y desde acá no hay token con el cual
    // asentarla.
    return _lectores.registrar(s);
  }
}
