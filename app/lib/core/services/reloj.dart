/// Fuente de tiempo del sistema.
///
/// Nada en el dominio llama a `DateTime.now()` directamente: todo pasa por
/// acá. Así los tests fijan el calendario con [RelojFijo] y los vencimientos,
/// multas y plazos de retiro quedan deterministas.
abstract interface class Reloj {
  DateTime get ahora;
}

/// Reloj real, el que se registra en producción.
class RelojDelSistema implements Reloj {
  const RelojDelSistema();

  @override
  DateTime get ahora => DateTime.now();
}

/// Reloj controlado por el test. Permite avanzar el tiempo a mano.
class RelojFijo implements Reloj {
  RelojFijo(this._ahora);

  DateTime _ahora;

  @override
  DateTime get ahora => _ahora;

  void fijar(DateTime momento) => _ahora = momento;
  void avanzar(Duration cuanto) => _ahora = _ahora.add(cuanto);
}

/// Generador de identificadores de entidades.
///
/// Igual que el reloj, se inyecta para que los tests obtengan IDs predecibles
/// en lugar de depender del microsegundo en que corrieron.
abstract interface class GeneradorId {
  String generar();
}

/// IDs únicos derivados del reloj más un contador, para no colisionar dentro
/// del mismo microsegundo.
class GeneradorIdPorTiempo implements GeneradorId {
  GeneradorIdPorTiempo(this._reloj);

  final Reloj _reloj;
  int _contador = 0;

  @override
  String generar() =>
      '${_reloj.ahora.microsecondsSinceEpoch}-${_contador++}';
}

/// IDs secuenciales: '0', '1', '2'... Sólo para tests.
class GeneradorIdSecuencial implements GeneradorId {
  int _contador = 0;

  @override
  String generar() => '${_contador++}';
}
