import 'enums.dart';

/// Ejemplar físico de un libro.
///
/// El `id` es el identificador interno e inmutable: la spec v2 §7 prohíbe
/// generar uno nuevo al reimprimir la etiqueta, porque eso rompería la
/// trazabilidad del historial de préstamos.
class Ejemplar {
  Ejemplar({
    required this.id,
    required this.libroId,
    required this.condicion,
    required this.estado,
    this.reimpresionesQr = 0,
  });

  final String id;
  final String libroId;
  final CondicionEjemplar condicion;
  final EstadoEjemplar estado;

  /// Cuántas veces se reimprimió la etiqueta. El QR en sí nunca cambia.
  final int reimpresionesQr;

  /// El contenido del QR se deriva del ID interno, nunca se almacena aparte.
  /// Así una reimpresión produce siempre exactamente la misma etiqueta.
  String get qr => 'BT-$libroId-$id';

  bool get estaDisponible => estado == EstadoEjemplar.disponible;

  Ejemplar copyWith({
    CondicionEjemplar? condicion,
    EstadoEjemplar? estado,
    int? reimpresionesQr,
  }) =>
      Ejemplar(
        id: id,
        libroId: libroId,
        condicion: condicion ?? this.condicion,
        estado: estado ?? this.estado,
        reimpresionesQr: reimpresionesQr ?? this.reimpresionesQr,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'libroId': libroId,
        'condicion': condicion.code,
        'estado': estado.code,
        'reimpresionesQr': reimpresionesQr,
      };

  factory Ejemplar.fromJson(Map<String, dynamic> json) => Ejemplar(
        id: json['id'] as String,
        libroId: json['libroId'] as String,
        condicion: CondicionEjemplar.fromCode(json['condicion'] as String?),
        estado: EstadoEjemplar.fromCode(json['estado'] as String?),
        reimpresionesQr: (json['reimpresionesQr'] as num?)?.toInt() ?? 0,
      );
}

class Libro {
  Libro({
    required this.id,
    required this.titulo,
    required this.autor,
    this.editorial = '',
    this.anio,
    this.isbn = '',
    this.sinopsis = '',
    this.genero = '',
    this.paginas,
    this.portada = '',
    this.validado = false,
    required this.fechaAlta,
    this.ejemplares = const [],
    this.camposPendientes = const [],
  });

  final String id;
  final String titulo;
  final String autor;
  final String editorial;
  final int? anio;
  final String isbn;
  final String sinopsis;
  final String genero;
  final int? paginas;
  final String portada;

  /// Regla de Validación Estricta (spec v2 §7): mientras sea `false` el libro
  /// no aparece en el catálogo público, sin importar la confianza de la IA.
  final bool validado;

  final DateTime fechaAlta;
  final List<Ejemplar> ejemplares;

  /// Campos que ninguna fuente externa pudo resolver y que quedaron
  /// marcados para carga manual (spec v2 §4.2).
  final List<String> camposPendientes;

  int get totalEjemplares => ejemplares.length;
  int get ejemplaresDisponibles =>
      ejemplares.where((e) => e.estaDisponible).length;
  bool get hayDisponible => ejemplaresDisponibles > 0;

  String get portadaUrl {
    if (portada.isNotEmpty) return portada;
    if (isbn.isNotEmpty) {
      return 'https://covers.openlibrary.org/b/isbn/$isbn-L.jpg';
    }
    return '';
  }

  Libro copyWith({
    String? titulo,
    String? autor,
    String? editorial,
    int? anio,
    String? isbn,
    String? sinopsis,
    String? genero,
    int? paginas,
    String? portada,
    bool? validado,
    List<Ejemplar>? ejemplares,
    List<String>? camposPendientes,
  }) =>
      Libro(
        id: id,
        titulo: titulo ?? this.titulo,
        autor: autor ?? this.autor,
        editorial: editorial ?? this.editorial,
        anio: anio ?? this.anio,
        isbn: isbn ?? this.isbn,
        sinopsis: sinopsis ?? this.sinopsis,
        genero: genero ?? this.genero,
        paginas: paginas ?? this.paginas,
        portada: portada ?? this.portada,
        validado: validado ?? this.validado,
        fechaAlta: fechaAlta,
        ejemplares: ejemplares ?? this.ejemplares,
        camposPendientes: camposPendientes ?? this.camposPendientes,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'titulo': titulo,
        'autor': autor,
        'editorial': editorial,
        'anio': anio,
        'isbn': isbn,
        'sinopsis': sinopsis,
        'genero': genero,
        'paginas': paginas,
        'portada': portada,
        'validado': validado,
        'fechaAlta': fechaAlta.toIso8601String(),
        'ejemplares': ejemplares.map((e) => e.toJson()).toList(),
        'camposPendientes': camposPendientes,
      };

  factory Libro.fromJson(Map<String, dynamic> json) => Libro(
        id: json['id'] as String,
        titulo: json['titulo'] as String? ?? '',
        autor: json['autor'] as String? ?? '',
        editorial: json['editorial'] as String? ?? '',
        anio: (json['anio'] as num?)?.toInt(),
        isbn: json['isbn'] as String? ?? '',
        sinopsis: json['sinopsis'] as String? ?? '',
        genero: json['genero'] as String? ?? '',
        paginas: (json['paginas'] as num?)?.toInt(),
        portada: json['portada'] as String? ?? '',
        validado: json['validado'] as bool? ?? false,
        fechaAlta: DateTime.parse(json['fechaAlta'] as String),
        ejemplares: (json['ejemplares'] as List<dynamic>? ?? [])
            .map((e) => Ejemplar.fromJson(e as Map<String, dynamic>))
            .toList(),
        camposPendientes:
            (json['camposPendientes'] as List<dynamic>? ?? []).cast<String>(),
      );
}

class Lector {
  Lector({
    required this.id,
    required this.nombre,
    required this.apellido,
    required this.email,
    this.dni = '',
    this.telefono = '',
    required this.categoria,
    this.tutor,
    required this.fechaAlta,
    this.activo = true,
    this.pin = '',
    this.generosInteres = const [],
    this.multasPendientes = 0,
    this.rol = RolUsuario.lector,
    this.fechaNacimiento,
  });

  final String id;
  final String nombre;
  final String apellido;
  final String email;
  final String dni;
  final String telefono;

  /// Categoría vigente. Los préstamos y reservas ya generados conservan la
  /// categoría con la que nacieron (spec v2 §7), por eso este campo solo
  /// afecta a operaciones nuevas.
  final CategoriaLector categoria;

  /// Requerido para lectores menores de edad.
  final String? tutor;

  final DateTime fechaAlta;
  final bool activo;
  final String pin;
  final List<String> generosInteres;
  final int multasPendientes;
  final RolUsuario rol;
  final DateTime? fechaNacimiento;

  String get nombreCompleto => '$nombre $apellido';
  String get iniciales {
    final n = nombre.isNotEmpty ? nombre[0] : '';
    final a = apellido.isNotEmpty ? apellido[0] : '';
    return '$n$a'.toUpperCase();
  }

  /// El QR del lector también deriva del ID interno e inmutable.
  String get qr => 'BTL-$id';

  bool get esPersonal => rol != RolUsuario.lector;

  Lector copyWith({
    String? nombre,
    String? apellido,
    String? email,
    String? dni,
    String? telefono,
    CategoriaLector? categoria,
    String? tutor,
    bool? activo,
    String? pin,
    List<String>? generosInteres,
    int? multasPendientes,
    DateTime? fechaNacimiento,
  }) =>
      Lector(
        id: id,
        nombre: nombre ?? this.nombre,
        apellido: apellido ?? this.apellido,
        email: email ?? this.email,
        dni: dni ?? this.dni,
        telefono: telefono ?? this.telefono,
        categoria: categoria ?? this.categoria,
        tutor: tutor ?? this.tutor,
        fechaAlta: fechaAlta,
        activo: activo ?? this.activo,
        pin: pin ?? this.pin,
        generosInteres: generosInteres ?? this.generosInteres,
        multasPendientes: multasPendientes ?? this.multasPendientes,
        rol: rol,
        fechaNacimiento: fechaNacimiento ?? this.fechaNacimiento,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'nombre': nombre,
        'apellido': apellido,
        'email': email,
        'dni': dni,
        'telefono': telefono,
        'categoria': categoria.code,
        'tutor': tutor,
        'fechaAlta': fechaAlta.toIso8601String(),
        'activo': activo,
        'pin': pin,
        'generosInteres': generosInteres,
        'multasPendientes': multasPendientes,
        'rol': rol.code,
        'fechaNacimiento': fechaNacimiento?.toIso8601String(),
      };

  factory Lector.fromJson(Map<String, dynamic> json) => Lector(
        id: json['id'] as String,
        nombre: json['nombre'] as String? ?? '',
        apellido: json['apellido'] as String? ?? '',
        email: json['email'] as String? ?? '',
        dni: json['dni'] as String? ?? '',
        telefono: json['telefono'] as String? ?? '',
        categoria: CategoriaLector.fromCode(json['categoria'] as String?),
        tutor: json['tutor'] as String?,
        fechaAlta: DateTime.parse(json['fechaAlta'] as String),
        activo: json['activo'] as bool? ?? true,
        pin: json['pin'] as String? ?? '',
        generosInteres:
            (json['generosInteres'] as List<dynamic>? ?? []).cast<String>(),
        multasPendientes: (json['multasPendientes'] as num?)?.toInt() ?? 0,
        rol: RolUsuario.fromCode(json['rol'] as String?),
        fechaNacimiento: json['fechaNacimiento'] == null
            ? null
            : DateTime.parse(json['fechaNacimiento'] as String),
      );
}

/// Préstamo de un ejemplar a un lector.
///
/// Congela las condiciones vigentes al momento de generarse
/// (`categoriaAlPrestar`, `plazoDiasAlPrestar`) para cumplir la regla de
/// transición de categoría de la spec v2 §7: si el lector cambia de categoría,
/// este préstamo conserva el plazo con el que nació.
class Prestamo {
  Prestamo({
    required this.id,
    required this.lectorId,
    required this.ejemplarId,
    required this.libroId,
    required this.fechaPrestamo,
    required this.fechaVencimiento,
    this.fechaDevolucion,
    required this.estado,
    this.tardio = false,
    required this.categoriaAlPrestar,
    required this.plazoDiasAlPrestar,
    this.multaAplicada = 0,
  });

  final String id;
  final String lectorId;
  final String ejemplarId;
  final String libroId;
  final DateTime fechaPrestamo;
  final DateTime fechaVencimiento;
  final DateTime? fechaDevolucion;
  final EstadoPrestamo estado;
  final bool tardio;
  final CategoriaLector categoriaAlPrestar;
  final int plazoDiasAlPrestar;

  /// Multa ya cargada al lector por este préstamo. Evita cobrar dos veces
  /// el mismo atraso cuando se recalculan los vencimientos.
  final int multaAplicada;

  bool get estaAbierto =>
      estado == EstadoPrestamo.activo || estado == EstadoPrestamo.vencido;

  int diasRestantes(DateTime ahora) =>
      fechaVencimiento.difference(ahora).inDays;

  bool estaVencido(DateTime ahora) =>
      estaAbierto && ahora.isAfter(fechaVencimiento);

  Prestamo copyWith({
    DateTime? fechaVencimiento,
    DateTime? fechaDevolucion,
    EstadoPrestamo? estado,
    bool? tardio,
    int? multaAplicada,
  }) =>
      Prestamo(
        id: id,
        lectorId: lectorId,
        ejemplarId: ejemplarId,
        libroId: libroId,
        fechaPrestamo: fechaPrestamo,
        fechaVencimiento: fechaVencimiento ?? this.fechaVencimiento,
        fechaDevolucion: fechaDevolucion ?? this.fechaDevolucion,
        estado: estado ?? this.estado,
        tardio: tardio ?? this.tardio,
        categoriaAlPrestar: categoriaAlPrestar,
        plazoDiasAlPrestar: plazoDiasAlPrestar,
        multaAplicada: multaAplicada ?? this.multaAplicada,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'lectorId': lectorId,
        'ejemplarId': ejemplarId,
        'libroId': libroId,
        'fechaPrestamo': fechaPrestamo.toIso8601String(),
        'fechaVencimiento': fechaVencimiento.toIso8601String(),
        'fechaDevolucion': fechaDevolucion?.toIso8601String(),
        'estado': estado.code,
        'tardio': tardio,
        'categoriaAlPrestar': categoriaAlPrestar.code,
        'plazoDiasAlPrestar': plazoDiasAlPrestar,
        'multaAplicada': multaAplicada,
      };

  factory Prestamo.fromJson(Map<String, dynamic> json) => Prestamo(
        id: json['id'] as String,
        lectorId: json['lectorId'] as String,
        ejemplarId: json['ejemplarId'] as String,
        libroId: json['libroId'] as String,
        fechaPrestamo: DateTime.parse(json['fechaPrestamo'] as String),
        fechaVencimiento: DateTime.parse(json['fechaVencimiento'] as String),
        fechaDevolucion: json['fechaDevolucion'] == null
            ? null
            : DateTime.parse(json['fechaDevolucion'] as String),
        estado: EstadoPrestamo.fromCode(json['estado'] as String?),
        tardio: json['tardio'] as bool? ?? false,
        categoriaAlPrestar:
            CategoriaLector.fromCode(json['categoriaAlPrestar'] as String?),
        plazoDiasAlPrestar: (json['plazoDiasAlPrestar'] as num?)?.toInt() ?? 14,
        multaAplicada: (json['multaAplicada'] as num?)?.toInt() ?? 0,
      );
}

/// Reserva de un título.
///
/// La cola se resuelve por `fechaReserva` en orden estrictamente cronológico
/// (spec v2 §7). Igual que el préstamo, congela el plazo de retiro vigente al
/// momento de generarse.
class Reserva {
  Reserva({
    required this.id,
    required this.lectorId,
    required this.libroId,
    required this.fechaReserva,
    this.fechaVencimientoRetiro,
    required this.estado,
    this.ejemplarAsignadoId,
    required this.plazoRetiroHorasAlReservar,
  });

  final String id;
  final String lectorId;
  final String libroId;
  final DateTime fechaReserva;

  /// Se completa recién cuando la reserva pasa a `lista`.
  final DateTime? fechaVencimientoRetiro;
  final EstadoReserva estado;
  final String? ejemplarAsignadoId;
  final int plazoRetiroHorasAlReservar;

  bool get esActiva => estado.esActiva;

  Reserva copyWith({
    DateTime? fechaVencimientoRetiro,
    EstadoReserva? estado,
    String? ejemplarAsignadoId,
  }) =>
      Reserva(
        id: id,
        lectorId: lectorId,
        libroId: libroId,
        fechaReserva: fechaReserva,
        fechaVencimientoRetiro:
            fechaVencimientoRetiro ?? this.fechaVencimientoRetiro,
        estado: estado ?? this.estado,
        ejemplarAsignadoId: ejemplarAsignadoId ?? this.ejemplarAsignadoId,
        plazoRetiroHorasAlReservar: plazoRetiroHorasAlReservar,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'lectorId': lectorId,
        'libroId': libroId,
        'fechaReserva': fechaReserva.toIso8601String(),
        'fechaVencimientoRetiro': fechaVencimientoRetiro?.toIso8601String(),
        'estado': estado.code,
        'ejemplarAsignadoId': ejemplarAsignadoId,
        'plazoRetiroHorasAlReservar': plazoRetiroHorasAlReservar,
      };

  factory Reserva.fromJson(Map<String, dynamic> json) => Reserva(
        id: json['id'] as String,
        lectorId: json['lectorId'] as String,
        libroId: json['libroId'] as String,
        fechaReserva: DateTime.parse(json['fechaReserva'] as String),
        fechaVencimientoRetiro: json['fechaVencimientoRetiro'] == null
            ? null
            : DateTime.parse(json['fechaVencimientoRetiro'] as String),
        estado: EstadoReserva.fromCode(json['estado'] as String?),
        ejemplarAsignadoId: json['ejemplarAsignadoId'] as String?,
        plazoRetiroHorasAlReservar:
            (json['plazoRetiroHorasAlReservar'] as num?)?.toInt() ?? 48,
      );
}

class Notificacion {
  Notificacion({
    required this.id,
    required this.lectorId,
    required this.tipo,
    required this.titulo,
    required this.descripcion,
    required this.fecha,
    this.leida = false,
  });

  final String id;
  final String lectorId;
  final TipoNotificacion tipo;
  final String titulo;
  final String descripcion;
  final DateTime fecha;
  final bool leida;

  String get icono => tipo.icono;

  Notificacion copyWith({bool? leida}) => Notificacion(
        id: id,
        lectorId: lectorId,
        tipo: tipo,
        titulo: titulo,
        descripcion: descripcion,
        fecha: fecha,
        leida: leida ?? this.leida,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'lectorId': lectorId,
        'tipo': tipo.code,
        'titulo': titulo,
        'descripcion': descripcion,
        'fecha': fecha.toIso8601String(),
        'leida': leida,
      };

  factory Notificacion.fromJson(Map<String, dynamic> json) => Notificacion(
        id: json['id'] as String,
        lectorId: json['lectorId'] as String,
        tipo: TipoNotificacion.fromCode(json['tipo'] as String?),
        titulo: json['titulo'] as String? ?? '',
        descripcion: json['descripcion'] as String? ?? '',
        fecha: DateTime.parse(json['fecha'] as String),
        leida: json['leida'] as bool? ?? false,
      );
}

class EventoAuditoria {
  EventoAuditoria({
    required this.id,
    required this.tipo,
    required this.descripcion,
    required this.usuarioId,
    required this.fecha,
  });

  final String id;
  final TipoEventoAuditoria tipo;
  final String descripcion;
  final String usuarioId;
  final DateTime fecha;

  Map<String, dynamic> toJson() => {
        'id': id,
        'tipo': tipo.code,
        'descripcion': descripcion,
        'usuario': usuarioId,
        'fecha': fecha.toIso8601String(),
      };

  factory EventoAuditoria.fromJson(Map<String, dynamic> json) =>
      EventoAuditoria(
        id: json['id'] as String,
        tipo: TipoEventoAuditoria.fromCode(json['tipo'] as String?),
        descripcion: json['descripcion'] as String? ?? '',
        usuarioId: json['usuario'] as String? ?? 'sistema',
        fecha: DateTime.parse(json['fecha'] as String),
      );
}

/// Parámetros de configuración editables por el Administrador (spec v2 §3).
class ConfiguracionBiblioteca {
  const ConfiguracionBiblioteca({
    this.plazoPrestamoDias = const {
      CategoriaLector.menor: 7,
      CategoriaLector.adulto: 14,
      CategoriaLector.docente: 21,
      CategoriaLector.senior: 14,
      CategoriaLector.personal: 30,
    },
    this.limiteEjemplares = const {
      CategoriaLector.menor: 2,
      CategoriaLector.adulto: 3,
      CategoriaLector.docente: 5,
      CategoriaLector.senior: 3,
      CategoriaLector.personal: 5,
    },
    this.limiteReservas = const {
      CategoriaLector.menor: 2,
      CategoriaLector.adulto: 3,
      CategoriaLector.docente: 5,
      CategoriaLector.senior: 3,
      CategoriaLector.personal: 5,
    },
    this.plazoRetiroReservaHoras = 48,
    this.multaPorDiaDemora = 100,
    this.recordatorioAntesDias = 3,
    this.pesoHistorialRecomendacion = 0.7,
    this.minPrestamosParaHistorial = 5,
    this.edadMayoriaEdad = 18,
  });

  final Map<CategoriaLector, int> plazoPrestamoDias;
  final Map<CategoriaLector, int> limiteEjemplares;
  final Map<CategoriaLector, int> limiteReservas;

  /// Spec v2 §7: el sistema retiene el libro reservado 48 hs.
  final int plazoRetiroReservaHoras;
  final int multaPorDiaDemora;
  final int recordatorioAntesDias;

  /// Spec v2 §2: 70% historial personal / 30% popularidad general.
  final double pesoHistorialRecomendacion;

  /// Debajo de este umbral el lector se considera "cold start" y la
  /// recomendación pasa a 100% popularidad.
  final int minPrestamosParaHistorial;

  final int edadMayoriaEdad;

  double get pesoPopularidadRecomendacion => 1 - pesoHistorialRecomendacion;

  int plazoPara(CategoriaLector c) => plazoPrestamoDias[c] ?? 14;
  int limiteEjemplaresPara(CategoriaLector c) => limiteEjemplares[c] ?? 3;
  int limiteReservasPara(CategoriaLector c) => limiteReservas[c] ?? 3;

  ConfiguracionBiblioteca copyWith({
    Map<CategoriaLector, int>? plazoPrestamoDias,
    Map<CategoriaLector, int>? limiteEjemplares,
    Map<CategoriaLector, int>? limiteReservas,
    int? plazoRetiroReservaHoras,
    int? multaPorDiaDemora,
    int? recordatorioAntesDias,
    double? pesoHistorialRecomendacion,
    int? minPrestamosParaHistorial,
  }) =>
      ConfiguracionBiblioteca(
        plazoPrestamoDias: plazoPrestamoDias ?? this.plazoPrestamoDias,
        limiteEjemplares: limiteEjemplares ?? this.limiteEjemplares,
        limiteReservas: limiteReservas ?? this.limiteReservas,
        plazoRetiroReservaHoras:
            plazoRetiroReservaHoras ?? this.plazoRetiroReservaHoras,
        multaPorDiaDemora: multaPorDiaDemora ?? this.multaPorDiaDemora,
        recordatorioAntesDias:
            recordatorioAntesDias ?? this.recordatorioAntesDias,
        pesoHistorialRecomendacion:
            pesoHistorialRecomendacion ?? this.pesoHistorialRecomendacion,
        minPrestamosParaHistorial:
            minPrestamosParaHistorial ?? this.minPrestamosParaHistorial,
        edadMayoriaEdad: edadMayoriaEdad,
      );

  static Map<String, dynamic> _mapToJson(Map<CategoriaLector, int> m) =>
      m.map((k, v) => MapEntry(k.code, v));

  static Map<CategoriaLector, int> _mapFromJson(
      Map<String, dynamic>? m, Map<CategoriaLector, int> fallback) {
    if (m == null) return fallback;
    return m.map(
        (k, v) => MapEntry(CategoriaLector.fromCode(k), (v as num).toInt()));
  }

  Map<String, dynamic> toJson() => {
        'plazoPrestamoDias': _mapToJson(plazoPrestamoDias),
        'limiteEjemplares': _mapToJson(limiteEjemplares),
        'limiteReservas': _mapToJson(limiteReservas),
        'plazoRetiroReservaHoras': plazoRetiroReservaHoras,
        'multaPorDiaDemora': multaPorDiaDemora,
        'recordatorioAntesDias': recordatorioAntesDias,
        'pesoHistorialRecomendacion': pesoHistorialRecomendacion,
        'minPrestamosParaHistorial': minPrestamosParaHistorial,
        'edadMayoriaEdad': edadMayoriaEdad,
      };

  factory ConfiguracionBiblioteca.fromJson(Map<String, dynamic> json) {
    const def = ConfiguracionBiblioteca();
    return ConfiguracionBiblioteca(
      plazoPrestamoDias: _mapFromJson(
          json['plazoPrestamoDias'] as Map<String, dynamic>?,
          def.plazoPrestamoDias),
      limiteEjemplares: _mapFromJson(
          json['limiteEjemplares'] as Map<String, dynamic>?,
          def.limiteEjemplares),
      limiteReservas: _mapFromJson(
          json['limiteReservas'] as Map<String, dynamic>?, def.limiteReservas),
      plazoRetiroReservaHoras:
          (json['plazoRetiroReservaHoras'] as num?)?.toInt() ?? 48,
      multaPorDiaDemora: (json['multaPorDiaDemora'] as num?)?.toInt() ?? 100,
      recordatorioAntesDias:
          (json['recordatorioAntesDias'] as num?)?.toInt() ?? 3,
      pesoHistorialRecomendacion:
          (json['pesoHistorialRecomendacion'] as num?)?.toDouble() ?? 0.7,
      minPrestamosParaHistorial:
          (json['minPrestamosParaHistorial'] as num?)?.toInt() ?? 5,
      edadMayoriaEdad: (json['edadMayoriaEdad'] as num?)?.toInt() ?? 18,
    );
  }
}

/// Resultado de una operación de negocio que puede fallar por regla.
class ResultadoOperacion<T> {
  const ResultadoOperacion.ok(this.valor)
      : exito = true,
        motivo = '';
  const ResultadoOperacion.error(this.motivo)
      : exito = false,
        valor = null;

  final bool exito;
  final T? valor;
  final String motivo;
}
