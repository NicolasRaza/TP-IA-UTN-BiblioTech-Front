import '../../../../core/api/cliente_api.dart';
import '../../../../core/api/mapeo_api.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/error/result.dart';
import '../../domain/entities/reserva.dart';

/// Acceso a las reservas del backend SGB (`/api/v1/reservas`).
///
/// La reserva la crea el propio lector autenticado: el backend resuelve a qué
/// ficha corresponde el JWT, así que el cuerpo sólo lleva el título. La
/// posición en la cola también la asigna el servidor.
abstract interface class ReservaApiDataSource {
  /// `POST /reservas` — reserva del lector dueño de la sesión.
  Future<Result<Reserva>> reservar(String libroId);

  /// `DELETE /reservas/{id}`.
  Future<Result<void>> cancelar(String reservaId);

  /// `GET /reservas/lector/{id}` — sólo las activas: en cola o retenidas.
  Future<Result<List<Reserva>>> deLector(String lectorId);

  /// `GET /reservas` — todas, en cualquier estado. Pide rol bibliotecario.
  Future<Result<List<Reserva>>> todas();
}

class ReservaApiDataSourceHttp implements ReservaApiDataSource {
  const ReservaApiDataSourceHttp(this._api);

  final ClienteApi _api;

  @override
  Future<Result<Reserva>> reservar(String libroId) {
    final id = idHaciaApi(libroId);
    if (id == null) {
      return Future.value(const Fallo(
        NoEncontradoFailure('Ese título no existe en el servidor'),
      ));
    }
    return _api.post<Reserva>(
      '/api/v1/reservas',
      cuerpo: {'titulo_id': id},
      leer: (json) => reservaDesdeApi(json as Map<String, dynamic>),
    );
  }

  @override
  Future<Result<void>> cancelar(String reservaId) {
    final id = idHaciaApi(reservaId);
    if (id == null) {
      return Future.value(const Fallo(
        NoEncontradoFailure('Esa reserva no existe en el servidor'),
      ));
    }
    return _api.delete<void>('/api/v1/reservas/$id', leer: (_) {});
  }

  @override
  Future<Result<List<Reserva>>> deLector(String lectorId) {
    final id = idHaciaApi(lectorId);
    if (id == null) return Future.value(const Exito([]));
    return _api.get<List<Reserva>>(
      '/api/v1/reservas/lector/$id',
      leer: _leerLista,
    );
  }

  @override
  Future<Result<List<Reserva>>> todas() =>
      _api.get<List<Reserva>>('/api/v1/reservas', leer: _leerLista);

  static List<Reserva> _leerLista(Object? json) =>
      (json as List<Object?>? ?? const [])
          .map((e) => reservaDesdeApi(e as Map<String, dynamic>))
          .toList();
}

/// Traduce un `ReservaResponse` del backend.
///
/// `ejemplarAsignadoId` queda en `null`: el backend retiene el título, no un
/// ejemplar puntual, y su respuesta no nombra ninguno. El plazo de retiro se
/// deriva de las dos fechas que sí devuelve cuando la reserva ya está
/// disponible; mientras está en cola todavía no hay plazo corriendo y se usa
/// el que fija la configuración del servidor (48 hs).
Reserva reservaDesdeApi(Map<String, dynamic> json) {
  final solicitud = fechaDesdeApi(json['fecha_solicitud'], DateTime.now());
  final disponible = fechaOpcionalDesdeApi(json['fecha_disponible']);
  final limite = fechaOpcionalDesdeApi(json['fecha_limite_retiro']);

  return Reserva(
    id: idDesdeApi(json['id']),
    lectorId: idDesdeApi(json['lector_id']),
    libroId: idDesdeApi(json['titulo_id']),
    fechaReserva: solicitud,
    fechaVencimientoRetiro: limite,
    estado: estadoReservaDesdeApi(json['estado'] as String?),
    plazoRetiroHorasAlReservar: disponible != null && limite != null
        ? limite.difference(disponible).inHours
        : horasDeRetiroPorDefecto,
  );
}

/// `HORAS_RESERVA_DISPONIBLE` del backend, que es también el valor de la
/// spec v2 §7.
const horasDeRetiroPorDefecto = 48;
