# Cómo contribuir — BiblioTech Backend

Guía rápida del flujo de trabajo del equipo. El objetivo es simple: que `main` sea siempre código funcionando y revisado, y que nadie pise el trabajo de otro sin querer.

## Flujo de ramas

```
feature/tu-cambio  →  develop  →  main
```

1. **Nunca se trabaja directo sobre `develop` ni `main`.** Toda tarea nueva arranca con una rama propia desde `develop` actualizada:
   ```bash
   git checkout develop
   git pull origin develop
   git checkout -b feature/nombre-descriptivo
   ```

2. **Cuando la tarea está lista**, se abre un Pull Request de `feature/nombre-descriptivo` → `develop`. Se mergea ahí primero, no directo a `main`.

3. **`main` solo recibe merges desde `develop`**, cuando develop tiene un conjunto de cambios probado y listo para mostrarse. Ese merge también va por Pull Request — `main` tiene protección activada (Rulesets) que no deja pushear directo, ni siquiera a los administradores del repo.

4. **Nomenclatura de ramas** (Conventional Branches):
   - `feature/algo-nuevo` — funcionalidad nueva
   - `fix/algo-roto` — corrección de un bug
   - `chore/algo-de-mantenimiento` — limpieza, dependencias, configuración

## Reglas activas en GitHub

- **`main`**: Pull Request obligatorio, sin force-push, sin borrado de la rama. Método de merge permitido: **Merge** únicamente (no Squash, no Rebase) — mantiene el historial completo y consistente con el resto del proyecto.
- **`develop`**: sin restricciones — es el espacio de trabajo ágil del equipo, admite push directo.

## Antes de abrir un PR a main

- [ ] Probado en local (`uvicorn main:app --reload` sin errores)
- [ ] Sin credenciales ni API keys hardcodeadas en el código (usar `.env`, ya excluido por `.gitignore`)
- [ ] Si tocaste el modelo de datos o agregaste endpoints, avisar al equipo — puede afectar el frontend o la colección de Postman

## Limpieza de ramas

Cuando un PR se mergea, borrar la rama (`Automatically delete head branches` está activado en Settings → General, así que en general se borra sola). Si por algo queda huérfana, se puede borrar manualmente desde la pestaña **Branches** del repo.
