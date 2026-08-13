import 'package:bibliotech/data/repositorio.dart';
import 'package:bibliotech/data/store.dart';
import 'package:bibliotech/domain/enums.dart';
import 'package:bibliotech/domain/models.dart';
import 'package:flutter_test/flutter_test.dart';

/// Tests de las reglas de negocio de la spec v2 §7.
///
/// El reloj se fija para que los vencimientos sean deterministas.
void main() {
  late DateTime ahora;
  late Repositorio repo;
  var contador = 0;

  setUp(() {
    ahora = DateTime(2026, 3, 10, 12);
    contador = 0;
    repo = Repositorio(
      store: MemoryStore(),
      reloj: () => ahora,
      generadorId: () => '${contador++}',
    )..inicializar();
  });

  group('Regla de Validación Estricta', () {
    test('un libro nuevo no entra al catálogo público sin confirmación', () {
      final nuevo = repo.agregarLibro(Libro(
        id: 'lib-nuevo',
        titulo: 'Libro de prueba',
        autor: 'Autora Prueba',
        validado: true, // aunque venga marcado, el alta lo fuerza a false
        fechaAlta: ahora,
      ));

      expect(nuevo.validado, isFalse,
          reason: 'el alta nunca publica directo, ni con confianza alta');
      expect(repo.catalogoPublico.any((l) => l.id == 'lib-nuevo'), isFalse);
      expect(repo.pendientesValidacion.any((l) => l.id == 'lib-nuevo'), isTrue);
    });

    test('tras la confirmación del bibliotecario aparece en el catálogo', () {
      repo.agregarLibro(Libro(
        id: 'lib-nuevo',
        titulo: 'Libro de prueba',
        autor: 'Autora Prueba',
        fechaAlta: ahora,
      ));
      repo.validarLibro('lib-nuevo', usuarioId: 'bib-001');

      expect(repo.catalogoPublico.any((l) => l.id == 'lib-nuevo'), isTrue);
    });
  });

  group('Límites y bloqueos de préstamo', () {
    test('no se presta a un lector con multa impaga', () {
      // lec-002 arranca con $1500 de multa en los datos semilla.
      final r = repo.crearPrestamo(lectorId: 'lec-002', libroId: 'lib-001');

      expect(r.exito, isFalse);
      expect(r.motivo, contains('Multa'));
    });

    test('no se supera el límite de ejemplares de la categoría', () {
      final cfg = repo.config;
      final limite = cfg.limiteEjemplaresPara(CategoriaLector.senior);

      // lec-005 (senior) no tiene préstamos abiertos ni multas.
      final disponibles = repo.catalogoPublico
          .where((l) => l.hayDisponible)
          .take(limite + 1)
          .toList();
      expect(disponibles.length, greaterThan(limite));

      for (var i = 0; i < limite; i++) {
        final r =
            repo.crearPrestamo(lectorId: 'lec-005', libroId: disponibles[i].id);
        expect(r.exito, isTrue, reason: 'el préstamo ${i + 1} debe entrar');
      }

      final excedente =
          repo.crearPrestamo(lectorId: 'lec-005', libroId: disponibles[limite].id);
      expect(excedente.exito, isFalse);
      expect(excedente.motivo, contains('límite'));
    });

    test('un préstamo vencido bloquea nuevos préstamos y reservas', () {
      // lec-002 tiene pres-002 vencido en la semilla.
      expect(repo.puedePedirPrestado('lec-002').exito, isFalse);
      expect(repo.puedeReservar('lec-002').exito, isFalse);
    });
  });

  group('Regla de Transición de Categoría', () {
    test('los préstamos vigentes conservan el plazo con el que nacieron', () {
      // Sofía es menor: plazo 7 días.
      final prestamo =
          repo.crearPrestamo(lectorId: 'lec-003', libroId: 'lib-001').valor!;
      expect(prestamo.plazoDiasAlPrestar, 7);
      expect(prestamo.categoriaAlPrestar, CategoriaLector.menor);
      final vencimientoOriginal = prestamo.fechaVencimiento;

      // Cumple la mayoría de edad y pasa a adulto.
      repo.cambiarCategoria('lec-003', CategoriaLector.adulto);

      final guardado = repo.prestamo(prestamo.id)!;
      expect(guardado.plazoDiasAlPrestar, 7,
          reason: 'el préstamo ya generado no cambia de plazo');
      expect(guardado.fechaVencimiento, vencimientoOriginal);
      expect(guardado.categoriaAlPrestar, CategoriaLector.menor);
    });

    test('los préstamos nuevos usan la categoría actualizada', () {
      repo.cambiarCategoria('lec-003', CategoriaLector.adulto);

      final nuevo =
          repo.crearPrestamo(lectorId: 'lec-003', libroId: 'lib-001').valor!;
      expect(nuevo.plazoDiasAlPrestar, 14);
      expect(nuevo.categoriaAlPrestar, CategoriaLector.adulto);
    });

    test('el cambio de categoría queda registrado en auditoría', () {
      repo.cambiarCategoria('lec-003', CategoriaLector.adulto,
          usuarioId: 'bib-001');

      final evento = repo.auditoria
          .firstWhere((e) => e.tipo == TipoEventoAuditoria.cambioCategoria);
      expect(evento.descripcion, contains('Menor → Adulto'));
      expect(evento.usuarioId, 'bib-001');
    });
  });

  group('Regla de Continuidad de Identidad ante Reimpresión de QR', () {
    test('la reimpresión conserva el mismo identificador y etiqueta', () {
      final libro = repo.libro('lib-001')!;
      final ejemplar = libro.ejemplares.first;
      final qrOriginal = ejemplar.qr;

      final r = repo.reimprimirEtiqueta('lib-001', ejemplar.id,
          motivo: 'Etiqueta rota', usuarioId: 'bib-001');

      expect(r.exito, isTrue);
      expect(r.valor!.id, ejemplar.id, reason: 'el ID interno nunca cambia');
      expect(r.valor!.qr, qrOriginal, reason: 'la etiqueta reimpresa es idéntica');
      expect(r.valor!.reimpresionesQr, 1);
    });

    test('el historial de préstamos del ejemplar queda intacto', () {
      final ejemplarId = repo.libro('lib-001')!.ejemplares.first.id;
      final prestamo = repo
          .crearPrestamo(
              lectorId: 'lec-001', libroId: 'lib-001', ejemplarId: ejemplarId)
          .valor!;

      repo.reimprimirEtiqueta('lib-001', ejemplarId, motivo: 'Desgaste');

      final delEjemplar =
          repo.prestamos.where((p) => p.ejemplarId == ejemplarId).toList();
      expect(delEjemplar.map((p) => p.id), contains(prestamo.id));
    });

    test('la reimpresión queda registrada en auditoría con su motivo', () {
      final ejemplarId = repo.libro('lib-001')!.ejemplares.first.id;
      repo.reimprimirEtiqueta('lib-001', ejemplarId,
          motivo: 'Etiqueta ilegible', usuarioId: 'bib-001');

      final evento = repo.auditoria
          .firstWhere((e) => e.tipo == TipoEventoAuditoria.reimpresionQr);
      expect(evento.descripcion, contains('Etiqueta ilegible'));
      expect(evento.usuarioId, 'bib-001');
    });
  });

  group('Priorización de Reservas', () {
    test('la cola respeta el orden cronológico estricto', () {
      // lib-013 tiene un ejemplar prestado y otros disponibles; se usa un
      // título sin disponibilidad para que la cola se forme.
      final libroId = 'lib-003'; // un solo ejemplar
      final prestamo =
          repo.crearPrestamo(lectorId: 'lec-001', libroId: libroId).valor!;
      expect(repo.libro(libroId)!.hayDisponible, isFalse);

      ahora = ahora.add(const Duration(hours: 1));
      repo.crearReserva(lectorId: 'lec-004', libroId: libroId);
      ahora = ahora.add(const Duration(hours: 1));
      repo.crearReserva(lectorId: 'lec-005', libroId: libroId);

      final cola = repo.colaDeReservas(libroId);
      expect(cola.map((r) => r.lectorId), ['lec-004', 'lec-005']);

      // Al devolver, el ejemplar se le retiene al primero de la cola.
      repo.devolver(prestamo.id);

      final actualizada = repo.colaDeReservas(libroId);
      expect(actualizada.first.lectorId, 'lec-004');
      expect(actualizada.first.estado, EstadoReserva.lista);
      expect(actualizada.last.estado, EstadoReserva.pendiente);
    });

    test('pasadas las 48 hs sin retirar, pasa al siguiente de la lista', () {
      const libroId = 'lib-003';
      final prestamo =
          repo.crearPrestamo(lectorId: 'lec-001', libroId: libroId).valor!;
      ahora = ahora.add(const Duration(hours: 1));
      repo.crearReserva(lectorId: 'lec-004', libroId: libroId);
      ahora = ahora.add(const Duration(hours: 1));
      repo.crearReserva(lectorId: 'lec-005', libroId: libroId);
      repo.devolver(prestamo.id);

      final retenida = repo.colaDeReservas(libroId).first;
      expect(retenida.lectorId, 'lec-004');
      expect(
        retenida.fechaVencimientoRetiro,
        ahora.add(const Duration(hours: 48)),
      );

      // Pasan 49 horas sin que lo retire.
      ahora = ahora.add(const Duration(hours: 49));
      repo.procesarVencimientos();

      final deLec004 = repo
          .reservasDeLector('lec-004')
          .firstWhere((r) => r.libroId == libroId);
      expect(deLec004.estado, EstadoReserva.vencida);

      final deLec005 = repo
          .reservasDeLector('lec-005')
          .firstWhere((r) => r.libroId == libroId);
      expect(deLec005.estado, EstadoReserva.lista,
          reason: 'el ejemplar pasa automáticamente al siguiente en espera');
    });

    test('no se puede reservar dos veces el mismo título', () {
      const libroId = 'lib-003';
      repo.crearPrestamo(lectorId: 'lec-001', libroId: libroId);
      repo.crearReserva(lectorId: 'lec-004', libroId: libroId);

      final segunda = repo.crearReserva(lectorId: 'lec-004', libroId: libroId);
      expect(segunda.exito, isFalse);
      expect(segunda.motivo, contains('Ya tenés una reserva'));
    });
  });

  group('Multas por demora', () {
    test('se cobra por día de atraso al devolver', () {
      final prestamo =
          repo.crearPrestamo(lectorId: 'lec-001', libroId: 'lib-001').valor!;
      final multaDiaria = repo.config.multaPorDiaDemora;

      // Tres días después del vencimiento.
      ahora = prestamo.fechaVencimiento.add(const Duration(days: 3));
      repo.devolver(prestamo.id);

      final lector = repo.lector('lec-001')!;
      expect(lector.multasPendientes, 3 * multaDiaria);
    });

    test('procesar vencimientos dos veces no duplica la multa', () {
      final prestamo =
          repo.crearPrestamo(lectorId: 'lec-001', libroId: 'lib-001').valor!;
      ahora = prestamo.fechaVencimiento.add(const Duration(days: 2));

      repo.procesarVencimientos();
      final multaLector1 = repo.lector('lec-001')!.multasPendientes;
      final multaPrestamo1 = repo.prestamo(prestamo.id)!.multaAplicada;

      repo.procesarVencimientos();
      final multaLector2 = repo.lector('lec-001')!.multasPendientes;
      final multaPrestamo2 = repo.prestamo(prestamo.id)!.multaAplicada;

      expect(multaPrestamo1, 2 * repo.config.multaPorDiaDemora,
          reason: 'dos días de atraso sobre este préstamo');
      expect(multaPrestamo2, multaPrestamo1,
          reason: 'la segunda corrida no vuelve a cargar el mismo atraso');
      expect(multaLector2, multaLector1,
          reason: 'el saldo del lector no se mueve al reprocesar');
    });

    test('la multa sigue creciendo si pasan más días sin devolver', () {
      final prestamo =
          repo.crearPrestamo(lectorId: 'lec-001', libroId: 'lib-001').valor!;
      final diaria = repo.config.multaPorDiaDemora;

      ahora = prestamo.fechaVencimiento.add(const Duration(days: 2));
      repo.procesarVencimientos();
      expect(repo.prestamo(prestamo.id)!.multaAplicada, 2 * diaria);

      ahora = ahora.add(const Duration(days: 3));
      repo.procesarVencimientos();
      expect(repo.prestamo(prestamo.id)!.multaAplicada, 5 * diaria,
          reason: 'se cobra solo el incremento, no el total de nuevo');
    });
  });
}
