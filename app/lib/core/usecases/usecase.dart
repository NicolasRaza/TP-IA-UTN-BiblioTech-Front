import 'package:equatable/equatable.dart';

import '../error/result.dart';

/// Contrato de un caso de uso.
///
/// Cada operación de negocio del sistema es una clase que implementa esta
/// interfaz: recibe sus parámetros, devuelve un [Result] y no sabe nada de
/// Flutter ni de dónde salen los datos. Es la unidad que los blocs invocan.
///
/// La firma es asincrónica aunque hoy la persistencia sea local y sincrónica.
/// El dominio no debe asumir que leer es instantáneo: si mañana el
/// almacenamiento pasa a ser una API remota, sólo cambia la implementación en
/// `data`, y ni los casos de uso ni los blocs se enteran.
abstract interface class UseCase<Tipo, Params> {
  Future<Result<Tipo>> call(Params params);
}

/// Caso de uso sin parámetros de entrada.
final class SinParametros extends Equatable {
  const SinParametros();

  @override
  List<Object?> get props => const [];
}
