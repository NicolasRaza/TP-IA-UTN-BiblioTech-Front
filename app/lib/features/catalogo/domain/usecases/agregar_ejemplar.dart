import 'package:equatable/equatable.dart';

import '../../../../core/error/result.dart';
import '../../../../core/services/reloj.dart';
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
class AgregarEjemplar implements UseCase<Ejemplar, AgregarEjemplarParams> {
  const AgregarEjemplar({
    required CatalogoRepository catalogoRepository,
    required GeneradorId generadorId,
  })  : _catalogo = catalogoRepository,
        _generadorId = generadorId;

  final CatalogoRepository _catalogo;
  final GeneradorId _generadorId;

  @override
  Future<Result<Ejemplar>> call(AgregarEjemplarParams params) async {
    final libroResult = await _catalogo.obtenerPorId(params.libroId);
    if (libroResult case Fallo(:final failure)) return Fallo(failure);
    final libro = libroResult.valorONull!;

    final nuevo = Ejemplar(
      id: 'ej-${_generadorId.generar()}',
      libroId: params.libroId,
      condicion: params.condicion,
      estado: EstadoEjemplar.disponible,
    );

    final guardado = await _catalogo
        .actualizar(libro.copyWith(ejemplares: [...libro.ejemplares, nuevo]));
    if (guardado case Fallo(:final failure)) return Fallo(failure);

    return Exito(nuevo);
  }
}
