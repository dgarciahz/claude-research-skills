# per--stack — Gestión de IT Stack Docs

Añade o actualiza entradas en los stack docs de `$CLAUDE_PERSONAL_DIR/IT_stacks/`.

## Cuándo activar
- El usuario invoca `/per--stack [texto]`
- El usuario pide "añadir al stack", "actualizar stack", "guardar en stack", etc.

## Flujo

### Paso 1 — Leer CLAUDE_PERSONAL_DIR
Obtén la ruta desde la variable de entorno `CLAUDE_PERSONAL_DIR`. Si no está definida, informa y detente.

### Paso 2 — Identificar stack file
Lee `$CLAUDE_PERSONAL_DIR/IT_stacks/_index_stacks.md`. Determina a qué fichero pertenece la nueva info. Si no es obvio, muestra la tabla al usuario y pregunta.

### Paso 3 — Leer el stack file
Lee el fichero completo.

### Paso 4 — Check de deduplicación
Busca contenido similar o contradictorio en la sección relevante:
- Si hay solapamiento sin contradicción → informa y pregunta si actualizar o añadir igualmente.
- Si hay contradicción → muestra ambas versiones y pregunta qué mantener.
- Si no hay solapamiento → continúa.

### Paso 5 — Identificar sección de destino
Determina a qué sección (`##`) del stack file pertenece la nueva info. Si no existe la sección, créala.

### Paso 6 — Escribir
Añade la entrada en la sección correspondiente. Formato: prosa concisa, sin fecha, sin campos Contexto/Feedback/Regla (eso es para learnings). Si se actualiza una entrada existente en lugar de añadir, reemplaza solo esa línea/bloque.

### Paso 7 — Confirmar
Muestra el bloque añadido/modificado tal como quedó en el fichero.

## Notas
- Nunca sobreescribas una sección entera — solo la entrada afectada.
- Si el usuario quiere crear un stack file nuevo (nueva plataforma): crea el `.md` en `IT_stacks/` con cabecera y secciones iniciales, y añade la fila correspondiente en `_index_stacks.md`.
