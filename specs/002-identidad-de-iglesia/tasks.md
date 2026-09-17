# 002-identidad-de-iglesia — tareas

Implementa [`plan.md`](plan.md). Cada tarea es atómica: se termina, se
verifica y se confirma en git por separado.

Regla: **ninguna tarea que añade comportamiento se cierra sin su prueba**
(constitución, punto 4). La prueba va en la misma tarea, no en una posterior.

Cada fase indica el **modelo sugerido**. Si el modelo en uso no es el sugerido,
hay que avisar y esperar antes de empezar, no decidirlo por cuenta propia.

> **Este módulo tiene más Opus de lo normal.** El aislamiento entre iglesias y
> la emisión de sesiones son las dos piezas donde un error no se ve hasta que
> ya filtró datos de una congregación a otra. Las fases mecánicas —catálogos,
> pantallas de administración, comandos— siguen siendo de Sonnet.

## Fase 1 — Esquema y aislamiento de la nube (spec R1–R3, [ADR 0015](../../docs/adr/0015-aislamiento-por-rls-y-nodo-atado-a-su-iglesia.md))

> **Modelo sugerido: Opus** — es la fase que decide si una iglesia puede ver datos de otra. Una política mal escrita pasa las pruebas ingenuas y falla en la que importa.

- [x] T1.1 Escribir `services/cloud-api/migrations/0002_identidad.sql` con las
      tablas de la nube: `iglesia`, `propietario_saas`, `usuario`,
      `usuario_rol`, `instrumento`, `usuario_instrumento`, `dispositivo`,
      `sesion`. Identificadores UUIDv7
      ([ADR 0005](../../docs/adr/0005-identificadores.md)).
- [x] T1.2 `usuario`: correo único **dentro de la iglesia**, no global. Dos
      iglesias pueden tener el mismo correo como dos personas distintas.
- [x] T1.3 Activar `ENABLE` **y `FORCE ROW LEVEL SECURITY`** en toda tabla con
      `iglesia_id`, con su política contra la variable de sesión. `FORCE` no es
      opcional: sin él, el dueño de las tablas se salta la política.
- [x] T1.4 Crear el rol de aplicación: **`NOBYPASSRLS`**, no dueño de las
      tablas, con permiso solo sobre lo que necesita.
- [x] T1.5 Crear el rol del propietario del SaaS, que ve todas las iglesias.
      Documentar en `docs/operacion/` qué caminos pueden usarlo.
- [x] T1.6 Sembrar el catálogo de instrumentos con los diez de hoy y su
      afinación: `bb` para trompeta y clarinete, `c` para el resto.
- [x] T1.7 Prueba: con dos iglesias sembradas, una sesión de la primera no
      alcanza **ninguna** fila de la segunda, teniendo todos sus
      identificadores a mano.
- [x] T1.8 Prueba: una consulta escrita a propósito **sin** filtro de iglesia
      devuelve cero filas, no filas ajenas.
- [x] T1.9 Prueba: el rol de aplicación no puede desactivar la política ni
      leer sin fijar iglesia.

## Fase 2 — Esquema del nodo (spec R1, R3)

> **Modelo sugerido: Opus** — la singularidad de la iglesia y la negativa a arrancar son el mecanismo que detecta el respaldo restaurado en el equipo equivocado.

- [x] T2.1 Escribir `apps/node-server/migrations/0002_identidad.sql`: las
      mismas tablas menos `propietario_saas`.
- [x] T2.2 `iglesia` admite **exactamente una fila**, impuesto por el esquema.
      No por convención ni por código: la base rechaza la segunda.
- [x] T2.3 Clave foránea de toda tabla de dominio a esa única fila, para que
      insertar algo de otra iglesia falle en el motor.
- [x] T2.4 Añadir `SYMPHONY_NODE_IGLESIA_ID` a `NodeOptions`, con la misma
      regla de 001: si falta, el proceso no arranca y la nombra.
- [x] T2.5 Al arrancar, comparar esa variable con la fila de `iglesia`. Si no
      coincide, **el nodo muere** diciendo qué iglesia esperaba y cuál
      encontró.
- [x] T2.6 Prueba: la segunda fila en `iglesia` es rechazada.
- [x] T2.7 Prueba: el nodo se niega a arrancar con una base de otra iglesia, y
      el mensaje lo explica.
- [x] T2.8 Prueba: insertar una fila de dominio con otra `iglesia_id` falla.

## Fase 3 — Acceso a datos ([ADR 0017](../../docs/adr/0017-acceso-a-datos-con-sql-explicito.md))

> **Modelo sugerido: Opus** — la puerta única es lo que sostiene la fase 1. Si se puede obtener una conexión sin pasar por ella, la RLS deja de proteger nada.

- [x] T3.1 Añadir Dapper a los dos proyectos.
- [x] T3.2 Escribir la **única** puerta a la base de la nube: abre transacción,
      fija la iglesia de la sesión y recién entonces deja consultar.
- [x] T3.3 Garantizar que **no hay otra forma** de obtener una conexión a la
      nube desde el código de dominio. Si nadie fijó iglesia, no se consulta.
- [x] T3.4 Prueba: pedir una conexión sin iglesia fijada falla, no devuelve una
      conexión sin filtrar.
- [x] T3.5 Prueba: dos unidades de trabajo seguidas sobre la misma conexión del
      pozo no heredan la iglesia de la anterior.
- [x] T3.6 Borrar el endpoint `weatherforecast` de la plantilla en los dos
      proyectos.

## Fase 4 — Contraseñas y sesiones ([ADR 0016](../../docs/adr/0016-sesion-firmada-verificable-sin-internet.md))

> **Modelo sugerido: Opus** — criptografía y caducidad. Aquí un error se descubre el día que alguien falsifica una sesión, no antes.

- [ ] T4.1 Implementar el guardado de contraseñas con Argon2id, con sal por
      usuario y **parámetros versionados junto al hash**, para poder subirlos
      después sin invalidar a nadie.
- [ ] T4.2 Calibrar los parámetros contra el hardware más débil de las
      iglesias, que en una es la misma PC que proyecta. Dejar el criterio
      escrito.
- [ ] T4.3 Generar los pares de claves de firma (nube y nodo) y leerlos del
      entorno. Ninguna clave privada entra al repositorio (constitución,
      punto 7).
- [ ] T4.4 Emitir el token de acceso: usuario, iglesia, roles, dispositivo,
      emisión, caducidad, emisor e identificador de clave.
- [ ] T4.5 Verificar un token contra la clave pública, **sin red**.
- [ ] T4.6 Emitir y verificar el token de renovación, atado a un dispositivo.
      Se guarda **solo su huella**, nunca el token.
- [ ] T4.7 Prueba: un token con la firma alterada se rechaza.
- [ ] T4.8 Prueba: un token caducado se rechaza aunque el cliente afirme otra
      fecha.
- [ ] T4.9 Prueba: el nodo verifica un token emitido por la nube sin ninguna
      llamada de red.
- [ ] T4.10 Prueba: un token emitido para una iglesia no sirve en otra.
- [ ] T4.11 Añadir las variables nuevas a `.env.example` con valores
      obviamente falsos.

## Fase 5 — Autenticación y autorización (spec R7, R8)

> **Modelo sugerido: Opus** para la autorización, **Sonnet** para los endpoints una vez fijada. La regla de "ningún rol incluye a otro" es fácil de romper sin darse cuenta.

- [ ] T5.1 Endpoint de login en la nube: correo, contraseña y dispositivo →
      sesión.
- [ ] T5.2 Endpoint de login en el nodo, que autentica **sin consultar a la
      nube** y emite con su propia clave.
- [ ] T5.3 Renovación de sesión, y cierre de sesión que revoca la renovación.
- [ ] T5.4 Comprobación de autorización por operación, en el servidor. Los
      roles **no se heredan entre sí**.
- [ ] T5.5 Un identificador válido de otra iglesia se responde como
      inexistente, no como prohibido.
- [ ] T5.6 Verificar que **ninguna API acepta un identificador de iglesia por
      parámetro**: siempre sale del token.
- [ ] T5.7 Prueba: un músico que afirma ser administrador recibe el mismo
      rechazo que si no dijera nada.
- [ ] T5.8 Prueba: un administrador **no** puede operar el servicio sin tener
      además el rol de operador.
- [ ] T5.9 Prueba: el nodo autentica y emite sesión con la nube inalcanzable.

## Fase 6 — Usuarios, instrumentos y dispositivos (spec R4–R6)

> **Modelo sugerido: Sonnet** — trabajo de altas y bajas sobre un modelo ya decidido. La única trampa es la baja que borra, y la prueba la cubre.

- [ ] T6.1 Alta de usuario dentro de una iglesia, con sus roles.
- [ ] T6.2 Baja de usuario: **cambia el estado, nunca borra la fila ni su
      trabajo** (constitución, punto 5). Readmitir es volver a cambiarlo.
- [ ] T6.3 Impedir que una iglesia se quede sin ningún administrador.
- [ ] T6.4 Asignar y quitar instrumentos a un músico (varios por persona).
- [ ] T6.5 Alta de dispositivo en el primer login, con nombre legible para que
      el músico reconozca cuál es.
- [ ] T6.6 Listar y revocar dispositivos por separado.
- [ ] T6.7 Si hay límite de dispositivos activos y se alcanza, responder
      diciendo qué pasa y ofreciendo cerrar uno. **Nunca un rechazo mudo**,
      como el 403 de hoy.
- [ ] T6.8 Prueba: tras baja y readmisión, el usuario conserva instrumentos y
      dispositivos.
- [ ] T6.9 Prueba: revocar un dispositivo no afecta a los demás del mismo
      usuario.
- [ ] T6.10 Prueba: quitar el último administrador de una iglesia se rechaza.

## Fase 7 — Alta de la primera iglesia sin panel (spec R9)

> **Modelo sugerido: Sonnet** — un comando, al estilo del `-- migrar` que ya existe en el nodo.

- [ ] T7.1 Comando en la nube que crea una iglesia y su primer administrador.
- [ ] T7.2 La credencial inicial se fija en el momento del alta. **Sin
      contraseña por defecto ni cuenta de fábrica.**
- [ ] T7.3 El comando devuelve lo que el nodo necesita para configurarse.
- [ ] T7.4 Documentar el procedimiento en `docs/operacion/`, sin secretos.
- [ ] T7.5 Prueba: el comando deja una iglesia utilizable, con administrador y
      sin credenciales adivinables.

## Fase 8 — Verificación del aislamiento (spec R10)

> **Modelo sugerido: Opus** — estas pruebas tienen que estar escritas para *intentar* romper el aislamiento. Una prueba complaciente aquí es peor que ninguna.

- [ ] T8.1 Semilla de dos iglesias ficticias con datos completos y evidentes
      (001 R5: nada real).
- [ ] T8.2 Recorrer **todas** las operaciones del módulo intentando cruzarse de
      iglesia con identificadores válidos. Ninguna lo consigue.
- [ ] T8.3 Prueba de que las tablas nuevas tienen su política activa: que nadie
      pueda añadir una tabla de dominio sin RLS y que las pruebas sigan verdes.
- [ ] T8.4 Verificar que estas pruebas corren en la tubería de 001 y bloquean
      la fusión.

## Cierre del módulo

- [ ] C1 `dotnet test` en verde, incluidas las pruebas de cruce de iglesias.
- [ ] C2 Los nueve puntos de la estrategia de verificación de
      [`plan.md`](plan.md) tienen prueba automática, no revisión a ojo.
- [ ] C3 Ninguna clave privada ni contraseña entró al repositorio;
      `.env.example` tiene los nombres nuevos.
- [ ] C4 `docs/arquitectura/estado-actual.md` actualizado: el hallazgo "No
      existe el concepto de iglesia" queda resuelto y se dice cómo.
- [ ] C5 `specs/README.md` marca 002 como ✅ y nombra el módulo siguiente.
- [ ] C6 Las notas para 006 —bases por afinación, el archivo en Do duplicado
      cinco veces— quedan recogidas donde ese módulo las encuentre.
