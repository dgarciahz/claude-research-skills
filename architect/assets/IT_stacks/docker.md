# Stack: Docker

Particularidades de Docker/Compose/registries encontradas operando contenedores
reales (no teoría de la documentación oficial). Relevante más allá de proyectos
puntuales: una vía real para ejecutar Claude Code Desktop en entorno
corporativo es dentro de un contenedor gestionado por MDM con permisos
acotados — vale la pena acumular este conocimiento de forma específica en vez
de disperso en el stack file de cada proyecto que use Docker.

---

## Pin de versiones — `docker inspect --format '{{.Id}}'` NO es el digest para `image: repo@sha256:...`

Para fijar una imagen por digest en vez de por tag flotante (`image:
repo@sha256:...` en Compose, o `FROM repo@sha256:...` en un Dockerfile), el
valor correcto es el **digest de manifest** (`RepoDigests`), no el `Id` local
de la imagen (que es el digest de la *config*, un objeto distinto).

Evidencia concreta (verificada, no supuesta): al hacer `docker pull
pgvector/pgvector:0.8.6-pg16`, el registry reportó `Digest:
sha256:ccc6e83d6e35e931dc7c5def2022729d5a6c370318d099181995567ff1fb4d6b` — pero
`docker inspect pgvector/pgvector:0.8.6-pg16 --format '{{.Id}}'` devolvió
`sha256:9b05db12a35460fff0587e009f9326e414a53e9484555547f96d214a2ba98ef7`.
Valores completamente distintos para la misma imagen recién descargada.

Usar `.Id` como si fuera el digest de pin produce `manifest unknown` en el
siguiente `docker pull`/`docker compose build` — el mismo error superficial
que un tag inexistente, pero causado por confundir dos digests distintos, no
por un typo.

**Comando correcto para obtener el valor a pinnear**:
```
docker inspect <imagen>:<tag> --format '{{index .RepoDigests 0}}'
```

## "Misma versión declarada, digest distinto" — no asumir que dos tags con igual versión son intercambiables

Dos tags de la misma imagen pueden declarar la misma versión de software y
resolver a **binarios distintos** por diferir en la imagen base del sistema
operativo. Caso real: una instancia corriendo `pgvector/pgvector:pg16`
(flotante) reportaba PostgreSQL 16.14 y `pgvector` extversion `0.8.6` — mismos
números que el tag versionado recién publicado `pgvector/pgvector:0.8.6-pg16`
en Docker Hub. Pero al pullear ambos y comparar `RepoDigests`, eran imágenes
distintas: la que corría en producción estaba sobre Debian bookworm, la
recién publicada con ese mismo nombre de versión ya había migrado a Debian
trixie. Incluso "fijar a la versión que declara lo mismo que ya corre" puede
introducir un cambio real de base de sistema si no se verifica por digest.

## `docker compose build` requiere buildx ≥ 0.17

Con un `docker compose build` fallando `"compose build requires buildx
0.17.0 or later"` pese a tener Docker funcionando, el fix es actualizar el
plugin `buildx` (no Docker Engine en sí) descargando el binario más reciente
desde los releases de GitHub (`docker/buildx`) y colocándolo en
`~/.docker/cli-plugins/docker-buildx` (o el path de plugins equivalente del
sistema). Escribir el binario directamente en `cli-plugins/` con `curl -o`
puede fallar a media escritura (`curl: (23) Failure writing output`, visto en
la práctica) — descargar primero a un directorio temporal y mover el binario
ya completo evita dejar un plugin corrupto a medio escribir.

## Formato de tags — no asumir el orden, verificar contra el registry

Los nombres de tag versionados no siguen un formato uniforme entre imágenes
— `pgvector/pgvector` usa `<versión-extensión>-<versión-pg>` (ej.
`0.8.6-pg16`), no `<versión-pg>-<versión-extensión>` (`pg16-v0.8.6`, que no
existe y da `manifest unknown`). Verificar el formato real contra la página
de tags del registry (Docker Hub / GHCR) antes de escribirlo en un Dockerfile
o compose — adivinar el formato por analogía con otra imagen cuesta un
roundtrip de despliegue fallido por cada suposición incorrecta.
