import 'package:bibliotech/core/usecases/usecase.dart';
import 'package:bibliotech/features/administracion/domain/entities/evento_auditoria.dart';
import 'package:bibliotech/features/administracion/domain/usecases/gestionar_configuracion.dart';
import 'package:bibliotech/features/agentes/domain/usecases/procesar_vencimientos.dart';
import 'package:bibliotech/features/catalogo/domain/entities/libro.dart';
import 'package:bibliotech/features/catalogo/domain/usecases/consultas_catalogo.dart';
import 'package:bibliotech/features/catalogo/domain/usecases/obtener_catalogo.dart';
import 'package:bibliotech/features/catalogo/domain/usecases/registrar_libro.dart';
import 'package:bibliotech/features/catalogo/domain/usecases/reimprimir_etiqueta.dart';
import 'package:bibliotech/features/catalogo/domain/usecases/validar_libro.dart';
import 'package:bibliotech/features/lectores/domain/entities/lector.dart';
import 'package:bibliotech/features/lectores/domain/usecases/cambiar_categoria.dart';
import 'package:bibliotech/features/lectores/domain/usecases/gestionar_lectores.dart';
import 'package:bibliotech/features/prestamos/domain/entities/prestamo.dart';
import 'package:bibliotech/features/prestamos/domain/repositories/prestamo_repository.dart';
import 'package:bibliotech/features/prestamos/domain/usecases/consultas_prestamos.dart';
import 'package:bibliotech/features/prestamos/domain/usecases/registrar_devolucion.dart';
import 'package:bibliotech/features/prestamos/domain/usecases/registrar_prestamo.dart';
import 'package:bibliotech/features/reservas/domain/entities/reserva.dart';
import 'package:bibliotech/features/reservas/domain/usecases/consultas_reservas.dart';
import 'package:bibliotech/features/reservas/domain/usecases/crear_reserva.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/entorno_de_prueba.dart';

/// Tests de las reglas de negocio de la spec v2 §7.
///
/// Corren contra los casos de uso reales resueltos desde el composition root,
/// con reloj fijo para que vencimientos y multas sean deterministas.
void main() {
  late EntornoDePrueba entorno;

  setUp(() async {
    entorno = await EntornoDePrueba.montar();
  });

  tearDown(() => entorno.desmontar());

  // ── Atajos de lectura ────────────────────────────────────────────────
  Future<List<Libro>> catalogoPublico() async =>
      (await entorno<ObtenerCatalogo>()(
        const ObtenerCatalogoParams(soloValidados: true),
      ))
          .valorONull!;

  Future<Libro> libro(String id) async =>
      (await entorno<ObtenerLibro>()(ObtenerLibroParams(id))).valorONull!;

  Future<Lector> lector(String id) async =>
      (await entorno<ObtenerLector>()(ObtenerLectorParams(id))).valorONull!;

  Future<Prestamo> prestamo(String id) async =>
      (await entorno<PrestamoRepository>().obtenerPorId(id)).valorONull!;

  Future<List<EventoAuditoria>> auditoria() async =>
      (await entorno<ObtenerAuditoria>()(const SinParametros())).valorONull!;

  Future<List<Reserva>> cola(String libroId) async =>
      (await entorno<ObtenerColaDeReservas>()(ColaDeReservasParams(libroId)))
          .valorONull!;

  Future<int> multaPorDia() async =>
      (await entorno<ObtenerConfiguracion>()(const SinParametros()))
          .valorONull!
          .multaPorDiaDemora;

  group('Regla de Validación Estricta', () {
    test('un libro nuevo no entra al catálogo público sin confirmación',
        () async {
      final r = await entorno<RegistrarLibro>()(RegistrarLibroParams(
        libro: Libro(
          id: 'lib-nuevo',
          titulo: 'Libro de prueba',
          autor: 'Autora Prueba',
          validado: true, // aunque venga marcado, el alta lo fuerza a false
          fechaAlta: entorno.ahora,
        ),
      ));

      expect(r.valorONull!.validado, isFalse,
          reason: 'el alta nunca publica directo, ni con confianza alta');

      final publico = await catalogoPublico();
      expect(publico.any((l) => l.id == 'lib-nuevo'), isFalse);

      final pendientes =
          (await entorno<ObtenerPendientesValidacion>()(const SinParametros()))
              .valorONull!;
      expect(pendientes.any((l) => l.id == 'lib-nuevo'), isTrue);
    });

    test('tras la confirmación del bibliotecario aparece en el catálogo',
        () async {
      await entorno<RegistrarLibro>()(RegistrarLibroParams(
        libro: Libro(
          id: 'lib-nuevo',
          titulo: 'Libro de prueba',
          autor: 'Autora Prueba',
          fechaAlta: entorno.ahora,
        ),
      ));
      await entorno<ValidarLibro>()(
        const ValidarLibroParams(libroId: 'lib-nuevo', usuarioId: 'bib-001'),
      );

      final publico = await catalogoPublico();
      expect(publico.any((l) => l.id == 'lib-nuevo'), isTrue);
    });
  });

  group('Límites y bloqueos de préstamo', () {
    test('no se presta a un lector con multa impaga', () async {
      // lec-002 arranca con $1500 de multa en los datos semilla.
      final r = await entorno<RegistrarPrestamo>()(
        const RegistrarPrestamoParams(lectorId: 'lec-002', libroId: 'lib-001'),
      );

      expect(r.esFallo, isTrue);
      expect(r.failureONull!.mensaje, contains('Multa'));
    });

    test('no se supera el límite de ejemplares de la categoría', () async {
      final cfg = (await entorno<ObtenerConfiguracion>()(const SinParametros()))
          .valorONull!;
      final limite = cfg.limiteEjemplaresPara(CategoriaLector.senior);

      // lec-005 (senior) no tiene préstamos abiertos ni multas.
      final disponibles = (await catalogoPublico())
          .where((l) => l.hayDisponible)
          .take(limite + 1)
          .toList();
      expect(disponibles.length, greaterThan(limite));

      for (var i = 0; i < limite; i++) {
        final r = await entorno<RegistrarPrestamo>()(RegistrarPrestamoParams(
          lectorId: 'lec-005',
          libroId: disponibles[i].id,
        ));
        expect(r.esExito, isTrue, reason: 'el préstamo ${i + 1} debe entrar');
      }

      final excedente =
          await entorno<RegistrarPrestamo>()(RegistrarPrestamoParams(
        lectorId: 'lec-005',
        libroId: disponibles[limite].id,
      ));
      expect(excedente.esFallo, isTrue);
      expect(excedente.failureONull!.mensaje, contains('límite'));
    });

    test('un préstamo vencido bloquea nuevos préstamos y reservas', () async {
      // lec-002 tiene pres-002 vencido en la semilla.
      final prestar = await entorno<RegistrarPrestamo>()(
        const RegistrarPrestamoParams(lectorId: 'lec-002', libroId: 'lib-001'),
      );
      final reservar = await entorno<CrearReserva>()(
        const CrearReservaParams(lectorId: 'lec-002', libroId: 'lib-001'),
      );

      expect(prestar.esFallo, isTrue);
      expect(reservar.esFallo, isTrue);
    });
  });

  group('Regla de Transición de Categoría', () {
    test('los préstamos vigentes conservan el plazo con el que nacieron',
        () async {
      // Sofía es menor: plazo 7 días.
      final creado = (await entorno<RegistrarPrestamo>()(
        const RegistrarPrestamoParams(lectorId: 'lec-003', libroId: 'lib-001'),
      ))
          .valorONull!;
      expect(creado.plazoDiasAlPrestar, 7);
      expect(creado.categoriaAlPrestar, CategoriaLector.menor);
      final vencimientoOriginal = creado.fechaVencimiento;

      // Cumple la mayoría de edad y pasa a adulto.
      await entorno<CambiarCategoria>()(const CambiarCategoriaParams(
        lectorId: 'lec-003',
        nueva: CategoriaLector.adulto,
      ));

      final guardado = await prestamo(creado.id);
      expect(guardado.plazoDiasAlPrestar, 7,
          reason: 'el préstamo ya generado no cambia de plazo');
      expect(guardado.fechaVencimiento, vencimientoOriginal);
      expect(guardado.categoriaAlPrestar, CategoriaLector.menor);
    });

    test('los préstamos nuevos usan la categoría actualizada', () async {
      await entorno<CambiarCategoria>()(const CambiarCategoriaParams(
        lectorId: 'lec-003',
        nueva: CategoriaLector.adulto,
      ));

      final nuevo = (await entorno<RegistrarPrestamo>()(
        const RegistrarPrestamoParams(lectorId: 'lec-003', libroId: 'lib-001'),
      ))
          .valorONull!;
      expect(nuevo.plazoDiasAlPrestar, 14);
      expect(nuevo.categoriaAlPrestar, CategoriaLector.adulto);
    });

    test('el cambio de categoría queda registrado en auditoría', () async {
      await entorno<CambiarCategoria>()(const CambiarCategoriaParams(
        lectorId: 'lec-003',
        nueva: CategoriaLector.adulto,
        usuarioId: 'bib-001',
      ));

      final evento = (await auditoria())
          .firstWhere((e) => e.tipo == TipoEventoAuditoria.cambioCategoria);
      expect(evento.descripcion, contains('Menor → Adulto'));
      expect(evento.usuarioId, 'bib-001');
    });
  });

  group('Regla de Continuidad de Identidad ante Reimpresión de QR', () {
    test('la reimpresión conserva el mismo identificador y etiqueta', () async {
      final ejemplar = (await libro('lib-001')).ejemplares.first;
      final qrOriginal = ejemplar.qr;

      final r = await entorno<ReimprimirEtiqueta>()(ReimprimirEtiquetaParams(
        libroId: 'lib-001',
        ejemplarId: ejemplar.id,
        motivo: 'Etiqueta rota',
        usuarioId: 'bib-001',
      ));

      expect(r.esExito, isTrue);
      expect(r.valorONull!.id, ejemplar.id,
          reason: 'el ID interno nunca cambia');
      expect(r.valorONull!.qr, qrOriginal,
          reason: 'la etiqueta reimpresa es idéntica');
      expect(r.valorONull!.reimpresionesQr, 1);
    });

    test('el historial de préstamos del ejemplar queda intacto', () async {
      final ejemplarId = (await libro('lib-001')).ejemplares.first.id;
      final creado = (await entorno<RegistrarPrestamo>()(
        RegistrarPrestamoParams(
          lectorId: 'lec-001',
          libroId: 'lib-001',
          ejemplarId: ejemplarId,
        ),
      ))
          .valorONull!;

      await entorno<ReimprimirEtiqueta>()(ReimprimirEtiquetaParams(
        libroId: 'lib-001',
        ejemplarId: ejemplarId,
        motivo: 'Desgaste',
      ));

      final todos =
          (await entorno<ObtenerTodosLosPrestamos>()(const SinParametros()))
              .valorONull!;
      final delEjemplar =
          todos.where((p) => p.ejemplarId == ejemplarId).toList();
      expect(delEjemplar.map((p) => p.id), contains(creado.id));
    });

    test('la reimpresión queda registrada en auditoría con su motivo',
        () async {
      final ejemplarId = (await libro('lib-001')).ejemplares.first.id;
      await entorno<ReimprimirEtiqueta>()(ReimprimirEtiquetaParams(
        libroId: 'lib-001',
        ejemplarId: ejemplarId,
        motivo: 'Etiqueta ilegible',
        usuarioId: 'bib-001',
      ));

      final evento = (await auditoria())
          .firstWhere((e) => e.tipo == TipoEventoAuditoria.reimpresionQr);
      expect(evento.descripcion, contains('Etiqueta ilegible'));
      expect(evento.usuarioId, 'bib-001');
    });
  });

  group('Priorización de Reservas', () {
    const libroId = 'lib-003'; // un solo ejemplar

    test('la cola respeta el orden cronológico estricto', () async {
      final creado = (await entorno<RegistrarPrestamo>()(
        const RegistrarPrestamoParams(lectorId: 'lec-001', libroId: libroId),
      ))
          .valorONull!;
      expect((await libro(libroId)).hayDisponible, isFalse);

      entorno.avanzar(const Duration(hours: 1));
      await entorno<CrearReserva>()(
        const CrearReservaParams(lectorId: 'lec-004', libroId: libroId),
      );
      entorno.avanzar(const Duration(hours: 1));
      await entorno<CrearReserva>()(
        const CrearReservaParams(lectorId: 'lec-005', libroId: libroId),
      );

      expect(
          (await cola(libroId)).map((r) => r.lectorId), ['lec-004', 'lec-005']);

      // Al devolver, el ejemplar se le retiene al primero de la cola.
      await entorno<RegistrarDevolucion>()(
        RegistrarDevolucionParams(prestamoId: creado.id),
      );

      final actualizada = await cola(libroId);
      expect(actualizada.first.lectorId, 'lec-004');
      expect(actualizada.first.estado, EstadoReserva.lista);
      expect(actualizada.last.estado, EstadoReserva.pendiente);
    });

    test('pasadas las 48 hs sin retirar, pasa al siguiente de la lista',
        () async {
      final creado = (await entorno<RegistrarPrestamo>()(
        const RegistrarPrestamoParams(lectorId: 'lec-001', libroId: libroId),
      ))
          .valorONull!;

      entorno.avanzar(const Duration(hours: 1));
      await entorno<CrearReserva>()(
        const CrearReservaParams(lectorId: 'lec-004', libroId: libroId),
      );
      entorno.avanzar(const Duration(hours: 1));
      await entorno<CrearReserva>()(
        const CrearReservaParams(lectorId: 'lec-005', libroId: libroId),
      );
      await entorno<RegistrarDevolucion>()(
        RegistrarDevolucionParams(prestamoId: creado.id),
      );

      final retenida = (await cola(libroId)).first;
      expect(retenida.lectorId, 'lec-004');
      expect(
        retenida.fechaVencimientoRetiro,
        entorno.ahora.add(const Duration(hours: 48)),
      );

      // Pasan 49 horas sin que lo retire.
      entorno.avanzar(const Duration(hours: 49));
      await entorno<ProcesarVencimientos>()(const SinParametros());

      final deLec004 = (await entorno<ObtenerReservasDeLector>()(
        const ReservasDeLectorParams('lec-004'),
      ))
          .valorONull!
          .firstWhere((r) => r.libroId == libroId);
      expect(deLec004.estado, EstadoReserva.vencida);

      final deLec005 = (await entorno<ObtenerReservasDeLector>()(
        const ReservasDeLectorParams('lec-005'),
      ))
          .valorONull!
          .firstWhere((r) => r.libroId == libroId);
      expect(deLec005.estado, EstadoReserva.lista,
          reason: 'el ejemplar pasa automáticamente al siguiente en espera');
    });

    test('no se puede reservar dos veces el mismo título', () async {
      await entorno<RegistrarPrestamo>()(
        const RegistrarPrestamoParams(lectorId: 'lec-001', libroId: libroId),
      );
      await entorno<CrearReserva>()(
        const CrearReservaParams(lectorId: 'lec-004', libroId: libroId),
      );

      final segunda = await entorno<CrearReserva>()(
        const CrearReservaParams(lectorId: 'lec-004', libroId: libroId),
      );
      expect(segunda.esFallo, isTrue);
      expect(segunda.failureONull!.mensaje, contains('Ya tenés una reserva'));
    });
  });

  group('Multas por demora', () {
    test('se cobra por día de atraso al devolver', () async {
      final creado = (await entorno<RegistrarPrestamo>()(
        const RegistrarPrestamoParams(lectorId: 'lec-001', libroId: 'lib-001'),
      ))
          .valorONull!;
      final diaria = await multaPorDia();

      // Tres días después del vencimiento.
      entorno.fijar(creado.fechaVencimiento.add(const Duration(days: 3)));
      await entorno<RegistrarDevolucion>()(
        RegistrarDevolucionParams(prestamoId: creado.id),
      );

      expect((await lector('lec-001')).multasPendientes, 3 * diaria);
    });

    test('procesar vencimientos dos veces no duplica la multa', () async {
      final creado = (await entorno<RegistrarPrestamo>()(
        const RegistrarPrestamoParams(lectorId: 'lec-001', libroId: 'lib-001'),
      ))
          .valorONull!;
      final diaria = await multaPorDia();

      entorno.fijar(creado.fechaVencimiento.add(const Duration(days: 2)));

      await entorno<ProcesarVencimientos>()(const SinParametros());
      final multaLector1 = (await lector('lec-001')).multasPendientes;
      final multaPrestamo1 = (await prestamo(creado.id)).multaAplicada;

      await entorno<ProcesarVencimientos>()(const SinParametros());
      final multaLector2 = (await lector('lec-001')).multasPendientes;
      final multaPrestamo2 = (await prestamo(creado.id)).multaAplicada;

      expect(multaPrestamo1, 2 * diaria,
          reason: 'dos días de atraso sobre este préstamo');
      expect(multaPrestamo2, multaPrestamo1,
          reason: 'la segunda corrida no vuelve a cargar el mismo atraso');
      expect(multaLector2, multaLector1,
          reason: 'el saldo del lector no se mueve al reprocesar');
    });

    test('la multa sigue creciendo si pasan más días sin devolver', () async {
      final creado = (await entorno<RegistrarPrestamo>()(
        const RegistrarPrestamoParams(lectorId: 'lec-001', libroId: 'lib-001'),
      ))
          .valorONull!;
      final diaria = await multaPorDia();

      entorno.fijar(creado.fechaVencimiento.add(const Duration(days: 2)));
      await entorno<ProcesarVencimientos>()(const SinParametros());
      expect((await prestamo(creado.id)).multaAplicada, 2 * diaria);

      entorno.avanzar(const Duration(days: 3));
      await entorno<ProcesarVencimientos>()(const SinParametros());
      expect((await prestamo(creado.id)).multaAplicada, 5 * diaria,
          reason: 'se cobra solo el incremento, no el total de nuevo');
    });
  });
}
