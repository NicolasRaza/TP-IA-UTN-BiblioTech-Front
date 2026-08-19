import 'package:equatable/equatable.dart';

import '../../../../core/error/result.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/ejemplar.dart';
import '../repositories/catalogo_repository.dart';

class AgregarEjemplarParams extends Equatable {
  const AgregarEjemplarParams({
    required this.libroId,
    required this.condicion,
  });

  final String libroId;
  final CondicionEjemplar condicion;

  @override
  List<Object?> get props => [libroId, condicion];
}

/// Suma una copia física a un título ya existente.
///
/// El id y el código QR del ejemplar los asigna quien guarda: el backend
/// cuando la app corre contra la API, el repositorio local cuando corre sobre
/// el almacenamiento del navegador. Por eso el caso de uso delega el alta en
/// el repositorio en vez de armar el ejemplar acá.
class AgregarEjemplar implements UseCase<Ejemplar, AgregarEjemplarParams> {
  const AgregarEjemplar({required CatalogoRepository catalogoRepository})
      : _catalogo = catalogoRepository;

  final CatalogoRepository _catalogo;

  @override
  Future<Result<Ejemplar>> call(AgregarEjemplarParams params) =>
      _catalogo.agregarEjemplar(params.libroId, params.condicion);
}
