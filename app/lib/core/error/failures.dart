import 'package:equatable/equatable.dart';

/// Falla de dominio.
///
/// Es el único tipo de error que cruza hacia la capa de presentación: la UI
/// nunca ve una excepción de `data` ni un `FormatException` de `dart:convert`.
/// Cada implementación de repositorio traduce sus errores técnicos a uno de
/// estos antes de devolverlos.
sealed class Failure extends Equatable {
  const Failure(this.mensaje);

  /// Texto ya redactado para mostrarle al usuario final.
  final String mensaje;

  @override
  List<Object?> get props => [mensaje, runtimeType];

  @override
  String toString() => '$runtimeType: $mensaje';
}

/// La entidad pedida no existe.
class NoEncontradoFailure extends Failure {
  const NoEncontradoFailure(super.mensaje);
}

/// Una regla de negocio de la spec §7 impide la operación: límite de préstamos
/// alcanzado, multa pendiente, libro sin validar, reserva duplicada.
class ReglaDeNegocioFailure extends Failure {
  const ReglaDeNegocioFailure(super.mensaje);
}

/// Los datos que entran a un caso de uso no son válidos.
class ValidacionFailure extends Failure {
  const ValidacionFailure(super.mensaje);
}

/// El almacenamiento local falló al leer o escribir.
class CacheFailure extends Failure {
  const CacheFailure(
      [super.mensaje = 'No se pudo acceder a los datos locales']);
}

/// Credenciales incorrectas o cuenta dada de baja.
class AutenticacionFailure extends Failure {
  const AutenticacionFailure(super.mensaje);
}

/// La cuenta existe y las credenciales son correctas, pero todavía no la
/// verificó nadie del personal de la biblioteca.
///
/// Es distinta de [AutenticacionFailure] porque no hay nada que corregir: no
/// se reintenta con otros datos, se espera. La UI la muestra como aviso y no
/// como error de credenciales.
class CuentaPendienteFailure extends Failure {
  const CuentaPendienteFailure(
      [super.mensaje = 'Tu cuenta todavía no fue verificada por la '
          'biblioteca. Vas a poder ingresar cuando un bibliotecario '
          'confirme tus datos.']);
}

/// No se pudo hablar con el backend: sin conexión, timeout, o una respuesta
/// que la API no debería haber devuelto.
class RedFailure extends Failure {
  const RedFailure([super.mensaje = 'No se pudo conectar con el servidor']);
}

/// El servicio de notificaciones push del dispositivo falló o fue rechazado
/// por el usuario.
class PushFailure extends Failure {
  const PushFailure(super.mensaje);
}
