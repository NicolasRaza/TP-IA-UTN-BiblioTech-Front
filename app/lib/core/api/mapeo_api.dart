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

/// Los mapas `categoría -> número` de la configuración, en el vocabulario del
/// backend.
///
/// Arrastran la misma pérdida que [categoriaHaciaApi] y por el mismo motivo:
/// `menor` se abre en las dos categorías que el backend distingue y `senior`
/// viaja como `adulto`, que es la categoría con la que el servidor le
/// calcularía el plazo de todos modos. Ida y vuelta no devuelve el mismo mapa;
/// devuelve el mismo significado.
Map<String, int> mapaPorCategoriaHaciaApi(Map<CategoriaLector, int> mapa) {
  int valor(CategoriaLector c) => mapa[c] ?? mapa[CategoriaLector.adulto] ?? 0;
  return {
    'infantil': valor(CategoriaLector.menor),
    'adolescente': valor(CategoriaLector.menor),
    'adulto': valor(CategoriaLector.adulto),
    'docente': valor(CategoriaLector.docente),
    'institucional': valor(CategoriaLector.personal),
  };
}

Map<CategoriaLector, int> mapaPorCategoriaDesdeApi(
  Object? json,
  Map<CategoriaLector, int> porDefecto,
) {
  if (json is! Map) return porDefecto;

  int? leer(String clave) => (json[clave] as num?)?.toInt();
  final adulto = leer('adulto') ?? porDefecto[CategoriaLector.adulto]!;

  return {
    CategoriaLector.menor: leer('infantil') ??
        leer('adolescente') ??
        porDefecto[CategoriaLector.menor]!,
    CategoriaLector.adulto: adulto,
    CategoriaLector.docente:
        leer('docente') ?? porDefecto[CategoriaLector.docente]!,
    // El backend no tiene `senior`: se le aplica lo mismo que a un adulto.
    CategoriaLector.senior: adulto,
    CategoriaLector.personal:
        leer('institucional') ?? porDefecto[CategoriaLector.personal]!,
  };
}

// ── Estado del lector ────────────────────────────────────────────────────────
//
// Las dos escalas coinciden código a código —`pendiente`, `activo`,
// `suspendido`, `baja`—, así que la conversión es directa. Un código que el
// backend agregue y la app no conozca se lee como `activo`, que es el estado
// que no bloquea nada: inventar una suspensión sería peor que ignorarla.

EstadoLector estadoLectorDesdeApi(String? estado) =>
    EstadoLector.fromCode(estado);

String estadoLectorHaciaApi(EstadoLector estado) => estado.code;

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
