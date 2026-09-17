# Roles de base de datos de la nube

Quién se conecta a PostgreSQL y con qué permisos
([ADR 0015](../adr/0015-aislamiento-por-rls-y-nodo-atado-a-su-iglesia.md)).
**Ningún paso aquí incluye contraseñas reales.**

Son tres roles con trabajos distintos. La migración `0002_identidad.sql` crea
los dos últimos; el primero ya existe de
[la creación de la base](base-de-datos-de-la-nube.md).

| Rol | Quién lo usa | Qué puede |
|---|---|---|
| `symphony_cloud` | Solo las migraciones | Dueño de las tablas. No lo usa la aplicación |
| `symphony_app` | La aplicación, siempre | `NOBYPASSRLS`. Solo ve la iglesia de la sesión |
| `symphony_propietario` | Caminos de administración del SaaS, marcados uno a uno | `BYPASSRLS`. Ve todas las iglesias |

## Por qué son tres y no uno

La política de aislamiento la aplica el motor, pero **al dueño de una tabla no
le aplica salvo con `FORCE`**, y aun con `FORCE` un rol con `BYPASSRLS` se la
salta entera. Por eso la aplicación no es dueña de nada y no puede saltarse la
política: si alguien olvida el filtro en una consulta, el resultado son cero
filas, nunca filas de otra congregación.

`symphony_propietario` existe porque el propietario del SaaS sí necesita ver
todas las iglesias —dar de alta una nueva, por ejemplo—. Es el único camino que
se salta el aislamiento, y por eso está separado: el riesgo queda en unos pocos
caminos auditables, no repartido por todas las consultas.

## Fijar sus contraseñas

La migración crea los roles **sin contraseña**, porque una contraseña en el
repositorio es una contraseña comprometida (constitución, punto 7). Sin
contraseña ningún rol puede conectarse, así que hay que fijarlas en el servidor
después de aplicar las migraciones:

```bash
openssl rand -base64 24   # una por rol, distintas
sudo -u postgres psql -d symphony_cloud
```

```sql
ALTER ROLE symphony_app          WITH PASSWORD '...';
ALTER ROLE symphony_propietario  WITH PASSWORD '...';
```

Cada una va al `.env` del servidor (`/etc/symphony/.env`, `chmod 600`), nunca al
repositorio.

## Qué rol va en qué variable

- `SYMPHONY_CLOUD_POSTGRES_CONNECTION_STRING` — **`symphony_app`**. Es la
  conexión con la que la aplicación atiende peticiones.
- `SYMPHONY_CLOUD_POSTGRES_PROPIETARIO_CONNECTION_STRING` — **`symphony_propietario`**.
  Se usa solo en los caminos marcados arriba.
- Las migraciones se aplican con `symphony_cloud`, que es el dueño.

## Permiso para crear roles

`0002_identidad.sql` ejecuta `CREATE ROLE`, así que quien aplica las migraciones
necesita poder crearlos. Una vez, en el VPS:

```sql
ALTER ROLE symphony_cloud CREATEROLE;
```

La alternativa es aplicar las migraciones como `postgres`. Se prefiere
`CREATEROLE` sobre el superusuario: es el permiso más chico que basta.

## Qué caminos pueden usar el rol del propietario

**Un camino que use este rol y no esté en esta lista es un defecto**, porque es
un camino que ve todas las iglesias sin que nadie lo haya revisado.

- `POST /autenticacion/iniciar-sesion` (`AccesoComoPropietario.BuscarPorCorreo`,
  fase 5 de [002](../../specs/002-identidad-de-iglesia/tasks.md)). El correo es
  único solo dentro de su iglesia (spec R4), así que el login todavía no sabe
  cuál es la suya cuando busca al usuario. En cuanto lo sabe, todo lo demás
  —dispositivo, sesión, roles— pasa por `symphony_app` como cualquier otro
  camino.

El comando de alta de la primera iglesia (fase 7) es candidato a sumarse
después.
