import 'failures.dart';

/// Resultado de una operación que puede fallar.
///
/// Cumple el papel del `Either<Failure, T>` habitual en Clean Architecture,
/// pero implementado con clases selladas de Dart 3: el `switch` sobre un
/// [Result] es exhaustivo y lo verifica el compilador, así que no hay forma de
/// olvidarse de manejar el error. Reemplaza al `ResultadoOperacion` del diseño
/// anterior, que devolvía éxito y motivo en el mismo objeto y obligaba a
/// consultar un booleano antes de leer el valor.
sealed class Result<T> {
  const Result();

  const factory Result.exito(T valor) = Exito<T>;
  const factory Result.fallo(Failure failure) = Fallo<T>;

  bool get esExito => this is Exito<T>;
  bool get esFallo => this is Fallo<T>;

  /// El valor si la operación salió bien, `null` si falló.
  T? get valorONull => switch (this) {
        Exito<T>(:final valor) => valor,
        Fallo<T>() => null,
      };

  /// La falla si la operación salió mal, `null` si tuvo éxito.
  Failure? get failureONull => switch (this) {
        Exito<T>() => null,
        Fallo<T>(:final failure) => failure,
      };

  /// Colapsa ambas ramas a un único valor. Es la forma recomendada de
  /// consumir un [Result] desde un bloc.
  R fold<R>(R Function(Failure failure) siFalla, R Function(T valor) siSale) =>
      switch (this) {
        Exito<T>(:final valor) => siSale(valor),
        Fallo<T>(:final failure) => siFalla(failure),
      };

  /// Transforma el valor de éxito conservando la falla.
  Result<R> map<R>(R Function(T valor) transformar) => switch (this) {
        Exito<T>(:final valor) => Exito<R>(transformar(valor)),
        Fallo<T>(:final failure) => Fallo<R>(failure),
      };

  /// Encadena otra operación que también puede fallar.
  Result<R> flatMap<R>(Result<R> Function(T valor) siguiente) => switch (this) {
        Exito<T>(:final valor) => siguiente(valor),
        Fallo<T>(:final failure) => Fallo<R>(failure),
      };
}

final class Exito<T> extends Result<T> {
  const Exito(this.valor);
  final T valor;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Exito<T> && other.valor == valor);

  @override
  int get hashCode => valor.hashCode;

  @override
  String toString() => 'Exito($valor)';
}

final class Fallo<T> extends Result<T> {
  const Fallo(this.failure);
  final Failure failure;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Fallo<T> && other.failure == failure);

  @override
  int get hashCode => failure.hashCode;

  @override
  String toString() => 'Fallo($failure)';
}
