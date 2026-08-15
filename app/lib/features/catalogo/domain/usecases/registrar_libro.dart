import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/error/result.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../administracion/domain/entities/evento_auditoria.dart';
import '../../../administracion/domain/repositories/auditoria_repository.dart';
import '../entities/libro.dart';
import '../repositories/catalogo_repository.dart';

class RegistrarLibroParams extends Equatable {
  const RegistrarLibroParams({required this.libro, this.usuarioId});

  final Libro libro;
  final String? usuarioId;

  @override
  List<Object?> get props => [libro, usuarioId];
}

/// Da de alta un libro en el catálogo.
///
/// Regla de Validación Estricta (spec v2 §7): nace **siempre** sin validar,
/// aunque quien lo cargue intente marcarlo como validado. El libro no aparece
/// en el catálogo público hasta que un bibliotecario lo confirme
/// explícitamente con `ValidarLibro`. Forzar el `validado: false` acá, y no
/// confiar en el llamador, es lo que hace que la regla no se pueda esquivar.
class RegistrarLibro implements UseCase<Libro, RegistrarLibroParams> {
  const RegistrarLibro({
    required CatalogoRepository catalogoRepository,
    required AuditoriaRepository auditoriaRepository,
  })  : _catalogo = catalogoRepository,
        _auditoria = auditoriaRepository;

  final CatalogoRepository _catalogo;
  final AuditoriaRepository _auditoria;

  @override
  Future<Result<Libro>> call(RegistrarLibroParams params) async {
    if (params.libro.titulo.trim().isEmpty) {
      return const Fallo(ValidacionFailure('El título es obligatorio'));
    }
    if (params.libro.autor.trim().isEmpty) {
      return const Fallo(ValidacionFailure('El autor es obligatorio'));
    }

    final creado =
        await _catalogo.crear(params.libro.copyWith(validado: false));
    if (creado case Fallo(:final failure)) return Fallo(failure);

    await _auditoria.registrar(
      tipo: TipoEventoAuditoria.altaLibro,
      descripcion: 'Alta del libro "${creado.valorONull!.titulo}" '
          '(pendiente de validación)',
      usuarioId: params.usuarioId,
    );

    return creado;
  }
}
