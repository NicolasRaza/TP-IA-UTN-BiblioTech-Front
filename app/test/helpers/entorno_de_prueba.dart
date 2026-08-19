import 'package:bibliotech/core/di/inyeccion.dart';
import 'package:bibliotech/core/services/reloj.dart';
import 'package:bibliotech/core/storage/key_value_store.dart';
import 'package:bibliotech/core/usecases/usecase.dart';
import 'package:bibliotech/features/administracion/domain/usecases/gestionar_configuracion.dart';

/// Levanta el grafo real de la aplicación sobre memoria y con reloj fijo.
///
/// Los tests usan exactamente los mismos casos de uso, servicios de dominio y
/// repositorios que corren en producción: lo único que cambia son las tres
/// piezas de infraestructura del borde —almacenamiento, reloj y generador de
/// ids—. Eso es lo que hace que un test verde diga algo sobre la app real y
/// no sobre una maqueta paralela.
class EntornoDePrueba {
  EntornoDePrueba._(this.reloj);

  final RelojFijo reloj;

  /// Momento actual del entorno. Avanza con [avanzar] y [fijar].
  DateTime get ahora => reloj.ahora;

  void avanzar(Duration cuanto) => reloj.avanzar(cuanto);
  void fijar(DateTime momento) => reloj.fijar(momento);

  /// Arma el entorno y siembra los datos de demostración.
  static Future<EntornoDePrueba> montar({DateTime? desde}) async {
    await sl.reset();

    final reloj = RelojFijo(desde ?? DateTime(2026, 3, 10, 12));
    await configurarInyeccion(
      store: MemoryStore(),
      reloj: reloj,
      generadorId: GeneradorIdSecuencial(),
      // Los tests describen las reglas de dominio de la app, no el contrato
      // con el backend: corren sobre el almacenamiento local para no depender
      // de la red. El contrato con la API lo cubren los tests de datasource,
      // con un cliente HTTP falso.
      usarBackend: false,
    );

    await sl<InicializarDatos>()(const SinParametros());

    return EntornoDePrueba._(reloj);
  }

  /// Resuelve cualquier pieza del grafo: `entorno<RegistrarPrestamo>()`.
  T call<T extends Object>() => sl<T>();

  Future<void> desmontar() => sl.reset();
}
