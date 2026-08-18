import '../../../../core/error/result.dart';
import '../entities/lector.dart';

/// Contrato de acceso al padrón de personas.
abstract interface class LectorRepository {
  /// Todas las personas registradas, incluido el personal.
  Future<Result<List<Lector>>> obtenerUsuarios();

  /// Sólo los lectores: excluye bibliotecarios y administradores.
  Future<Result<List<Lector>>> obtenerLectores();

  Future<Result<Lector>> obtenerPorId(String lectorId);

  Future<Result<Lector>> obtenerPorEmail(String email);

  Future<Result<Lector>> obtenerPorQr(String qr);

  Future<Result<Lector>> crear(Lector lector);

  Future<Result<Lector>> actualizar(Lector lector);

  /// Suma (o resta, con un delta negativo) al saldo de multas del lector.
  ///
  /// Es una operación aparte de [actualizar] porque el importe se acumula:
  /// leerlo, sumarle y reescribirlo desde otro feature abriría una condición
  /// de carrera sobre el saldo.
  Future<Result<Lector>> ajustarMultas(String lectorId, int delta);
}
