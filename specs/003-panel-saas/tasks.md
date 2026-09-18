# 003-panel-saas — tareas

Implementa [`plan.md`](plan.md). Cada tarea es atómica: se termina, se
verifica y se confirma en git por separado.

Regla: **ninguna tarea que añade comportamiento se cierra sin su prueba**
(constitución, punto 4). La prueba va en la misma tarea, no en una posterior.

Cada fase indica el **modelo sugerido**. Si el modelo en uso no es el sugerido,
hay que avisar y esperar antes de empezar, no decidirlo por cuenta propia.

> **Este módulo estrena la interfaz del proyecto.** La fase 0 no es preámbulo:
> **ninguna pantalla se implementa sin su prototipo aprobado** (spec R6), y el
> archivo de traducciones nace aquí. Lo que se decida en la fase 0 lo heredan
> 007 y 010.

## Fase 0 — Decisiones, diseño y traducciones

> **Modelo sugerido: Opus** — las dos decisiones de arquitectura y la
> separación de zonas. Un ADR no se reescribe (constitución, punto 6), y una
> convención de interfaz mal puesta se hereda tres veces.

- [ ] T0.1 Escribir `docs/adr/0019-panel-web-servido-por-la-nube.md`: Blazor
      Server dentro de `Symphony.Cloud`, dos zonas por rol, con el costo
      aceptado y las alternativas descartadas. Decir explícitamente que **no
      contradice** a [ADR 0013](../../docs/adr/0013-app-de-escritorio-en-vez-de-panel-web.md),
      que retira el panel *del templo*.
- [ ] T0.2 Escribir `docs/adr/0020-licencia-anual-por-iglesia.md`: anual por
      iglesia, tope de dispositivos que **avisa y no bloquea**, y qué degrada
      exactamente una licencia vencida (constitución, punto 1).
- [ ] T0.3 Comprobar qué *skills* y plantillas hay disponibles para Blazor y
      para diseño antes de empezar, y dejar anotado cuáles se usan. No se
      descarga nada a mitad de la fase 4.
- [ ] T0.4 Inventario de pantallas de las dos zonas, con quién entra a cada una
      y qué puede hacer. Es la lista contra la que se revisa que no falta nada.
- [ ] T0.5 Wireframes de los dos flujos: **alta de iglesia** y **emisión y
      canje de invitación**. Las pantallas de lista y formulario sin
      interacción nueva pasan directo a prototipo (spec R6).
- [ ] T0.6 Prototipo de cada pantalla del inventario, en Claude Design.
      **Aprobado por el propietario antes de escribir código de interfaz.**
- [ ] T0.7 Escribir las reglas de UX en `docs/diseno/`: qué se confirma, qué se
      puede deshacer, cómo se enuncia un error, qué se ve mientras algo carga,
      cómo se muestra una advertencia que no bloquea. Valen para todas las
      pantallas y para 007 y 010.
- [ ] T0.8 Crear el archivo de traducciones, español e inglés, y el mecanismo
      que lo lee. **Ningún texto visible en el código** (constitución, punto 9).
- [ ] T0.9 Añadir a [`specs/README.md`](../README.md) la regla de proceso:
      ninguna pantalla se implementa sin prototipo aprobado, en este módulo y
      en los siguientes.

## Fase 1 — Licencias (spec R3, ADR 0020)

> **Modelo sugerido: Opus** — dónde se comprueba la licencia decide si una
> licencia vencida puede apagar un culto. Es el punto donde un atajo razonable
> rompe el primer principio de la constitución.

- [ ] T1.1 Migración `0003_licencias.sql` en la nube: tabla `licencia` con
      iglesia, vigencia, tope de dispositivos, estado, quién la emitió y el
      motivo de revocación. UUIDv7
      ([ADR 0005](../../docs/adr/0005-identificadores.md)).
- [ ] T1.2 Renovar **emite una fila nueva**; la licencia anterior no se
      sobrescribe. Una iglesia tiene historia.
- [ ] T1.3 Emitir, renovar y revocar licencia, solo desde el camino del
      propietario.
- [ ] T1.4 Comprobación de licencia **en las operaciones administrativas**, con
      un nombre que diga qué bloquea. No en el login, no en la entrega de
      partituras, no en un filtro global.
- [ ] T1.5 El tope de dispositivos produce una **advertencia** visible para el
      propietario y para el administrador de esa iglesia. No rechaza nada.
- [ ] T1.6 Prueba: con licencia vencida se entra y se proyecta igual, y **no**
      se puede dar de alta un usuario. Las dos mitades en la misma prueba.
- [ ] T1.7 Prueba: pasarse del tope avisa y no bloquea.
- [ ] T1.8 Prueba: revocar una licencia queda registrado con motivo y autor, y
      no borra la fila.

## Fase 2 — Invitaciones (spec R5)

> **Modelo sugerido: Opus** — es el único camino público del módulo y crea
> usuarios. Aquí se decide la iglesia de alguien sin que haya sesión todavía.

- [ ] T2.1 Migración: tabla `invitacion` con iglesia, huella del código, roles,
      instrumentos, caducidad, canje y revocación.
- [ ] T2.2 Generar el código aleatorio y guardar **solo su huella**, como el
      token de renovación de 002. Nadie lo recupera de la base.
- [ ] T2.3 Emitir invitación desde la zona de iglesia, con rol e instrumentos.
- [ ] T2.4 Generar el QR en el servidor. **Contiene solo el código**: ni
      iglesia, ni rol, ni correo. Ofrecer también el código en texto.
- [ ] T2.5 Endpoint público de canje: nombre y contraseña elegida por la
      persona, usuario creado con los roles e instrumentos de la invitación,
      invitación marcada y sesión emitida.
- [ ] T2.6 La iglesia del usuario nuevo sale **de la invitación**, nunca del
      cuerpo de la petición.
- [ ] T2.7 Revocar una invitación viva, y listar cuáles siguen vigentes, cuáles
      se canjearon y quién las canjeó.
- [ ] T2.8 Caducada, canjeada y revocada responden **lo mismo**: ya no es
      válida. No se confirma si existió.
- [ ] T2.9 Prueba: una invitación de una iglesia no se canjea contra otra, ni
      afirmando otra iglesia en la petición.
- [ ] T2.10 Prueba: los tres estados inválidos dan la misma respuesta.
- [ ] T2.11 Prueba: revocar antes del canje la inutiliza.
- [ ] T2.12 Prueba: el contenido del QR no incluye ningún dato de la iglesia.

## Fase 3 — Armazón del panel (spec R1, R7, ADR 0019)

> **Modelo sugerido: Opus** — la separación de zonas es lo que sostiene todo lo
> demás. Si un componente de iglesia puede alcanzar el acceso del propietario,
> las pantallas dejan de importar.

- [ ] T3.1 Añadir Blazor Server al proyecto de la nube, servido por el mismo
      proceso. Las minimal API siguen donde están.
- [ ] T3.2 Autenticación del panel sobre la sesión firmada de 002. No se
      inventa una segunda forma de guardar la sesión.
- [ ] T3.3 Entrada del propietario del SaaS por su propio camino
      (`propietario_saas`), separada de la de los usuarios de iglesia.
- [ ] T3.4 Las dos zonas, `/saas/*` y `/iglesia/*`, cada una con **su** acceso
      a datos: `AccesoComoPropietario` y `AccesoALaNube`.
- [ ] T3.5 Impedir en el código que un componente de `/iglesia/*` obtenga
      `AccesoComoPropietario`. Impuesto, no confiado.
- [ ] T3.6 Cada operación comprobada en el servidor con `ExigirOperacion`.
      Esconder un botón no autoriza nada.
- [ ] T3.7 Selector de idioma, tomando el inicial del navegador
      (constitución, punto 9).
- [ ] T3.8 Prueba: un componente de la zona de iglesia no puede obtener el
      acceso del propietario.
- [ ] T3.9 Prueba: un administrador que pide una ruta `/saas/*` recibe el mismo
      rechazo que quien no tiene sesión.
- [ ] T3.10 Prueba: recorrer la interfaz y fallar si hay una cadena de texto
      visible escrita en el código.

## Fase 4 — Zona del propietario (spec R2, R3)

> **Modelo sugerido: Sonnet** — pantallas sobre un modelo ya decidido, con el
> prototipo de la fase 0 delante.

- [ ] T4.1 Extraer la lógica de `crear-iglesia` a un servicio que usen **el
      comando y el panel**. El comando no se retira.
- [ ] T4.2 Alta de iglesia desde el panel: crea la iglesia, emite su licencia y
      emite la invitación del primer administrador. **No pide contraseña.**
- [ ] T4.3 Entregar al final lo que el nodo de esa iglesia necesita para
      configurarse, igual que lo imprime hoy el comando.
- [ ] T4.4 Lista de iglesias con estado, licencia, dispositivos activos y
      última vez que se vio su nodo.
- [ ] T4.5 Suspender y reactivar una iglesia. **Nunca borrar** (constitución,
      punto 5). Renombrar no cambia el identificador.
- [ ] T4.6 Pantallas de licencia: emitir, renovar, revocar y ver las que están
      por vencer.
- [ ] T4.7 Prueba: el alta desde el panel deja una iglesia utilizable, con
      licencia, con invitación de administrador y sin credenciales adivinables.
- [ ] T4.8 Prueba: el comando `crear-iglesia` sigue funcionando tras la
      extracción.

## Fase 5 — Zona de la iglesia (spec R4, R5)

> **Modelo sugerido: Sonnet** — altas y bajas sobre lo que 002 ya expone. La
> única trampa es la baja que borra, y la prueba la cubre.

- [ ] T5.1 Usuarios: alta, baja, readmisión y roles. La baja **cambia el
      estado, nunca borra** (constitución, punto 5).
- [ ] T5.2 Impedir dejar la iglesia sin ningún administrador (002 R7).
- [ ] T5.3 Instrumentos por músico: asignar y quitar, varios por persona.
- [ ] T5.4 Dispositivos: listar y **revocar por separado**, con el nombre
      legible con que se dieron de alta.
- [ ] T5.5 Invitaciones: emitir, mostrar el QR, revocar y ver las vivas.
- [ ] T5.6 Ninguna pantalla de esta zona muestra ni acepta un identificador de
      iglesia: siempre sale del token.
- [ ] T5.7 Prueba: tras baja y readmisión, el usuario conserva instrumentos y
      dispositivos.
- [ ] T5.8 Prueba: quitar el último administrador se rechaza desde el panel.
- [ ] T5.9 Prueba: revocar un dispositivo no afecta a los demás del usuario.

## Fase 6 — Verificación del aislamiento en el panel (spec R8)

> **Modelo sugerido: Opus** — estas pruebas se escriben para *intentar* romper
> el aislamiento. Una prueba complaciente aquí es peor que ninguna.

- [ ] T6.1 Semilla de dos iglesias ficticias con licencias, usuarios,
      dispositivos e invitaciones (001 R5: nada real).
- [ ] T6.2 Recorrer **todas** las operaciones de la zona de iglesia intentando
      cruzarse con identificadores válidos de la otra. Ninguna lo consigue.
- [ ] T6.3 Un músico no alcanza ninguna operación de administrador desde el
      panel, aunque conozca la ruta.
- [ ] T6.4 Un administrador no alcanza ninguna operación del propietario.
- [ ] T6.5 Verificar que estas pruebas corren en la tubería de 001 y bloquean
      la fusión.

## Cierre del módulo

- [ ] C1 `dotnet test` en verde, incluidas las pruebas de cruce de iglesias del
      panel.
- [ ] C2 Los once puntos de la estrategia de verificación de
      [`plan.md`](plan.md) tienen prueba automática, no revisión a ojo.
- [ ] C3 Ningún secreto en el repositorio; `.env.example` con los nombres
      nuevos, si los hubo.
- [ ] C4 Toda pantalla implementada tiene su prototipo aprobado y su texto en
      el archivo de traducciones, en los dos idiomas.
- [ ] C5 `docs/arquitectura/licencias-saas.md` deja de estar vacío: recoge lo
      que decide este módulo y deja marcado qué es de 008.
- [ ] C6 **Deuda de 002:** escribir `docs/arquitectura/vision-general.md` y
      `docs/arquitectura/modelo-datos.md`, que nacieron vacíos y tocaban al
      cerrar 002.
- [ ] C7 `docs/arquitectura/estado-actual.md` actualizado: el alta de iglesia
      por terminal y el alta de músicos a mano quedan resueltos, y se dice cómo.
- [ ] C8 `docs/operacion/alta-de-iglesia.md` actualizado: el panel es el camino
      normal, el comando queda como camino de entorno nuevo y de contingencia.
- [ ] C9 `specs/README.md` marca 003 como ✅ y nombra el módulo siguiente.
