import 'package:bibliotech/features/administracion/domain/entities/configuracion_biblioteca.dart';
import 'package:bibliotech/features/agentes/domain/entities/decision.dart';
import 'package:bibliotech/features/agentes/domain/entities/estado_del_sistema.dart';
import 'package:bibliotech/features/agentes/domain/services/agente_evaluador.dart';
import 'package:bibliotech/features/catalogo/domain/entities/ejemplar.dart';
import 'package:bibliotech/features/catalogo/domain/entities/libro.dart';
import 'package:bibliotech/features/lectores/domain/entities/lector.dart';
import 'package:bibliotech/features/prestamos/domain/entities/prestamo.dart';
import 'package:bibliotech/features/reservas/domain/entities/reserva.dart';
import 'package:flutter_test/flutter_test.dart';

/// Tests del Agente Evaluador (spec v2 §4.3).
///
/// Estos tests son la prueba de que la separación de roles funciona: el
/// evaluador se construye con `const AgenteEvaluador()` y recibe un
/// [EstadoDelSistema] armado a mano. No hay almacenamiento, ni repositorios,
/// ni dobles de prueba — porque el agente no puede tocar nada.
void main() {
  const evaluador = AgenteEvaluador();
  final ahora = DateTime(2026, 3, 10, 12);

  Libro libroCon({
    String id = 'lib-1',
    bool validado = true,
    List<Ejemplar> ejemplares = const [],
  }) =>
      Libro(
        id: id,
        titulo: 'Título $id',
        autor: 'Autora',
        genero: 'Novela',
        validado: validado,
        fechaAlta: ahora,
        ejemplares: ejemplares,
      );

  Ejemplar ejemplarCon({
    String id = 'ej-1',
    String libroId = 'lib-1',
    EstadoEjemplar estado = EstadoEjemplar.disponible,
  }) =>
      Ejemplar(
        id: id,
        libroId: libroId,
        condicion: CondicionEjemplar.bueno,
        estado: estado,
      );

  Lector lectorCon({
    String id = 'lec-1',
    int multas = 0,
    CategoriaLector categoria = CategoriaLector.adulto,
    DateTime? nacimiento,
  }) =>
      Lector(
        id: id,
        nombre: 'Ana',
        apellido: 'Pérez',
        email: '$id@test.ar',
        categoria: categoria,
        fechaAlta: ahora,
        multasPendientes: multas,
        fechaNacimiento: nacimiento,
      );

  Prestamo prestamoCon({
    String id = 'pres-1',
    required DateTime vencimiento,
    EstadoPrestamo estado = EstadoPrestamo.activo,
  }) =>
      Prestamo(
        id: id,
        lectorId: 'lec-1',
        ejemplarId: 'ej-1',
        libroId: 'lib-1',
        fechaPrestamo: vencimiento.subtract(const Duration(days: 14)),
        fechaVencimiento: vencimiento,
        estado: estado,
        categoriaAlPrestar: CategoriaLector.adulto,
        plazoDiasAlPrestar: 14,
      );

  EstadoDelSistema estadoCon({
    List<Libro> libros = const [],
    List<Lector> lectores = const [],
    List<Prestamo> prestamos = const [],
    List<Reserva> reservas = const [],
    ConfiguracionBiblioteca configuracion = const ConfiguracionBiblioteca(),
  }) =>
      EstadoDelSistema(
        momento: ahora,
        configuracion: configuracion,
        libros: libros,
        lectores: lectores,
        prestamos: prestamos,
        reservas: reservas,
      );

  group('Decisiones sobre préstamos', () {
    test('un préstamo pasado de fecha genera una decisión de aviso', () {
      final estado = estadoCon(
        libros: [libroCon()],
        lectores: [lectorCon()],
        prestamos: [
          prestamoCon(vencimiento: ahora.subtract(const Duration(days: 3))),
        ],
      );

      final decisiones = evaluador.decidir(estado);
      final vencido = decisiones.singleWhere(
        (d) => d.tipo == TipoDecision.notificarPrestamoVencido,
      );

      expect(vencido.dias, 3);
      expect(vencido.motivo, contains('venció hace 3 días'));
    });

    test('un préstamo próximo a vencer genera un recordatorio', () {
      final estado = estadoCon(
        libros: [libroCon()],
        lectores: [lectorCon()],
        prestamos: [
          prestamoCon(vencimiento: ahora.add(const Duration(days: 2))),
        ],
      );

      final decisiones = evaluador.decidir(estado);
      expect(
        decisiones
            .where((d) => d.tipo == TipoDecision.notificarVencimientoProximo),
        hasLength(1),
      );
    });

    test('un préstamo lejos del vencimiento no genera ninguna decisión', () {
      final estado = estadoCon(
        libros: [libroCon()],
        lectores: [lectorCon()],
        prestamos: [
          prestamoCon(vencimiento: ahora.add(const Duration(days: 10))),
        ],
      );

      expect(evaluador.decidir(estado), isEmpty);
    });
  });

  group('Decisiones sobre reservas', () {
    test('con ejemplar libre y cola pendiente, propone asignarlo al primero',
        () {
      final estado = estadoCon(
        libros: [
          libroCon(ejemplares: [ejemplarCon()]),
        ],
        lectores: [lectorCon()],
        reservas: [
          Reserva(
            id: 'res-1',
            lectorId: 'lec-1',
            libroId: 'lib-1',
            fechaReserva: ahora.subtract(const Duration(hours: 2)),
            estado: EstadoReserva.pendiente,
            plazoRetiroHorasAlReservar: 48,
          ),
        ],
      );

      final decisiones = evaluador.decidir(estado);
      expect(
        decisiones
            .where((d) => d.tipo == TipoDecision.asignarReservaAlSiguiente),
        hasLength(1),
      );
    });

    test('si ya hay una reserva retenida, no propone asignar otra', () {
      final estado = estadoCon(
        libros: [
          libroCon(ejemplares: [ejemplarCon()]),
        ],
        lectores: [lectorCon()],
        reservas: [
          Reserva(
            id: 'res-1',
            lectorId: 'lec-1',
            libroId: 'lib-1',
            fechaReserva: ahora.subtract(const Duration(hours: 2)),
            fechaVencimientoRetiro: ahora.add(const Duration(hours: 40)),
            estado: EstadoReserva.lista,
            plazoRetiroHorasAlReservar: 48,
          ),
        ],
      );

      expect(
        evaluador
            .decidir(estado)
            .where((d) => d.tipo == TipoDecision.asignarReservaAlSiguiente),
        isEmpty,
        reason: 'el ejemplar ya está comprometido con el primero de la cola',
      );
    });
  });

  group('Decisiones sobre lectores', () {
    test('una multa impaga genera una alerta para el bibliotecario', () {
      final estado = estadoCon(lectores: [lectorCon(multas: 1500)]);

      final alerta = evaluador.decidir(estado).singleWhere(
            (d) => d.tipo == TipoDecision.alertarMultaPendiente,
          );
      expect(alerta.motivo, contains(r'$1500'));
    });

    test('un menor que ya cumplió 18 se propone para revisión de categoría',
        () {
      final estado = estadoCon(
        lectores: [
          lectorCon(
            categoria: CategoriaLector.menor,
            nacimiento: DateTime(2005, 1, 1),
          ),
        ],
      );

      final sugerencia = evaluador.decidir(estado).singleWhere(
            (d) => d.tipo == TipoDecision.sugerirRevisionCategoria,
          );
      expect(sugerencia.motivo, contains('corresponde Adulto'));
      expect(sugerencia.motivo, contains('conservan sus condiciones'),
          reason: 'el aviso aclara que no toca los préstamos vigentes');
    });

    test('docente y senior nunca se derivan de la edad', () {
      final estado = estadoCon(
        lectores: [
          lectorCon(
            categoria: CategoriaLector.docente,
            nacimiento: DateTime(2005, 1, 1),
          ),
        ],
      );

      expect(
        evaluador
            .decidir(estado)
            .where((d) => d.tipo == TipoDecision.sugerirRevisionCategoria),
        isEmpty,
        reason: 'son asignaciones administrativas, no etarias',
      );
    });
  });

  group('Recomendaciones', () {
    test('sin historial suficiente, se recomienda por popularidad general', () {
      final estado = estadoCon(
        libros: [
          libroCon(id: 'lib-1', ejemplares: [ejemplarCon()]),
          libroCon(id: 'lib-2'),
        ],
        lectores: [lectorCon()],
      );

      final recomendaciones = evaluador.recomendarPara(estado, 'lec-1');

      expect(recomendaciones, isNotEmpty);
      expect(recomendaciones.every((r) => r.esColdStart), isTrue);
    });

    test('no se recomienda un título que el lector ya tiene prestado', () {
      final estado = estadoCon(
        libros: [libroCon(id: 'lib-1'), libroCon(id: 'lib-2')],
        lectores: [lectorCon()],
        prestamos: [
          prestamoCon(vencimiento: ahora.add(const Duration(days: 10))),
        ],
      );

      final recomendaciones = evaluador.recomendarPara(estado, 'lec-1');
      expect(recomendaciones.map((r) => r.libro.id), isNot(contains('lib-1')));
    });

    test('los libros sin validar nunca se recomiendan', () {
      final estado = estadoCon(
        libros: [libroCon(id: 'lib-1', validado: false)],
        lectores: [lectorCon()],
      );

      expect(evaluador.recomendarPara(estado, 'lec-1'), isEmpty);
    });
  });
}
