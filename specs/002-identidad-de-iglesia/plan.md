# 002-identidad-de-iglesia — plan

**Estado:** 📝 propuesto · Cumple [`spec.md`](spec.md)

El **cómo**. Las tres decisiones de arquitectura que exige este módulo están
registradas (constitución, punto 6):
[ADR 0015](../../docs/adr/0015-aislamiento-por-rls-y-nodo-atado-a-su-iglesia.md) aislamiento,
[ADR 0016](../../docs/adr/0016-sesion-firmada-verificable-sin-internet.md) sesión,
[ADR 0017](../../docs/adr/0017-acceso-a-datos-con-sql-explicito.md) acceso a datos.

## Punto de partida verificado

Comprobado en el código, no supuesto:

| Qué | Estado |
|---|---|
| `Symphony.sln` | Symphony.Node, Symphony.Cloud, Symphony.Migraciones y sus tres proyectos de pruebas |
| `apps/node-server/migrations/0001_inicial.sql` | solo `migraciones_aplicadas`; dice que el dominio entra en 002 |
| `services/cloud-api/migrations/0001_inicial.sql` | igual, y menciona que las políticas de RLS entran en 002 |
| Acceso a datos hoy | `Npgsql` y `Microsoft.Data.Sqlite` en crudo, sin ORM |
| `NodeOptions` | `SYMPHONY_NODE_SQLITE_PATH`, `SYMPHONY_NODE_CLOUD_URL` |
| `CloudOptions` | `SYMPHONY_CLOUD_POSTGRES_CONNECTION_STRING` |
| `Program.cs` (nodo) | aplica migraciones al arrancar; muere si fallan; `-- migrar` aplica y sale |
| Endpoints reales | ninguno: solo el `weatherforecast` de la plantilla, que se borra aquí |

Este módulo escribe `0002_identidad.sql` en cada carpeta de migraciones. Son
dos archivos distintos, no uno compartido (ADR 0010).

## El modelo

### Qué es cada cosa

- **Iglesia** — la entidad que hoy no existe. Identificador UUIDv7
  ([ADR 0005](../../docs/adr/0005-identificadores.md)), nombre, estado. Vive en
  la nube, que es su autoridad (ADR 0002).
- **Usuario** — una persona dentro de una iglesia. Correo único *dentro de su
  iglesia*: el mismo correo en dos iglesias son dos usuarios sin nada
  compartido (spec R4).
- **Propietario del SaaS** — identidad aparte, no una iglesia con más permisos.
  Tabla propia, en la nube, y nunca aparece como miembro de ninguna
  congregación.
- **Rol** — lista cerrada por iglesia: `administrador`, `operador`, `musico`.
  **Un usuario puede tener varios**, y **ninguno incluye a otro**: ser
  administrador no concede operar el servicio. Toda iglesia conserva al menos
  un administrador.
- **Instrumento** — catálogo común a todas las iglesias, en datos y no en
  código. Dos campos: un **código** (`piano`, `violin1`, `violin2`,
  `clarinete`) y su **afinación** (`c`, `bb`). El nombre visible no se guarda:
  sale del archivo de traducciones (constitución, punto 9).
- **Dispositivo** — un teléfono, una tableta o una pantalla de proyección.
  Varios por usuario, cada uno revocable por separado (spec R6).
- **Sesión** — un token de renovación vivo, atado a un dispositivo. Se guarda
  su huella, nunca el token (ADR 0016).

> **Por qué la afinación vive aquí y no en 006.** Un canto no tiene *una*
> partitura base: tiene una **por afinación**. Los instrumentos en Do —piano,
> violines, flautas, guitarra, cello— leen la base en Do; la trompeta y el
> clarinete leen la de Si♭. Encima de eso, un canto **puede** tener un arreglo
> propio para un instrumento. La regla de entrega es una sola: *si hay arreglo
> para este canto y este instrumento, se entrega; si no, la base de su
> afinación.*
>
> Por eso el catálogo no lleva ningún campo tipo `tiene_arreglo`: eso no es una
> propiedad del instrumento —el mismo instrumento tiene arreglo en un canto y
> no en otro— y se responde solo mirando si el archivo existe. Un campo que
> repite lo que ya dicen los datos acaba mintiendo.
>
> **Los archivos son de [006](../006-catalogo-y-partituras/); la afinación es
> de aquí**, porque es del instrumento. Nota para ese módulo: el archivo que
> hoy está copiado en `/piano/`, `/violin1/`, `/violin2/`, `/flute1/` y
> `/flute2/` no son cinco archivos, es **una base en Do duplicada cinco
> veces**. Y conviene llamarla *base*, no *melodía*: la de Si♭ también es la
> melodía.

### Esquema de la nube — `0002_identidad.sql` (PostgreSQL)

```
iglesia                id · nombre · estado · creada_en
propietario_saas       id · correo · hash_contrasena · creado_en
usuario                id · iglesia_id · correo · nombre · hash_contrasena
                       estado · creado_en        único (iglesia_id, correo)
usuario_rol            usuario_id · rol          lista cerrada, varios por usuario
instrumento            id · codigo · afinacion · orden   compartido, sin iglesia_id
usuario_instrumento    usuario_id · instrumento_id
dispositivo            id · iglesia_id · usuario_id (nulo si es pantalla) · tipo
                       nombre · creado_en · ultimo_visto_en · revocado_en
sesion                 id · dispositivo_id · iglesia_id · huella_token
                       emitida_en · expira_en · revocada_en
```

Sobre cada tabla con `iglesia_id`: `ENABLE` + **`FORCE ROW LEVEL SECURITY`**, y
una política que la compara con la variable de sesión que fija la aplicación
(ADR 0015). `instrumento` y `propietario_saas` quedan fuera, por ser
compartida y global respectivamente — son las excepciones cerradas de spec R2.

Dos roles de base de datos: el de la aplicación, `NOBYPASSRLS` y no dueño de
las tablas, y el del propietario del SaaS, que ve todas las iglesias y se usa
solo en los caminos de administración marcados.

### Esquema del nodo — `0002_identidad.sql` (SQLite)

Las mismas tablas, menos `propietario_saas`, y con dos diferencias:

- **`iglesia` tiene exactamente una fila**, impuesto por el esquema (clave
  primaria constante con restricción de valor único). No es una convención: la
  base rechaza la segunda.
- Las demás tablas referencian esa fila por clave foránea, así que **insertar
  algo de otra iglesia falla en el motor** (ADR 0015).

Usuarios, roles e instrumentos del nodo son **réplicas** de lo que manda la
nube (ADR 0002); cómo se replican es de
[008](../008-sincronizacion-y-licencias/). Lo que el nodo escribe por su cuenta
son dispositivos y sesiones: es él quien autentica el domingo.

## Cómo se cumple cada requisito

### R1, R2, R3 — Iglesia, pertenencia y aislamiento

Esquema de arriba más [ADR 0015](../../docs/adr/0015-aislamiento-por-rls-y-nodo-atado-a-su-iglesia.md).
Tres piezas de código:

1. **Una sola puerta a la base de la nube**: un envoltorio que abre la
   transacción y fija la iglesia de la sesión antes de dejar consultar. No hay
   otra forma de obtener una conexión. Si nadie fijó iglesia, no se consulta.
2. **La iglesia sale del token**, nunca de la ruta ni del cuerpo de la
   petición. No existe ningún parámetro `iglesiaId` en ninguna API.
3. **Verificación al arrancar en el nodo**: se compara la variable
   `SYMPHONY_NODE_IGLESIA_ID` con la fila de `iglesia`. Si falta, si sobra o si
   no coincide, el proceso **muere nombrando el problema**, igual que hoy hace
   con las migraciones y con la configuración.

Un identificador válido con la iglesia equivocada se responde como inexistente:
la política devuelve cero filas y el código traduce "cero filas" a "no existe",
sin un camino aparte para "prohibido".

### R4, R5, R6 — Usuarios, instrumentos, dispositivos

Alta de usuario dentro de una iglesia, con correo único en ella. Dar de baja
cambia el estado; **nunca borra la fila ni su trabajo** (constitución, punto 5),
y readmitir es volver a cambiar el estado.

Instrumentos: catálogo sembrado por migración con los diez de hoy, cada uno con
su afinación —`bb` para trompeta y clarinete, `c` para el resto—, y la relación
muchos-a-muchos con el usuario. Añadir uno nuevo es una migración y una clave
de traducción; no obliga a publicar la app.

No se guarda la clave (sol/fa): no cambia qué partitura le toca a nadie —el
piano usa dos a la vez y el cello lee la misma base en Do—, y una versión
específica para un instrumento es un arreglo, no un campo.

Dispositivos: alta al primer login, con nombre legible para que el músico
reconozca cuál es. Listar y revocar por separado. Revocar borra la sesión, no
los archivos del teléfono. El límite de dispositivos activos, si se aplica,
responde diciendo qué pasa y ofreciendo cerrar uno — nunca con un rechazo mudo
como el 403 de hoy.

### R7, R8 — Roles y autenticación

[ADR 0016](../../docs/adr/0016-sesion-firmada-verificable-sin-internet.md).
Contraseñas con Argon2id. El token lleva usuario, iglesia, roles y dispositivo,
y lo verifica quien recibe la petición.

La autorización se escribe como **una comprobación por operación, en el
servidor**, no como una capa de interfaz: la app puede mostrar lo que quiera,
el servidor responde lo mismo.

Nuevas variables de entorno, con la misma regla de 001 —si falta una, el
proceso no arranca y la nombra:

- **nodo:** `SYMPHONY_NODE_IGLESIA_ID`, su clave privada de firma y la clave
  pública de la nube.
- **nube:** su clave privada de firma, y la conexión del rol de propietario.

Ninguna vive en el repositorio (constitución, punto 7); `.env.example` gana sus
nombres con valores obviamente falsos.

### R9 — La primera iglesia sin panel

Un comando del proceso de la nube, al estilo del `-- migrar` que ya existe en
el nodo: crea la iglesia, su primer administrador y devuelve lo que el nodo
necesita para configurarse. La credencial inicial se da en el momento; no hay
contraseña por defecto ni cuenta de fábrica.

Sirve además para levantar un entorno de desarrollo y para las pruebas.

### R10 — Verificación

Sobre el armazón de 001
([ADR 0011](../../docs/adr/0011-pruebas-con-base-real-efimera.md)): PostgreSQL
en contenedor efímero, SQLite en archivo temporal. La RLS **solo se puede
probar contra el motor real**, que es una de las razones por las que se eligió
ese armazón.

## Estrategia de verificación

El módulo está cerrado cuando estas pruebas existen y pasan:

1. **Cruzar iglesias no funciona.** Con dos iglesias sembradas y todos los
   identificadores de la segunda a mano, ninguna lectura ni escritura desde la
   sesión de la primera los alcanza. La prueba falla solo si el intento
   funciona.
2. **El filtro olvidado devuelve cero filas.** Una consulta escrita a propósito
   sin `WHERE iglesia_id` no trae filas ajenas.
3. **El rol lo decide el servidor.** Un cliente que afirma ser administrador
   siendo músico recibe el mismo rechazo que si no dijera nada.
4. **El nodo se niega a arrancar** con una base de otra iglesia, y lo dice.
5. **Sin internet se entra igual.** El nodo autentica y emite sesión con la
   nube inalcanzable.
6. **El token manda sobre el reloj.** Una sesión caducada se rechaza aunque el
   cliente insista con una fecha falsa.
7. **Un dispositivo revocado deja de servir**, y los otros del mismo usuario
   siguen funcionando.
8. **Dar de baja no borra.** Tras baja y readmisión, el usuario conserva sus
   instrumentos y sus dispositivos.
9. **Ningún camino acepta un identificador de iglesia por parámetro.**

Todas corren en la integración continua de 001 y bloquean la fusión
(constitución, punto 4).

## Decisiones registradas

| Decisión | Elegida | Alternativa descartada | ADR |
|---|---|---|---|
| Cómo se impone el aislamiento | RLS forzada en la nube; nodo atado a su iglesia | Confiar en que toda consulta lleve su filtro | [0015](../../docs/adr/0015-aislamiento-por-rls-y-nodo-atado-a-su-iglesia.md) |
| Qué es una sesión | Token firmado con clave asimétrica, dos emisores | Sesión opaca consultada en la nube | [0016](../../docs/adr/0016-sesion-firmada-verificable-sin-internet.md) |
| Acceso a datos | SQL explícito con mapeador delgado | Entity Framework Core | [0017](../../docs/adr/0017-acceso-a-datos-con-sql-explicito.md) |

## Fuera de este plan

- Interfaz de administración, licencias e invitaciones por QR →
  [003](../003-panel-saas/). Aquí la iglesia nace por comando (R9).
- **Cómo viajan usuarios, revocaciones y claves entre nube y nodo** →
  [008](../008-sincronizacion-y-licencias/). Este plan deja las réplicas
  definidas y el nodo capaz de verificar sin internet; no construye la
  sincronización.
- Salas por iglesia en el protocolo de tiempo real → [005](../005-tiempo-real/).
- Pantallas de instrumentos, sesión y dispositivos en la app Flutter →
  [007](../007-app-movil/). Aquí se define el modelo y la API que consumirá.
- **Partituras base por afinación, arreglos por instrumento y la regla de qué
  se entrega** → [006](../006-catalogo-y-partituras/). Aquí solo se declara qué
  instrumentos existen y en qué afinación está cada uno.
