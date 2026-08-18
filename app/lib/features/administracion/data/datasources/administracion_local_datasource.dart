import '../../../../core/error/result.dart';
import '../../../../core/storage/coleccion_json.dart';
import '../../../../core/storage/key_value_store.dart';
import '../../domain/entities/configuracion_biblioteca.dart';
import '../../domain/entities/evento_auditoria.dart';
import '../models/configuracion_biblioteca_model.dart';
import '../models/evento_auditoria_model.dart';

/// Acceso al almacenamiento local de los parámetros y la auditoría.
abstract interface class AdministracionLocalDataSource {
  Result<ConfiguracionBiblioteca> leerConfiguracion();
  Result<void> guardarConfiguracion(ConfiguracionBiblioteca configuracion);

  Result<List<EventoAuditoriaModel>> leerAuditoria();
  Result<void> guardarAuditoria(List<EventoAuditoria> eventos);
}

class AdministracionLocalDataSourceImpl
    implements AdministracionLocalDataSource {
  AdministracionLocalDataSourceImpl(KeyValueStore store)
      : _configuracion = DocumentoJson<ConfiguracionBibliotecaModel>(
          store: store,
          clave: ClavesAlmacenamiento.config,
          desdeJson: ConfiguracionBibliotecaModel.fromJson,
          aJson: (c) => c.toJson(),
        ),
        _auditoria = ColeccionJson<EventoAuditoriaModel>(
          store: store,
          clave: ClavesAlmacenamiento.auditoria,
          desdeJson: EventoAuditoriaModel.fromJson,
          aJson: (e) => e.toJson(),
        );

  final DocumentoJson<ConfiguracionBibliotecaModel> _configuracion;
  final ColeccionJson<EventoAuditoriaModel> _auditoria;

  @override
  Result<ConfiguracionBiblioteca> leerConfiguracion() =>
      _configuracion.leer(const ConfiguracionBibliotecaModel());

  @override
  Result<void> guardarConfiguracion(ConfiguracionBiblioteca configuracion) =>
      _configuracion
          .escribir(ConfiguracionBibliotecaModel.fromEntity(configuracion));

  @override
  Result<List<EventoAuditoriaModel>> leerAuditoria() => _auditoria.leer();

  @override
  Result<void> guardarAuditoria(List<EventoAuditoria> eventos) => _auditoria
      .escribir(eventos.map(EventoAuditoriaModel.fromEntity).toList());
}
