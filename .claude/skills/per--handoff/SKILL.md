# Skill: per--handoff

Crea o recupera un documento de handoff para retomar el trabajo en una sesión futura.

## Trigger

Usar cuando el usuario invoque `/per--handoff`.

## Directorio de handoffs

`$CLAUDE_PERSONAL_DIR/handoffs/`

Si no existe, créalo antes de guardar. Si `CLAUDE_PERSONAL_DIR` no está definida, informa y detente.

---

## Resolución del modo

### Con argumento explícito

- Argumento contiene "guarda" o "guardar" → **modo guardar** con el nombre indicado
- Argumento contiene "recupera", "recuperar" o "carga" → **modo recuperar** con el nombre indicado

### Con nombre de fichero sin calificador explícito

1. Comprobar si `$CLAUDE_PERSONAL_DIR/handoffs/<nombre>` existe
   - Existe → **modo recuperar**
   - No existe → **modo guardar**, pero antes buscar ficheros con nombre similar en el directorio

   Si hay ficheros similares (diferencia mínima de caracteres, mismo prefijo, o fecha parecida), avisar:
   > "El fichero `<nombre>` no existe, pero hay ficheros similares: `<lista>`. ¿Crear nuevo o quisiste decir uno de estos?"
   
   Esperar confirmación antes de continuar.

### Sin argumento

**Modo guardar** con nombre automático: `handoff-YYYY-MM-DD-HH-MM.md`

---

## Modo guardar

### 1. Generar el documento

```markdown
# Handoff — YYYY-MM-DD HH:MM

## Contexto del proyecto
[Proyecto, objetivo general, estado actual — 2-4 frases]

## Dónde lo dejamos
[Punto exacto de interrupción: qué se estaba haciendo, qué paso o decisión quedó pendiente]

## Tareas pendientes
- [tarea con suficiente contexto para retomarse sin releer la conversación]

## Decisiones tomadas en esta sesión
- [solo las que un nuevo agente necesita conocer para continuar]

## Artefactos relevantes
[Referencias por path o URL — no duplicar contenido]
- `ruta/al/archivo.ext` — descripción breve

## Skills sugeridos para la siguiente sesión
- `/per--handoff <nombre-fichero>` — cargar este handoff
- [otros skills relevantes según el trabajo pendiente]
```

### 2. No duplicar contenido existente

Si hay artefactos ya generados (planes, PRDs, commits, diffs), **referencialos por path o URL**.

### 3. Redactar información sensible

Enmascara con `[REDACTED]`: API keys, passwords, tokens, datos personales.

### 4. Guardar y confirmar

Guardar en `$CLAUDE_PERSONAL_DIR/handoffs/<nombre>`. Confirmar:
> "Handoff guardado: `<nombre>`"

---

## Modo recuperar

### 1. Leer el fichero

Lee `$CLAUDE_PERSONAL_DIR/handoffs/<nombre>`. Si no existe, lista los ficheros disponibles y detente.

### 2. Presentar el contexto y confirmar

Muestra el contenido del handoff y confirma:
> "Handoff recuperado: `<nombre>`. Agente listo para continuar desde este punto."

No actúes sobre las tareas pendientes hasta que el usuario lo indique explícitamente.

---

## Nota general

Siempre indicar explícitamente si se ha **guardado** o **recuperado**, y el nombre exacto del fichero. Esto evita que una recuperación se malinterprete como un guardado por una mala sintaxis.
