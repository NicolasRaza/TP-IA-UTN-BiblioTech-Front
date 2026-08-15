import '../../../../core/error/result.dart';
import '../entities/ejemplar.dart';
import '../entities/libro.dart';

/// Un ejemplar junto con el libro al que pertenece, para las búsquedas por QR
/// del mostrador.
typedef EjemplarLocalizado = ({Libro libro, Ejemplar ejemplar});

/// Contrato de acceso al catálogo.
///
/// Lo define el dominio y lo implementa `data`: esa es la inversión de
/// dependencias que sostiene toda la arquitectura. Los casos de uso dependen
/// de esta interfaz y no saben si detrás hay SharedPreferences, una base
/// local o una API remota.
abstract interface class CatalogoRepository {
  /// Todos los libros, validados o no. Es la vista del bibliotecario.
  Future<Result<List<Libro>>> obtenerTodos();

  /// Sólo los libros validados: el catálogo que ve el lector.
  ///
  /// Regla de Validación Estricta (spec v2 §7).
  Future<Result<List<Libro>>> obtenerCatalogoPublico();

  /// Altas que todavía esperan la confirmación del bibliotecario.
  Future<Result<List<Libro>>> obtenerPendientesValidacion();

  Future<Result<Libro>> obtenerPorId(String libroId);

  /// Busca dentro del catálogo público por texto libre y género.
  Future<Result<List<Libro>>> buscar({String texto, String genero});

  /// Géneros presentes en el catálogo público, ordenados alfabéticamente.
  Future<Result<List<String>>> obtenerGeneros();

  /// Localiza un ejemplar por el contenido de su etiqueta QR.
  Future<Result<EjemplarLocalizado>> buscarPorQr(String qr);

  /// Inserta un libro nuevo.
  Future<Result<Libro>> crear(Libro libro);

  /// Reemplaza un libro existente por completo, ejemplares incluidos.
  Future<Result<Libro>> actualizar(Libro libro);

  Future<Result<void>> eliminar(String libroId);

  /// Cambia el estado de un ejemplar puntual.
  ///
  /// Existe como operación propia porque préstamos y reservas necesitan mover
  /// ejemplares entre disponible/prestado/reservado sin tener que leer,
  /// mutar y reescribir el libro entero desde otro feature.
  Future<Result<Ejemplar>> cambiarEstadoEjemplar(
    String libroId,
    String ejemplarId,
    EstadoEjemplar estado,
  );
}
