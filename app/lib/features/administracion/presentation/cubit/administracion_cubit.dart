import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/presentation/estado_carga.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../agentes/domain/services/agente_aprendizaje.dart';
import '../../../agentes/domain/services/agente_evaluador.dart';
import '../../../agentes/domain/usecases/consultas_agentes.dart';
import '../../../lectores/domain/entities/lector.dart';
import '../../../lectores/domain/usecases/gestionar_lectores.dart';
import '../../../prestamos/domain/entities/prestamo.dart';
import '../../../prestamos/domain/usecases/consultas_prestamos.dart';
import '../../domain/entities/configuracion_biblioteca.dart';
import '../../domain/entities/evento_auditoria.dart';
import '../../domain/usecases/gestionar_configuracion.dart';

part 'administracion_state.dart';

/// Panel del administrador: parámetros, auditoría, indicadores y reinicio.
class AdministracionCubit extends Cubit<AdministracionState> {
  AdministracionCubit({
    required ObtenerConfiguracion obtenerConfiguracion,
    required GuardarConfiguracion guardarConfiguracion,
    required ObtenerAuditoria obtenerAuditoria,
    required ObtenerIndicadores obtenerIndicadores,
    required ObtenerSugerencias obtenerSugerencias,
    required ObtenerReporteAprendizaje obtenerReporteAprendizaje,
    required ObtenerEstadisticasPrestamos obtenerEstadisticas,
    required ObtenerUsuarios obtenerUsuarios,
    required String? Function() usuarioActualId,
  })  : _obtenerConfiguracion = obtenerConfiguracion,
        _guardarConfiguracion = guardarConfiguracion,
        _obtenerAuditoria = obtenerAuditoria,
        _obtenerIndicadores = obtenerIndicadores,
        _obtenerSugerencias = obtenerSugerencias,
        _obtenerReporte = obtenerReporteAprendizaje,
        _obtenerEstadisticas = obtenerEstadisticas,
        _obtenerUsuarios = obtenerUsuarios,
        _usuarioActualId = usuarioActualId,
        super(const AdministracionState());

  final ObtenerConfiguracion _obtenerConfiguracion;
  final GuardarConfiguracion _guardarConfiguracion;
  final ObtenerAuditoria _obtenerAuditoria;
  final ObtenerIndicadores _obtenerIndicadores;
  final ObtenerSugerencias _obtenerSugerencias;
  final ObtenerReporteAprendizaje _obtenerReporte;
  final ObtenerEstadisticasPrestamos _obtenerEstadisticas;
  final ObtenerUsuarios _obtenerUsuarios;
  final String? Function() _usuarioActualId;

  Future<void> cargar() async {
    emit(state.copyWith(estado: EstadoCarga.cargando, limpiarMensajes: true));
    await _recargar();
  }

  Future<void> guardarConfiguracion(
      ConfiguracionBiblioteca configuracion) async {
    final resultado = await _guardarConfiguracion(GuardarConfiguracionParams(
      configuracion: configuracion,
      usuarioId: _usuarioActualId(),
    ));

    await resultado.fold(
      (failure) async => emit(state.copyWith(mensajeError: failure.mensaje)),
      (cfg) async {
        await _recargar();
        emit(state.copyWith(mensajeExito: 'Parámetros guardados'));
      },
    );
  }

  void limpiarMensajes() => emit(state.copyWith(limpiarMensajes: true));

  Future<void> _recargar() async {
    final configuracion = await _obtenerConfiguracion(const SinParametros());
    final auditoria = await _obtenerAuditoria(const SinParametros());
    final indicadores = await _obtenerIndicadores(const SinParametros());
    final sugerencias = await _obtenerSugerencias(const SinParametros());
    final reporte = await _obtenerReporte(const SinParametros());
    final estadisticas = await _obtenerEstadisticas(const SinParametros());
    final usuarios = await _obtenerUsuarios(const SinParametros());

    configuracion.fold(
      (failure) => emit(state.copyWith(
        estado: EstadoCarga.error,
        mensajeError: failure.mensaje,
      )),
      (cfg) => emit(state.copyWith(
        estado: EstadoCarga.exito,
        configuracion: cfg,
        auditoria: auditoria.valorONull ?? const [],
        indicadores: indicadores.valorONull,
        sugerencias: sugerencias.valorONull ?? const [],
        reporteAprendizaje: reporte.valorONull,
        estadisticas: estadisticas.valorONull,
        usuarios: usuarios.valorONull ?? const [],
      )),
    );
  }
}
