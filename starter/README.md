# Starter Framework

Framework base de Claude Code. Proporciona skills reutilizables, output styles y sistema de personalización persistente.

## Cómo inicializar

Dile a Claude:

```
"ejecuta starter/INIT.md"
```

o cualquier variante como "inicializa el proyecto" o "inicializa el starter framework". Claude leerá `starter/INIT.md` y configurará todo.

INIT.md es idempotente — puede ejecutarse múltiples veces sin duplicar configuración. Re-ejecútalo después de `sys--template-pull` para aplicar cambios del template.

## Contenido

```
starter/
├── INIT.md               ← instalador autocontenido e idempotente
├── README.md             ← este fichero
└── assets/
    ├── config.yaml       ← configuración declarativa (MCP servers, permisos, output styles)
    ├── caveman.md        ← output style minimalista
    ├── statusline-command.sh  ← script de statusline para Claude Code
    └── version-check.sh  ← comprueba versión del template al arranque
```

## Skills disponibles (tras inicializar)

| Skill | Descripción |
|-------|-------------|
| `/gh--pull` | Sincroniza la rama local con el remote (git pull) |
| `/gh--push` | Commit y push a GitHub con mensaje de commit generado automáticamente |
| `/per--handoff` | Crea o recupera un documento de handoff para retomar trabajo en la próxima sesión |
| `/per--history` | Lee el historial de sesiones y presenta un resumen ponderado por antigüedad |
| `/per--learn` | Añade aprendizajes a `learnings.md` en `CLAUDE_PERSONAL_DIR` |
| `/per--session-close` | Genera un resumen de la sesión y lo guarda en el historial persistente |
| `/sys--context-report` | Regenera `project-tools.html` con información actualizada de MCP servers y skills |
| `/sys--template-pull` | Actualiza skills y framework del proyecto desde el template `claude-starter` |
| `/sys--template-push` | Propaga mejoras de skills desde el proyecto al template `claude-starter` |

## Actualizar el framework

Para recibir mejoras del template en tu proyecto:

```
/sys--template-pull
```

Después de hacer pull, re-ejecuta `starter/INIT.md` para aplicar cambios en la configuración.

Para propagar mejoras de skills desde tu proyecto al template:

```
/sys--template-push
```

## Personalización

El sistema de personalización persiste en `$CLAUDE_PERSONAL_DIR/` (fuera del repo). Se configura durante `INIT.md`. Ficheros:

- `soul.md` — identidad y principios de Claude
- `user.md` — preferencias del usuario
- `learnings.md` — observaciones acumuladas
- `learnings/` — ficheros temáticos de aprendizajes
- `history/` — historial de sesiones
