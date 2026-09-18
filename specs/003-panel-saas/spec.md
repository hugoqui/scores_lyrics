# 003-panel-saas — spec

**Estado:** 📝 especificado · **Depende de:** 002

## Alcance

La primera interfaz del sistema nuevo. Hasta hoy una iglesia se crea con un
comando en una terminal
([`docs/operacion/alta-de-iglesia.md`](../../docs/operacion/alta-de-iglesia.md))
y un músico se da de alta a mano; con este módulo cerrado, el propietario del
SaaS administra iglesias y licencias desde una pantalla, y cada administrador
de iglesia administra su congregación sin pedirle nada a nadie.

Son **dos superficies distintas sobre la misma aplicación**:

- **Operación del SaaS** — solo el propietario. Ve todas las iglesias, las crea
  y emite o revoca sus licencias.
- **Administración de la iglesia** — el administrador de cada congregación. Ve
  **solo la suya**: sus usuarios, sus instrumentos, sus dispositivos, sus
  invitaciones.

No son dos aplicaciones, pero tampoco las mismas pantallas: mezclarlas es
exactamente donde se filtran datos entre congregaciones, porque una misma vista
tendría que decidir en cada consulta si filtra o no. Cómo se separan es
decisión de arquitectura y va en [`plan.md`](plan.md) con su ADR.

Casi nada del dominio se inventa aquí: 002 ya dejó la iglesia, los roles, los
usuarios, los instrumentos y los dispositivos revocables. Este módulo les pone
interfaz, y añade dos cosas nuevas: la **licencia** y la **invitación**.

## Qué (requisitos)

### R1 — El panel es una aplicación web, y puede exigir internet

- El panel se sirve desde la nube y se usa con un navegador. No se instala nada
  en el templo.
- **Es lo único del sistema que puede exigir conexión** (constitución, punto 2:
  el alta de iglesias y la licencia son excepciones explícitas). Si el panel
  está caído, el domingo sigue funcionando igual, porque el nodo no depende de
  él.
- El panel **no se proyecta ni se abre en el equipo del templo durante un
  servicio**. Ningún aviso de cobro, licencia o error suyo puede aparecer en la
  pantalla de la iglesia (constitución, punto 1).
- No reemplaza a la app de escritorio ni al panel que retira
  [ADR 0013](../../docs/adr/0013-app-de-escritorio-en-vez-de-panel-web.md): eso
  es la proyección y el control del culto, y es de
  [010](../010-app-de-escritorio/). Esto es administración.

### R2 — Alta y administración de iglesias

- El propietario crea una iglesia desde el panel: nombre, correo de contacto y
  el nombre de su primer administrador. Lo mismo que hace hoy el comando, sin
  terminal.
- El alta deja la iglesia utilizable: existe, tiene licencia y tiene un
  administrador que puede entrar. **Sin contraseña por defecto ni cuenta de
  fábrica** (constitución, punto 7): el primer administrador recibe una
  invitación (R5) y elige su propia contraseña.
- Al terminar, el panel entrega lo que el nodo de esa iglesia necesita para
  configurarse, igual que hoy lo imprime el comando.
- El propietario ve la lista de iglesias con lo que importa de un vistazo:
  estado, licencia, dispositivos activos, última vez que su nodo se hizo ver.
- Una iglesia se **suspende y se reactiva**; no se borra. Suspender cierra el
  acceso, no destruye nada (constitución, punto 5).
- Renombrar una iglesia no cambia su identificador (002 R1).
- **El comando sigue existiendo** y no se retira: es lo que levanta un entorno
  nuevo desde cero, y lo que se usa si el panel está caído.

### R3 — La licencia es anual, por iglesia, y nunca interrumpe un culto

- Una licencia pertenece a **una iglesia**, tiene fecha de inicio, fecha de fin
  y estado. El modelo de cobro es **anual por congregación**, no por
  dispositivo ni por usuario: los músicos son voluntarios y nadie va a contar
  teléfonos cada mes.
- La licencia declara un **tope de dispositivos activos**, por tamaño de la
  iglesia. El tope existe para que el número signifique algo, no para cobrar de
  más.
- **Pasarse del tope nunca bloquea nada**: se avisa al propietario y al
  administrador de esa iglesia, y se sigue trabajando. El límite duro de
  dispositivos por usuario es el de 002 R6, que ya responde ofreciendo cerrar
  uno y nunca con un rechazo mudo.
- **Una licencia vencida degrada funciones administrativas, jamás la
  proyección** (constitución, punto 1). Con la licencia vencida el
  administrador no puede dar de alta usuarios nuevos ni emitir invitaciones; el
  domingo se proyecta, se entra y se entregan partituras exactamente igual.
- El propietario emite, renueva y revoca licencias, y ve cuáles están por
  vencer. Revocar es un acto explícito y registrado, no un efecto secundario.
- Aquí la licencia es un **registro en la nube**. La licencia **firmada, que el
  nodo verifica sin internet**, es de
  [008](../008-sincronizacion-y-licencias/); este módulo define qué dice una
  licencia y quién la emite, para que 008 tenga qué firmar.

### R4 — El administrador administra su iglesia, y solo la suya

- Desde su zona del panel, el administrador de una iglesia:
  - da de alta y de baja usuarios, y les asigna roles (002 R7: la lista es
    cerrada y **ningún rol incluye a otro**);
  - asigna y quita instrumentos a cada músico (varios por persona, 002 R5);
  - ve y **revoca dispositivos por separado**, que es cómo se resuelve un
    teléfono perdido sin tocar la contraseña (002 R6);
  - emite y revoca invitaciones (R5).
- Dar de baja **cambia el estado, nunca borra** el usuario ni su trabajo
  (constitución, punto 5). Readmitir se lo devuelve intacto.
- No puede dejar a su iglesia sin ningún administrador (002 R7).
- **No ve ni alcanza nada de otra iglesia**, ni siquiera conociendo un
  identificador válido: se le responde como inexistente, no como prohibido
  (002 R2). Esto no se supone: se prueba (R8).
- El administrador **no** administra licencias, ni crea iglesias, ni ve cuánto
  paga nadie. Eso es del propietario.

### R5 — Invitaciones: el administrador no llega a conocer ninguna contraseña

- Una invitación es un **código opaco de un solo uso**, con caducidad, emitido
  para una iglesia y con el rol y los instrumentos que tendrá quien la canje.
- El código se entrega como **QR** —para proyectarlo en un ensayo o pasarlo por
  el grupo— y también en texto, para pegarlo a mano.
- **El QR no lleva datos dentro**: ni el nombre de la iglesia, ni su
  identificador, ni el rol. Solo el código. Si se filtra, no revela nada, y
  caduca solo.
- Quien la canje pone su nombre y **elige su propia contraseña**. El
  administrador nunca la conoce ni la teclea: hoy eso acaba en un WhatsApp para
  siempre.
- Una invitación se puede **revocar antes de que la usen**, y se ve cuáles
  siguen vivas y cuáles se canjearon y quién.
- Canjear una invitación caducada, ya usada o revocada se rechaza diciendo qué
  pasó, y no distingue entre "no existe" y "ya se usó" con más detalle del
  necesario.
- El primer administrador de una iglesia nueva entra por este mismo camino
  (R2), así que el propietario tampoco conoce contraseñas ajenas.
- **Escanear el QR con la cámara es de [007](../007-app-movil/)**. Aquí se
  emite, se canjea y se revoca; y el canje funciona sin cámara, con el código
  escrito.

### R6 — Ninguna pantalla se implementa sin diseño aprobado

- Antes de escribir código de interfaz hay un **inventario de pantallas**, y
  para cada una un **prototipo aprobado**. El wireframe previo es obligatorio
  cuando hay flujo nuevo —la invitación, el alta de iglesia— y omitible cuando
  la pantalla es una lista o un formulario sin interacción nueva.
- Las **reglas de UX** —qué se confirma, qué se puede deshacer, cómo se dice un
  error, qué se ve mientras algo carga— se escriben una vez y valen para todas
  las pantallas. No se redecide pantalla por pantalla.
- **Todo texto visible sale del archivo de traducciones, en español e inglés**
  (constitución, punto 9, que nombra al panel del SaaS explícitamente). Ningún
  texto se escribe directo en el código, ni siquiera "temporalmente".
- Esta regla **no es de este módulo**: vale para toda interfaz del proyecto —
  este panel, la app móvil de [007](../007-app-movil/) y la de escritorio de
  [010](../010-app-de-escritorio/)— y se escribe como regla de proceso en
  [`specs/README.md`](../README.md).

### R7 — El panel no es una puerta trasera al aislamiento

- El panel usa **los mismos caminos que cualquier otro cliente**: la sesión
  firmada de 002, la iglesia siempre desde el token, nunca por parámetro
  (002 R3).
- La zona del propietario, que sí ve todas las iglesias, es la **única**
  excepción, y está declarada y acotada como ya lo están los caminos que usan
  el rol de propietario en la base
  ([`docs/operacion/roles-de-base-de-datos.md`](../../docs/operacion/roles-de-base-de-datos.md)).
  Una pantalla de la zona de iglesia nunca puede alcanzarla.
- Que una pantalla no muestre un botón **no es autorización**. Cada operación
  se comprueba en el servidor, aunque la interfaz ya la hubiera escondido
  (002 R7).
- El propietario del SaaS **no es un usuario de iglesia con más permisos**
  (002 R4): entra por su propio camino y no aparece como miembro de ninguna
  congregación.

### R8 — Se verifica que el panel no filtra

- Hay pruebas que, con una sesión de administrador de una iglesia, **intentan**
  alcanzar iglesias, usuarios, dispositivos e invitaciones de otra con
  identificadores válidos. Fallan solo si el intento funciona.
- Hay pruebas de que un administrador no alcanza ninguna operación del
  propietario, y de que un músico no alcanza ninguna de administrador.
- Hay pruebas de que una invitación de una iglesia no se canjea contra otra.
- Hay una prueba de que una licencia vencida **no impide entrar ni proyectar**,
  y sí impide las altas.
- Todas corren en la integración continua de 001 y bloquean la fusión
  (constitución, punto 4).

## Por qué

003 es el primer entregable visible del negocio. Todo lo de 001 y 002 es
cimiento: real, verificado y completamente invisible. Aquí es donde el sistema
deja de ser un esquema con pruebas y pasa a ser algo que se abre y se usa.

También es donde el SaaS empieza a ser un SaaS. Hoy dar de alta una iglesia
significa abrir una terminal, exportar una variable de conexión con el rol de
propietario y ejecutar un comando; eso no escala más allá de las dos iglesias
actuales, y cada alta pasa por las manos del dueño. Y dar de alta un músico
significa que alguien invente una contraseña y se la pase por mensaje, que es
la forma más común de que una credencial se quede escrita para siempre en el
teléfono de otra persona.

La licencia entra aquí y no en 008 porque sin ella el panel no tiene qué
administrar, y porque decidir tarde qué se cobra obliga a retrofitear el
concepto sobre pantallas ya escritas. Lo que se deja para 008 es lo que
realmente depende de la sincronización: que el nodo pueda comprobar la licencia
el domingo sin conexión.

Y es el primer módulo con interfaz. De aquí salen las convenciones visuales y
de UX que reutilizarán la app móvil y la de escritorio; hacerlas bien una vez
es más barato que unificarlas después en tres lugares.

## Fuera de alcance

- **Siembra del catálogo inicial** → [006](../006-catalogo-y-partituras/).
  Sembrar cantos obliga a decidir ya el modelo melodía/arreglo y la
  deduplicación por hash, que es justo lo que ese módulo especifica. Una
  iglesia nueva nace aquí con el catálogo de instrumentos que ya siembra 002, y
  nada más.
- **Escanear el QR con la cámara** → [007](../007-app-movil/). Aquí se emite,
  se canjea y se revoca.
- **La licencia firmada, verificable sin internet por el nodo, y la
  sincronización de revocaciones** → [008](../008-sincronizacion-y-licencias/).
  Aquí la licencia es un registro en la nube.
- **Proyección, control del culto y estado en vivo** → [004](../004-estado-en-vivo/),
  [005](../005-tiempo-real/) y [010](../010-app-de-escritorio/). El panel
  administra; no toca un servicio en curso.
- **Cobro real**: pasarelas de pago, facturas y recibos. La licencia se emite a
  mano desde el panel. Si algún día se automatiza, será con su propio ADR.
- **Autoservicio**: ninguna iglesia se da de alta sola. Las crea el
  propietario.
- **Migrar usuarios de la base actual**: no se migran, se dan de alta de nuevo
  ([ADR 0008](../../docs/adr/0008-no-tocar-bd-existente.md)).

## Abierto / bloqueante

- **Resuelto:** una sola aplicación web con dos zonas separadas por rol, no dos
  aplicaciones ni dos despliegues. Con qué se construye es decisión de
  arquitectura y va en [`plan.md`](plan.md) con su ADR (constitución, punto 6).
- **Resuelto:** licencia anual por iglesia con tope de dispositivos por tamaño
  (R3). Se descartó cobrar por dispositivo: deja ingreso impredecible, incentiva
  a compartir cuentas —justo lo que 002 evitó— y pone al tesorero a contar
  teléfonos.
- **Resuelto:** la siembra del catálogo se mueve a 006, y el escaneo del QR a
  007.
- **Deuda de 002:** [`vision-general.md`](../../docs/arquitectura/vision-general.md)
  y [`modelo-datos.md`](../../docs/arquitectura/modelo-datos.md) siguen vacíos
  aunque tocaban al cerrar 002. Este módulo se apoya en los dos, así que se
  escriben en su cierre.
- **Sin decidir:** los tramos concretos del tope de dispositivos por tamaño de
  iglesia. No bloquea: el tope es un número en la licencia, no una regla en el
  código.
