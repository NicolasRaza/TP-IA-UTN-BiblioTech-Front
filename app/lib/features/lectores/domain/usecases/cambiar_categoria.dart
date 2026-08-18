import 'package:equatable/equatable.dart';

import '../../../../core/error/result.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../administracion/domain/entities/evento_auditoria.dart';
import '../../../administracion/domain/repositories/auditoria_repository.dart';
import '../entities/lector.dart';
import '../repositories/lector_repository.dart';

class CambiarCategoriaParams extends Equatable {
  const CambiarCategoriaParams({
    required this.lectorId,
    required this.nueva,
    this.usuarioId,
  });

  final String lectorId;
  final CategoriaLector nueva;
  final String? usuarioId;

  @override
  List<Object?> get props => [lectorId, nueva, usuarioId];
}

/// Cambia la categoría de un lector.
///
/// Regla de Transición de Categoría (spec v2 §7): la nueva categoría rige
/// **sólo para préstamos y reservas futuros**. Los que ya están activos
/// conservan las condiciones con las que se generaron.
///
/// Este caso de uso no necesita hacer nada para respetar esa regla, y eso es
/// intencional: cada `Prestamo` guarda su propio `plazoDiasAlPrestar` y su
/// `categoriaAlPrestar` al nacer, así que cambiar la categoría del lector no
/// puede alcanzarlos. La regla vive en el modelo, no en un recorrido que
/// alguien pueda olvidarse de escribir.
class CambiarCategoria implements UseCase<Lector, CambiarCategoriaParams> {
  const CambiarCategoria({
    required LectorRepository lectorRepository,
    required AuditoriaRepository auditoriaRepository,
  })  : _lectores = lectorRepository,
        _auditoria = auditoriaRepository;

  final LectorRepository _lectores;
  final AuditoriaRepository _auditoria;

  @override
  Future<Result<Lector>> call(CambiarCategoriaParams params) async {
    final actualResult = await _lectores.obtenerPorId(params.lectorId);
    if (actualResult case Fallo(:final failure)) return Fallo(failure);
    final actual = actualResult.valorONull!;

    if (actual.categoria == params.nueva) return Exito(actual);

    final actualizado =
        await _lectores.actualizar(actual.copyWith(categoria: params.nueva));
    if (actualizado case Fallo(:final failure)) return Fallo(failure);

    await _auditoria.registrar(
      tipo: TipoEventoAuditoria.cambioCategoria,
      descripcion: 'Cambio de categoría de ${actual.nombreCompleto}: '
          '${actual.categoria.label} → ${params.nueva.label}. '
          'Los préstamos y reservas vigentes conservan sus condiciones '
          'originales.',
      usuarioId: params.usuarioId,
    );

    return actualizado;
  }
}
