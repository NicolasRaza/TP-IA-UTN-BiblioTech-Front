/// Consultas de sólo lectura del catálogo.
///
/// Van agrupadas en un archivo porque son delegaciones directas al
/// repositorio, sin reglas propias: separarlas en un archivo por clase
/// agregaría ceremonia sin agregar información. Las operaciones que sí
/// llevan reglas —alta, validación, reimpresión— viven cada una en su
/// propio archivo.
library;

import 'package:equatable/equatable.dart';

import '../../../../core/error/result.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/libro.dart';
import '../repositories/catalogo_repository.dart';

/// Géneros presentes en el catálogo público, para los filtros.
class ObtenerGeneros implements UseCase<List<String>, SinParametros> {
  const ObtenerGeneros(this._repository);

  final CatalogoRepository _repository;

  @override
  Future<Result<List<String>>> call(SinParametros params) =>
      _repository.obtenerGeneros();
}

/// Altas que esperan la confirmación del bibliotecario.
class ObtenerPendientesValidacion
    implements UseCase<List<Libro>, SinParametros> {
  const ObtenerPendientesValidacion(this._repository);

  final CatalogoRepository _repository;

  @override
  Future<Result<List<Libro>>> call(SinParametros params) =>
      _repository.obtenerPendientesValidacion();
}

class ObtenerLibroParams extends Equatable {
  const ObtenerLibroParams(this.libroId);

  final String libroId;

  @override
  List<Object?> get props => [libroId];
}

class ObtenerLibro implements UseCase<Libro, ObtenerLibroParams> {
  const ObtenerLibro(this._repository);

  final CatalogoRepository _repository;

  @override
  Future<Result<Libro>> call(ObtenerLibroParams params) =>
      _repository.obtenerPorId(params.libroId);
}

class BuscarPorQrParams extends Equatable {
  const BuscarPorQrParams(this.qr);

  final String qr;

  @override
  List<Object?> get props => [qr];
}

/// Localiza un ejemplar por su etiqueta QR. Es la entrada del mostrador.
class BuscarEjemplarPorQr
    implements UseCase<EjemplarLocalizado, BuscarPorQrParams> {
  const BuscarEjemplarPorQr(this._repository);

  final CatalogoRepository _repository;

  @override
  Future<Result<EjemplarLocalizado>> call(BuscarPorQrParams params) =>
      _repository.buscarPorQr(params.qr);
}
