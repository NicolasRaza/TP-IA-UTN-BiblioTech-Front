import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../../../../core/api/cliente_api.dart';
import '../../../../core/api/mapeo_api.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/error/result.dart';
import '../../domain/entities/ejemplar.dart';
import '../../domain/entities/libro.dart';
import '../../../agentes/domain/entities/ficha_sugerida.dart';

/// Acceso al catálogo del backend SGB (`/api/v1/catalogo`).
///
/// Es el gemelo remoto de `CatalogoLocalDataSource`: la única clase del
/// feature que sabe que del otro lado hay títulos y ejemplares en PostgreSQL
/// en vez de JSON en el navegador. Traduce el vocabulario de la API
/// —`autores`, `estado_validacion`, `codigo_qr`— al del dominio.
abstract interface class CatalogoApiDataSource {
  /// `GET /titulos`. El backend sólo devuelve títulos ya validados: la Regla
  /// de Validación Estricta (spec §7) la aplica el servidor, no la app.
  Future<Result<List<Libro>>> buscarTitulos({String texto, String genero});

  Future<Result<Libro>> obtenerTitulo(String libroId);

  /// `GET /titulos/{id}/ejemplares` — los ejemplares activos del título, con
  /// su código QR, su estado y su condición física.
  Future<Result<List<Ejemplar>>> listarEjemplares(String libroId);

  Future<Result<Libro>> crearTitulo(Libro libro);

  Future<Result<Libro>> editarTitulo(Libro libro);

  /// `POST /titulos/captura-ocr` — envía las 3 fotos para extraer la ficha por OCR.
  Future<Result<FichaSugerida>> capturarOcr({
    required List<int> fotoTapa,
    required List<int> fotoContratapa,
    required List<int> fotoFicha,
    String? extensionTapa,
    String? extensionContratapa,
    String? extensionFicha,
  });

  /// `POST /titulos/{id}/validar` — publica el título con la ficha corregida.
  Future<Result<Libro>> validarTitulo(Libro libro);

  /// `POST /ejemplares` — el backend genera el código QR y lo devuelve.
  Future<Result<Ejemplar>> crearEjemplar({
    required String libroId,
    required CondicionEjemplar condicion,
  });

  Future<Result<Ejemplar>> buscarEjemplarPorQr(String codigoQr);

  Future<Result<void>> darDeBajaEjemplar(String ejemplarId);
}

class CatalogoApiDataSourceHttp implements CatalogoApiDataSource {
  const CatalogoApiDataSourceHttp(this._api);

  final ClienteApi _api;

  @override
  Future<Result<List<Libro>>> buscarTitulos({
    String texto = '',
    String genero = '',
  }) =>
      _api.get<List<Libro>>(
        '/api/v1/catalogo/titulos',
        query: {
          if (texto.trim().isNotEmpty) 'q': texto.trim(),
          if (genero.trim().isNotEmpty && genero != 'Todos')
            'genero': genero.trim(),
        },
        leer: (json) => (json as List<Object?>? ?? const [])
            .map((e) => _libroDesdeApi(e as Map<String, dynamic>))
            .toList(),
      );

  @override
  Future<Result<Libro>> obtenerTitulo(String libroId) => _conIdRemoto(
      libroId,
      (id) => _api.get<Libro>(
            '/api/v1/catalogo/titulos/$id',
            leer: _leerLibro,
          ));

  @override
  Future<Result<List<Ejemplar>>> listarEjemplares(String libroId) =>
      _conIdRemoto(
          libroId,
          (id) => _api.get<List<Ejemplar>>(
                '/api/v1/catalogo/titulos/$id/ejemplares',
                leer: (json) => (json as List<Object?>? ?? const [])
                    .map((e) => _ejemplarDesdeApi(e as Map<String, dynamic>))
                    .toList(),
              ));

  @override
  Future<Result<Libro>> crearTitulo(Libro libro) => _api.post<Libro>(
        '/api/v1/catalogo/titulos',
        cuerpo: _cuerpoTitulo(libro, conIsbn: true),
        leer: _leerLibro,
      );

  @override
  Future<Result<Libro>> editarTitulo(Libro libro) => _conIdRemoto(
      libro.id,
      (id) => _api.patch<Libro>(
            '/api/v1/catalogo/titulos/$id',
            cuerpo: _cuerpoTitulo(libro, conIsbn: false),
            leer: _leerLibro,
          ));

  @override
  Future<Result<FichaSugerida>> capturarOcr({
    required List<int> fotoTapa,
    required List<int> fotoContratapa,
    required List<int> fotoFicha,
    String? extensionTapa,
    String? extensionContratapa,
    String? extensionFicha,
  }) {
    final mimeTapa = _determinarMime(extensionTapa);
    final mimeContratapa = _determinarMime(extensionContratapa);
    final mimeFicha = _determinarMime(extensionFicha);

    return _api.postMultipart<FichaSugerida>(
      '/api/v1/catalogo/titulos/captura-ocr',
      archivos: [
        http.MultipartFile.fromBytes(
          'foto_tapa',
          fotoTapa,
          filename: 'tapa.${extensionTapa ?? "jpg"}',
          contentType:
              MediaType(mimeTapa.split('/')[0], mimeTapa.split('/')[1]),
        ),
        http.MultipartFile.fromBytes(
          'foto_contratapa',
          fotoContratapa,
          filename: 'contratapa.${extensionContratapa ?? "jpg"}',
          contentType: MediaType(
              mimeContratapa.split('/')[0], mimeContratapa.split('/')[1]),
        ),
        http.MultipartFile.fromBytes(
          'foto_ficha',
          fotoFicha,
          filename: 'ficha.${extensionFicha ?? "jpg"}',
          contentType:
              MediaType(mimeFicha.split('/')[0], mimeFicha.split('/')[1]),
        ),
      ],
      leer: _leerFichaOcr,
    );
  }

  String _determinarMime(String? ext) {
    if (ext == null) return 'image/jpeg';
    switch (ext.toLowerCase()) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }

  @override
  Future<Result<Libro>> validarTitulo(Libro libro) =>
      // El payload de validación es la ficha ya revisada por el bibliotecario:
      // el backend guarda esas correcciones y recién entonces publica.
      _conIdRemoto(
          libro.id,
          (id) => _api.post<Libro>(
                '/api/v1/catalogo/titulos/$id/validar',
                cuerpo: _cuerpoTitulo(libro, conIsbn: false),
                leer: _leerLibro,
              ));

  @override
  Future<Result<Ejemplar>> crearEjemplar({
    required String libroId,
    required CondicionEjemplar condicion,
  }) =>
      _conIdRemoto(
          libroId,
          (id) => _api.post<Ejemplar>(
                '/api/v1/catalogo/ejemplares',
                cuerpo: {
                  'titulo_id': id,
                  'condicion': condicionHaciaApi(condicion),
                },
                leer: _leerEjemplar,
              ));

  @override
  Future<Result<Ejemplar>> buscarEjemplarPorQr(String codigoQr) =>
      _api.get<Ejemplar>(
        '/api/v1/catalogo/ejemplares/qr/${Uri.encodeComponent(codigoQr)}',
        leer: _leerEjemplar,
      );

  @override
  Future<Result<void>> darDeBajaEjemplar(String ejemplarId) => _conIdRemoto(
      ejemplarId,
      (id) => _api.delete<void>(
            '/api/v1/catalogo/ejemplares/$id',
            leer: (_) {},
          ));

  // ── Traducción de la respuesta ─────────────────────────────────────────────

  static Libro _leerLibro(Object? json) =>
      _libroDesdeApi(json as Map<String, dynamic>);

  static Ejemplar _leerEjemplar(Object? json) =>
      _ejemplarDesdeApi(json as Map<String, dynamic>);

  static Libro _libroDesdeApi(Map<String, dynamic> json) => Libro(
        id: idDesdeApi(json['id']),
        titulo: json['titulo'] as String? ?? '',
        autor: json['autores'] as String? ?? '',
        editorial: json['editorial'] as String? ?? '',
        // El backend guarda el año como texto libre ("1967", "c. 1967").
        anio: int.tryParse('${json['anio_edicion'] ?? ''}'),
        isbn: json['isbn'] as String? ?? '',
        sinopsis: json['sinopsis'] as String? ?? '',
        genero: json['genero'] as String? ?? '',
        paginas: (json['paginas'] as num?)?.toInt(),
        portada: json['portada_url'] as String? ?? '',
        validado: json['estado_validacion'] == 'validado',
        fechaAlta: fechaDesdeApi(json['creado_en'], DateTime.now()),
        // La API informa los totales pero no lista los ejemplares: se guarda
        // el conteo tal cual y no se inventa ninguno.
        totalInformado: (json['total_ejemplares'] as num?)?.toInt() ?? 0,
        disponiblesInformado:
            (json['ejemplares_disponibles'] as num?)?.toInt() ?? 0,
      );

  static Ejemplar _ejemplarDesdeApi(Map<String, dynamic> json) => Ejemplar(
        id: idDesdeApi(json['id']),
        libroId: idDesdeApi(json['titulo_id']),
        condicion: condicionDesdeApi(json['condicion'] as String?),
        estado: estadoEjemplarDesdeApi(json['estado'] as String?),
        ubicacion: json['ubicacion_fisica'] as String? ?? 'Sin asignar',
        // El código lo emite el servidor: se conserva tal cual, porque es lo
        // único que resuelve contra `GET /ejemplares/qr/{codigo}`.
        qrAsignado: json['codigo_qr'] as String?,
      );

  static FichaSugerida _leerFichaOcr(Object? json) {
    final data = json as Map<String, dynamic>;

    // Mapeo del JSON OCRResultado a FichaSugerida
    final campos = <String, CampoSugerido>{};

    void agregarCampo(String clave, String? valor, num? confianza) {
      if (valor == null || valor.isEmpty) {
        campos[clave] = const CampoSugerido.pendiente();
      } else {
        campos[clave] = CampoSugerido(
          valor: valor,
          confianza: (confianza ?? 0) >= 0.8
              ? NivelConfianza.alta
              : ((confianza ?? 0) >= 0.5
                  ? NivelConfianza.media
                  : NivelConfianza.baja),
          porcentaje: ((confianza ?? 0) * 100).round(),
          fuente: 'OCR',
        );
      }
    }

    agregarCampo(
        'isbn', data['isbn'] as String?, data['confianza_isbn'] as num?);
    agregarCampo(
        'titulo', data['titulo'] as String?, data['confianza_titulo'] as num?);
    agregarCampo(
        'autor', data['autores'] as String?, data['confianza_autores'] as num?);

    // Estos campos no tienen nivel de confianza específico en el backend, se consideran de enriquecimiento o alta
    agregarCampo('editorial', data['editorial'] as String?, 0.9);
    agregarCampo('anio', data['anio_edicion'] as String?, 0.9);
    agregarCampo('paginas', data['paginas']?.toString(), 0.9);

    return FichaSugerida(campos: campos);
  }

  /// Los campos que aceptan `TituloCreate`, `TituloUpdate` y `TituloValidar`.
  /// El ISBN sólo viaja en el alta: el backend no lo deja cambiar después.
  static Map<String, Object?> _cuerpoTitulo(
    Libro libro, {
    required bool conIsbn,
  }) =>
      {
        if (conIsbn && libro.isbn.isNotEmpty) 'isbn': libro.isbn,
        'titulo': libro.titulo,
        'autores': libro.autor,
        if (libro.editorial.isNotEmpty) 'editorial': libro.editorial,
        if (libro.anio != null) 'anio_edicion': '${libro.anio}',
        if (libro.genero.isNotEmpty) 'genero': libro.genero,
        if (libro.sinopsis.isNotEmpty) 'sinopsis': libro.sinopsis,
        if (libro.portada.isNotEmpty) 'portada_url': libro.portada,
        if (libro.paginas != null) 'paginas': libro.paginas,
      };

  /// Corre [peticion] sólo si el id es uno del backend.
  ///
  /// Un id local de la semilla (`lib-abc`) no existe del otro lado; se corta
  /// acá en vez de mandar un request que el servidor contestaría con un 422.
  static Future<Result<T>> _conIdRemoto<T>(
    String id,
    Future<Result<T>> Function(int id) peticion,
  ) {
    final remoto = idHaciaApi(id);
    if (remoto == null) {
      return Future.value(
        const Fallo(
            NoEncontradoFailure('Ese registro no existe en el servidor')),
      );
    }
    return peticion(remoto);
  }
}
