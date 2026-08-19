import '../../../../core/error/result.dart';
import '../entities/recomendacion.dart';

/// Puerto para las recomendaciones que calcula el backend.
///
/// Existe por una razón de permisos, no de comodidad: el motor local necesita
/// ver el catálogo, el padrón y **toda** la circulación para ponderar historial
/// contra popularidad, y el backend no le deja ver nada de eso a un lector
/// —`/lectores`, `/prestamos` y `/reservas` piden rol bibliotecario—. El
/// servidor, en cambio, expone `GET /recomendaciones`, que corre la misma
/// ponderación de la spec §2 (70/30, cold start con 5 préstamos o menos) sobre
/// datos que sí puede leer entero.
///
/// Cuando está registrado, `ObtenerRecomendaciones` delega acá.
abstract interface class RecomendacionRemota {
  Future<Result<List<Recomendacion>>> para(String lectorId, {int limite});
}
