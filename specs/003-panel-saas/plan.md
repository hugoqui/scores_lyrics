# 003-panel-saas — plan

**Estado:** 📝 propuesto · Cumple [`spec.md`](spec.md)

El **cómo**. Este módulo exige dos decisiones de arquitectura nuevas, que se
registran **antes** de implementar (constitución, punto 6) y son las dos
primeras tareas de [`tasks.md`](tasks.md):

| | Decisión | ADR |
|---|---|---|
| 1 | Con qué se construye el panel y cómo se separan sus dos zonas | [0019](../../docs/adr/0019-panel-web-servido-por-la-nube.md) ✅ |
| 2 | Qué es una licencia y qué hace al vencer | [0020](../../docs/adr/0020-licencia-anual-por-iglesia.md) ✅ |

## Punto de partida verificado

Comprobado en el código, no supuesto:

| Qué | Estado |
|---|---|
| Interfaz de usuario en el repositorio | **ninguna.** `Symphony.Cloud` es minimal API con OpenAPI; `apps/web-panel` es legado que se retira ([ADR 0013](../../docs/adr/0013-app-de-escritorio-en-vez-de-panel-web.md)) |
| `Program.cs` (nube) | `MapearAutenticacion`, `MapearUsuarios`, `MapearInstrumentos`, `MapearDispositivos`; migraciones al arrancar; comandos `generar-claves`, `migrar`, `crear-iglesia` |
| Puerta única a la base | `AccesoALaNube` fija la iglesia de la sesión antes de dejar consultar ([ADR 0017](../../docs/adr/0017-acceso-a-datos-con-sql-explicito.md)) |
| Camino que ve todas las iglesias | `AccesoComoPropietario`, acotado y documentado en [`roles-de-base-de-datos.md`](../../docs/operacion/roles-de-base-de-datos.md) |
| Sesiones | `EmisorDeSesiones` / `VerificadorDeSesiones` en `libs/sesiones` ([ADR 0016](../../docs/adr/0016-sesion-firmada-verificable-sin-internet.md)) |
| Autorización por operación | `ExigirOperacion`, `SesionDeLaPeticion`, `Roles` — ningún rol incluye a otro |
| Alta de iglesia hoy | comando `-- crear-iglesia`, contraseña por entrada estándar ([alta-de-iglesia.md](../../docs/operacion/alta-de-iglesia.md)) |
| Tabla `licencia` | no existe. `docs/arquitectura/licencias-saas.md` está vacío a propósito |
| Archivo de traducciones | no existe todavía en ninguna parte |

Dos consecuencias: **este módulo estrena la capa de interfaz del proyecto** y
**estrena las traducciones**. Las dos cosas se hacen una vez y las heredan 007
y 010.

## Decisión 1 — El panel

**Una sola aplicación web Blazor Server, servida por el propio proceso de
`Symphony.Cloud`, con dos zonas separadas por rol.**

Por qué Blazor Server y no un frontend aparte:

- Un despliegue, un lenguaje, una tubería. No hay proyecto de frontend, ni
  empaquetado de JavaScript, ni una segunda superficie de autenticación que
  mantener en sincronía con la primera.
- La sesión firmada de 002 ya sirve tal cual; no hay que inventar cómo viaja un
  token hasta un navegador y cómo se renueva allí.
- El panel **no va al templo** y puede exigir internet (spec R1), que es
  precisamente la condición que hacía inviable un panel web para el culto y
  motivó [ADR 0013](../../docs/adr/0013-app-de-escritorio-en-vez-de-panel-web.md).
  Aquel ADR retira el panel *del templo*; no dice nada del panel del SaaS, y
  este no lo contradice.

Alternativas descartadas: un SPA (Vue, React) contra la API — añade un segundo
despliegue y una segunda forma de guardar la sesión para dos usuarios y un
puñado de pantallas; y dos aplicaciones separadas, una por zona — duplica
plantillas, traducciones y autenticación para separar algo que se separa mejor
por rol.

### Cómo se separan las dos zonas

La separación no es cosmética. Cada zona tiene **su propio acceso a datos**:

```
/saas/*      →  propietario del SaaS  →  AccesoComoPropietario  →  ve todas las iglesias
/iglesia/*   →  administrador         →  AccesoALaNube          →  RLS, solo su iglesia
```

- La iglesia sale **siempre del token**, nunca de la ruta ni del formulario
  (002 R3, spec R7). No hay ninguna pantalla con un selector de iglesia en la
  zona de iglesia.
- Ningún componente de `/iglesia/*` puede alcanzar `AccesoComoPropietario`. Eso
  se impone en el código y se comprueba con una prueba, no con disciplina.
- Compartir componentes de presentación entre zonas es correcto. Compartir
  acceso a datos, no.
- Cada operación se comprueba en el servidor con `ExigirOperacion`, la misma
  que usan los endpoints. Esconder un botón no autoriza nada.

## Decisión 2 — La licencia

Una licencia es una fila en la nube, por iglesia:

```
licencia    id · iglesia_id · inicia_en · vence_en · tope_dispositivos
            estado · emitida_en · emitida_por · revocada_en · motivo_revocacion
```

- **Anual por iglesia**, no por dispositivo ni por usuario (spec R3).
- `tope_dispositivos` es un número en la licencia, no una regla en el código:
  cambiar los tramos por tamaño de iglesia es emitir otra licencia.
- Una iglesia tiene **historia de licencias**, no una licencia que se
  sobrescribe: renovar emite una fila nueva. Se ve qué se cobró y cuándo.
- `estado` es `vigente`, `vencida` o `revocada`. Vencer es efecto del
  calendario; revocar es un acto explícito, con motivo y con quién lo hizo.

**Qué hace una licencia vencida**, que es lo que de verdad decide este diseño:

| Qué | Con licencia vencida |
|---|---|
| Entrar, proyectar, entregar partituras, lista de alabanza | **funciona igual** |
| Login de músicos contra el nodo | **funciona igual** |
| Alta de usuarios, invitaciones nuevas, alta de instrumentos | bloqueado, diciendo por qué |
| Aviso en la pantalla del templo | **nunca** |

Constitución, punto 1: una licencia vencida degrada funciones
administrativas, jamás la proyección. La comprobación de licencia vive en las
operaciones de administración, **no** en el camino de autenticación ni en el de
entrega de partituras; si se pusiera ahí, una licencia vencida apagaría un
culto, y eso es lo único que el proyecto no permite.

El **tope de dispositivos avisa, no bloquea**: pasarse produce una advertencia
visible para el propietario y para el administrador de esa iglesia, y nada más.
El único límite duro que existe es el de dispositivos por usuario de 002 R6,
que ya responde ofreciendo cerrar uno.

Lo que este plan **no** construye: la licencia firmada que el nodo verifica sin
internet. Eso es de [008](../008-sincronizacion-y-licencias/), y el esquema de
arriba es lo que 008 firmará.

## La invitación

```
invitacion  id · iglesia_id · codigo_hash · roles · instrumentos
            creada_por · creada_en · expira_en
            canjeada_en · canjeada_por_usuario_id · revocada_en
```

- El código se genera aleatorio y **solo se guarda su huella**, igual que el
  token de renovación de 002. Quien lo pierde lo revoca y emite otro; nadie
  puede recuperarlo de la base.
- El QR contiene **solo el código**. Ni la iglesia, ni el rol, ni el correo de
  nadie: un QR proyectado en un ensayo acaba fotografiado.
- Canjearlo es el único camino público del módulo: no hay sesión todavía. Pide
  nombre y contraseña, crea el usuario con los roles e instrumentos que la
  invitación declara, marca la invitación como canjeada y emite sesión.
- Caducada, canjeada o revocada se responden igual: *esta invitación ya no es
  válida*. No se confirma si existió.
- La iglesia del usuario nuevo sale **de la invitación**, nunca de lo que envíe
  quien la canjea.
- El primer administrador de una iglesia nueva se crea por este mismo camino
  (spec R2), con una invitación que emite el propietario en el momento del
  alta. Por eso el alta desde el panel no pide ninguna contraseña.

## Diseño antes de código

Ninguna pantalla se implementa sin prototipo aprobado (spec R6). El orden es
inventario de pantallas → wireframe → prototipo → reglas de UX y textos. El
wireframe se omite en pantallas que son una lista o un formulario sin
interacción nueva; es obligatorio donde hay flujo: el alta de iglesia y la
invitación.

Esto **no es una regla de este módulo**: es de proceso, y vale también para
[007](../007-app-movil/) y [010](../010-app-de-escritorio/). Se escribe en
[`specs/README.md`](../README.md), junto a "no se escribe código de un módulo
sin su `spec.md` aprobado".

Las reglas de UX resultantes van a `docs/diseno/`, no a `tasks.md`: son lo que
queda vigente cuando el spec ya caducó.

Traducciones: el panel estrena el archivo de traducciones del proyecto, español
e inglés desde el primer día (constitución, punto 9). Ningún texto visible se
escribe en el código, ni siquiera durante el prototipo. Una prueba recorre la
interfaz buscando cadenas literales: es la única forma de que la regla siga
viva dentro de seis meses.

## Cómo se cumple cada requisito

### R1, R7 — El panel y el aislamiento

Blazor Server dentro de `Symphony.Cloud`, dos zonas por rol, cada una con su
acceso a datos (decisión 1). La comprobación por operación es la misma
`ExigirOperacion` de 002; no se escribe una autorización paralela para la
interfaz.

El propietario del SaaS entra por su propio camino de autenticación
—`propietario_saas` es una tabla aparte desde 002— y no aparece como miembro de
ninguna congregación.

### R2 — Alta de iglesias

La lógica del comando `crear-iglesia` se extrae a un servicio que usan **los
dos** caminos: el comando y el panel. El comando no se retira (spec R2): es lo
que levanta un entorno desde cero y lo que queda si el panel está caído.

Diferencia: el panel no pide contraseña. Crea la iglesia, emite su licencia y
emite la invitación del primer administrador.

### R3 — Licencias

Esquema y reglas de la decisión 2. La comprobación se escribe como **una
comprobación explícita en las operaciones administrativas**, nombrada de forma
que se vea en el código qué se está bloqueando. Nada de un filtro global que
algún día alcance al login.

### R4 — Administración de la iglesia

Pantallas sobre lo que 002 ya expone: usuarios, roles, instrumentos,
dispositivos. Sin modelo nuevo. Lo único que se añade son las invitaciones.

### R5 — Invitaciones

Esquema de arriba. Un endpoint público de canje, y las pantallas de emisión y
revocación en la zona de iglesia. El QR se genera en el servidor a partir del
código; la app de [007](../007-app-movil/) solo le pondrá cámara.

### R6 — Diseño y traducciones

Fase 0 de [`tasks.md`](tasks.md), antes de la primera línea de interfaz.

### R8 — Verificación

Sobre el armazón de 001
([ADR 0011](../../docs/adr/0011-pruebas-con-base-real-efimera.md)): PostgreSQL
efímero, y las pantallas probadas contra el servidor real, no contra dobles.

## Estrategia de verificación

El módulo está cerrado cuando estas pruebas existen y pasan:

1. **Un administrador no alcanza otra iglesia.** Con identificadores válidos de
   la segunda iglesia a mano, ninguna pantalla ni operación de la zona de
   iglesia los alcanza. Falla solo si el intento funciona.
2. **Un administrador no alcanza la zona del propietario**, ni por ruta directa
   ni por una operación suelta.
3. **Ningún componente de `/iglesia/*` obtiene `AccesoComoPropietario`.**
4. **Una licencia vencida no impide entrar ni proyectar**, y sí impide dar de
   alta un usuario. Las dos mitades en la misma prueba.
5. **Pasarse del tope de dispositivos avisa y no bloquea.**
6. **Una invitación de una iglesia no se canja contra otra**, y la iglesia del
   usuario creado sale de la invitación aunque el cuerpo de la petición diga
   otra cosa.
7. **Una invitación caducada, canjeada o revocada se rechaza**, con la misma
   respuesta en los tres casos.
8. **Revocar una invitación antes del canje la inutiliza.**
9. **Crear una iglesia desde el panel deja una iglesia utilizable**, con
   licencia, con invitación de administrador y **sin ninguna contraseña
   adivinable**.
10. **No hay texto visible escrito en el código**: una prueba lo recorre y
    falla si encuentra una cadena literal.
11. **El comando `crear-iglesia` sigue funcionando** después de extraer la
    lógica compartida.

Todas corren en la integración continua de 001 y bloquean la fusión
(constitución, punto 4).

## Decisiones registradas

| Decisión | Elegida | Alternativa descartada | ADR |
|---|---|---|---|
| Con qué se construye el panel | Blazor Server en `Symphony.Cloud`, dos zonas por rol | SPA contra la API; dos aplicaciones separadas | [0019](../../docs/adr/0019-panel-web-servido-por-la-nube.md) |
| Qué es una licencia | Anual por iglesia, tope de dispositivos que avisa | Cobro por dispositivo; licencia que bloquea al vencer | [0020](../../docs/adr/0020-licencia-anual-por-iglesia.md) |

## Fuera de este plan

- **Siembra del catálogo inicial** → [006](../006-catalogo-y-partituras/).
- **Cámara y escaneo del QR** → [007](../007-app-movil/).
- **Licencia firmada verificable sin internet y sincronización de
  revocaciones** → [008](../008-sincronizacion-y-licencias/). Este plan deja el
  registro que 008 firmará.
- **Cobro real, pasarelas y facturación.** La licencia se emite a mano.
- **Proyección y control del culto** → [004](../004-estado-en-vivo/),
  [005](../005-tiempo-real/), [010](../010-app-de-escritorio/).
