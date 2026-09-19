# 003-panel-saas — inventario de pantallas (T0.4)

La lista contra la que se revisa que no falta nada. Cumple [`spec.md`](spec.md)
R6 y es la entrada de T0.5 (wireframes) y T0.6 (prototipos).

Tres zonas, no dos: además de `/saas/*` y `/iglesia/*` hay un **camino
público** sin sesión, que es el canje de la invitación (plan: «el único camino
público del módulo»).

Columna **Diseño**: `W` = necesita wireframe antes del prototipo por tener
interacción nueva; `P` = pasa directo a prototipo por ser lista o formulario
(spec R6).

## Público — sin sesión

| # | Pantalla | Quién entra | Qué puede hacer | Diseño |
|---|---|---|---|---|
| P1 | Entrada de usuario de iglesia | cualquiera | Identificarse. Emite la sesión firmada de 002 | P |
| P2 | Entrada del propietario del SaaS | el propietario | Identificarse por **su propio camino** (`propietario_saas`), separado de P1 (spec R7, ADR 0019) | P |
| P3 | Canje de invitación | quien tenga un código | Escribir el código, poner su nombre y **elegir su contraseña**. Entra ya con sesión | **W** |
| P4 | Invitación no válida | íd. | Enterarse de que ya no sirve. Caducada, canjeada y revocada dicen **lo mismo** (T2.8) | P |

P3 acepta el código **escrito a mano**; la cámara es de
[007](../007-app-movil/). P3 nunca muestra el nombre de la iglesia antes del
canje: el QR no lleva datos dentro (spec R5).

## `/saas/*` — propietario del SaaS

Ve todas las iglesias. Acceso a datos: `AccesoComoPropietario`.

| # | Pantalla | Qué puede hacer | Diseño |
|---|---|---|---|
| S1 | Lista de iglesias | Estado, licencia, dispositivos activos y última vez que se vio su nodo (T4.4). Punto de entrada de la zona | P |
| S2 | Alta de iglesia | Nombre, correo de contacto y nombre del primer administrador. Crea la iglesia, emite su licencia y emite la invitación del administrador. **No pide contraseña** (T4.2) | **W** |
| S3 | Entrega de configuración del nodo | Lo que el nodo de esa iglesia necesita para configurarse, igual que hoy lo imprime el comando (T4.3). Cierra el flujo de S2 | **W** |
| S4 | Ficha de una iglesia | Sus datos, su licencia vigente y su historia de licencias. Renombrar —**sin cambiar el identificador**—, suspender y reactivar. **Nunca borrar** (T4.5) | P |
| S5 | Emitir o renovar licencia | Vigencia y tope de dispositivos. Renovar **emite una fila nueva** (T1.2) | P |
| S6 | Revocar licencia | Acto explícito, con motivo. Queda registrado con autor (T1.8) | P |
| S7 | Licencias por vencer | Las que están por caducar, para actuar antes (T4.6) | P |

S2 y S3 son **un solo flujo**: el alta no está terminada hasta que el
propietario tiene en la mano la invitación del administrador y la configuración
del nodo. Por eso llevan un wireframe común.

## `/iglesia/*` — administrador de la iglesia

Ve **solo la suya**. Acceso a datos: `AccesoALaNube`, con RLS. Ninguna de estas
pantallas muestra ni acepta un identificador de iglesia: siempre sale del token
(T5.6).

| # | Pantalla | Qué puede hacer | Diseño |
|---|---|---|---|
| I1 | Resumen de la iglesia | Qué hay que mirar hoy: advertencia de tope de dispositivos (T1.5), aviso de licencia vencida o por vencer, invitaciones vivas | **W** |
| I2 | Lista de usuarios | Su gente, con rol y estado. Punto de entrada | P |
| I3 | Ficha de usuario | Roles (lista cerrada, **ningún rol incluye a otro**), instrumentos (varios por persona), dispositivos | P |
| I4 | Baja y readmisión de usuario | **Cambia el estado, nunca borra** (T5.1). No se puede dejar la iglesia sin ningún administrador (T5.2) | P |
| I5 | Instrumentos de un músico | Asignar y quitar, varios por persona (T5.3) | P |
| I6 | Dispositivos | Listar con su nombre legible y **revocar por separado**, sin tocar la contraseña (T5.4) | P |
| I7 | Emitir invitación | Rol e instrumentos que tendrá quien la canje, y caducidad | **W** |
| I8 | Invitación emitida — QR y código | El QR y el código en texto, para proyectar o pegar. **El código no se vuelve a mostrar**: solo se guarda su huella (T2.2) | **W** |
| I9 | Invitaciones | Las vivas, las canjeadas —con quién— y las revocadas. Revocar una viva (T2.7) | P |

I1 lleva wireframe porque es donde se decide **cómo se muestra una advertencia
que no bloquea** (T0.7), que es la regla de UX más delicada del módulo: el tope
de dispositivos avisa y no rechaza nada (ADR 0020).

I7, I8 e I9 son **un solo flujo** con P3: emitir → mostrar → canjear → ver
quién la canjeó. Wireframe común.

## Común a las tres zonas

| # | Elemento | Qué hace | Diseño |
|---|---|---|---|
| C1 | Selector de idioma | Español e inglés, el inicial del navegador (T3.7, constitución punto 9). Presente también sin sesión, porque P3 se usa sin haber entrado nunca | P |
| C2 | Cierre de sesión y quién soy | En qué zona estoy y con qué identidad | P |
| C3 | Error y estado de carga | Qué se ve mientras algo carga y cómo se enuncia un error. **Se decide una vez** en T0.7, no pantalla por pantalla | P |

Compartir estos componentes de presentación entre zonas es correcto; compartir
acceso a datos, no (ADR 0019).

## Lo que este inventario deja visto

- **Faltan operaciones en el catálogo de 002.** `Operaciones` tiene hoy
  `administrar_usuarios`, `administrar_dispositivos`, `operar_el_servicio` y
  `ver_lo_mio_de_musico`. Las invitaciones (I7–I9) y las licencias (S5–S7) no
  están: hay que añadirlas en sus fases, no improvisarlas en la pantalla.
  Las del propietario no son un rol de iglesia y no entran en esa lista.
- **Ninguna pantalla de `/iglesia/*` tiene equivalente en `/saas/*`.** El
  propietario no administra usuarios de nadie y el administrador no ve
  licencias (spec R4). Si alguna vez una pantalla aparece en las dos zonas, es
  señal de que se está mezclando lo que ADR 0019 separó.
- **Tres flujos con wireframe**, no dos: el alta de iglesia (S2–S3), la
  invitación completa (I7–I8–P3) y el resumen de iglesia (I1) por la
  advertencia que no bloquea. Las 17 pantallas restantes pasan directo a
  prototipo.
