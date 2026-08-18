import 'servicio_push.dart';
import 'servicio_push_movil.dart'
    if (dart.library.js_interop) 'servicio_push_web.dart' as implementacion;

/// Construye la implementación de [ServicioPush] de la plataforma actual.
///
/// El import condicional vive acá y no en `servicio_push.dart` para que el
/// dominio pueda depender del contrato sin arrastrar ni el plugin de Firebase
/// ni `dart:js_interop`.
ServicioPush crearServicioPush() => implementacion.crearServicioPush();
