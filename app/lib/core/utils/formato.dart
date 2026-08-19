import 'package:intl/intl.dart';

/// Formateo de fechas y montos en es-AR.
class Formato {
  static final _fecha = DateFormat('dd/MM/yyyy');
  static final _fechaHora = DateFormat('dd/MM/yyyy HH:mm');
  static final _fechaLarga = DateFormat("d 'de' MMMM 'de' y", 'es');

  static String fecha(DateTime? d) => d == null ? '—' : _fecha.format(d);
  static String fechaHora(DateTime? d) =>
      d == null ? '—' : _fechaHora.format(d);
  static String fechaLarga(DateTime? d) =>
      d == null ? '—' : _fechaLarga.format(d);

  /// "hace un momento", "hace 5 min", "ayer", o la fecha completa.
  static String relativa(DateTime? d, {DateTime? ahora}) {
    if (d == null) return '—';
    final ref = ahora ?? DateTime.now();
    final s = ref.difference(d).inSeconds;
    if (s < 60) return 'hace un momento';
    if (s < 3600) return 'hace ${s ~/ 60} min';
    if (s < 86400) return 'hace ${s ~/ 3600} hs';
    if (s < 172800) return 'ayer';
    return fecha(d);
  }

  /// Texto del vencimiento visto desde hoy.
  static String vencimiento(DateTime venc, {DateTime? ahora}) {
    final ref = ahora ?? DateTime.now();
    final dias = venc.difference(ref).inDays;
    if (dias < 0) {
      final n = dias.abs();
      return 'Venció hace $n ${n == 1 ? 'día' : 'días'}';
    }
    if (dias == 0) return 'Vence hoy';
    if (dias == 1) return 'Vence mañana';
    return 'Vence en $dias días';
  }

  static String pesos(num monto) =>
      NumberFormat.currency(locale: 'es_AR', symbol: r'$', decimalDigits: 0)
          .format(monto);

  static String porcentaje(num v) => '${v.toStringAsFixed(1)}%';
}
