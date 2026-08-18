import 'package:bibliotech/core/presentation/estado_carga.dart';
import 'package:bibliotech/features/prestamos/domain/usecases/registrar_prestamo.dart';
import 'package:bibliotech/features/reservas/presentation/bloc/reservas_bloc.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/entorno_de_prueba.dart';

/// Tests del [ReservasBloc] contra el grafo real.
///
/// Verifican que cada evento del usuario termine en el estado que la pantalla
/// espera, incluido el mensaje que la SnackBar va a mostrar.
void main() {
  late EntornoDePrueba entorno;

  // lib-003 tiene un solo ejemplar: prestándolo se fuerza la cola.
  const libroId = 'lib-003';

  setUp(() async {
    entorno = await EntornoDePrueba.montar();
  });

  tearDown(() => entorno.desmontar());

  /// Deja el único ejemplar del título fuera de circulación.
  Future<void> agotarStock() async {
    await entorno<RegistrarPrestamo>()(
      const RegistrarPrestamoParams(lectorId: 'lec-001', libroId: libroId),
    );
  }

  blocTest<ReservasBloc, ReservasState>(
    'con ejemplar disponible la reserva queda lista para retirar',
    build: () => entorno<ReservasBloc>(),
    act: (bloc) => bloc.add(
      const ReservaCreada(lectorId: 'lec-004', libroId: 'lib-001'),
    ),
    wait: const Duration(milliseconds: 50),
    verify: (bloc) {
      expect(bloc.state.listasParaRetirar, hasLength(1));
      expect(bloc.state.mensajeExito, contains('lista para retirar'));
    },
  );

  blocTest<ReservasBloc, ReservasState>(
    'sin ejemplares libres el lector queda en la lista de espera',
    setUp: agotarStock,
    build: () => entorno<ReservasBloc>(),
    act: (bloc) => bloc.add(
      const ReservaCreada(lectorId: 'lec-004', libroId: libroId),
    ),
    wait: const Duration(milliseconds: 50),
    verify: (bloc) {
      expect(bloc.state.activas, hasLength(1));
      expect(bloc.state.listasParaRetirar, isEmpty);
      expect(bloc.state.mensajeExito, contains('lista de espera'));
    },
  );

  blocTest<ReservasBloc, ReservasState>(
    'reservar dos veces el mismo título deja un error en el estado',
    setUp: agotarStock,
    build: () => entorno<ReservasBloc>(),
    act: (bloc) async {
      bloc.add(const ReservaCreada(lectorId: 'lec-004', libroId: libroId));
      await Future<void>.delayed(const Duration(milliseconds: 30));
      bloc.add(const ReservaCreada(lectorId: 'lec-004', libroId: libroId));
    },
    wait: const Duration(milliseconds: 80),
    verify: (bloc) {
      expect(bloc.state.mensajeError, contains('Ya tenés una reserva'));
      expect(bloc.state.activas, hasLength(1),
          reason: 'la segunda no se registra');
    },
  );

  blocTest<ReservasBloc, ReservasState>(
    'cancelar una reserva la saca de las activas',
    setUp: agotarStock,
    build: () => entorno<ReservasBloc>(),
    act: (bloc) async {
      bloc.add(const ReservaCreada(lectorId: 'lec-004', libroId: libroId));
      await Future<void>.delayed(const Duration(milliseconds: 30));
      bloc.add(ReservaCancelada(bloc.state.activas.single.id));
    },
    wait: const Duration(milliseconds: 80),
    verify: (bloc) {
      expect(bloc.state.activas, isEmpty);
      expect(bloc.state.mensajeExito, 'Reserva cancelada');
    },
  );

  blocTest<ReservasBloc, ReservasState>(
    'un lector con multa impaga no puede reservar',
    build: () => entorno<ReservasBloc>(),
    // lec-002 arranca con multa en los datos de demostración.
    act: (bloc) => bloc.add(
      const ReservaCreada(lectorId: 'lec-002', libroId: 'lib-001'),
    ),
    wait: const Duration(milliseconds: 50),
    verify: (bloc) {
      expect(bloc.state.mensajeError, contains('Multa'));
      expect(bloc.state.activas, isEmpty);
    },
  );

  blocTest<ReservasBloc, ReservasState>(
    'pedir las reservas del lector deja el estado en éxito',
    build: () => entorno<ReservasBloc>(),
    act: (bloc) => bloc.add(const ReservasDeLectorSolicitadas('lec-001')),
    wait: const Duration(milliseconds: 50),
    verify: (bloc) => expect(bloc.state.estado, EstadoCarga.exito),
  );

  test('la cola de un título queda en orden cronológico', () async {
    await agotarStock();

    final bloc = entorno<ReservasBloc>();
    bloc.add(const ReservaCreada(lectorId: 'lec-004', libroId: libroId));
    await Future<void>.delayed(const Duration(milliseconds: 30));

    entorno.avanzar(const Duration(hours: 1));
    bloc.add(const ReservaCreada(lectorId: 'lec-005', libroId: libroId));
    await Future<void>.delayed(const Duration(milliseconds: 30));

    bloc.add(const TodasLasReservasSolicitadas());
    await Future<void>.delayed(const Duration(milliseconds: 30));

    expect(
      bloc.state.colaDe(libroId).map((r) => r.lectorId),
      ['lec-004', 'lec-005'],
    );
    await bloc.close();
  });
}
