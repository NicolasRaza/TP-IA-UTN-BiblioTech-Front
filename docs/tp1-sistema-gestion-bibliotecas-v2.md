# Sistema de Gestión de Bibliotecas

Tomás Bacchetta Julio Flores Matías Ledesma Alex Raza

_Curso IA para Desarrolladores_

## 1. Descripción del problema

### ¿Qué problema se desea resolver?

Las bibliotecas (públicas, escolares e institucionales) gestionan hoy su operación diaria de forma manual o con herramientas desconectadas entre sí: planillas o fichas físicas para socios, registros en papel o cuadernos para préstamos y devoluciones, y carga manual y lenta de cada libro nuevo al catálogo. Esto genera baja visibilidad sobre qué libros están disponibles en cada momento, demoras evitables en el mostrador y dependencia total del personal presente para cualquier consulta. Además, cierto _aggiornamento_ en la interacción entre el lector y la biblioteca es siempre bienvenido, ya que a pesar de todo, hoy en día las bibliotecas siguen siendo instituciones con un saldo muy positivo para con la sociedad, y ese vínculo debe afianzarse en este pleno siglo XXI.

### ¿A quién afecta?

• **Lectores/socios**: no pueden saber si un libro está disponible sin acercarse o llamar a la biblioteca, ni reservarlo con anticipación, y además, el aviso de vencimiento de préstamo podría canalizarse de una forma más eficiente.

• **Bibliotecarios**: pierden tiempo en tareas repetitivas (carga manual de datos editoriales, búsqueda de ejemplares, control de vencimientos uno por uno) en lugar de dedicarlo a la atención del lector, orientación, talleres y otras actividades que promocionen la lectura, etc. Incluso poder leer.

• **Biblioteca**: Tal vez no cuenta con datos centralizados y confiables (este sistema facilitaría rehacer la carga) sobre su propio inventario y su nivel de uso, lo que dificulta decisiones de compra, baja o promoción de material. Cualquier ahorro de esfuerzo en tareas repetitivas, permite que los empleados se enfoquen en tareas críticas como la conservación y puesta a punto de los ejemplares, entre muchas otras más.

### ¿Por qué es importante resolverlo?

Una biblioteca que no puede informar disponibilidad en tiempo real ni avisar vencimientos pierde lectores frecuentes por simple fricción operativa, y acumula pérdidas de material por demoras en la devolución que nadie notificó a tiempo. Además, las tareas administrativas alejan al bibliotecario de enfocarse en lo importante: el lector y sus libros.

### ¿Qué beneficios generaría la solución propuesta?

- Reducción del tiempo administrativo del bibliotecario, especialmente en la carga de libros nuevos al inventario.

- Menor cantidad de préstamos vencidos y material perdido, gracias a las notificaciones proactivas al lector.

- Mayor uso de la biblioteca: el lector puede explorar el catálogo, reservar y recibir recomendaciones desde su celular, sin depender del horario de atención.

• Trazabilidad completa de cada ejemplar físico mediante su identificación única (QR), simplificando préstamos, devoluciones y auditorías de inventario.

• Datos centralizados que permiten conocer qué se lee más, qué lectores están activos y qué decisiones tomar sobre el fondo bibliográfico.

## 2. Objetivo de la aplicación

### ¿Qué hará la aplicación?

- Administración de usuarios lectores

- Aplicación de celular para autogestión por parte del lector

- Gestión de inventario con semi-automatización de carga de datos de libros nuevos

El sistema digitalizará y centralizará los tres pilares de la gestión de una biblioteca: la administración de lectores, la consulta y reserva de material por parte del lector desde su celular (lo que facilita notificaciones), y la incorporación y trazabilidad del inventario físico por parte del bibliotecario, incluyendo el reconocimiento automático de datos del libro a partir de fotos y la identificación de cada ejemplar mediante un código QR único, que puede ser impreso por etiquetadora de pequeño formato.

### ¿Qué resultados se esperan?

- Disponibilidad del catálogo consultable en tiempo real, las 24 horas, desde el celular del lector.

- Reducción significativa del tiempo que toma dar de alta un libro nuevo al inventario, frente a la carga manual de cada dato.

- Bibliotecario con carga de horas liberada de tareas repetitivas, pudiendo enfocarse en tareas más acordes a su formación y oficio.

- Disminución de préstamos vencidos por falta de aviso, gracias a notificaciones automáticas.

- Un inventario físico totalmente trazable: cada ejemplar identificable de forma inequívoca con su QR.

### ¿Qué decisiones o recomendaciones podrá generar?

• Para el **lector**: recomendaciones personalizadas de lectura en base a su historial y a la popularidad general, y alertas de cuándo retirar una reserva o devolver un préstamo antes de la fecha límite.

> **Regla de Ponderación de Recomendaciones:** el motor de recomendación combina ambas señales con un peso configurable, con un valor por defecto de 70% historial personal / 30% popularidad general para lectores con historial suficiente (ej. más de 5 préstamos registrados). Para lectores nuevos sin historial ("cold start"), el peso se invierte automáticamente a 100% popularidad general hasta acumular datos propios suficientes.

• Para el **bibliotecario**: sugerencias de datos editoriales y de catalogación (sinopsis, género, portada) al cargar un libro nuevo, que el bibliotecario revisa y confirma antes de incorporarlas. Parcial o totalmente transparente también al lector en su aplicación web.

• Para la **biblioteca**: indicadores de uso (títulos más prestados, lectores más activos, materiales con alta demora) que orientan decisiones de compra, refuerzo de ejemplares o promoción de ciertos títulos.

## 3. Entradas del sistema

Información que la aplicación necesita recibir o capturar para funcionar, agrupada por origen.

|**Categoría de entrada**|**Detalle**|
|---|---|
|Datos ingresados por el lector|Alta de cuenta propia (o vinculación con código entregado en mostrador), búsquedas, solicitudes de reserva, cancelaciones, valoraciones/comentarios de libros leídos, preferencias de notificación y géneros de interés.|
|Datos ingresados por el bibliotecario|Alta y modificación de lectores (datos personales, categoría, tutor si es menor), validación/corrección de datos de libros tras el reconocimiento automático, registro de condición física del ejemplar, registro de bajas, confirmación de préstamos y devoluciones.|
|Imágenes capturadas (cámara)|Tres fotos por libro nuevo: tapa, contratapa y página con ficha tecnica (ISBN, autor, editorial, año y lugar de edición), usadas como entrada para el reconocimiento automático utilizando OCR (reconocimiento óptico de caracteres) y visión por computadora.|
|Lectura de código QR|Escaneo del QR único de cada ejemplar al momento de préstamo, devolución o reimpresión de etiqueta y escaneo del QR del lector como identificación rápida en mostrador.|
|Datos históricos propios del sistema|Historial de préstamos y reservas por lector y por título, historial de multas, fechas de alta y baja de ejemplares, estado de validación de cada título cargado.|
|Información externa enriquecida (agente de búsqueda)|Datos complementarios obtenidos de internet a partir del ISBN/título/autor: sinopsis, género o categoría, cantidad de páginas, portada en alta resolución, valoraciones externas|
|Calendario / tiempo|Fechas de vencimiento de préstamo, plazos de retiro de reservas, frecuencia de los recordatorios automáticos (parametrizable por categoría de lector).|
|Indicadores de negocio (uso interno)|Cantidad de préstamos por título/categoría, tasa de devoluciones tardías, ranking de títulos más reservados, lectores con mayor actividad usados para reportes y recomendaciones|
|Registros de actividad (auditoría)|Quién y cuándo dio de alta o baja un libro o lector, reimpresiones de etiquetas QR, cambios manuales sobre datos sugeridos por el reconocimiento automático.|
|Parámetros de configuración|Límites de préstamos y reservas simultáneas, plazos de devolución y de retiro de reserva por categoría de lector definidos por el Administrador.|

## 4. Procesos internos

La aplicación se apoya en una red de agentes especializados, que operan de forma coordinada desde la captura de la información hasta la generación de recomendaciones y reportes.

### 1. Agente de Captura de Información (Visión y QR)

**Función:** Se encarga de digitalizar y registrar los estímulos e interacciones del entorno físico hacia el sistema. Procesa las tres fotos obligatorias tomadas por el bibliotecario (tapa, contratapa y página técnica) aplicando técnicas de reconocimiento óptico de caracteres (OCR) y visión computacional. Asimismo, gestiona la lectura de los códigos QR únicos de cada ejemplar físico durante los procesos de préstamo, devolución o auditoría de inventario, al igual que el escaneo del QR identificatorio del lector en el mostrador.

**Interacción con otros agentes:** Extrae el texto crudo de las imágenes y aísla la cadena numérica del ISBN para enviarlos de forma directa al Agente Analizador para su estructuración y validación.

### 2. Agente Analizador y de Enriquecimiento

**Función:** Actúa como el procesador de lenguaje y datos de la aplicación. Su tarea principal consiste en clasificar gramaticalmente y estructurar el texto crudo enviado por el agente anterior en campos editoriales definidos (título, autor, editorial, año). Si detecta un ISBN válido, activa un sub-agente de búsqueda externa en internet para recopilar información complementaria como sinopsis, género preciso, cantidad de páginas y portadas en alta resolución. También procesa y analiza las entradas del lector, tales como búsquedas, preferencias temáticas e intereses de notificación.

**Interacción con otros agentes:** Presenta los datos estructurados y enriquecidos en la interfaz para que el bibliotecario valide o corrija la ficha. Una vez confirmada la carga, almacena la información limpia en la memoria persistente del sistema y distribuye los nuevos datos tanto al Agente Planificador como al Agente Evaluador.

> **Regla de Resolución de Fuentes Externas:** si el ISBN no arroja resultados en ninguna fuente externa, el campo correspondiente queda vacío y marcado como "pendiente de carga manual" para el bibliotecario. Si dos o más fuentes externas ofrecen datos distintos para el mismo campo (ej. sinopsis o género), el Agente Analizador prioriza la fuente con mayor autoridad editorial predefinida (ej. ISBN agency / editorial oficial por sobre bases colaborativas) y, de persistir la discrepancia, presenta ambas opciones al bibliotecario para que elija — nunca completa el campo con un dato de baja confianza sin marcarlo como tal.

### 3. Agente Planificador y de Gestión Operativa (Alertas)

**Función:** Es el administrador del tiempo, los flujos de trabajo y la agenda operativa del sistema. Monitorea permanentemente las variables temporales del calendario (fechas de vencimiento de préstamos, plazos máximos para retirar una reserva en mostrador y plazos parametrizables por tipo de socio). Su propósito es programar cronológicamente y disparar de forma automática las tareas de comunicación proactiva.

**Interacción con otros agentes:** Utiliza las reglas de negocio provistas por el administrador y las alertas generadas para enviar notificaciones push directas a la aplicación de celular del lector afectado. Adicionalmente, reporta al Agente Evaluador los estados de cumplimiento de plazos para actualizar las métricas operativas.

> **Aclaración de responsabilidades (Agente Evaluador vs. Agente Planificador):** el Agente Evaluador es quien *decide* qué acción corresponde a partir de las métricas monitoreadas (ej. "este préstamo está vencido, corresponde notificar"; "esta reserva llegó a las 48hs, corresponde liberar"). El Agente Planificador es exclusivamente el *ejecutor*: recibe la decisión ya tomada por el Evaluador y la traduce en la tarea concreta (enviar la notificación push, liberar el cupo de la reserva, actualizar el estado en el sistema). De esta forma, el Evaluador nunca ejecuta directamente sobre el sistema, y el Planificador nunca decide criterios de negocio por sí mismo — solo orquesta la agenda y el disparo de tareas ya definidas.

<!-- Start of picture text -->
Observacién<br>Nueva observacion Analisis<br>ciclo<br>Aprendizaje Planificacién<br>Evaluacién Accién<br><!-- End of picture text -->

**Observación**: Se registran los eventos, ya sea nuevos usuarios, búsquedas, reservas, préstamos, devoluciones a tiempo o tardías. Altas de libros en inventario. _(agente evaluador)_

**Análisis**: Esos eventos se agregan en indicadores: títulos más reservados, lectores que incumplen frecuentemente, tiempos de carga de inventario. _(agente analizador)_

**Planificación**: El bibliotecario o administrador decide qué ajuste realizar: por ejemplo plazos de entrega por categoría, refuerzo de ejemplares, prioridad de notificación. _(agente planificador)_

**Acción**: El sistema ejecuta: envía notificaciones, libera o asigna reservas, sugiere recomendaciones, aplica los nuevos parámetros. _(decisión del agente evaluador, ejecución a cargo del agente planificador — ver aclaración de responsabilidades en la sección anterior)_

**Evaluación**: Se mide si por ejemplo disminuyeron los incumplimientos, si hay menos libros requeridos ya reservados, etc. _(agente evaluador)_

**Aprendizaje**: Si algo funcionó, se agrega como nueva regla o se refina el criterio de recomendación para el próximo ciclo. _(agente de aprendizaje)_

**Nueva observación**: Se empieza de nuevo el ciclo pero con reglas y recomendaciones aún mejores. _(agente evaluador)_

## 6. Memoria persistente

|**Nombre**|**Descripción**|**Tipo de agente**|
|---|---|---|
|Historial de lectores|Préstamos realizados (libro, fecha, si se devolvió a tiempo o tarde), reservas hechas/canceladas/vencidas sin retirar, valoraciones y comentarios, búsquedas en el catálogo|Agente de recomendación, agente planificador|
|Preferencias declaradas|Géneros de interés, frecuencia y canal de notificación preferido, categoría de lector|Agente de recomendación, agente planificador|
|Decisiones anteriores del sistema|Qué dato sugirió el agente de reconocimiento/enriquecimiento en cada alta de libro, qué recomendación de lectura se le mostró a cada lector, qué notificación se envió y cuándo|Agente evaluador, agente de recomendación, agente planificador|
|Resultados obtenidos (feedback humano)|Si el bibliotecario aceptó, corrigió o rechazó cada sugerencia de catalogación; si el lector aceptó o ignoró una recomendación; si una notificación logró evitar la demora en la devolución|Agente evaluador, agente de recomendación, agente planificador|
|Eventos registrados (auditoría)|Altas/Bajas de libros y lectores (quién, cuándo), reimpresiones de QR, confirmaciones de préstamo/devolución por escaneo|Agente de auditoría, agente analizador de indicadores|
|Indicadores agregados|Préstamos por título/categoría, tasa de devoluciones tardías, ranking de títulos reservados, lectores más activos|Agente analizador de indicadores|

## 7. Reglas, parámetros y restricciones

- **Regla de Validación Estricta:** Ningún libro nuevo ingresa al catálogo público visible sin la aprobación final (clic de confirmación) del bibliotecario, por más que la IA tenga un 100% de confianza en los datos.

- **Regla de Préstamos y Restricciones:** Un usuario no puede reservar nuevos libros si posee material con fecha de devolución vencida o multas impagas. Límite máximo de ejemplares simultáneos parametrizable según la categoría del socio (ej. 3)

- **Priorización de Reservas:** Las reservas se otorgan por estricto orden cronológico. El sistema retiene el libro reservado por un máximo de 48 hs; si no es retirado, pasa automáticamente al siguiente en la lista de espera.

- **Regla de Continuidad de Identidad ante Reimpresión de QR:** ante desgaste o rotura de una etiqueta, el sistema **nunca genera un ID nuevo** para el ejemplar: el bibliotecario solicita una reimpresión vinculada al mismo identificador interno ya existente en la base de datos, preservando intacto el historial de préstamos y su trazabilidad. La reimpresión queda registrada en el log de auditoría (quién, cuándo, motivo) y, hasta que la nueva etiqueta esté disponible, el ejemplar puede identificarse manualmente por su ID interno o ISBN en el mostrador, sin que eso afecte su historial.

- **Regla de Asignación y Transición de Categoría de Lector:** la categoría de lector (ej. infantil, adulto, institucional) se asigna en el alta de cuenta según la fecha de nacimiento declarada (validada por el bibliotecario si hay tutor) o el tipo de convenio institucional. Ante un cambio de categoría (ej. un menor que alcanza la mayoría de edad), el sistema aplica las nuevas reglas únicamente a partir de esa fecha: los préstamos y reservas activos al momento del cambio conservan las condiciones (plazos, límites) vigentes al momento en que fueron generados, y solo los préstamos/reservas nuevos usan la categoría actualizada.

## 8. Frenos y aceleradores

##### **Frenos**:

- Mala iluminación, reflejos o cámaras de baja resolución al momento de tomar las fotos de los libros, lo que reduce drásticamente la eficacia del OCR.

- Etiquetas QR físicas que se desgasten o rompan con el uso, dificultando el escaneo en el mostrador.

- El bibliotecario puede desconfiar de los datos sugeridos por OCR o del motor de recomendaciones, y optar por ignorar las asistencias automáticas.

##### **Aceleradores:**

- Alta adopción de la app móvil por parte de los lectores, lo que automatiza casi por completo las reservas y la comunicación.

- La mayoría de los libros modernos ya tienen el ISBN impreso como código de barras, lo que permite cargar la información de forma mucho más rápida.

- Retroalimentación constante del bibliotecario corrigiendo datos, lo que entrena rápidamente al sistema.

## 9. Interfaces

Se organizan según el rol de quien interactúa con el sistema: el lector, el bibliotecario y la propia biblioteca.

### Interfaz de Entrada

• **Lector**: alta de cuenta, búsquedas en el catálogo, solicitudes de reserva o cancelación, valoraciones de libros leídos y escaneo de su QR en mostrador, todo desde la app de celular.

• **Bibliotecario**: fotos de tapa, contratapa y ficha técnica al cargar un libro nuevo, escaneo del QR de cada ejemplar en préstamos y devoluciones, y validación o corrección de los datos sugeridos por el reconocimiento automático.

### Interfaz de Procesamiento

El análisis de la IA se visualiza distinto según a quién esté dirigido. Al bibliotecario se le muestra una pantalla de revisión con los datos sugeridos (título, autor, sinopsis, portada), resaltando los campos de menor confianza para que los confirme o corrija antes de aprobar el alta. Al lector, en cambio, el procesamiento queda oculto: solo ve el resultado, integrado como recomendaciones dentro del catálogo de su app.

### Interfaz de Salida

• **Lector**: notificaciones de vencimiento próximo o liberación de una reserva, y recomendaciones personalizadas de lectura dentro de la app.

• **Bibliotecario**: un dashboard con indicadores de uso (préstamos por título, devoluciones tardías, lectores más activos) y alertas operativas, como ejemplares vencidos o multas pendientes.

#### Arquitectura del Sistema de Biblioteca Inteligente

<!-- Start of picture text -->
APIs Externas de Libros — Aplicación Móvil del Lector, Infraestructura en la Nube y Núcleo de IA, Panel de Escritorio del Bibliotecario — Búsqueda de Libros / Agente de Captura / Entrada de Fotografías — Reserva por 48 Horas / Agente de Análisis / Agente de Planificación — Perfil / QR del Usuario / Agente de Evaluación / Agente de Aprendizaje — Impresión de Etiquetas QR
<!-- End of picture text -->

Flujo de agentes

<!-- Start of picture text -->
Flujo de Agentes en Sistema de Biblioteca — Information Capture Agent (OCR y Escaneo QR) — Analyzer Agent (Búsqueda Web y Enriquecimiento de Datos) — Validación Humana Estricta (Filtro de Aprobación del Bibliotecario) — Planning Agent (Notificaciones y Asignación de Reservas) — Evaluator Agent (Monitoreo de Retrasos y Métricas) — Learning Agent (Ajuste de Reglas y Recomendaciones)
<!-- End of picture text -->

<!-- Start of picture text -->
Learning / AI Decision Cycle / Planning
<!-- End of picture text -->

<!-- Start of picture text -->
Book Search / Profile — Search for books — The Great Gatsby (Classic, F. Scott Fitzgerald) — Sapiens: A Brief History of Humankind (Non-fiction, Yuval Noah Harari) — The Midnight Library (Matt Haig) — Scan QR Code — Laura Simmons, laura.simmons@email.com — Active Reservations: To Kill a Mockingbird (Due Sep 20, 2022), Ready for Pickup: 1984 (Sep 25, 2022), Checked Out — Popular Now: 1984 — Home, Search, Reservations, Profile
<!-- End of picture text -->

<!-- Start of picture text -->
Dashboard / Reports / Inventory / Settings — Most Read Genres (Fiction, Non-Fiction, Mystery, Sci-Fi, Biography) — Loan Peaks (Mon–Sun) — On-time Returns — Return Rate 98% — Books Returned 320 — Late Returns 25
<!-- End of picture text -->
