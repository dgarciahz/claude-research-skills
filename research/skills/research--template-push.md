# Research Framework — Template Push

Cuando el usuario diga "research push", "contribuye mejoras al framework" o similar, ejecuta este flujo para proponer cambios en el core del framework al repositorio de origen via PR.

## Cuándo activar

- "research push"
- "contribuye cambios al framework"
- "propón mejoras al research framework"
- "abre un PR en el framework"

## Flujo

### Paso 1 — Leer la URL de origen

Lee `research/config/config.yaml` y extrae `source.upstream_url`.

### Paso 2 — Identificar cambios en el core

Comprueba qué ficheros del core han cambiado respecto al último commit:

```bash
git diff HEAD -- research/agents/ research/config/ research/skills/ research/RESEARCH.md research/INIT.md research/README.md
```

Si no hay cambios en el core, informa: "No hay cambios en el framework core para proponer." y termina.

Muestra al usuario la lista de ficheros modificados y pide confirmación antes de continuar.

### Paso 3 — Crear una rama con los cambios

Crea una rama descriptiva con los cambios del core:

```bash
git checkout -b research-improvement/<descripción-breve>
git add research/agents/ research/config/ research/skills/ research/RESEARCH.md research/INIT.md research/README.md
git commit -m "feat(research): <descripción del cambio>"
git push origin research-improvement/<descripción-breve>
```

Los ficheros de datos del usuario (`data/market/`, `data/projects/`, `wip/`, `state/`) no se incluyen en ningún caso.

### Paso 4 — Abrir el PR

Usa `gh pr create` para abrir un PR hacia el repo de origen:

```bash
gh pr create \
  --repo <upstream_url_sin_.git> \
  --head <usuario>:research-improvement/<descripción-breve> \
  --title "feat(research): <descripción>" \
  --body "<descripción detallada de los cambios>"
```

### Paso 5 — Confirmar

Muestra al usuario la URL del PR creado. El admin del framework decidirá en GitHub si aceptar, pedir cambios o rechazar la propuesta.

## Notas

- Este skill nunca modifica `research/data/`, `research/wip/` ni `research/state/`.
- Este skill nunca modifica los remotes git del repo del usuario.
- El PR se abre hacia el repo de origen definido en `research/config/config.yaml` bajo `source`.
- Requiere `gh` (GitHub CLI) autenticado en el entorno del usuario.
