import 'package:equatable/equatable.dart';

import '../../../../core/error/result.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/libro.dart';
import '../repositories/catalogo_repository.dart';

class BuscarLibrosParams extends Equatable {
  const BuscarLibrosParams({this.texto = '', this.genero = 'Todos'});

  final String texto;
  final String genero;

  @override
  List<Object?> get props => [texto, genero];
}

/// Busca dentro del catálogo público por texto libre y género.
class BuscarLibros implements UseCase<List<Libro>, BuscarLibrosParams> {
  const BuscarLibros(this._repository);

  final CatalogoRepository _repository;

  @override
  Future<Result<List<Libro>>> call(BuscarLibrosParams params) =>
      _repository.buscar(texto: params.texto, genero: params.genero);
}
