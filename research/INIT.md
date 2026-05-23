# Research Framework — Inicialización

Este fichero contiene las instrucciones para instalar el Research Framework en el proyecto actual.

## Cómo invocar

El usuario debe decirle a Claude algo como:
- `"ejecuta research/INIT.md"`
- `"inicializa el research framework"`
- `"instala el framework de research en este proyecto"`

Claude leerá este fichero y seguirá los pasos a continuación.

---

## Instrucciones de instalación

### Paso 1 — Verificar que el framework está presente

Comprueba que existe el directorio `research/` en la raíz del proyecto actual con los subdirectorios esperados (`config/`, `agents/`, `data/`, `wip/`, `state/`).

- Si no existe → informa al usuario: "El directorio `research/` no está presente. Copia primero la carpeta del framework al proyecto."
- Si existe → continúa.

### Paso 2 — Verificar que no está ya inicializado

Busca el bloque `<!-- RESEARCH:START -->` en el fichero `CLAUDE.md` de la raíz del proyecto.

- Si ya existe → informa al usuario: "El Research Framework ya está inicializado en este proyecto (bloque RESEARCH encontrado en CLAUDE.md)." y detente.
- Si no existe → continúa.

### Paso 3 — Añadir @filepath al CLAUDE.md

Busca el fichero `CLAUDE.md` en la raíz del proyecto. Si no existe, créalo vacío.

Añade el siguiente bloque al **final** del fichero:

```
<!-- RESEARCH:START -->
@research/RESEARCH.md
<!-- RESEARCH:END -->
```

### Paso 4 — Actualizar .gitignore

Busca el fichero `.gitignore` en la raíz del proyecto. Si no existe, créalo.

Añade las siguientes líneas si no están ya presentes:

```
research/wip/
research/state/
```

### Paso 5 — Confirmar instalación

Muestra al usuario el siguiente mensaje:

```
Research Framework inicializado correctamente.

Se ha añadido a tu CLAUDE.md:
  @research/RESEARCH.md

Directorios gitignored:
  research/wip/
  research/state/

Próximos pasos:
  1. Reinicia Claude Code para que el @filepath cargue en el contexto.
  2. Añade ficheros .md de proyectos de referencia en research/data/market/
  3. Pide a Claude: "analiza este proyecto: [descripción]"
```

---

## Notas

- Este fichero solo debe ejecutarse una vez por proyecto.
- Para desinstalar: elimina el bloque `<!-- RESEARCH:START/END -->` del CLAUDE.md y el directorio `research/`.
- Para añadir nuevos agentes de research: crea un fichero `.md` en `research/agents/` y regístralo en `research/config/workflow.yaml`.
