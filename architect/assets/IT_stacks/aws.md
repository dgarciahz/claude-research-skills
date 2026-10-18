# Stack: AWS

Particularidades de configuración y límites de servicios AWS.

---

## Lambda — cuota de `MemorySize` vs techo de plataforma

El techo real de la **plataforma** Lambda para `MemorySize` es **10.240 MB** — eso no cambia y no requiere ninguna gestión.

Lo que sí está limitado es la **cuota de la cuenta**: cada cuenta AWS tiene un tope propio (puede ser muy inferior al techo de plataforma) que determina hasta cuánto se puede desplegar sin intervención. Subir ese tope de cuenta **no es autoservicio** — requiere abrir un caso de soporte AWS y esperar aprobación. Es un bloqueante externo con tiempos fuera de control, no un cambio de configuración.

Consecuencia práctica: si un `sam deploy`/`cloudformation deploy` falla al subir `MemorySize` por encima de lo ya aprobado para la cuenta, no es un bug de la plantilla — es la cuota de cuenta. No hay forma de "activarlo ya y que quede pendiente" (AWS valida la cuota en el momento del deploy, no en tiempo de ejecución).

No confundir los dos números: el techo de plataforma (10.240 MB, fijo) y la cuota de cuenta (variable, gestionada vía soporte).

---

## Billing de IPv4 pública (desde feb-2024)

Toda IP pública factura $0.005/hora por igual, sea Elastic IP o efímera automática — el precio por hora ya no distingue entre ambas.

La diferencia real no es el precio, es la **persistencia**: la IP efímera se libera sola en cuanto se hace `stop` de la instancia (deja de facturar mientras esté parada), mientras que la Elastic IP queda reservada a tu cuenta y sigue facturando aunque la instancia esté parada — solo deja de cobrarse si se libera explícitamente (`release-address`).

Relevante para cualquier arquitectura que dependa de parar instancias para ahorrar coste: una EIP asociada rompe ese ahorro en la parte de red (sigue facturando ~$3.60/mes durante toda la parada); una IP efímera sí llega a $0 de IP mientras la instancia está parada, a cambio de no ser estable entre arranques.

---

## SSM `get-command-invocation` — límite de 24.000 caracteres en el output

`StandardOutputContent` de `aws ssm get-command-invocation` se trunca en exactamente 24.000 caracteres, sin aviso — si el comando genera más output, se pierde el resto en silencio (comprobar `length(StandardOutputContent)` para detectarlo, no asumir que llegó completo).

Para logs largos (ej. `docker compose logs`), filtrar **dentro del propio comando** (`grep` de las líneas relevantes antes de que salgan del `send-command`) en vez de traer todo y filtrar después — así el límite de 24K aplica sobre las líneas que ya importan, no sobre el log completo.

## `aws s3 sync` compara tamaño+fecha, no contenido

`aws s3 sync` decide si re-descargar/re-subir un fichero comparando tamaño y
`LastModified`, nunca el contenido. Si dos versiones de un fichero tienen
**el mismo tamaño en bytes** (típico en ficheros `.env` de una sola línea
tipo `CLAVE=valor` donde el valor nuevo tiene la misma longitud que el
viejo — ej. `LIGHTRAG_IMAGE_TAG=latest` → `LIGHTRAG_IMAGE_TAG=v1.5.6`, ambos
6 caracteres), `sync` puede saltarse la descarga en silencio, sin error, aun
cuando el contenido remoto ya cambió. Verificado en la práctica: un `.env`
con un tag de imagen actualizado en S3 no se propagó a una instancia EC2 vía
`aws s3 sync` por esta razón exacta — el contenedor siguió arrancando con la
imagen vieja hasta forzar `aws s3 cp` explícito sobre ese fichero.

Para ficheros pequeños y críticos (configuración, `.env`) donde una
coincidencia de tamaño es plausible, usar `aws s3 cp` explícito en vez de
confiar en `sync` para detectar el cambio. `sync` es apropiado para
directorios con muchos ficheros donde la probabilidad de colisión exacta de
tamaño+fecha es baja, no para un fichero de config de pocas líneas.

## CloudFormation — que la API de EC2 permita un cambio in-place no significa que CFN sepa ejecutarlo

Dos incidentes reales en el mismo proyecto, misma causa raíz: CloudFormation
no siempre traduce fielmente lo que la API subyacente de EC2 puede hacer.

1. **`ImageId` con resolución dinámica SSM** (`{{resolve:ssm:.../latest}}`)
   en un `AWS::EC2::Instance`: CloudFormation re-resuelve la referencia en
   **cada** actualización del stack, aunque el cambio no toque la instancia
   en absoluto. Si AWS publicó una AMI nueva desde el despliegue anterior,
   cualquier update del stack (IAM, parámetros no relacionados) dispara un
   **reemplazo completo de la instancia**. Fix: `ImageId` como parámetro
   estático, resuelto una vez fuera de CFN (script de deploy) y reutilizado
   en updates siguientes — nunca la referencia dinámica dentro del template.

2. **`DeleteOnTermination` de un volumen en `BlockDeviceMappings` inline**:
   la documentación de CFN afirma textualmente que modificar solo ese campo
   "does not interrupt the instance" — cierto para la API de EC2
   (`ModifyInstanceAttribute`), **falso para lo que el handler de
   CloudFormation sabe ejecutar**. En la práctica, el intento de update
   falló con `"The request must contain the parameter ebs"` (falta el
   `VolumeId`, que con `BlockDeviceMappings` inline no existe hasta después
   de creada la instancia) y dejó el stack en `UPDATE_ROLLBACK_FAILED`
   (recuperado con `continue-update-rollback --resources-to-skip <recurso>`
   — seguro cuando el estado real ya coincide con el que CFN intenta
   restaurar). Fix: dejar el template con el valor que CFN sí puede aplicar
   sin fallos, y aplicar el valor real deseado **fuera de banda** con
   `aws ec2 modify-instance-attribute` como paso posterior del script de
   deploy — idempotente, sin drift declarado en el template.

Regla general: antes de meter en un template un cambio que la doc de la API
de EC2 (no la de CloudFormation) describe como "sin interrupción", probarlo
contra un stack real primero, o asumir que CFN puede fallar de forma no
obvia y tener lista la vía de recuperación (`continue-update-rollback`) antes
de necesitarla.

## Editar `UserData` de una instancia ya lanzada dispara un stop+start real — y aun así no se re-ejecuta

`UserData` en `AWS::EC2::Instance` tiene "Update requires: Some
interruptions" — en la práctica, esto es un **stop+start real de la
instancia** para poder aplicar el cambio (verificado: `LaunchTime` avanza al
momento del update, el agente SSM pasa por `PingStatus=None`, Postgres
registra un `fast shutdown request` en su log). No es un simple reboot en
caliente sin downtime.

Y aun con ese stop+start real, **`UserData` sigue sin re-ejecutarse** — el
log de arranque (`/var/log/km-lightrag-userdata.log` en este proyecto,
equivalente a cualquier log que el propio script escriba) mantiene su
`mtime` del primer boot original. Cualquier fichero que solo se sincronice
en `UserData` (no en el propio script de deploy, vía `aws s3 sync`/`cp`
explícito post-deploy) no llega a la instancia con un simple update de
stack — hace falta sincronizarlo a mano tras el reinicio.

Consecuencia práctica: cualquier edición de `UserData` en un template ya
desplegado reinicia la PoC/instancia real, con el downtime que eso implica
para los servicios que corran ahí — no es un cambio "solo de configuración
en reposo".

Regla general: antes de meter en un template un cambio que la doc de la API

## SSM Session Manager — fragilidad de red por diseño, no por implementación

El port-forwarding de Session Manager (`AWS-StartPortForwardingSession`) depende de un único WebSocket persistente hacia el endpoint de mensajería SSM de la región — a diferencia de SSH (keepalives + reconexión tolerante a nivel de aplicación), si la red intermedia resetea esa conexión larga (redes inestables/congestionadas, NAT agresivo, AV con interceptación TLS), no hay reconexión automática transparente: hay que relanzar la sesión a mano. Síntoma observado: error de socket tipo `wsasend: An existing connection was forcibly closed by the remote host` contra el endpoint SSM, correlacionado con latencia TCP alta y muy variable (ej. wifi compartida) al mismo endpoint — no es un defecto de SSM/AWS, es la naturaleza de un WebSocket largo sobre una red poco fiable.
