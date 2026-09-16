# 002-identidad-de-iglesia — spec

**Estado:** 📝 especificado · **Depende de:** 000, 001

## Alcance

Crea la **iglesia** como entidad de primera clase —hoy no existe en ninguna
parte (`estado-actual.md`)— y la propaga a los datos, a los usuarios y a los
permisos. Con este módulo cerrado, toda fila del sistema nuevo pertenece a una
iglesia, todo usuario pertenece a una iglesia, y el servidor —no el cliente—
decide qué puede hacer cada quien.

Incluye la autenticación funcionando: sin ella el nodo no puede levantarse
(000-seguridad R6) y los módulos 003 y 004 no tienen sobre qué apoyarse. Aquí
se materializan R6 (el nodo nace con autenticación) y R7 (contraseñas seguras)
de [000-seguridad](../000-seguridad/spec.md).

Las migraciones `0001_inicial.sql` de nodo y nube creadas en 001 contienen solo
la tabla de control de migraciones, y dicen explícitamente que las tablas de
dominio y las políticas de aislamiento entran en este módulo. Este es el módulo
que escribe el primer esquema real.

## Qué (requisitos)

### R1 — La iglesia existe como entidad, con identidad propia
- Una iglesia es una fila con identificador propio, UUIDv7 generado por quien
  la crea ([ADR 0005](../../docs/adr/0005-identificadores.md)), nombre y estado.
  No es el nombre de una base de datos, ni el título de una ventana, ni una
  carpeta en un servidor.
- **La nube es la autoridad** sobre qué iglesias existen
  ([ADR 0002](../../docs/adr/0002-arquitectura-hibrida-nube-nodo-local.md)). El
  nodo no inventa iglesias.
- **Un nodo sirve a una sola iglesia** (ADR 0002). El nodo conoce su identidad
  de iglesia desde su configuración, la verifica al arrancar, y **se niega a
  arrancar** si falta o no coincide con los datos que ya tiene en su base.
- Renombrar una iglesia nunca cambia su identificador. El nombre es para las
  personas; el identificador es para los datos.

> Hoy cada iglesia es una instalación manual del mismo código, la base se llama
> `belen`, y el único rastro de a quién sirve es el título de una ventana. Por
> eso no hay forma de que dos iglesias convivan en la nube.

### R2 — Todo dato de dominio pertenece a una iglesia
- Toda tabla de dominio, en nube y en nodo, lleva la iglesia a la que pertenece.
  Una tabla de dominio sin iglesia es un defecto, no una simplificación.
- Toda consulta de dominio filtra por iglesia. Una consulta sin ese filtro es
  un defecto (constitución, punto 3), aunque hoy solo haya una iglesia en esa
  base.
- **Excepciones explícitas y cerradas**, que son datos compartidos y de solo
  lectura para la iglesia: la Biblia, el catálogo maestro de la nube y el
  catálogo de instrumentos. Cualquier otra excepción futura requiere ADR.
- **Conocer un identificador no concede acceso.** Pedir un dato con el
  identificador correcto y la iglesia equivocada responde como si no existiera,
  no como "prohibido": no se confirma la existencia de datos ajenos.

### R3 — El aislamiento se impone abajo, no en cada consulta
- En la nube, la regla "esta sesión solo ve filas de su iglesia" vive en el
  motor de base de datos, no repetida en cada consulta
  ([ADR 0004](../../docs/adr/0004-sqlite-en-el-nodo.md), *row-level security*).
  Olvidar un filtro debe producir cero filas, no filas de otra congregación.
- En el nodo el aislamiento es además físico: una base por iglesia, y el
  proceso rechaza al arrancar una base que pertenezca a otra iglesia (R1).
- El identificador de iglesia de una sesión **sale del token**, nunca de un
  parámetro de la petición. Un cliente no puede pedir "dame los datos de esta
  otra iglesia" ni siquiera intentándolo.
- Cambiar la iglesia de una fila ya creada no es una operación del sistema.

### R4 — Un usuario pertenece a una iglesia
- Todo usuario —músico, operador, administrador— pertenece a exactamente una
  iglesia, y se identifica dentro de ella. Un mismo correo en dos iglesias son
  dos usuarios distintos, sin nada compartido.
- **Excepción:** el propietario del SaaS, que administra el sistema y no
  pertenece a ninguna iglesia. No es un usuario de iglesia con más permisos: es
  una identidad aparte, y no participa en el uso diario de ninguna
  congregación.
- Dar de baja a un usuario **no borra su trabajo** (constitución, punto 5): se
  le cierra el acceso, sus datos siguen ahí, y readmitirlo se lo devuelve
  intacto.
- Los usuarios se dan de alta de nuevo, con contraseñas nuevas: la tabla de
  usuarios actual se considera comprometida y no se importa
  ([ADR 0008](../../docs/adr/0008-no-tocar-bd-existente.md)).

> Hoy un usuario es un correo con un `deviceId` pegado en una base compartida
> por todas las iglesias (`legacy/belen-backend/src/controllers/usuarios.js`).
> No pertenece a nada.

### R5 — Un músico tiene varios instrumentos, y los instrumentos son datos
- Un músico puede tener **varios instrumentos** —en la práctica alguien toca
  piano, clarinete y flauta— y puede cambiarlos sin que nadie toque código.
- El catálogo de instrumentos vive en la base de datos, no escrito a fuego en
  la app. Hoy son diez fijos en
  `apps/mobile/lib/core/services/instruments_service.dart`, y un músico solo
  puede tener uno.
- El catálogo es común a todas las iglesias; añadir uno nuevo no obliga a
  publicar una versión de la app.
- **Lo asignable es el puesto, no la familia del instrumento.** `violin1` y
  `violin2` son dos entradas distintas del catálogo: a un músico se le asigna
  violín 2, y eso determina qué papel le toca. No se colapsan en "violín".
- **Cada instrumento declara su afinación** (`c`, `bb`, y las que hagan falta
  después). No es un dato decorativo: es lo que decide qué partitura ve un
  músico cuando su instrumento no tiene arreglo propio para un canto. El
  clarinete no lee la partitura del piano, lee la de su afinación.
- El nombre visible del instrumento está traducido (constitución, punto 9). Lo
  que se guarda en los datos es el código del instrumento, nunca su nombre en
  español: añadir un idioma no puede obligar a tocar datos.

> **Nada sobre archivos de partitura se decide aquí.** Este módulo solo declara
> qué instrumentos existen y con qué afinación. Cómo se guarda una partitura
> base por afinación, cuándo un canto tiene arreglo propio para un instrumento
> y cuál de los dos se entrega es de
> [006-catalogo-y-partituras](../006-catalogo-y-partituras/). La afinación se
> define aquí porque es una propiedad del instrumento, no del canto.

### R6 — Un músico tiene varios dispositivos
- Un usuario puede tener **varios dispositivos activos** a la vez: cambiar de
  teléfono, o usar teléfono y tableta, no requiere que intervenga nadie.
- Cada dispositivo es visible y **revocable por separado**: perder el teléfono
  se resuelve cerrando esa sesión, sin cambiar la contraseña ni tocar los demás
  dispositivos.
- Puede haber un límite de dispositivos activos por usuario; si se alcanza, el
  sistema lo dice claramente y ofrece cerrar uno, nunca responde con un rechazo
  mudo.
- Revocar un dispositivo **no borra lo descargado en él** (constitución, punto
  5; 000-seguridad R8): cierra el acceso, no destruye trabajo.

> Hoy el `deviceId` se fija en el primer login y, si después no coincide, el
> usuario recibe 403 sin forma de liberarse
> (`usuarios.js:23-34`). Cambiar de teléfono deja al músico fuera.

### R7 — El rol lo decide el servidor
- Los roles son una lista cerrada, **por iglesia**: administrador de iglesia,
  operador, músico. Fuera de la iglesia queda el propietario del SaaS (R4).
- **Un usuario puede tener varios roles a la vez.** El administrador de una
  iglesia de este tamaño también toca, y quien dirige la alabanza es operador y
  músico. Un solo rol por persona obliga a mentir desde el primer día.
- **Ningún rol incluye a otro.** Ser administrador no concede operar el
  servicio: se asigna aparte. Administrar músicos y proyectar en medio de un
  culto son cosas distintas, y nadie recibe la segunda sin que se la den.
- La pantalla de proyección **no es un rol de persona**: es un dispositivo
  autorizado por la iglesia (R6). Hoy es alguien que abre una URL y se
  autoproclama.
- El rol viaja en la sesión emitida por el servidor. **Nunca lo declara el
  cliente.** Hoy sale de `localStorage` del navegador, así que cualquiera que
  abra la URL se autoproclama operador.
- Cada operación sensible dice qué rol la permite. Sin rol suficiente, se
  rechaza en el servidor, aunque la interfaz haya mostrado el botón.
- **Estar en la red del templo no autoriza nada** (000-seguridad R6).
- Toda iglesia tiene al menos un administrador. El sistema no permite dejar una
  iglesia sin ninguno.

### R8 — Autenticarse funciona, y funciona sin internet
- Las contraseñas se guardan con un algoritmo de hash lento y con sal; nunca
  SHA1 sin sal, nunca en claro (000-seguridad R7). La app no guarda la
  contraseña en el dispositivo.
- Un músico se autentica **contra el nodo de su templo, sin internet**
  (constitución, punto 2): el domingo el login no puede depender de la
  conexión.
- La sesión que emite la nube y la que acepta el nodo son la misma cosa: el
  nodo la valida sin consultar a la nube.
- El resultado de autenticarse dice quién es, a qué iglesia pertenece y qué rol
  tiene. Nada de eso se le pregunta después al cliente.
- Este módulo emite y valida sesiones. **Cómo se replican credenciales y
  revocaciones entre nube y nodo se especifica en
  [008](../008-sincronizacion-y-licencias/)**; aquí se fija que el nodo deba
  poder hacerlo sin internet.

### R9 — La primera iglesia se crea sin panel
- Crear una iglesia, su primer administrador y la configuración de su nodo es
  posible por un medio explícito y auditable, sin interfaz gráfica: el panel es
  del módulo 003 y este módulo no puede depender de él.
- Ese medio sirve también para las pruebas y para levantar un entorno nuevo
  desde cero.
- No crea contraseñas por defecto ni cuentas de fábrica: la credencial inicial
  se fija en el momento del alta (constitución, punto 7).

### R10 — El aislamiento se verifica con pruebas, no se supone
- Hay pruebas que **intentan** leer y escribir datos de otra iglesia con
  identificadores válidos, y que fallan solo si el intento funciona
  (constitución, punto 3).
- Hay una prueba de que una consulta a la que se le olvidó el filtro de iglesia
  devuelve cero filas, y no filas ajenas (R3).
- Hay pruebas de que el rol se respeta en el servidor aunque el cliente afirme
  otro (R7).
- Estas pruebas corren en la integración continua de 001 y bloquean la fusión
  (constitución, punto 4).

## Por qué

El hallazgo de `estado-actual.md` no es que la iglesia esté mal modelada: es
que **no existe**. La base se llama `belen`, el socket emite en difusión global
sin salas, y cada iglesia es una copia manual del mismo código. Mientras eso
siga así, no hay SaaS: hay dos instalaciones que casualmente comparten
repositorio.

Todo lo que viene después descansa aquí. El panel del SaaS (003) administra
iglesias que tienen que existir. El estado en vivo (004) es por iglesia. Las
salas de tiempo real (005) son por iglesia. El permiso para descargar una
partitura (006) se deriva de la pertenencia a una iglesia, nunca de conocer un
hash o una URL (ADR 0005). Si la iglesia se añade después, hay que retrofitear
el aislamiento sobre código ya escrito, que es exactamente como se producen las
fugas entre congregaciones.

La constitución exige que ninguna iglesia vea datos de otra y que eso se
verifique, no se suponga (punto 3). Hoy el daño posible está acotado a una
instalación; en multi-iglesia, un filtro olvidado alcanza a todo el sistema.
Este módulo es donde esa regla deja de ser una intención y se convierte en
esquema, en política del motor y en pruebas.

Que un músico pueda cambiar de teléfono y tocar tres instrumentos no es un
adorno: son las dos cosas que hoy obligan a intervenir a mano en cada caso.

## Fuera de alcance

- **Alta de iglesias por interfaz, licencias, invitaciones por QR y siembra del
  catálogo inicial** → [003-panel-saas](../003-panel-saas/). Aquí la iglesia se
  crea por el medio explícito de R9.
- **Lista de alabanza, canto actual y cualquier estado del servicio** →
  [004-estado-en-vivo](../004-estado-en-vivo/). Este módulo no toca `songid.txt`
  ni el array en memoria.
- **Salas por iglesia y autorización de los eventos de tiempo real** →
  [005-tiempo-real](../005-tiempo-real/). Aquí se define el rol; allí se aplica
  sobre el protocolo.
- **Modelo melodía/arreglo, deduplicación por hash y acceso a los archivos** →
  [006-catalogo-y-partituras](../006-catalogo-y-partituras/). Aquí solo se fija
  que el permiso se deriva de la pertenencia a la iglesia.
- **Reescritura de la capa de datos de la app Flutter, incluida la pantalla de
  instrumentos** → [007-app-movil](../007-app-movil/). Este módulo define el
  modelo; la app lo consume allí.
- **Replicación de usuarios y revocaciones entre nube y nodo, y verificación
  offline de licencia** → [008-sincronizacion-y-licencias](../008-sincronizacion-y-licencias/).
- **Migrar los usuarios de la base actual**: no se migran, se dan de alta de
  nuevo (ADR 0008). El repertorio y el historial, si se migran, son trabajo
  aparte y solo de lectura.
- **Todo lo que será reemplazado**: `back-scores`, `belen-backend`, `web-panel`,
  `desktop-node` y `stream-agent` no se adaptan a la iglesia; se retiran
  ([ADR 0009](../../docs/adr/0009-no-se-parchea-el-legado.md),
  [0013](../../docs/adr/0013-app-de-escritorio-en-vez-de-panel-web.md),
  [0014](../../docs/adr/0014-obs-por-websocket.md)).

## Abierto / bloqueante

- **Resuelto:** un usuario pertenece a una sola iglesia (R4). Con dos iglesias
  reales y ningún caso de músico compartido, la pertenencia múltiple añade
  complejidad de aislamiento sin comprar nada. Si alguna vez hace falta, se
  decide con un ADR nuevo y no se improvisa.
- **Resuelto:** la iglesia se crea sin panel (R9); el panel llega en 003.
- Cómo se impone el aislamiento en la nube y cómo se ata el nodo a su iglesia
  es decisión de arquitectura y va en `plan.md` con su ADR (constitución,
  punto 6).
- Qué formato tiene la sesión, quién la firma y cómo la verifica el nodo sin
  internet es decisión de arquitectura y va en `plan.md` con su ADR. El
  transporte de las claves entre nube y nodo pertenece a 008.
- **Sin verificar:** si en alguna de las dos iglesias hay hoy usuarios con el
  mismo correo. Es irrelevante para el modelo —se dan de alta de nuevo (R4)—
  pero conviene saberlo antes de sembrar datos.
