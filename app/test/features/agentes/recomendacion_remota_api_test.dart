import 'dart:convert';

import 'package:bibliotech/core/api/cliente_api.dart';
import 'package:bibliotech/core/error/failures.dart';
import 'package:bibliotech/core/error/result.dart';
import 'package:bibliotech/features/agentes/data/repositories/recomendacion_remota_api.dart';
import 'package:bibliotech/features/prestamos/domain/entities/prestamo.dart';
import 'package:bibliotech/features/prestamos/domain/repositories/prestamo_repository.dart';
import 'package:bibliotech/features/lectores/domain/entities/lector.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// `GET /api/v1/recomendaciones`.
///
/// Las recomendaciones las calcula el servidor por una razón de permisos: el
/// motor local necesita ver toda la circulación para ponderar popularidad, y
/// el backend no se la muestra a un lector.
void main() {
  /// El endpoint no devuelve un `TituloResponse` sino el shape con el que
  /// trabajan los agentes del backend, que ya usa el vocabulario del dominio.
  List<Map<String, Object?>> librosJson(int cantidad) => [
        for (var i = 1; i <= cantidad; i++)
          {
            'id': '$i',
            'titulo': 'Libro $i',
            'autor': 'Autora $i',
            'editorial': 'Editorial',
            'anio': '1999',
            'isbn': '',
            'sinopsis': '',
            'genero': 'Novela',
            'paginas': '200',
            'portada': '',
            'validado': true,
            'fechaAlta': '2026-02-01T10:00:00',
            'ejemplares': <Object?>[],
          },
      ];

  RecomendacionRemotaApi construir({
    required List<Map<String, Object?>> libros,
    required int prestamosDelLector,
  }) =>
      RecomendacionRemotaApi(
        api: ClienteApi(
          baseUrl: 'https://backend.test',
          token: () => 'jwt',
          cliente: MockClient(
            (_) async => http.Response(jsonEncode(libros), 200),
          ),
        ),
        prestamos: _HistorialDe(prestamosDelLector),
      );

  test('traduce los libros del motor del servidor', () async {
    final recomendaciones = (await construir(
      libros: librosJson(3),
      prestamosDelLector: 10,
    ).para('3'))
        .valorONull!;

    expect(recomendaciones, hasLength(3));
    expect(recomendaciones.first.libro.titulo, 'Libro 1');
    expect(recomendaciones.first.libro.autor, 'Autora 1');
    expect(recomendaciones.first.libro.anio, 1999);
  });

  test('respeta el orden del servidor y el límite pedido', () async {
    final recomendaciones = (await construir(
      libros: librosJson(8),
      prestamosDelLector: 10,
    ).para('3', limite: 4))
        .valorONull!;

    expect(recomendaciones, hasLength(4));
    expect(recomendaciones.map((r) => r.libro.id), ['1', '2', '3', '4']);
    // El puntaje sale de la posición: el servidor no lo publica.
    expect(recomendaciones.first.puntaje,
        greaterThan(recomendaciones.last.puntaje));
  });

  test('con historial corto avisa que es cold start', () async {
    // El umbral es el mismo que usa el backend: 5 préstamos o menos.
    final recomendaciones = (await construir(
      libros: librosJson(2),
      prestamosDelLector: RecomendacionRemotaApi.umbralColdStart,
    ).para('3'))
        .valorONull!;

    expect(recomendaciones.every((r) => r.esColdStart), isTrue);
    expect(recomendaciones.first.motivo, contains('más pedido'));
  });

  test('con historial suficiente la recomendación deja de ser cold start',
      () async {
    final recomendaciones = (await construir(
      libros: librosJson(2),
      prestamosDelLector: RecomendacionRemotaApi.umbralColdStart + 1,
    ).para('3'))
        .valorONull!;

    expect(recomendaciones.every((r) => r.esColdStart), isFalse);
    expect(recomendaciones.first.motivo, contains('venís leyendo'));
  });

  test('si el historial no se puede leer igual hay recomendaciones', () async {
    // Perder la advertencia de cold start es mejor que dejar la pantalla vacía.
    final recomendaciones = (await RecomendacionRemotaApi(
      api: ClienteApi(
        baseUrl: 'https://backend.test',
        token: () => 'jwt',
        cliente: MockClient(
          (_) async => http.Response(jsonEncode(librosJson(2)), 200),
        ),
      ),
      prestamos: _HistorialQueFalla(),
    ).para('3'))
        .valorONull!;

    expect(recomendaciones, hasLength(2));
  });
}

class _HistorialDe implements PrestamoRepository {
  _HistorialDe(this.cantidad);
  final int cantidad;

  @override
  Future<Result<List<Prestamo>>> obtenerDeLector(String lectorId) async =>
      Exito(List.generate(
        cantidad,
        (i) => Prestamo(
          id: '$i',
          lectorId: lectorId,
          ejemplarId: '$i',
          libroId: '$i',
          fechaPrestamo: DateTime(2026),
          fechaVencimiento: DateTime(2026, 1, 15),
          estado: EstadoPrestamo.devuelto,
          categoriaAlPrestar: CategoriaLector.adulto,
          plazoDiasAlPrestar: 14,
        ),
      ));

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _HistorialQueFalla implements PrestamoRepository {
  @override
  Future<Result<List<Prestamo>>> obtenerDeLector(String lectorId) async =>
      const Fallo(RedFailure());

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
