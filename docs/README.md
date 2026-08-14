# Documentación de BiblioTech

Directorio de referencia del proyecto **Sistema de Gestión de Bibliotecas (BiblioTech)** —
TP del *Curso IA para Desarrolladores*, UTN.

Equipo: Tomás Bacchetta · Julio Flores · Matías Ledesma · Alex Raza

## Documentos

| Archivo | Contenido | Estado |
|---|---|---|
| [`tp1-sistema-gestion-bibliotecas-v2.md`](./tp1-sistema-gestion-bibliotecas-v2.md) | Entrega del TP 1: problema, objetivo, entradas, agentes, memoria persistente, reglas de negocio, frenos/aceleradores e interfaces. | **Canónico** — usar este como fuente de verdad |
| [`tp1-sistema-gestion-bibliotecas-v1.md`](./tp1-sistema-gestion-bibliotecas-v1.md) | Versión original del mismo documento, previa a la revisión. | Histórico — solo consulta |

### Qué cambió de v1 a v2

La v2 conserva la estructura y el texto de la v1, corrige las tablas y el texto extraído
de las imágenes, y agrega definiciones que en v1 quedaban abiertas:

- **Ponderación de recomendaciones** (§2): 70% historial personal / 30% popularidad
  general, con inversión a 100% popularidad para lectores sin historial (*cold start*).
- **Resolución de fuentes externas** (§4.2): qué hacer si el ISBN no arroja resultados
  o si dos fuentes se contradicen — nunca completar un campo de baja confianza sin marcarlo.
- **Evaluador vs. Planificador** (§4.3): el Evaluador *decide*, el Planificador *ejecuta*.
- **Continuidad de identidad ante reimpresión de QR** (§7): la reimpresión reusa el ID
  interno existente; nunca se genera uno nuevo.
- **Asignación y transición de categoría de lector** (§7): los préstamos y reservas
  activos conservan las condiciones vigentes al momento de generarse.

## Cómo usar estos documentos

Estos archivos son la **especificación funcional** del proyecto. Antes de implementar o
modificar comportamiento del sistema, verificar contra la v2 — en particular las
secciones 4 (procesos internos / agentes) y 7 (reglas, parámetros y restricciones), que
definen invariantes que el código debe respetar.

Si una decisión de implementación se aparta de lo especificado, o el documento no cubre
el caso, dejarlo explícito en el commit o en el PR en lugar de resolverlo en silencio.

## Mapa documento → código

| Concepto en el documento | Implementación |
|---|---|
| Agente Analizador y de Enriquecimiento (§4.2) | `js/agents.js` → `AgenteAnalizador` |
| Agente Planificador y de Gestión Operativa (§4.3) | `js/agents.js` → `AgentePlanificador` |
| Agente Evaluador (ciclo Observación→Evaluación, §5) | `js/agents.js` → `AgenteEvaluador` |
| Agente de Aprendizaje (§5) | `js/agents.js` → `AgenteAprendizaje` |
| Memoria persistente (§6) | `js/db.js` → `DB` (localStorage + seed data) |
| Interfaz del lector (§9) | `lector.html` |
| Interfaz del bibliotecario (§9) | `bibliotecario.html` |
| Parámetros de configuración (§3, §7) | `admin.html` |
| Estilos compartidos | `css/main.css` |

## Pendiente para la entrega final

Los requisitos de la entrega de fin de ciclo están en el [`README.md`](../README.md) raíz:
app publicada con links en vivo, diagrama de arquitectura, diagrama UML, tabla de
tecnologías justificadas, capturas del frontend, log de una sesión real de uso,
autoevaluación UX/UI contra las heurísticas de Nielsen, log de ciberseguridad con al
menos cuatro riesgos, documentación del uso de IA en co-work, y la reflexión sobre
integración de un LLM/SLM local.
