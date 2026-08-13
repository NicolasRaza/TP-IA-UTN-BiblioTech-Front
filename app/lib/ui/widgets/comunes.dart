import 'package:flutter/material.dart';

import '../../core/tema.dart';
import '../../domain/enums.dart';
import '../../domain/models.dart';

/// Etiqueta de estado con color, equivalente a los `.badge` del CSS.
class Insignia extends StatelessWidget {
  const Insignia(this.texto, {super.key, required this.color, this.icono});

  final String texto;
  final Color color;
  final IconData? icono;

  factory Insignia.estadoEjemplar(EstadoEjemplar e) => Insignia(
        e.label,
        color: switch (e) {
          EstadoEjemplar.disponible => Paleta.success,
          EstadoEjemplar.prestado => Paleta.danger,
          EstadoEjemplar.reservado => Paleta.warning,
          EstadoEjemplar.baja => Paleta.textMuted,
        },
      );

  factory Insignia.estadoPrestamo(EstadoPrestamo e) => Insignia(
        e.label,
        color: switch (e) {
          EstadoPrestamo.activo => Paleta.success,
          EstadoPrestamo.vencido => Paleta.danger,
          EstadoPrestamo.devuelto => Paleta.textMuted,
        },
      );

  factory Insignia.estadoReserva(EstadoReserva e) => Insignia(
        e.label,
        color: switch (e) {
          EstadoReserva.pendiente => Paleta.info,
          EstadoReserva.lista => Paleta.teal,
          EstadoReserva.completada => Paleta.textMuted,
          EstadoReserva.cancelada => Paleta.textMuted,
          EstadoReserva.vencida => Paleta.danger,
        },
      );

  factory Insignia.condicion(CondicionEjemplar c) => Insignia(
        c.label,
        color: switch (c) {
          CondicionEjemplar.bueno => Paleta.success,
          CondicionEjemplar.regular => Paleta.warning,
          CondicionEjemplar.malo => Paleta.danger,
        },
      );

  factory Insignia.categoria(CategoriaLector c) => Insignia(
        c.label,
        color: switch (c) {
          CategoriaLector.menor => Paleta.teal,
          CategoriaLector.adulto => Paleta.primary,
          CategoriaLector.docente => Paleta.info,
          CategoriaLector.senior => Paleta.gold,
          CategoriaLector.personal => Paleta.pink,
        },
      );

  /// Marca de confianza de un campo sugerido por el agente (spec v2 §4.2).
  factory Insignia.confianza(NivelConfianza n) => Insignia(
        switch (n) {
          NivelConfianza.alta => 'Confianza alta',
          NivelConfianza.media => 'Confianza media',
          NivelConfianza.baja => 'Confianza baja',
          NivelConfianza.pendiente => 'Pendiente de carga manual',
          NivelConfianza.enConflicto => 'Fuentes en conflicto',
        },
        color: switch (n) {
          NivelConfianza.alta => Paleta.success,
          NivelConfianza.media => Paleta.warning,
          NivelConfianza.baja => Paleta.danger,
          NivelConfianza.pendiente => Paleta.textMuted,
          NivelConfianza.enConflicto => Paleta.pink,
        },
        icono: switch (n) {
          NivelConfianza.alta => Icons.check_circle_outline,
          NivelConfianza.media => Icons.info_outline,
          NivelConfianza.baja => Icons.warning_amber_outlined,
          NivelConfianza.pendiente => Icons.edit_note_outlined,
          NivelConfianza.enConflicto => Icons.call_split,
        },
      );

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(Radios.xl),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icono != null) ...[
            Icon(icono, size: 13, color: color),
            const SizedBox(width: 5),
          ],
          Text(
            texto,
            style: TextStyle(
                color: color, fontSize: 11.5, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

/// Portada del libro con fallback cuando la imagen no carga.
class Portada extends StatelessWidget {
  const Portada(this.libro, {super.key, this.alto = 180, this.ancho});

  final Libro libro;
  final double alto;
  final double? ancho;

  @override
  Widget build(BuildContext context) {
    final url = libro.portadaUrl;
    final placeholder = Container(
      height: alto,
      width: ancho,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Paleta.bgHover, Paleta.bgCard],
        ),
        borderRadius: BorderRadius.circular(Radios.base),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.menu_book_outlined,
                size: 30, color: Paleta.textMuted),
            const SizedBox(height: 6),
            Text(
              libro.titulo,
              maxLines: 3,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, color: Paleta.textMuted),
            ),
          ],
        ),
      ),
    );

    if (url.isEmpty) return placeholder;

    return ClipRRect(
      borderRadius: BorderRadius.circular(Radios.base),
      child: Image.network(
        url,
        height: alto,
        width: ancho,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => placeholder,
        loadingBuilder: (ctx, child, progress) =>
            progress == null ? child : placeholder,
      ),
    );
  }
}

/// Mensaje para listas vacías.
class EstadoVacio extends StatelessWidget {
  const EstadoVacio({
    super.key,
    required this.icono,
    required this.titulo,
    this.detalle = '',
    this.accion,
  });

  final IconData icono;
  final String titulo;
  final String detalle;
  final Widget? accion;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icono, size: 48, color: Paleta.textMuted),
            const SizedBox(height: 14),
            Text(titulo,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium),
            if (detalle.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(detalle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Paleta.textMuted)),
            ],
            if (accion != null) ...[const SizedBox(height: 18), accion!],
          ],
        ),
      ),
    );
  }
}

/// Tarjeta de métrica del dashboard.
class TarjetaMetrica extends StatelessWidget {
  const TarjetaMetrica({
    super.key,
    required this.titulo,
    required this.valor,
    required this.icono,
    required this.color,
    this.detalle = '',
  });

  final String titulo;
  final String valor;
  final IconData icono;
  final Color color;
  final String detalle;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(Radios.base),
                  ),
                  child: Icon(icono, color: color, size: 19),
                ),
                const Spacer(),
              ],
            ),
            const SizedBox(height: 14),
            Text(valor,
                style: TextStyle(
                    fontSize: 27, fontWeight: FontWeight.w700, color: color)),
            const SizedBox(height: 2),
            Text(titulo,
                style: const TextStyle(
                    color: Paleta.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500)),
            if (detalle.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(detalle,
                  style:
                      const TextStyle(color: Paleta.textMuted, fontSize: 11.5)),
            ],
          ],
        ),
      ),
    );
  }
}

/// Encabezado de sección con título y subtítulo.
class EncabezadoSeccion extends StatelessWidget {
  const EncabezadoSeccion(this.titulo,
      {super.key, this.subtitulo = '', this.accion});

  final String titulo;
  final String subtitulo;
  final Widget? accion;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontSize: 22, fontWeight: FontWeight.w700)),
                if (subtitulo.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(subtitulo,
                      style: const TextStyle(
                          color: Paleta.textMuted, fontSize: 13.5)),
                ],
              ],
            ),
          ),
          if (accion != null) accion!,
        ],
      ),
    );
  }
}

/// Avatar con las iniciales del lector.
class AvatarLector extends StatelessWidget {
  const AvatarLector(this.lector, {super.key, this.radio = 20});

  final Lector lector;
  final double radio;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radio,
      backgroundColor: Paleta.primary.withOpacity(0.2),
      child: Text(
        lector.iniciales,
        style: TextStyle(
          color: Paleta.primaryLight,
          fontWeight: FontWeight.w700,
          fontSize: radio * 0.7,
        ),
      ),
    );
  }
}

/// Muestra un mensaje breve al pie de la pantalla.
void avisar(BuildContext context, String mensaje, {bool esError = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              esError ? Icons.error_outline : Icons.check_circle_outline,
              color: esError ? Paleta.danger : Paleta.success,
              size: 19,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(mensaje)),
          ],
        ),
      ),
    );
}
