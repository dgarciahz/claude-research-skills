# Research Framework — Template Push

Cuando el usuario diga "research push", "sube los cambios al framework" o similar, ejecuta este flujo para commitear y subir cambios del core directamente a `main`.

## Cuándo activar

- "research push"
- "sube los cambios al framework"
- "actualiza el repo del framework"

## Flujo

### Paso 1 — Leer la URL de origen

Lee `research/config/config.yaml` y extrae `source.upstream_url`.

### Paso 2 — Identificar cambios en el core

Comprueba qué ficheros del core han cambiado respecto al último commit:

```bash
git diff HEAD -- research/agents/ research/assets/ research/config/ research/skills/ research/market/ research/RESEARCH.md research/INIT.md research/README.md
```

Si no hay cambios en el core, informa: "No hay cambios en el framework core para subir." y termina.

Muestra al usuario la lista de ficheros modificados y pide confirmación antes de continuar.

### Paso 3 — Commitear y subir a main

Stagea y commitea solo los ficheros del core:

```bash
git add research/agents/ research/assets/ research/config/ research/skills/ research/market/ research/RESEARCH.md research/INIT.md research/README.md
git commit -m "feat(research): <descripción del cambio>"
git push origin main
```

Los ficheros locales del usuario (`data/projects/`, `wip/`, `state/`) no se incluyen en ningún caso. `market/` sí se incluye — es core del framework.

### Paso 4 — Confirmar

Muestra al usuario un resumen de los ficheros subidos.

## Notas

- Este skill nunca modifica `research/data/`, `research/wip/` ni `research/state/`. Sí incluye `research/market/` en el push.
- Este skill nunca modifica los remotes git del repo del usuario.
- El repo de origen está definido en `research/config/config.yaml` bajo `source`.
