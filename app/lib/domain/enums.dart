/// Enumeraciones del dominio.
///
/// Cada enum expone `code`, que es el valor que viaja a la capa de
/// persistencia. Se mantienen los mismos literales que usaba el prototipo
/// HTML/JS para que los datos guardados sigan siendo legibles.
library;

enum RolUsuario {
  lector('lector'),
  bibliotecario('bibliotecario'),
  administrador('administrador');

  const RolUsuario(this.code);
  final String code;

  static RolUsuario fromCode(String? code) => RolUsuario.values.firstWhere(
        (r) => r.code == code,
        orElse: () => RolUsuario.lector,
      );
}

/// Categoría de lector. Determina plazos y límites (spec v2 §7).
enum CategoriaLector {
  menor('menor', 'Menor'),
  adulto('adulto', 'Adulto'),
  docente('docente', 'Docente'),
  senior('senior', 'Senior'),
  personal('personal', 'Personal');

  const CategoriaLector(this.code, this.label);
  final String code;
  final String label;

  static CategoriaLector fromCode(String? code) =>
      CategoriaLector.values.firstWhere(
        (c) => c.code == code,
        orElse: () => CategoriaLector.adulto,
      );
}

enum EstadoEjemplar {
  disponible('disponible', 'Disponible'),
  prestado('prestado', 'Prestado'),
  reservado('reservado', 'Reservado'),
  baja('baja', 'De baja');

  const EstadoEjemplar(this.code, this.label);
  final String code;
  final String label;

  static EstadoEjemplar fromCode(String? code) =>
      EstadoEjemplar.values.firstWhere(
        (e) => e.code == code,
        orElse: () => EstadoEjemplar.disponible,
      );
}

enum CondicionEjemplar {
  bueno('bueno', 'Bueno'),
  regular('regular', 'Regular'),
  malo('malo', 'Malo');

  const CondicionEjemplar(this.code, this.label);
  final String code;
  final String label;

  static CondicionEjemplar fromCode(String? code) =>
      CondicionEjemplar.values.firstWhere(
        (c) => c.code == code,
        orElse: () => CondicionEjemplar.bueno,
      );
}

enum EstadoPrestamo {
  activo('activo', 'Activo'),
  vencido('vencido', 'Vencido'),
  devuelto('devuelto', 'Devuelto');

  const EstadoPrestamo(this.code, this.label);
  final String code;
  final String label;

  static EstadoPrestamo fromCode(String? code) =>
      EstadoPrestamo.values.firstWhere(
        (e) => e.code == code,
        orElse: () => EstadoPrestamo.activo,
      );
}

enum EstadoReserva {
  /// En cola, esperando que se libere un ejemplar.
  pendiente('pendiente', 'En cola'),

  /// Ejemplar retenido en mostrador, corriendo el plazo de retiro (§7).
  lista('lista', 'Lista para retirar'),

  /// Se convirtió en préstamo.
  completada('completada', 'Completada'),
  cancelada('cancelada', 'Cancelada'),

  /// Venció el plazo de retiro sin que el lector la retirara.
  vencida('vencida', 'Vencida');

  const EstadoReserva(this.code, this.label);
  final String code;
  final String label;

  static EstadoReserva fromCode(String? code) =>
      EstadoReserva.values.firstWhere(
        (e) => e.code == code,
        orElse: () => EstadoReserva.pendiente,
      );

  bool get esActiva =>
      this == EstadoReserva.pendiente || this == EstadoReserva.lista;
}

enum TipoNotificacion {
  vencimientoProximo('vencimiento_proximo', '⏰'),
  prestamoVencido('prestamo_vencido', '🚨'),
  reservaDisponible('reserva_disponible', '🔔'),
  reservaConfirmada('reserva_confirmada', '📚'),
  reservaVencida('reserva_vencida', '⌛'),
  recomendacion('recomendacion', '✨');

  const TipoNotificacion(this.code, this.icono);
  final String code;
  final String icono;

  static TipoNotificacion fromCode(String? code) =>
      TipoNotificacion.values.firstWhere(
        (t) => t.code == code,
        orElse: () => TipoNotificacion.recomendacion,
      );
}

/// Confianza de un campo sugerido por el Agente Analizador.
///
/// La spec v2 §4.2 exige que ningún campo de baja confianza se complete sin
/// quedar marcado como tal, y que un ISBN sin resultados quede `pendiente`.
enum NivelConfianza {
  alta('alta'),
  media('media'),
  baja('baja'),

  /// Sin dato: ninguna fuente externa respondió. Requiere carga manual.
  pendiente('pendiente'),

  /// Dos fuentes discrepan y ninguna tiene autoridad suficiente para desempatar.
  enConflicto('en_conflicto');

  const NivelConfianza(this.code);
  final String code;

  static NivelConfianza fromPorcentaje(int pct) {
    if (pct >= 85) return NivelConfianza.alta;
    if (pct >= 65) return NivelConfianza.media;
    return NivelConfianza.baja;
  }

  /// Un campo necesita intervención explícita del bibliotecario.
  bool get requiereRevision =>
      this == NivelConfianza.baja ||
      this == NivelConfianza.pendiente ||
      this == NivelConfianza.enConflicto;
}

enum TipoEventoAuditoria {
  altaLibro('alta_libro'),
  bajaLibro('baja_libro'),
  edicionLibro('edicion_libro'),
  altaLector('alta_lector'),
  edicionLector('edicion_lector'),
  prestamo('prestamo'),
  devolucion('devolucion'),
  reimpresionQr('reimpresion_qr'),
  correccionOcr('correccion_ocr'),
  cambioCategoria('cambio_categoria'),
  cambioConfig('cambio_config');

  const TipoEventoAuditoria(this.code);
  final String code;

  static TipoEventoAuditoria fromCode(String? code) =>
      TipoEventoAuditoria.values.firstWhere(
        (t) => t.code == code,
        orElse: () => TipoEventoAuditoria.edicionLibro,
      );
}
