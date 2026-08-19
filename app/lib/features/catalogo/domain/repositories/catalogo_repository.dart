import '../../../../core/error/result.dart';
import '../../../agentes/domain/entities/ficha_sugerida.dart';
import '../entities/ejemplar.dart';
import '../entities/libro.dart';

/// Un ejemplar junto con el libro al que pertenece, para las búsquedas por QR
/// del mostrador.
typedef EjemplarLocalizado = ({Libro libro, Ejemplar ejemplar});

/// Contrato de acceso al catálogo.
///
/// Lo define el dominio y lo implementa `data`: esa es la inversión de
/// dependencias que sostiene toda la arquitectura. Los casos de uso dependen
/// de esta interfaz y no saben qué hay detrás —hoy la API del backend, en los
/// tests un doble en memoria—.
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

  /// Envía fotos al OCR del backend y obtiene la ficha sugerida.
  Future<Result<FichaSugerida>> capturarOcr({
    required List<int> fotoTapa,
    required List<int> fotoContratapa,
    required List<int> fotoFicha,
    String? extensionTapa,
    String? extensionContratapa,
    String? extensionFicha,
  });

  Future<Result<void>> eliminar(String libroId);

  /// Suma una copia física a un título ya existente y la devuelve ya
  /// identificada.
  ///
  /// Es una operación propia y no un `actualizar` con la lista de ejemplares
  /// ampliada porque el alta de un ejemplar no es una edición del título: el
  /// backend la expone como su propia ruta (`POST /catalogo/ejemplares`) y es
  /// él quien asigna el id y el código QR de la etiqueta.
  Future<Result<Ejemplar>> agregarEjemplar(
    String libroId,
    CondicionEjemplar condicion,
  );

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
