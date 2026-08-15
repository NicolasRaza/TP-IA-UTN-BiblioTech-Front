import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/error/result.dart';
import '../../../../core/services/reloj.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../administracion/domain/repositories/configuracion_repository.dart';
import '../../../agentes/domain/entities/recomendacion.dart';
import '../../../agentes/domain/repositories/aprendizaje_repository.dart';
import '../../../catalogo/domain/repositories/catalogo_repository.dart';
import '../../../lectores/domain/repositories/lector_repository.dart';
import '../../../prestamos/domain/repositories/prestamo_repository.dart';
import '../entities/reserva.dart';
import '../repositories/reserva_repository.dart';
import '../services/asignador_de_cola.dart';
import '../services/politica_de_reserva.dart';

class CrearReservaParams extends Equatable {
  const CrearReservaParams({required this.lectorId, required this.libroId});

  final String lectorId;
  final String libroId;

  @override
  List<Object?> get props => [lectorId, libroId];
}

/// Pone al lector en la cola de espera de un título.
///
/// Si hay un ejemplar libre y nadie por delante, el [AsignadorDeCola] la deja
/// retenida de inmediato, sin que el lector tenga que esperar a que corra el
/// ciclo de agentes.
class CrearReserva implements UseCase<Reserva, CrearReservaParams> {
  const CrearReserva({
    required ReservaRepository reservaRepository,
    required LectorRepository lectorRepository,
    required PrestamoRepository prestamoRepository,
    required CatalogoRepository catalogoRepository,
    required ConfiguracionRepository configuracionRepository,
    required AprendizajeRepository aprendizajeRepository,
    required AsignadorDeCola asignadorDeCola,
    required Reloj reloj,
    PoliticaDeReserva politica = const PoliticaDeReserva(),
  })  : _reservas = reservaRepository,
        _lectores = lectorRepository,
        _prestamos = prestamoRepository,
        _catalogo = catalogoRepository,
        _configuracion = configuracionRepository,
        _aprendizaje = aprendizajeRepository,
        _asignador = asignadorDeCola,
        _reloj = reloj,
        _politica = politica;

  final ReservaRepository _reservas;
  final LectorRepository _lectores;
  final PrestamoRepository _prestamos;
  final CatalogoRepository _catalogo;
  final ConfiguracionRepository _configuracion;
  final AprendizajeRepository _aprendizaje;
  final AsignadorDeCola _asignador;
  final Reloj _reloj;
  final PoliticaDeReserva _politica;

  @override
  Future<Result<Reserva>> call(CrearReservaParams params) async {
    final lectorResult = await _lectores.obtenerPorId(params.lectorId);
    if (lectorResult case Fallo(:final failure)) return Fallo(failure);

    final prestamosResult = await _prestamos.obtenerDeLector(params.lectorId);
    if (prestamosResult case Fallo(:final failure)) return Fallo(failure);

    final reservasResult = await _reservas.obtenerDeLector(params.lectorId);
    if (reservasResult case Fallo(:final failure)) return Fallo(failure);
    final reservasDelLector = reservasResult.valorONull!;

    final configResult = await _configuracion.obtener();
    if (configResult case Fallo(:final failure)) return Fallo(failure);

    final habilitado = _politica.verificar(
      lector: lectorResult.valorONull!,
      prestamosDelLector: prestamosResult.valorONull!,
      reservasDelLector: reservasDelLector,
      configuracion: configResult.valorONull!,
    );
    if (habilitado case Fallo(:final failure)) return Fallo(failure);

    final libroResult = await _catalogo.obtenerPorId(params.libroId);
    if (libroResult case Fallo(:final failure)) return Fallo(failure);
    final libro = libroResult.valorONull!;

    // Regla de Validación Estricta: un libro sin validar no está en el
    // catálogo, así que tampoco se puede reservar.
    if (!libro.validado) {
      return const Fallo(ReglaDeNegocioFailure(
          'El libro no está disponible en el catálogo'));
    }

    final duplicada = reservasDelLector
        .any((r) => r.libroId == params.libroId && r.esActiva);
    if (duplicada) {
      return const Fallo(ReglaDeNegocioFailure(
          'Ya tenés una reserva activa para este libro'));
    }

    final creada = await _reservas.crear(
      Reserva(
        id: '',
        lectorId: params.lectorId,
        libroId: params.libroId,
        fechaReserva: _reloj.ahora,
        estado: EstadoReserva.pendiente,
        plazoRetiroHorasAlReservar:
            configResult.valorONull!.plazoRetiroReservaHoras,
      ),
    );
    if (creada case Fallo(:final failure)) return Fallo(failure);
    final reserva = creada.valorONull!;

    // Insumo del Agente de Aprendizaje: reservar es la señal más fuerte de
    // interés de un lector por un título.
    await _aprendizaje.registrarInteraccion(
      InteraccionLector(
        lectorId: params.lectorId,
        libroId: params.libroId,
        tipo: 'reserva',
        fecha: _reloj.ahora,
      ),
    );

    await _asignador.asignarSiguiente(params.libroId);

    // Puede haber quedado retenida en el paso anterior, así que se relee.
    final refrescada = await _reservas.obtenerPorId(reserva.id);
    return Exito(refrescada.valorONull ?? reserva);
  }
}
