# ADR 0020 — La licencia es anual por iglesia, y al vencer nunca apaga un culto

**Estado:** aceptada · **Fecha:** 2026-09-18

## Contexto

[003-panel-saas](../../specs/003-panel-saas/spec.md) incluye emitir y revocar
licencias, y no se puede construir un panel de administración sin saber qué
administra. Hoy no hay nada: no existe tabla de licencias, y
[licencias-saas.md](../arquitectura/licencias-saas.md) está vacío a propósito,
esperando al módulo [008](../../specs/008-sincronizacion-y-licencias/).

Esperar a 008 no es viable: obligaría a retrofitear el concepto sobre pantallas
ya escritas. Pero 008 tampoco se puede adelantar, porque lo suyo —que el nodo
verifique la licencia el domingo **sin internet**— depende de la
sincronización, que no existe todavía.

Hay dos preguntas distintas y aquí se responden las dos: **qué se cobra** y
**qué pasa cuando una licencia vence**. La segunda choca de frente con el
primer principio de la constitución, así que no puede quedar implícita.

## Decisión

### Qué se cobra

**Una licencia anual por iglesia**, con un tope de dispositivos declarado en la
propia licencia.

```
licencia    id · iglesia_id · inicia_en · vence_en · tope_dispositivos
            estado · emitida_en · emitida_por · revocada_en · motivo_revocacion
```

- `tope_dispositivos` es **un número en la licencia, no una regla en el
  código**: cambiar los tramos por tamaño de iglesia es emitir otra licencia,
  no publicar una versión.
- Una iglesia tiene **historia de licencias**, no una licencia que se
  sobrescribe. Renovar emite una fila nueva; se ve qué se cobró y cuándo.
- `estado` es `vigente`, `vencida` o `revocada`. Vencer es efecto del
  calendario; **revocar es un acto explícito**, con motivo y con quién lo hizo.

### Qué pasa al vencer

| Qué | Con licencia vencida |
|---|---|
| Entrar, proyectar, entregar partituras, lista de alabanza | **funciona igual** |
| Login de músicos contra el nodo | **funciona igual** |
| Alta de usuarios, invitaciones nuevas, alta de instrumentos | bloqueado, diciendo por qué |
| Aviso en la pantalla del templo | **nunca** |

De ahí sale la regla que decide el diseño del código:

> **La comprobación de licencia vive en las operaciones administrativas.** No
> en el camino de autenticación, no en el de entrega de partituras, y **nunca**
> como un filtro global que algún día alcance al login.

**Pasarse del tope de dispositivos avisa, no bloquea.** Produce una advertencia
para el propietario y para el administrador de esa iglesia, y nada más. El
único límite duro que existe es el de dispositivos por usuario de 002, que ya
responde ofreciendo cerrar uno y nunca con un rechazo mudo.

## Razones

### Del cobro anual por iglesia

- **Quién paga.** Los músicos son voluntarios. Cobrar por dispositivo significa
  cobrarle al voluntario, o poner al tesorero a contar teléfonos cada mes.
- **El incentivo queda al derecho.** Cobrando por dispositivo, una iglesia
  ahorra compartiendo cuentas — exactamente lo que 002 se construyó para
  evitar. Con cuota anual, dar de alta a cada músico con su propia cuenta no
  cuesta nada.
- **Ingreso predecible**, y una sola conversación de dinero al año en vez de
  una cada vez que entra alguien nuevo.
- **El mecanismo ya existe.** El tope de dispositivos activos y su mensaje
  amable son de 002; no se inventa nada.
- **El tope no es para cobrar de más**, es para que el número signifique algo y
  para detectar una iglesia que creció y conviene revisar.

### De que vencer no apague nada

- **Constitución, punto 1:** "una licencia vencida degrada funciones
  administrativas, jamás la proyección". Esto no es una interpretación
  generosa: es el texto.
- **El daño de la alternativa es irreversible.** Bloquear por licencia el
  domingo por la mañana no se arregla pidiendo disculpas el lunes; se arregla
  perdiendo al cliente, y con razón.
- **La palanca de cobro real es administrativa.** Una iglesia que no puede dar
  de alta músicos nuevos ni emitir invitaciones tiene un motivo suficiente para
  renovar, sin que nadie se quede mirando una pantalla negra en medio de un
  canto.

## Alternativas descartadas

- **Cobrar por dispositivo y regalar el software a la iglesia.** Ingreso
  impredecible, incentivo a compartir cuentas, y una negociación incómoda cada
  vez que se suma un músico.
- **Cobrar por usuario.** Mismo problema: penaliza justo el comportamiento que
  se quiere —que cada persona tenga su cuenta.
- **Licencia que bloquea el acceso al vencer.** Contradice el punto 1 de la
  constitución. No se descarta por prudencia comercial, se descarta por
  principio.
- **Licencia perpetua con soporte aparte.** No da ingreso recurrente, que es lo
  que sostiene un servicio que corre todos los domingos.
- **Sobrescribir la licencia al renovar.** Más simple, y deja al negocio sin
  memoria de qué se cobró.

## Costo aceptado

- **Los tramos del tope por tamaño de iglesia quedan sin fijar.** No bloquea:
  el tope es un dato de la licencia. Se decide al emitir la primera real.
- **La comprobación de licencia hay que escribirla operación por operación**,
  en vez de en un solo sitio. Es más código y más fácil de olvidar en una
  operación nueva — y es exactamente el precio de que sea imposible que alcance
  al login por accidente. Se paga con gusto.
- **Una licencia vencida no impide usar el sistema el domingo.** Una iglesia
  puede seguir proyectando meses sin pagar. Se acepta: son dos iglesias
  conocidas, no clientes anónimos, y el punto 1 no admite excepciones.
- **Cobrar y facturar es manual.** El panel emite y revoca; no hay pasarela de
  pago. Automatizarlo, si llega, será con su propio ADR.
- **El tope que solo avisa se puede ignorar.** Es deliberado: un aviso que
  bloquea acaba bloqueando en el peor momento.

## Notas de implementación

- Esto define la licencia como **registro en la nube**. La **licencia firmada
  que el nodo verifica sin internet** es de
  [008](../../specs/008-sincronizacion-y-licencias/); el esquema de arriba es
  lo que 008 firmará, y por eso lleva ya vigencia, tope y estado.
- [licencias-saas.md](../arquitectura/licencias-saas.md) deja de estar vacío al
  cerrar 003, recogiendo lo decidido aquí y marcando qué queda para 008.
- El alta de iglesia desde el panel emite su licencia en el mismo acto: ninguna
  iglesia existe sin licencia.
- Emitir, renovar y revocar son operaciones del propietario del SaaS. El
  administrador de una iglesia **no ve ni administra licencias**.
