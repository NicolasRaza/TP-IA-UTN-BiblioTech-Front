import '../../../../core/error/result.dart';
import '../entities/recomendacion.dart';

/// Contrato de la memoria del Agente de Aprendizaje.
///
/// Guarda las correcciones que el bibliotecario hizo sobre las sugerencias de
/// catalogación y las interacciones de los lectores con las recomendaciones.
/// Es el insumo del ciclo de retroalimentación de la spec v2 §5.
abstract interface class AprendizajeRepository {
  Future<Result<List<Correccion>>> obtenerCorrecciones();

  Future<Result<void>> registrarCorreccion(Correccion correccion);

  Future<Result<List<InteraccionLector>>> obtenerInteracciones();

  Future<Result<void>> registrarInteraccion(InteraccionLector interaccion);
}
