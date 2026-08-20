# BiblioTech

## Entrega Final - Proyecto en vivo

🔗 **URL de la aplicación:** https://nicolasraza.github.io/TP-IA-UTN-BiblioTech-Front/

Para ingresar como **lector**, es necesario registrarse en la aplicación y luego ser verificado del lado de la biblioteca antes de poder acceder con esas credenciales.

## Sobre el proyecto

**BiblioTech** es un sistema de gestión de bibliotecas desarrollado en Flutter, pensado para digitalizar la operatoria diaria de una biblioteca: catálogo de ejemplares, préstamos, reservas, gestión de lectores y administración, con soporte de agentes de IA y notificaciones.

### Funcionalidades principales

- **Catálogo**: alta, búsqueda y enriquecimiento de fichas de ejemplares (integración con Open Library).
- **Préstamos y reservas**: gestión del ciclo de vida de un préstamo y de las reservas de ejemplares.
- **Lectores**: registro de nuevos lectores y verificación por parte del personal de la biblioteca.
- **Administración**: gestión de usuarios, permisos y operatoria interna.
- **Agentes**: funcionalidades asistidas por IA dentro de la aplicación.
- **Notificaciones**: avisos push a los usuarios.
- Generación de **códigos QR** para ejemplares y lectores.

### Tecnologías

- **Flutter/Dart** como framework principal, con arquitectura por features (`app/lib/features`).
- **flutter_bloc** para el manejo de estado (BLoC/Cubit).
- **get_it** como service locator para inyección de dependencias.
- **shared_preferences** para persistencia local multiplataforma.
- **http** para consumo de APIs externas (Open Library) y del backend propio.
- Publicado como aplicación web estática vía **GitHub Pages**.
