# 000-seguridad — spec

**Estado:** 📝 especificado · **Depende de:** nada

## Alcance

Cierra los huecos de seguridad ya verificados en
[estado-actual.md](../../docs/arquitectura/estado-actual.md#seguridad--000-seguridad).
No diseña el modelo de autenticación/roles definitivo (usuarios, sesiones,
permisos por iglesia): eso depende de que exista la entidad iglesia y se
especifica en [002-identidad-de-iglesia](../002-identidad-de-iglesia/). Aquí
solo se exige una autenticación mínima donde hoy no hay ninguna, para no dejar
el sistema abierto mientras 002 se construye.

## Qué (requisitos)

### R1 — Ningún secreto vive sin control en el repositorio
- Credenciales, claves y tokens de servicios (BD, JWT, APIs) no viven en el
  código ni en el historial de ahora en adelante (constitución, punto 7).
- La configuración falla ruidosamente al arrancar si falta una variable de
  entorno requerida; nunca cae a un valor de producción por defecto.
- **Excepción deliberada:** las llaves de firma de la app móvil (keystore,
  certificados) se mantienen en claro en el repositorio, por decisión
  explícita del propietario — el riesgo de perderlas pesa más que el de
  exposición, dado que el repo es privado y de un solo administrador. Se
  reevalúa si el repo deja de ser privado o gana más administradores.

### R2 — La base de datos existente no se modifica; se provisiona una nueva
- Prohibido tocar (leer, escribir, migrar en sitio) la base de datos de
  producción actual. Se crea una base de datos nueva, con credenciales
  nuevas, para todo lo que construya este módulo y los que dependen de él.
- La base de datos actual queda congelada: solo se usa como fuente de lectura
  puntual si hace falta migrar datos, nunca como destino.
- El `jwtSecret` y cualquier otra credencial de servicio (no de BD) hallados
  en `legacy/back-scores` y `legacy/belen-backend` sí se rotan en sitio.
- Se asume que la tabla de usuarios de la BD actual ya fue copiada
  (constitución, hallazgo verificado); por eso no se reutiliza.
- **Esto es una decisión de arquitectura → requiere ADR antes de
  implementarse** (constitución, punto 6).

### R3 — Ningún motor de base de datos es alcanzable desde internet
- Ni la base del nodo ni la de la nube aceptan conexiones directas desde
  internet. No se expone su puerto, con o sin contraseña.
- Lo que sí se expone a internet es la API de nube (`services/`), que es la
  única que habla con la base. Descargar una partitura desde fuera del templo
  pasa por esa API autenticada, nunca por la base directamente.
- La base del nodo solo es alcanzable desde el propio proceso del nodo
  (ADR 0004: SQLite embebido, sin puerto ni contraseña).
- Esto no impide que las partituras se descarguen por internet: impide que se
  llegue a la base que las cataloga sin pasar por la API.

### R4 — Ninguna ejecución de comandos sin autenticar
- `apps/stream-agent` deja de construir comandos de PowerShell a partir de
  datos de socket sin validar ni autenticar.
- Un valor recibido por socket nunca se concatena en una cadena ejecutable.

### R5 — Ninguna consulta SQL se construye por concatenación
- Toda consulta a MySQL/lo que la reemplace usa parámetros. Aplica a
  `mysqlController.js` y a `usuarios.js` (o su equivalente si ya se
  reescribió en otro módulo antes de llegar aquí).

### R6 — El nodo del templo exige autenticación mínima
- Ninguna operación que lea, cree, edite o borre cantos, ni la proyección de
  texto arbitrario, es alcanzable sin autenticarse.
- No se exige aquí un modelo de roles ni de usuarios por iglesia (eso es
  002); basta con que un desconocido en la red ya no tenga control total.

### R7 — Las contraseñas se guardan y transmiten de forma segura
- Ninguna contraseña se guarda con SHA1 sin sal ni en texto claro.
- La app móvil deja de guardar la contraseña del usuario en claro en el
  dispositivo (`saved_password`).

### R8 — La app funciona sin internet, pero no se autoriza a sí misma
Muchos músicos no tienen internet en casa: descargan partituras cuando
consiguen conexión prestada y luego pasan semanas sin ella. La app tiene que
seguir sirviendo en esas condiciones. Al mismo tiempo, a un músico expulsado
hay que poder cortarle el acceso aunque nunca vuelva a ver internet.

- **Sin conexión, la app abre y funciona**: lo descargado —partituras,
  anotaciones, listas— se usa sin internet, sin pedir login de nuevo.
- **La sesión no se valida contra el reloj del teléfono.** Hoy la ventana de
  30 días se comprueba contra la fecha local, falseable atrasando el reloj.
  Esa comprobación deja de conceder acceso por sí sola.
- **La ventana de ~30 días se conserva, con su verdadero propósito: revocar.**
  No es "cuánto dura la sesión", es el tiempo máximo que alguien ya bloqueado
  puede seguir usando la app sin reportarse a ningún servidor. Es el peor
  caso, no el caso normal.
- **La vía normal de revocación es el nodo del templo**, no la nube. El nodo
  conoce la lista de miembros al día y valida la sesión sin internet,
  verificando la firma del token contra la clave pública de la nube. Un
  músico eliminado queda fuera el domingo siguiente, no en 30 días.
- **Bloqueado quiere decir que la app no sirve para nada**: ni en vivo, ni
  descargas nuevas, ni lo ya descargado.
- **Bloqueado no es borrado.** Los archivos y las anotaciones siguen intactos
  en el dispositivo; solo se les cierra el acceso. Si se readmite al músico,
  recupera su trabajo sin haber perdido nada (constitución, punto 5).
- **El retroceso del reloj se detecta**: la app recuerda la última hora vista
  de un servidor —nube o nodo— y trata como no confiable cualquier fecha
  local anterior a esa.

Costo aceptado: un músico bloqueado que no se conecte a nada, ni a la nube ni
a la red del templo, conserva el uso de lo que ya descargó hasta que expire su
token. Los 30 días son precisamente el techo de esa ventana.

> Cómo el nodo verifica una sesión sin internet se especifica en
> [008-sincronizacion-y-licencias](../008-sincronizacion-y-licencias/); aquí
> solo se fija el requisito de que deba poder hacerlo.

## Por qué

Estas seis fallas (verificadas en el código, no supuestas) exponen a las
iglesias a fuga total de datos, proyección de contenido arbitrario en el
templo y ejecución remota de comandos en la PC de transmisión — hoy, con el
sistema en producción. Migrar a multi-iglesia sobre esta base convertiría un
riesgo aislado por instalación en una fuga entre todas las iglesias del SaaS.
La constitución (puntos 3 y 7) exige que esto se cierre antes de construir
identidad y multi-tenencia encima.

## Fuera de alcance

- Modelo de usuarios, roles y permisos por iglesia → 002-identidad-de-iglesia.
- Acceso público al servidor de partituras → 006-catalogo-y-partituras.
- Migraciones de esquema versionadas, CI, logging estructurado →
  001-andamiaje-y-tests.

## Abierto / bloqueante

- Ya no bloquea: son dos iglesias, y el propietario hace personalmente la
  instalación y el soporte técnico de ambas. El corte es una desinstalación
  de la versión vieja e instalación de la nueva, no una coordinación remota.
  La base de datos actual se retira una vez hecho el corte en las dos.
- ADR de R2 (no tocar la BD actual, provisionar una nueva) ya escrito:
  [0008](../../docs/adr/0008-no-tocar-bd-existente.md).
