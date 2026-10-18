# Learnings — Registro de Feedback y Correcciones

Registro acumulativo de errores pasados, correcciones del usuario y patrones a evitar o repetir.
Actualizar con `/core--session-close` o manualmente tras recibir feedback relevante.

---

<!-- Añadir entradas en formato:
## YYYY-MM-DD — [tema]
**Contexto**: qué se estaba haciendo
**Error/feedback**: qué salió mal o qué corrigió el usuario
**Regla**: qué hacer (o no hacer) en el futuro
-->

## 2026-05-02 — Check de seguridad antes de incorporar recursos externos
**Contexto**: instalación del paquete `notebooklm-mcp-cli` que requería login con cuenta de Google
**Feedback**: el usuario preguntó si podría ser un troyano — señal de que hay que hacer el check de seguridad proactivamente, sin esperar a que el usuario lo pida
**Regla**: antes de incorporar cualquier skill, subagente, MCP server o paquete externo (npm, pip, etc.), hacer verificación activa de legitimidad: repo oficial, licencia open source, estrellas/actividad en GitHub, scans CI de seguridad, firma criptográfica, y confirmar que las credenciales no se transmiten a terceros. Descargar siempre del proveedor original. Reportar el resultado al usuario antes de proceder, aunque sea positivo.

## 2026-06-07 — Limpiar residuos tras reingeniería
**Contexto**: durante refactorizaciones o reorganizaciones de estructura de archivos/directorios
**Feedback**: al mover contenido a nuevas ubicaciones, quedaban directorios vacíos y materiales obsoletos sin eliminar — acumulación silenciosa de basura vestigial
**Regla**: cuando un directorio quede vacío tras mover su contenido, eliminarlo. Si hay duda sobre si el material antiguo sigue siendo útil, preguntar antes de dejarlo — nunca operar en modo silencioso dejando residuos

## 2026-06-20 — Primary working directory incorrecto con .code-workspace
**Contexto**: al abrir proyectos en VSCode con Claude Code activo
**Feedback**: cuando se usa un `.code-workspace` (atajo de workbench), Claude Code se queda con el último folder abierto como Primary working directory, no el del workspace activo
**Regla**: si el working directory parece incorrecto, sospechar que el proyecto se abrió via `.code-workspace`. La detección correcta solo ocurre cuando VSCode abre el proyecto como folder directo

## 2026-06-28 — Mensajes de estado/diagnóstico via stderr
**Contexto**: el usuario pide implementar un mensaje de estado o diagnóstico que pueda ver en pantalla
**Feedback**: Claude implementaba el mensaje de forma visible solo en su propio contexto, no en la pantalla del usuario
**Regla**: implementar mensajes de estado/diagnóstico via stderr y confirmar explícitamente al usuario que lo verá en su pantalla, no solo en el contexto de Claude

## 2026-06-28 — Permisos Bash en init: específicos y con aviso previo
**Contexto**: pasos de inicialización de frameworks o setups que requieren permisos Bash amplios
**Feedback**: Claude pedía permisos con wildcards amplios sin avisar qué comandos concretos los necesitaban ni cuáles requerirían confirmación manual del usuario
**Regla**: cuando un paso de init necesite permisos Bash, listar los comandos específicos requeridos en lugar de un wildcard, e informar al usuario de antemano cuáles necesitarán su confirmación manual

## 2026-06-28 — Definir off-limits al crear skills o subagentes
**Contexto**: diseño de skills, pseudo-skills o subagentes en frameworks de Claude Code
**Feedback**: sin límites explícitos, el skill actúa por defecto en zonas grises que el usuario no había pensado — toca ficheros, directorios o sistemas fuera del scope previsto
**Regla**: al crear cualquier skill, pseudo-skill o subagente, además de definir qué hace y cuándo aplica, preguntar y documentar explícitamente qué está off-limits: qué no debe tocar, qué no debe asumir, qué debe rechazar. Claude debe identificar proactivamente las zonas grises — comportamientos ambiguos que el usuario probablemente no ha pensado — para que el usuario decida antes de finalizar el diseño.

## 2026-05-01 — Diseño para concurrencia por defecto
**Contexto**: diseño y escritura de código de aplicaciones
**Feedback**: el usuario espera que el código se piense desde el inicio para soportar cargas elevadas de usuarios concurrentes
**Regla**: al escribir código (APIs, servicios, workers, acceso a BD, caché), asumir por defecto que habrá muchos usuarios simultáneos. Usar patrones stateless, evitar estado compartido mutable, preferir operaciones atómicas, dimensionar pools correctamente. No dejar la concurrencia como optimización posterior.


## 2026-10-04 — Sin rutas absolutas en ficheros versionados
**Contexto**: revisando los overrides de BMAD (`_bmad/custom/bmad-agent-architect.toml` y `bmad-create-architecture.toml`), que están en git pero apuntan a `C:/david/.../claude-personalization`; problema ya visto antes con rutas a aplicaciones al pasar de un despliegue a otro
**Feedback**: las rutas absolutas o específicas de máquina se cuelan en ficheros versionados y se rompen al clonar, cambiar de máquina o desplegar; el fallo aparece lejos de donde se introdujo
**Regla**: nada que se versione en git lleva rutas absolutas ni específicas de máquina (letra de unidad, `/home/...`, ejecutables de aplicaciones). Usar rutas relativas a la raíz del proyecto (`{project-root}/...`); para lo externo al repo, variable de entorno o valor de configuración. Las absolutas solo valen en capas no versionadas (`*.user.toml`, `.claude/settings.local.json`, `.env`). Si voy a escribir una ruta con letra de unidad o `/home/` en un fichero trackeado, parar y buscar otra forma. Excepción por diseño: el `CLAUDE.md` con `@C:\...` del sistema de personalización es por usuario y máquina y está gitignoreado en modo template.
