import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/error/result.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../administracion/domain/entities/evento_auditoria.dart';
import '../../../administracion/domain/repositories/auditoria_repository.dart';
import '../entities/ejemplar.dart';
import '../repositories/catalogo_repository.dart';

class ReimprimirEtiquetaParams extends Equatable {
  const ReimprimirEtiquetaParams({
    required this.libroId,
    required this.ejemplarId,
    required this.motivo,
    this.usuarioId,
  });

  final String libroId;
  final String ejemplarId;
  final String motivo;
  final String? usuarioId;

  @override
  List<Object?> get props => [libroId, ejemplarId, motivo, usuarioId];
}

/// Reimprime la etiqueta QR de un ejemplar.
///
/// Regla de Continuidad de Identidad (spec v2 §7): el identificador interno no
/// cambia, así que la etiqueta reimpresa es **idéntica** a la original y el
/// historial de préstamos del ejemplar queda intacto. Lo único que ocurre es
/// que se incrementa el contador de reimpresiones y se asienta el motivo en
/// auditoría.
///
/// El QR no se guarda: se deriva del ID en `Ejemplar.qr`. Esa decisión de
/// modelado es la que hace imposible, por construcción, que una reimpresión
/// genere una etiqueta distinta.
class ReimprimirEtiqueta
    implements UseCase<Ejemplar, ReimprimirEtiquetaParams> {
  const ReimprimirEtiqueta({
    required CatalogoRepository catalogoRepository,
    required AuditoriaRepository auditoriaRepository,
  })  : _catalogo = catalogoRepository,
        _auditoria = auditoriaRepository;

  final CatalogoRepository _catalogo;
  final AuditoriaRepository _auditoria;

  @override
  Future<Result<Ejemplar>> call(ReimprimirEtiquetaParams params) async {
    if (params.motivo.trim().isEmpty) {
      return const Fallo(ValidacionFailure(
          'Hay que indicar el motivo de la reimpresión'));
    }

    final libroResult = await _catalogo.obtenerPorId(params.libroId);
    if (libroResult case Fallo(:final failure)) return Fallo(failure);
    final libro = libroResult.valorONull!;

    final ejemplar = libro.ejemplar(params.ejemplarId);
    if (ejemplar == null) {
      return const Fallo(NoEncontradoFailure('El ejemplar no existe'));
    }

    final actualizado = await _catalogo.actualizar(
      libro.conEjemplarActualizado(
        params.ejemplarId,
        (e) => e.copyWith(reimpresionesQr: e.reimpresionesQr + 1),
      ),
    );
    if (actualizado case Fallo(:final failure)) return Fallo(failure);

    await _auditoria.registrar(
      tipo: TipoEventoAuditoria.reimpresionQr,
      descripcion: 'Reimpresión de etiqueta ${ejemplar.qr} '
          '("${libro.titulo}"). Motivo: ${params.motivo}',
      usuarioId: params.usuarioId,
    );

    return Exito(actualizado.valorONull!.ejemplar(params.ejemplarId)!);
  }
}
