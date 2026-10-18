# Starter Framework

Framework base de Claude Code. Proporciona skills reutilizables, output styles y sistema de personalización persistente.

## Cómo inicializar

Dile a Claude:

```
"ejecuta starter/INIT.md"
```

o cualquier variante como "inicializa el proyecto" o "inicializa el starter framework". Claude leerá `starter/INIT.md` y configurará todo.

INIT.md es idempotente — puede ejecutarse múltiples veces sin duplicar configuración. Re-ejecútalo después de `sys--template-pull starter` para aplicar cambios del template.

## Contenido

```
starter/
├── INIT.md               ← instalador autocontenido e idempotente
├── README.md             ← este fichero
├── assets/
│   ├── config.yaml            ← configuración declarativa (MCP servers, permisos, output styles)
│   ├── caveman.md             ← output style minimalista
│   ├── destructive-check.sh   ← PreToolUse hook para operaciones destructivas (opt-in)
│   ├── statusline-command.sh  ← script de statusline para Claude Code
│   └── version-check.sh       ← comprueba versión del template al arranque
└── skills/               ← pseudo-skills (invocación explícita por ruta)
    ├── per--handoff.md   ← crea/recupera documentos de handoff entre sesiones
    └── sys--context-report.md ← regenera project-tools.html con MCP servers y skills
```

## Pseudo-skills (invocación por ruta explícita)

Los pseudo-skills no se cargan en el contexto por defecto. Se invocan dando la ruta al fichero:

```
"ejecuta starter/skills/per--handoff.md"
"ejecuta starter/skills/sys--context-report.md"
```

## Skills disponibles (tras inicializar)

| Skill | Descripción |
|-------|-------------|
| `/gh--pull` | Sincroniza la rama local con el remote (git pull) |
| `/gh--push` | Commit y push a GitHub con mensaje de commit generado automáticamente |
| `/per--history` | Lee el historial de sesiones y presenta un resumen ponderado por antigüedad |
| `/per--add-task` | Declara una tarea durante la sesión; `per--session-close` la valida al cerrar |
| `/per--session-close` | Genera un resumen de la sesión y lo guarda en el historial persistente |
| `/sys--template-pull <fw>` | Actualiza skills y framework `<fw>` del proyecto desde su repo template |
| `/sys--template-push <fw>` | Propaga mejoras de skills y del framework `<fw>` desde el proyecto a su repo template |

## Actualizar el framework

Para recibir mejoras del template en tu proyecto:

```
/sys--template-pull starter
```

Después de hacer pull, re-ejecuta `starter/INIT.md` para aplicar cambios en la configuración.

Para propagar mejoras de skills desde tu proyecto al template:

```
/sys--template-push starter
```

## Personalización

El sistema de personalización persiste en `$CLAUDE_PERSONAL_DIR/` (fuera del repo). Se configura durante `INIT.md`. Ficheros:

- `soul.md` — identidad y principios de Claude
- `user.md` — preferencias del usuario
- `history/` — historial de sesiones
