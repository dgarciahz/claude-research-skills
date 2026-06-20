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

### Paso 2b — Verificar si README.md necesita actualización

Si `research/README.md` ya está en el diff del Paso 2 (el usuario ya lo modificó), salta este paso.

Si no está en el diff, analiza los ficheros cambiados y determina si alguno afecta lo documentado en README.md:

| Cambio detectado | Sección de README afectada |
|---|---|
| Nuevo/eliminado fichero en `agents/` | Tabla de agentes en `## Agents` |
| Cambio en descripción de agente existente | Fila correspondiente en tabla de agentes |
| Nuevo/eliminado fichero en `skills/` | Diagrama de estructura en `## Deep Dive` |
| Cambios en `config/config.yaml` que afecten al pipeline | Sección `config/config.yaml — Configuración del framework` |
| Cambios en `INIT.md` que afecten al proceso de instalación | Sección `## Install & Config` |

- Si no hay impacto: informa "README.md no requiere cambios." y continúa al Paso 3.
- Si hay impacto: lee `research/README.md`, aplica las actualizaciones necesarias e informa al usuario qué secciones se modificaron. README.md se incluirá en el commit del Paso 3.

### Paso 3 — Commitear y subir a main

Stagea y commitea solo los ficheros del core:

```bash
git add research/agents/ research/assets/ research/config/ research/skills/ research/market/ research/RESEARCH.md research/INIT.md research/README.md
git commit -m "feat(research): <descripción del cambio>"
git push origin main
```

Los ficheros locales del usuario (`data/projects/`, `wip/`, `state/`) no se incluyen en ningún caso. `market/` sí se incluye — es core del framework.

### Paso 3b — Actualizar versión del framework

Tras el push del Paso 3, obtén el hash del commit recién subido y actualiza `research/config/version`:

```bash
FRAMEWORK_HASH=$(git rev-parse HEAD)
echo $FRAMEWORK_HASH > research/config/version
git add research/config/version
git commit -m "chore: actualiza versión del framework — $FRAMEWORK_HASH"
git push origin main
```

Este hash es el identificador de versión que los proyectos consumidores comparan al activar el framework.

### Paso 4 — Confirmar

Muestra al usuario un resumen de los ficheros subidos.

## Notas

- Este skill nunca modifica `research/data/`, `research/wip/` ni `research/state/`. Sí incluye `research/market/` en el push.
- Este skill nunca modifica los remotes git del repo del usuario.
- El repo de origen está definido en `research/config/config.yaml` bajo `source`.
