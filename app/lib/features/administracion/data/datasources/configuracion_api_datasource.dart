import '../../../../core/api/cliente_api.dart';
import '../../../../core/api/mapeo_api.dart';
import '../../../../core/error/result.dart';
import '../../domain/entities/configuracion_biblioteca.dart';

/// Acceso a los parámetros de la biblioteca (`/api/v1/configuracion`).
///
/// La lectura la puede hacer cualquier rol —son los plazos y límites con los
/// que la app explica por qué una operación se permite o se niega—; la
/// escritura es del administrador.
abstract interface class ConfiguracionApiDataSource {
  Future<Result<ConfiguracionBiblioteca>> obtener();

  Future<Result<ConfiguracionBiblioteca>> guardar(ConfiguracionBiblioteca cfg);
}

class ConfiguracionApiDataSourceHttp implements ConfiguracionApiDataSource {
  const ConfiguracionApiDataSourceHttp(this._api);

  final ClienteApi _api;

  @override
  Future<Result<ConfiguracionBiblioteca>> obtener() =>
      _api.get<ConfiguracionBiblioteca>(
        '/api/v1/configuracion',
        leer: _leerConfiguracion,
      );

  @override
  Future<Result<ConfiguracionBiblioteca>> guardar(
    ConfiguracionBiblioteca cfg,
  ) =>
      // `PUT` y no `PATCH`: la configuración se guarda entera desde el
      // formulario, así que mandar sólo lo que cambió abriría la puerta a que
      // dos administradores se pisen sin darse cuenta.
      _api.put<ConfiguracionBiblioteca>(
        '/api/v1/configuracion',
        cuerpo: {
          'plazo_prestamo_dias':
              mapaPorCategoriaHaciaApi(cfg.plazoPrestamoDias),
          'limite_ejemplares': mapaPorCategoriaHaciaApi(cfg.limiteEjemplares),
          'limite_reservas': mapaPorCategoriaHaciaApi(cfg.limiteReservas),
          'plazo_retiro_reserva_horas': cfg.plazoRetiroReservaHoras,
          'multa_por_dia_demora': cfg.multaPorDiaDemora,
          'recordatorio_antes_dias': cfg.recordatorioAntesDias,
          'peso_historial_recomendacion': cfg.pesoHistorialRecomendacion,
          'min_prestamos_para_historial': cfg.minPrestamosParaHistorial,
          'edad_mayoria_edad': cfg.edadMayoriaEdad,
        },
        leer: _leerConfiguracion,
      );

  static ConfiguracionBiblioteca _leerConfiguracion(Object? json) {
    final mapa = json as Map<String, dynamic>;
    // Los valores por defecto de la entidad son los de la spec §3: si el
    // backend deja de informar un parámetro, la app sigue aplicando el que la
    // spec fija en vez de un cero que negaría toda operación.
    const porDefecto = ConfiguracionBiblioteca();

    return ConfiguracionBiblioteca(
      plazoPrestamoDias: mapaPorCategoriaDesdeApi(
          mapa['plazo_prestamo_dias'], porDefecto.plazoPrestamoDias),
      limiteEjemplares: mapaPorCategoriaDesdeApi(
          mapa['limite_ejemplares'], porDefecto.limiteEjemplares),
      limiteReservas: mapaPorCategoriaDesdeApi(
          mapa['limite_reservas'], porDefecto.limiteReservas),
      plazoRetiroReservaHoras:
          (mapa['plazo_retiro_reserva_horas'] as num?)?.toInt() ??
              porDefecto.plazoRetiroReservaHoras,
      multaPorDiaDemora: (mapa['multa_por_dia_demora'] as num?)?.toInt() ??
          porDefecto.multaPorDiaDemora,
      recordatorioAntesDias:
          (mapa['recordatorio_antes_dias'] as num?)?.toInt() ??
              porDefecto.recordatorioAntesDias,
      pesoHistorialRecomendacion:
          (mapa['peso_historial_recomendacion'] as num?)?.toDouble() ??
              porDefecto.pesoHistorialRecomendacion,
      minPrestamosParaHistorial:
          (mapa['min_prestamos_para_historial'] as num?)?.toInt() ??
              porDefecto.minPrestamosParaHistorial,
      edadMayoriaEdad: (mapa['edad_mayoria_edad'] as num?)?.toInt() ??
          porDefecto.edadMayoriaEdad,
    );
  }
}
