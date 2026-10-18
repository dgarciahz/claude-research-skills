# Architect Framework

Conocimiento de arquitectura transversal para Claude Code: learnings y stacks IT compartidos entre proyectos y usuarios. Complementa al Starter Framework.

## Cómo inicializar

```
"ejecuta architect/INIT.md"
```

INIT.md comprueba que los skills están instalados y añade al `CLAUDE.md` del proyecto el bloque `ARCHITECT` con los imports de `architect/assets/`. Sin ese paso, el contenido no se carga.

## Contenido

```
architect/
├── INIT.md
├── README.md
├── config/{manifest.yaml, version}
├── skills/                  ← pseudo-skills (invocación explícita por ruta); vacío por ahora
└── assets/
    ├── learnings/           ← learnings: learnings.md (transversales), _index.md y ficheros temáticos
    └── IT_stacks/           ← recetas por plataforma (_index_stacks.md + ficheros)
```

## Skills

| Skill | Descripción |
|-------|-------------|
| `/arch--learn` | Añade aprendizajes a `architect/assets/learnings/learnings.md` o a un fichero temático de `architect/assets/learnings/` |
| `/arch--stack` | Añade o actualiza entradas en `architect/assets/IT_stacks/` |

## Actualizar

```
/core--template-pull architect
/core--template-push architect
```

Tras el pull, re-ejecutar `architect/INIT.md`. Los learnings y stacks escritos en un proyecto solo llegan al repo con `push`.
