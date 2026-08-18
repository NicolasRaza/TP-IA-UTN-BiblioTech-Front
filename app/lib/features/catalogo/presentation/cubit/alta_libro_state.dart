part of 'alta_libro_cubit.dart';

class AltaLibroState extends Equatable {
  const AltaLibroState({
    this.estado = EstadoCarga.inicial,
    this.ficha,
    this.sugeridos = const {},
    this.guardando = false,
    this.mensajeError,
    this.mensajeExito,
  });

  final EstadoCarga estado;

  /// Ficha propuesta por el Agente Analizador, o `null` si todavía no se
  /// analizó ningún texto.
  final FichaSugerida? ficha;

  /// Valores originalmente sugeridos, para detectar qué corrigió la persona.
  final Map<String, String> sugeridos;

  final bool guardando;
  final String? mensajeError;
  final String? mensajeExito;

  bool get hayFicha => ficha != null;

  /// Campos que el bibliotecario debería mirar antes de aprobar.
  List<String> get camposARevisar => ficha?.camposARevisar ?? const [];

  AltaLibroState copyWith({
    EstadoCarga? estado,
    FichaSugerida? ficha,
    Map<String, String>? sugeridos,
    bool? guardando,
    String? mensajeError,
    String? mensajeExito,
    bool limpiarMensajes = false,
  }) =>
      AltaLibroState(
        estado: estado ?? this.estado,
        ficha: ficha ?? this.ficha,
        sugeridos: sugeridos ?? this.sugeridos,
        guardando: guardando ?? this.guardando,
        mensajeError: limpiarMensajes ? null : mensajeError,
        mensajeExito: limpiarMensajes ? null : mensajeExito,
      );

  @override
  List<Object?> get props =>
      [estado, ficha, sugeridos, guardando, mensajeError, mensajeExito];
}
