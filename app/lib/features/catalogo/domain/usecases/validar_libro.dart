import 'package:equatable/equatable.dart';

import '../../../../core/error/result.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../administracion/domain/entities/evento_auditoria.dart';
import '../../../administracion/domain/repositories/auditoria_repository.dart';
import '../entities/libro.dart';
import '../repositories/catalogo_repository.dart';

class ValidarLibroParams extends Equatable {
  const ValidarLibroParams({required this.libroId, this.usuarioId});

  final String libroId;
  final String? usuarioId;

  @override
  List<Object?> get props => [libroId, usuarioId];
}

/// Confirmación explícita del bibliotecario que publica el libro en el
/// catálogo público (spec v2 §7).
class ValidarLibro implements UseCase<Libro, ValidarLibroParams> {
  const ValidarLibro({
    required CatalogoRepository catalogoRepository,
    required AuditoriaRepository auditoriaRepository,
  })  : _catalogo = catalogoRepository,
        _auditoria = auditoriaRepository;

  final CatalogoRepository _catalogo;
  final AuditoriaRepository _auditoria;

  @override
  Future<Result<Libro>> call(ValidarLibroParams params) async {
    final libroResult = await _catalogo.obtenerPorId(params.libroId);
    if (libroResult case Fallo(:final failure)) return Fallo(failure);

    final validado = await _catalogo
        .actualizar(libroResult.valorONull!.copyWith(validado: true));
    if (validado case Fallo(:final failure)) return Fallo(failure);

    await _auditoria.registrar(
      tipo: TipoEventoAuditoria.altaLibro,
      descripcion:
          'Validación y publicación de "${validado.valorONull!.titulo}"',
      usuarioId: params.usuarioId,
    );

    return validado;
  }
}
