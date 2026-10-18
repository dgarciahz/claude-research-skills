# Stack: Windows

Recetas de setup y particularidades de configuración para entornos Windows.

---

## Paths en Git Bash
Usar `//c/Users/...` (doble barra inicial) en lugar de `/c/Users/...` para evitar ambigüedad con flags de comandos.

## SSL / TLS
`git config --global http.sslBackend schannel` — delega en el store de certificados de Windows.
Para errores de revocación específicamente: añadir `--ssl-no-revoke`. Nunca usar `--insecure` ni `sslVerify=false`.

AVG Antivirus instala un root CA propio ("AVG Web/Mail Shield Root") en `Cert:\LocalMachine\Root` para inspeccionar TLS saliente. Windows/.NET confía en él automáticamente, pero herramientas Python con su propio bundle de certificados (AWS CLI v2, SAM CLI, pip, requests/boto3) no lo conocen y fallan con `CERTIFICATE_VERIFY_FAILED: unable to get local issuer certificate`. Fix: generar un bundle PEM combinando todos los certificados de `Cert:\LocalMachine\Root` (incluye el de AVG + los estándar) y apuntar la herramienta a él vía su variable de CA correspondiente (`aws configure set ca_bundle <path>`, `AWS_CA_BUNDLE`, `REQUESTS_CA_BUNDLE`, `PIP_CERT`, `SSL_CERT_FILE`...). Nunca desactivar la verificación SSL como atajo. Mismo patrón que el workaround de NotebookLM MCP más abajo.

## Line Endings
`.gitattributes` en el repo: `* text=auto eol=lf` normaliza a LF en checkout.
`git config --global core.autocrlf input` — convierte CRLF→LF en commit, sin modificar checkout.

**`open(path, 'w')` de Python en Windows escribe CRLF por defecto** — el modo
texto traduce cada `\n` a `\r\n` al escribir, salvo que se pase
`newline='\n'` explícito (o se abra en modo binario). Esto pasa
desapercibido en la mayoría de consumidores tolerantes (Docker Compose
`env_file:` parsea bien un `.env` con CRLF), pero un `source fichero.env` en
bash dentro de una instancia Linux **no** hace ese trim — el `\r` queda
incrustado en el VALOR de la variable (`POSTGRES_USER` se vuelve literalmente
`lightrag\r`, no `lightrag`), y cualquier comando que use esa variable como
argumento literal (`psql -U "$POSTGRES_USER"`) falla contra algo que no
existe (`role "lightrag\r" does not exist`) mientras el recurso real sí está
bien. El bug puede quedar oculto semanas si nada dentro de la cadena hace
`source` + uso literal de la variable — verificado en producción, caso real
en `km/assets/AWS-lightrag-ec2/bootstrap/tests/run.sh`. Diagnóstico rápido:
`cat -A fichero.env | head` — un `^M` al final de cada línea es CRLF.
Cualquier script Python en Windows que genere un fichero que luego se
`source`-ea en Linux debe escribir con `newline='\n'`.

## `charmap codec can't encode` del AWS CLI — el fallo es de la consola local, no del comando remoto

Cuando `aws ssm get-command-invocation` (u otra llamada del CLI) lanza
`UnicodeEncodeError: 'charmap' codec can't encode character...`, el error
ocurre al **mostrar** el resultado en esta consola (Git Bash/PowerShell en
Windows, codificación por defecto tipo cp1252, sin soporte para `✓`/`✗`/`→`
u otros símbolos fuera de ese charset) — no significa que el comando
ejecutado en el remoto haya fallado. Si el comando ya se había completado
antes de la llamada de lectura, el trabajo remoto **ya ocurrió** aunque el
CLI no pueda enseñártelo; hay que verificar el estado real (reconsultar,
mirar el efecto en el sistema) antes de asumir que hay que reintentar. Fix
robusto: evitar caracteres fuera de ASCII/cp1252 en cualquier output que
vaya a leerse por este camino (usar `[OK]`/`[FAIL]`/`->` en vez de
`✓`/`✗`/`→`); o forzar `PYTHONIOENCODING=utf-8` antes de la llamada `aws`
como parche puntual.

## Git Config
<!-- reservado — añadir con arch--stack -->

## Python
Instalación en `C:\Python314\python.exe`. Invocar con `py` desde terminal o con la ruta completa en configs.

## Node / npx
Path para MCP servers npm-based: `C:\Program Files\nodejs\npx.cmd`.
Usar como `command` en `.mcp.json` para cualquier server que arranque con `npx -y <package>`.

## NotebookLM MCP — workaround SSL
NotebookLM no arranca vía npx; usa Python con un patch SSL para el cert store de Windows.

Ficheros requeridos en `~/.claude/`:
- `notebooklm_ssl_patch.py` — parchea SSL para que nlm funcione en Windows
- `combined-cacert.pem` — bundle de certificados custom

Entrada en `.mcp.json`:
```json
"notebooklm": {
  "command": "C:\\Python314\\python.exe",
  "args": ["C:\\Users\\<user>\\.claude\\notebooklm_ssl_patch.py"],
  "env": {
    "SSL_CERT_FILE": "C:\\Users\\<user>\\.claude\\combined-cacert.pem"
  }
}
```
