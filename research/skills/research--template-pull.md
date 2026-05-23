# Research Framework — Template Pull

Cuando el usuario diga "research pull", "actualiza el framework de research" o similar, ejecuta este flujo para actualizar el core del framework desde el repositorio de origen.

## Cuándo activar

- "research pull"
- "actualiza el framework"
- "actualiza el research framework"
- "sync framework"

## Flujo

### Paso 1 — Leer la URL de origen

Lee `research/config/config.yaml` y extrae `source.upstream_url` y `source.upstream_branch`.

### Paso 2 — Verificar el estado local

Antes de actualizar, comprueba que no hay cambios sin commitear en ficheros del core del framework:

```bash
git status research/agents/ research/config/ research/skills/ research/RESEARCH.md research/INIT.md research/README.md
```

Si hay cambios sin commitear, informa al usuario y pregunta si quiere continuar. No procedas sin confirmación.

### Paso 3 — Fetch desde upstream

Descarga el contenido del upstream directamente por URL, sin añadir ningún remote al repo del usuario:

```bash
git fetch <upstream_url> <upstream_branch>
```

### Paso 4 — Ver qué cambiaría

Muestra al usuario un diff de los ficheros del core antes de aplicar:

```bash
git diff FETCH_HEAD -- research/agents/ research/config/ research/skills/ research/RESEARCH.md research/INIT.md research/README.md
```

Si no hay cambios, informa: "El framework ya está actualizado." y termina.

### Paso 5 — Aplicar los cambios

Actualiza solo los ficheros del core. Los datos del usuario (`data/market/`, `data/projects/`) y los temporales (`wip/`, `state/`) nunca se tocan:

```bash
git checkout FETCH_HEAD -- research/agents/ research/config/ research/skills/ research/RESEARCH.md research/INIT.md research/README.md
```

### Paso 6 — Confirmar

Muestra un resumen de los ficheros actualizados. Si `RESEARCH.md` o algún skill cambiaron, recuerda al usuario:

> "Reinicia Claude Code para que los cambios en los @filepath carguen en el contexto."

## Notas

- Este skill nunca modifica `research/data/`, `research/wip/` ni `research/state/`.
- Este skill nunca añade ni modifica remotes git del repo del usuario.
- La URL de origen está en `research/config/config.yaml` bajo `source` — para cambiarla, edita ese fichero.
