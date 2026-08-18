import '../../../administracion/domain/entities/configuracion_biblioteca.dart';
import '../entities/lector.dart';

/// Deriva la categoría que le corresponde a un lector según su edad.
///
/// Es una función pura sobre la configuración vigente: sube a `adulto` al
/// cumplir la mayoría de edad parametrizada. Las categorías `docente` y
/// `senior` son asignaciones administrativas y nunca se derivan de la edad,
/// por eso quedan excluidas de la detección de desactualizados.
class PoliticaDeCategoria {
  const PoliticaDeCategoria();

  CategoriaLector categoriaPara({
    required DateTime fechaNacimiento,
    required ConfiguracionBiblioteca configuracion,
    required DateTime ahora,
  }) {
    final referencia = Lector(
      id: '',
      nombre: '',
      apellido: '',
      email: '',
      categoria: CategoriaLector.adulto,
      fechaAlta: ahora,
      fechaNacimiento: fechaNacimiento,
    );
    return referencia.edadA(ahora) < configuracion.edadMayoriaEdad
        ? CategoriaLector.menor
        : CategoriaLector.adulto;
  }

  /// ¿La categoría vigente del lector quedó desfasada respecto de su edad?
  /// (ej. un menor que ya cumplió los 18).
  bool estaDesactualizada({
    required Lector lector,
    required ConfiguracionBiblioteca configuracion,
    required DateTime ahora,
  }) {
    final nacimiento = lector.fechaNacimiento;
    if (nacimiento == null) return false;
    if (lector.categoria == CategoriaLector.docente ||
        lector.categoria == CategoriaLector.senior) {
      return false;
    }
    return categoriaPara(
          fechaNacimiento: nacimiento,
          configuracion: configuracion,
          ahora: ahora,
        ) !=
        lector.categoria;
  }
}
