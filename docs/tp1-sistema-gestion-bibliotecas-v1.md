# Sistema de Gestión de Bibliotecas 

Tomás Bacchetta Julio Flores Matías Ledesma Alex Raza 

_Curso IA para Desarrolladores_ 

## 1. Descripción del problema 

### ¿Qué problema se desea resolver? 

Las bibliotecas (públicas, escolares e institucionales) gestionan hoy su operación diaria de forma manual o con herramientas desconectadas entre sí: planillas o fichas físicas para socios, registros en papel o cuadernos para préstamos y devoluciones, y carga manual y lenta de cada libro nuevo al catálogo. Esto genera baja visibilidad sobre qué libros están disponibles en cada momento, demoras evitables en el mostrador y dependencia total del personal presente para cualquier consulta. Además, cierto _aggiornamento_ en la interacción entre el lector y la biblioteca es siempre bienvenido, ya que a pesar de todo, hoy en día las bibliotecas siguen siendo instituciones con un saldo muy positivo para con la sociedad, y ese vínculo debe afianzarse en este pleno siglo XXI. 

### ¿A quién afecta? 

• **Lectores/socios** : no pueden saber si un libro está disponible sin acercarse o llamar a la biblioteca, ni reservarlo con anticipación, y además, el aviso de vencimiento de préstamo podría canalizarse de una forma más eficiente. 

• **Bibliotecarios** : pierden tiempo en tareas repetitivas (carga manual de datos editoriales, búsqueda de ejemplares, control de vencimientos uno por uno) en lugar de dedicarlo a la atención del lector, orientación, talleres y otras actividades que promocionen la lectura, etc. Incluso poder leer. 

• **Biblioteca** : Tal vez no cuenta con datos centralizados y confiables (este sistema facilitaría rehacer la carga) sobre su propio inventario y su nivel de uso, lo que dificulta decisiones de compra, baja o promoción de material. Cualquier ahorro de esfuerzo en tareas repetitivas, permite que los empleados se enfoquen en tareas críticas como la conservación y puesta a punto de los ejemplares, entre muchas otras más. 

1 

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

2 

### ¿Qué resultados se esperan? 

- Disponibilidad del catálogo consultable en tiempo real, las 24 horas, desde el celular del lector. 

- Reducción significativa del tiempo que toma dar de alta un libro nuevo al  inventario, frente a la carga manual de cada dato. 

- Bibliotecario con carga de horas liberada de tareas repetitivas, pudiendo enfocarse en tareas más acordes a su formación y oficio. 

- Disminución de préstamos vencidos por falta de aviso, gracias a notificaciones automáticas. 

- Un inventario físico totalmente trazable: cada ejemplar identificable de forma inequívoca con su QR. 

### ¿Qué decisiones o recomendaciones podrá generar? 

• Para el **lector** : recomendaciones personalizadas de lectura en base a su historial y a la popularidad general, y alertas de cuándo retirar una reserva o devolver un préstamo antes de la fecha límite. 

• Para el **bibliotecario** : sugerencias de datos editoriales y de catalogación (sinopsis, género, portada) al cargar un libro nuevo, que el bibliotecario revisa y confirma antes de incorporarlas. Parcial o totalmente transparente también al lector en su aplicación web. 

• Para la **biblioteca** : indicadores de uso (títulos más prestados, lectores más activos, materiales con alta demora) que orientan decisiones de compra, refuerzo de ejemplares o promoción de ciertos títulos. 

## 3. Entradas del sistema 

Información que la aplicación necesita recibir o capturar para funcionar, agrupada por origen. 

|**Categoría de entrada**|**Detalle**|
|---|---|
|Datos ingresados por el lector|Alta de cuenta propia (o vinculación con<br>código entregado en mostrador),<br>búsquedas, solicitudes de reserva,<br>cancelaciones, valoraciones/comentarios<br>de libros leídos, preferencias de notificación<br>y géneros de interés.|
|Datos ingresados por el bibliotecario|Alta y modificación de lectores (datos<br>personales, categoría, tutor si es menor),<br>validación/corrección de datos de libros tras<br>el reconocimiento automático, registro de<br>condición física del ejemplar, registro de<br>bajas, confirmación de préstamos y<br>devoluciones.|



3 

|Imágenes capturadas (cámara)|Tres fotos por libro nuevo: tapa, contratapa<br>y página con ficha tecnica (ISBN, autor,<br>editorial, año y lugar de edición), usadas<br>como entrada para el reconocimiento<br>automático utilizando OCR (reconocimiento<br>óptico de caracteres) y visión por<br>computadora.|
|---|---|
|Lectura de código QR|Escaneo del QR único de cada ejemplar al<br>momento de préstamo, devolución o<br>reimpresión de etiqueta y escaneo del QR<br>del lector como identificación rápida en<br>mostrador.|
|Datos históricos propios del sistema|Historial de préstamos y reservas por lector<br>y por título, historial de multas, fechas de<br>alta y baja de ejemplares, estado de<br>validación de cada título cargado.|
|Información externa enriquecida (agente de<br>búsqueda)|Datos complementarios obtenidos de<br>internet a partir del ISBN/título/autor:<br>sinopsis, género o categoría, cantidad de<br>páginas, portada en alta resolución,<br>valoraciones externas|
|Calendario / tiempo|Fechas de vencimiento de préstamo,<br>plazos de retiro de reservas, frecuencia de<br>los recordatorios automáticos<br>(parametrizable por categoría de lector).|
|Indicadores de negocio (uso interno)|Cantidad de préstamos por título/categoría,<br>tasa de devoluciones tardías, ranking de<br>títulos más reservados, lectores con mayor<br>actividad usados para reportes y<br>recomendaciones|
|Registros de actividad (auditoría)|Quién y cuándo dio de alta o baja un libro o<br>lector, reimpresiones de etiquetas QR,<br>cambios manuales sobre datos sugeridos<br>por el reconocimiento automático.|
|Parámetros de configuración|Límites de préstamos y reservas<br>simultáneas, plazos de devolución y de<br>retiro de reserva por categoría de lector<br>definidos por el Administrador.|



## 4. Procesos internos 

4 

La aplicación se apoya en una red de agentes especializados, que operan de forma coordinada desde la captura de la información hasta la generación de recomendaciones y reportes. 

### 1. Agente de Captura de Información (Visión y QR) 

**Función:** Se encarga de digitalizar y registrar los estímulos e interacciones del entorno físico hacia el sistema. Procesa las tres fotos obligatorias tomadas por el bibliotecario (tapa, contratapa y página técnica) aplicando técnicas de reconocimiento óptico de caracteres (OCR) y visión computacional. Asimismo, gestiona la lectura de los códigos QR únicos de cada ejemplar físico durante los procesos de préstamo, devolución o auditoría de inventario, al igual que el escaneo del QR identificatorio del lector en el mostrador. 

**Interacción con otros agentes:** Extrae el texto crudo de las imágenes y aísla la cadena numérica del ISBN para enviarlos de forma directa al Agente Analizador para su estructuración y validación. 

### 2. Agente Analizador y de Enriquecimiento 

**Función:** Actúa como el procesador de lenguaje y datos de la aplicación. Su tarea principal consiste en clasificar gramaticalmente y estructurar el texto crudo enviado por el agente anterior en campos editoriales definidos (título, autor, editorial, año). Si detecta un ISBN válido, activa un sub-agente de búsqueda externa en internet para recopilar información complementaria como sinopsis, género preciso, cantidad de páginas y portadas en alta resolución. También procesa y analiza las entradas del lector, tales como búsquedas, preferencias temáticas e intereses de notificación. 

**Interacción con otros agentes:** Presenta los datos estructurados y enriquecidos en la interfaz para que el bibliotecario valide o corrija la ficha. Una vez confirmada la carga, almacena la información limpia en la memoria persistente del sistema y distribuye los nuevos datos tanto al Agente Planificador como al Agente Evaluador. 

### 3. Agente Planificador y de Gestión Operativa (Alertas) 

**Función:** Es el administrador del tiempo, los flujos de trabajo y la agenda operativa del sistema. Monitorea permanentemente las variables temporales del calendario (fechas de vencimiento de préstamos, plazos máximos para retirar una reserva en mostrador y plazos parametrizables por tipo de socio). Su propósito es programar cronológicamente y disparar de forma automática las tareas de comunicación proactiva. 

**Interacción con otros agentes:** Utiliza las reglas de negocio provistas por el administrador y las alertas generadas para enviar notificaciones push directas a la aplicación de celular del lector afectado. Adicionalmente, reporta al Agente Evaluador los estados de cumplimiento de plazos para actualizar las métricas operativas. 

5 



<!-- Start of picture text -->
Observacién<br>Nueva observacion Analisis<br>ciclo<br>Aprendizaje Planificacién<br>Evaluacién Accién<br><!-- End of picture text -->

**Observación** : Se registran los eventos, ya sea nuevos usuarios, búsquedas, reservas, préstamos, devoluciones a tiempo o tardías. Altas de libros en inventario. _(agente evaluador)_ 

**Análisis** : Esos eventos se agregan en indicadores: títulos más reservados, lectores que incumplen frecuentemente, tiempos de carga de inventario. _(agente analizador)_ 

**Planificación** : El bibliotecario o administrador decide qué ajuste realizar: por ejemplo plazos de entrega por categoría, refuerzo de ejemplares, prioridad de notificación. _(agente planificador)_ 

**Acción** : El sistema ejecuta: envía notificaciones, libera o asigna reservas, sugiere recomendaciones, aplica los nuevos parámetros. _(agente planificador/agente evaluador)_ 

**Evaluación** : Se mide si por ejemplo disminuyeron los incumplimientos, si hay menos libros requeridos ya reservados, etc. _(agente evaluador)_ 

**Aprendizaje** : Si algo funcionó, se agrega como nueva regla o se refina el criterio de recomendación para el próximo ciclo. _(agente de aprendizaje)_ 

**Nueva observación** : Se empieza de nuevo el ciclo pero con reglas y recomendaciones aún mejores. _(agente evaluador)_ 

## 6. Memoria persistente 

|**Nombre**|**Descripción**|**Tipo de agente**|
|---|---|---|
|Historial de lectores|Préstamos realizados (libro,<br>fecha, si se devolvió a<br>tiempo o tarde), reservas<br>hechas/canceladas/vencida<br>s sin retirar, valoraciones y<br>comentarios, búsquedas en<br>el catálogo|Agente de recomendación,<br>agente planificador|
|Preferencias declaradas|Géneros de interés,<br>frecuencia y canal de<br>notificación preferido,<br>categoría de lector|Agente de recomendación,<br>agente planificador|
|Decisiones anteriores del<br>sistema|Qué dato sugirió del agente<br>de<br>reconocimiento/enriquecimi<br>ento en cada alta de libro,<br>qué recomendación de<br>lectura se le mostró a cada<br>lector, qué notificación se<br>envió y cuándo|Agente evaluador, agente<br>de recomendación, agente<br>planificador|
|Resultados obtenidos|Si el biblioteca aceptó,|Agente evaluador, agente|



7 

|(feedback humano)|corrigió o rechazó cada<br>sugerencia de catalogación;<br>si el lector aceptó o ignoró<br>una recomendación; si una<br>notificación logró evitar la<br>demora en la devolución|de recomendación, agente<br>planificador|
|---|---|---|
|Eventos registrados<br>(auditoría)|Altas/Bajas de libros y<br>lectores (quién, cuándo),<br>reimpresiones de QR,<br>confirmaciones de<br>préstamo/devolución por<br>escaneo|Agente de auditoría, agente<br>analizador de inficadores|
|Indicadores agregados|Préstamos por<br>título/categoría, tasa de<br>devoluciones tardías,<br>ranking de títulos<br>reservados, lectores más<br>activos|Agente analizador de<br>indicadores|



## 7. Reglas, parámetros y restricciones 

- **Regla de Validación Estricta:** Ningún libro nuevo ingresa al catálogo público visible sin la aprobación final (clic de confirmación) del bibliotecario, por más que la IA tenga un 100% de confianza en los datos. 

- **Regla de Préstamos y Restricciones:** Un usuario no puede reservar nuevos libros si posee material con fecha de devolución vencida o multas impagas. Límite máximo de ejemplares simultáneos parametrizable según la categoría del socio (ej. 3) 

- **Priorización de Reservas:** Las reservas se otorgan por estricto orden cronológico. El sistema retiene el libro reservado por un máximo de 48 hs; si no es retirado, pasa automáticamente al siguiente en la lista de espera. 

## 8. Frenos y aceleradores 

##### **Frenos** : 

- Mala iluminación, reflejos o cámaras de baja resolución al momento de tomar las fotos de los libros, lo que reduce drásticamente la eficacia del OCR. 

- Etiquetas QR físicas que se desgasten o rompan con el uso, dificultando el escaneo en el mostrador. 

- El bibliotecario puede desconfiar de los datos sugeridos por OCR o del motor de recomendaciones, y optar por ignorar las asistencias automáticas. 

##### **Aceleradores:** 

- Alta adopción de la app móvil por parte de los lectores, lo que automatiza casi por completo las reservas y la comunicación. 

- La mayoría de los libros modernos ya tienen el ISBN impreso como código de barras, lo que permite cargar la información de forma mucho más rápida. 

8 

- Retroalimentación constante del bibliotecario corrigiendo datos, lo que entrena rápidamente al sistema. 

## 9. Interfaces 

Se organizan según el rol de quien interactúa con el sistema: el lector, el bibliotecario y la propia biblioteca. 

### Interfaz de Entrada 

• **Lector** : alta de cuenta, búsquedas en el catálogo, solicitudes de reserva o cancelación, valoraciones de libros leídos y escaneo de su QR en mostrador, todo desde la app de celular. 

• **Bibliotecario** : fotos de tapa, contratapa y ficha técnica al cargar un libro nuevo, escaneo del QR de cada ejemplar en préstamos y devoluciones, y validación o corrección de los datos sugeridos por el reconocimiento automático. 

### Interfaz de Procesamiento 

El análisis de la IA se visualiza distinto según a quién esté dirigido. Al bibliotecario se le muestra una pantalla de revisión con los datos sugeridos (título, autor, sinopsis, portada), resaltando los campos de menor confianza para que los confirme o corrija antes de aprobar el alta. Al lector, en cambio, el procesamiento queda oculto: solo ve el resultado, integrado como recomendaciones dentro del catálogo de su app. 

### Interfaz de Salida 

• **Lector** : notificaciones de vencimiento próximo o liberación de una reserva, y recomendaciones personalizadas de lectura dentro de la app. 

• **Bibliotecario** : un dashboard con indicadores de uso (préstamos por título, devoluciones tardías, lectores más activos) y alertas operativas, como ejemplares vencidos o multas pendientes. 

9 

#### Arquitectura del Sistema de Biblioteca Inteligente 



<!-- Start of picture text -->
APIs Externas<br>de Libros<br>“ =<br>Aplicacién Movil Infraestructura en la Nube Panel de Escritorio<br>del Lector y Nucleo de IA del Bibliotecario<br>LsQj Oo" -@" Entrada de<br>Busqueda de Libros- raAgente de Capturaon Fotografias<br>:<br>\<br>z: -@ @-— foE x tracciénx de<br>Reserva por 48 Horas Agente de Analisis Agente de Planificacion<br>AS ay‘ J SS ImpresionEtiquetas QR de<br>Perfil QR del Usuario Agente de Evaluacion = Agente de Aprendizaje<br><!-- End of picture text -->

Flujo de agentes 

11 



<!-- Start of picture text -->
Flujo de Agentes en Sistema de Biblioteca<br>mm 'nformation Capture Agent<br>; OCR y Escaneo QR<br>| ‘ \ Analyzer Agent |<br>| Q Busqueda Weby Enriquecimiento de Datos<br>3 Validacion Humana Estricta<br>aig Filtro de Aprobacion del Bibliotecario<br>a +] Planning Agent<br>— Notificaciones y Asignacion de Reservas<br>(~s Evaluator Agent<br>‘ aul Monitoreo de Retrasos y Meétricas<br>ON=  AjusteLearningde Reglas Agenty Recomendaciones |<br><!-- End of picture text -->



<!-- Start of picture text -->
Learning<br>Al<br>Decision Cycle<br>Planning<br><!-- End of picture text -->



<!-- Start of picture text -->
Book Search == Profile =<br>Q Search for books<br>“:<br>Recommendations<br>Haug The Great Gatsby Laura:  Simmons;<br>aame ClassicF. Scott .FitzarrisdFictior > laura.simmons@email.com<br>ig Scan QR Code<br>i Sapiens: A Brief History<br>BIRCINS of Humankind ><br>SF Ywial Noah Harar Active Reservations<br>TheMatt HaigMidnight Library 2)WH ToDue:KillSep a 20,Mockingbird2022 ><br>Ready for Pickup<br>Popular Now _ 1984<br>:<br>e 1984 Sep 25, 2022 ><br>1984 DUNG meme = Checked Out<br>z a View All<br>@<br>Home Search Reservations Profile Home Search Reservations Profile<br><!-- End of picture text -->



<!-- Start of picture text -->
f& Dashboard Reports Inventory Settings a 9°<br>Most Read Genres Loan Peaks<br>»11% a 34% FictionNon-Fiction anAg »<br>’<br>18%>,i x» 25%oe| @™@ MysterySci-Fi ps2 f iascead. |he~*~<br>18%% ® Biograph'& id Mon Tue Wed Thu Fri Sat Sun<br>#) On-time Returns<br>(> fs)<br>Return Rate Books Returned “ Late Returns =_ ae<br>Se  98% "| 320 ©) 25<br><!-- End of picture text -->

