/// Fase en la que está una operación asincrónica de la UI.
///
/// Todos los estados de bloc de la app la usan, para que las pantallas
/// resuelvan spinner / contenido / error siempre de la misma manera.
enum EstadoCarga {
  inicial,
  cargando,
  exito,
  error;

  bool get esInicial => this == EstadoCarga.inicial;
  bool get estaCargando => this == EstadoCarga.cargando;
  bool get esExito => this == EstadoCarga.exito;
  bool get esError => this == EstadoCarga.error;

  /// `true` mientras no haya nada que mostrar todavía.
  bool get sinDatosAun =>
      this == EstadoCarga.inicial || this == EstadoCarga.cargando;
}
