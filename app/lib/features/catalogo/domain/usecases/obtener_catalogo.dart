import 'package:equatable/equatable.dart';

import '../../../../core/error/result.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/libro.dart';
import '../repositories/catalogo_repository.dart';

class ObtenerCatalogoParams extends Equatable {
  const ObtenerCatalogoParams({this.soloValidados = true});

  /// `true` devuelve el catálogo público que ve el lector; `false`, el
  /// inventario completo que ve el bibliotecario.
  final bool soloValidados;

  @override
  List<Object?> get props => [soloValidados];
}

/// Devuelve los libros del catálogo.
class ObtenerCatalogo implements UseCase<List<Libro>, ObtenerCatalogoParams> {
  const ObtenerCatalogo(this._repository);

  final CatalogoRepository _repository;

  @override
  Future<Result<List<Libro>>> call(ObtenerCatalogoParams params) =>
      params.soloValidados
          ? _repository.obtenerCatalogoPublico()
          : _repository.obtenerTodos();
}
