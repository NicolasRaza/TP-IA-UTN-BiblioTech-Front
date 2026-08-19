/// Traducción entre el vocabulario del backend y el del dominio de la app.
///
/// Los dos modelos nacieron por separado y no coinciden campo a campo. En vez
/// de repartir los `switch` de conversión por los datasources, viven todos
/// acá, con la pérdida de información de cada uno documentada: si mañana el
/// backend agrega una categoría, este archivo es el único que hay que tocar.
library;

import '../../features/catalogo/domain/entities/ejemplar.dart';
import '../../features/lectores/domain/entities/lector.dart';
import '../../features/prestamos/domain/entities/prestamo.dart';
import '../../features/reservas/domain/entities/reserva.dart';

// ── Categoría de lector ──────────────────────────────────────────────────────
//
// Las dos escalas no son biyectivas:
//   · `infantil` y `adolescente` colapsan en `menor`, que es la única
//     distinción que usan las reglas de la spec §7 (plazo y límite reducidos).
//   · `senior` no existe en el backend y viaja como `adulto`, que es la
//     categoría con la que el backend le calcularía el plazo de todos modos.
// Por eso ida y vuelta no siempre devuelve el mismo código: la conversión es
// de significado, no de identidad.

CategoriaLector categoriaDesdeApi(String? code) => switch (code) {
      'infantil' || 'adolescente' => CategoriaLector.menor,
      'docente' => CategoriaLector.docente,
      'institucional' => CategoriaLector.personal,
      _ => CategoriaLector.adulto,
    };

String categoriaHaciaApi(CategoriaLector categoria) => switch (categoria) {
      CategoriaLector.menor => 'infantil',
      CategoriaLector.docente => 'docente',
      CategoriaLector.personal => 'institucional',
      CategoriaLector.adulto || CategoriaLector.senior => 'adulto',
    };

// ── Estado del lector ────────────────────────────────────────────────────────
//
// El backend distingue `suspendido` de `baja`; el dominio sólo tiene un
// booleano `activo`. Ambos estados dejan al lector sin operar, que es lo que
// el booleano representa.

bool lectorActivoDesdeApi(String? estado) => estado == 'activo';

// ── Rol ──────────────────────────────────────────────────────────────────────

RolUsuario rolDesdeApi(String? code) => switch (code) {
      'bibliotecario' => RolUsuario.bibliotecario,
      'administrador' => RolUsuario.administrador,
      _ => RolUsuario.lector,
    };

// ── Ejemplar ─────────────────────────────────────────────────────────────────

EstadoEjemplar estadoEjemplarDesdeApi(String? code) => switch (code) {
      'prestado' => EstadoEjemplar.prestado,
      'reservado' => EstadoEjemplar.reservado,
      'baja' => EstadoEjemplar.baja,
      _ => EstadoEjemplar.disponible,
    };

/// El backend tiene cuatro condiciones y el dominio tres: `nuevo` y `bueno`
/// comparten significado operativo para el mostrador.
CondicionEjemplar condicionDesdeApi(String? code) => switch (code) {
      'regular' => CondicionEjemplar.regular,
      'deteriorado' => CondicionEjemplar.malo,
      _ => CondicionEjemplar.bueno,
    };

String condicionHaciaApi(CondicionEjemplar condicion) => switch (condicion) {
      CondicionEjemplar.bueno => 'bueno',
      CondicionEjemplar.regular => 'regular',
      CondicionEjemplar.malo => 'deteriorado',
    };

// ── Circulación ──────────────────────────────────────────────────────────────

EstadoPrestamo estadoPrestamoDesdeApi(String? code) => switch (code) {
      'devuelto' => EstadoPrestamo.devuelto,
      'vencido' => EstadoPrestamo.vencido,
      _ => EstadoPrestamo.activo,
    };

EstadoReserva estadoReservaDesdeApi(String? code) => switch (code) {
      'disponible_para_retiro' => EstadoReserva.lista,
      'retirada' => EstadoReserva.completada,
      'cancelada' => EstadoReserva.cancelada,
      'vencida' => EstadoReserva.vencida,
      _ => EstadoReserva.pendiente,
    };

// ── Tipos primitivos ─────────────────────────────────────────────────────────

/// Los ids del backend son enteros y los del dominio texto. La conversión es
/// en un solo sentido seguro: `'12'` vuelve como `12`, y cualquier otra cosa
/// —un id local `lib-abc` de la semilla— no es un id del backend.
int? idHaciaApi(String id) => int.tryParse(id);

String idDesdeApi(Object? valor) => '${(valor as num).toInt()}';

DateTime fechaDesdeApi(Object? valor, DateTime porDefecto) {
  if (valor is! String || valor.isEmpty) return porDefecto;
  return DateTime.tryParse(valor) ?? porDefecto;
}

DateTime? fechaOpcionalDesdeApi(Object? valor) {
  if (valor is! String || valor.isEmpty) return null;
  return DateTime.tryParse(valor);
}

/// `YYYY-MM-DD`, que es como FastAPI parsea un campo `date`.
String fechaHaciaApi(DateTime fecha) =>
    '${fecha.year.toString().padLeft(4, '0')}-'
    '${fecha.month.toString().padLeft(2, '0')}-'
    '${fecha.day.toString().padLeft(2, '0')}';
