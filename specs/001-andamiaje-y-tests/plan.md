# 001-andamiaje-y-tests — plan

**Estado:** 📝 propuesto · Cumple [`spec.md`](spec.md)

El **cómo**. Las tres decisiones de arquitectura que exige este módulo ya están
registradas (constitución, punto 6):
[ADR 0010](../../docs/adr/0010-migraciones-sql-planas.md) migraciones,
[ADR 0011](../../docs/adr/0011-pruebas-con-base-real-efimera.md) pruebas,
[ADR 0012](../../docs/adr/0012-integracion-continua-en-github-actions.md) CI.

## Entorno verificado

Comprobado en la máquina, no supuesto:

| Qué | Estado |
|---|---|
| .NET SDK | 10.0.302 instalado |
| Docker | 29.7.2 instalado |
| Repositorio remoto | GitHub (`hugoqui/scores_lyrics`), privado |
| `apps/node-server/` | solo un README, sin proyecto |
| `services/cloud-api/` | solo un README, sin proyecto |
| Integración continua | no existe (`.github/` ausente) |

## Forma del repositorio al cerrar el módulo

```
scores_lyrics.sln              solución única, abre todo
Directory.Build.props          versión de .NET, nullable, warnings-as-errors
.editorconfig                  estilo, aplicado por el compilador
.github/workflows/ci.yml       compila y prueba en cada push

apps/node-server/
  src/NodeServer/              ASP.NET Core, ejecutable autocontenido
  migrations/                  SQL de SQLite, numerado
  tests/NodeServer.Tests/

services/cloud-api/
  src/CloudApi/                ASP.NET Core
  migrations/                  SQL de PostgreSQL, numerado
  tests/CloudApi.Tests/
```

Dos árboles paralelos y simétricos. Nada compartido entre nodo y nube en este
módulo: la biblioteca común, si hace falta, aparecerá cuando haya algo real que
compartir, no antes.

## Cómo se cumple cada requisito

### R1 — Migraciones versionadas ([ADR 0010](../../docs/adr/0010-migraciones-sql-planas.md))

Archivos **SQL planos**, numerados (`0001_inicial.sql`, `0002_…`), aplicados en
orden por un ejecutor que anota en una tabla `migraciones_aplicadas` lo que ya
corrió. Al arrancar, el proceso aplica lo pendiente; también hay un comando
para hacerlo a mano.

Dos carpetas independientes, una por motor. No se comparte SQL entre SQLite y
PostgreSQL: los dialectos difieren y la nube necesita cosas que SQLite no tiene
(row-level security).

Reglas de la carpeta:

- Una migración aplicada **nunca se edita**. Se corrige con una nueva.
- Solo avanza hacia adelante. No hay `down`: revertir es restaurar el respaldo,
  que en el nodo es copiar un archivo ([ADR 0004](../../docs/adr/0004-sqlite-en-el-nodo.md)).
- Cada migración se verifica por su contenido; si un archivo ya aplicado cambió
  en disco, el arranque falla en vez de seguir.

### R2 — Base de datos nueva desde cero

En el VPS: usuario, base y contraseña nuevos, creados a mano una vez y
documentados en `docs/operacion/`. El esquema lo construyen las migraciones,
nunca un volcado de la base actual.

PostgreSQL escucha solo en `localhost`; nadie llega a él desde internet
(000-seguridad R3). En el nodo no hay nada que provisionar: SQLite crea su
archivo al primer arranque.

La base MySQL actual no aparece en ninguna cadena de conexión de este módulo.

### R3 — Configuración fuera del código

Variables de entorno leídas al arrancar y validadas **de una vez, antes de
atender la primera petición**. Si falta una, el proceso muere con el nombre de
la que falta. No hay valores por defecto de producción en el código.

En el repositorio queda `.env.example` con los nombres y valores obviamente
falsos. El `.env` real está en `.gitignore`.

Qué necesita cada lado, como mínimo, al cerrar este módulo:

- **nube:** cadena de conexión a PostgreSQL, entorno (`Development`/`Production`).
- **nodo:** ruta del archivo SQLite, URL de la nube, entorno.

Lo demás (claves de firma, secretos de licencia) entra con 002 y 008.

### R4 — Armazón de pruebas ([ADR 0011](../../docs/adr/0011-pruebas-con-base-real-efimera.md))

Cada proyecto nace con su gemelo de pruebas. Tres niveles desde el día uno:

1. **Unitarias**: sin base de datos, sin red.
2. **De integración con base real**: PostgreSQL levantado en un contenedor
   efímero por la propia prueba; SQLite sobre un archivo temporal en carpeta
   propia. Cada prueba crea su base, aplica las migraciones y la destruye al
   terminar. Ninguna comparte estado ni depende del orden.
3. **De arranque**: la aplicación levanta con configuración válida y **falla**
   con una inválida. Esta es la prueba que hace verificable el R3.

SQLite se prueba contra un archivo de verdad, no en memoria: el modo en memoria
se comporta distinto y probaría algo que no es lo que corre en la iglesia.

Un solo comando en la raíz corre todo: `dotnet test`.

### R5 — Nada de datos reales

Los datos los fabrica la prueba. Las semillas versionadas, si aparecen, son
ficticias y evidentes (`Iglesia de Prueba`, `musico1@ejemplo.test`).

Ningún volcado de producción entra al repositorio ni a la tubería — y como la
tubería no tiene credenciales de producción, tampoco podría alcanzarlo.

### R6 — Integración continua ([ADR 0012](../../docs/adr/0012-integracion-continua-en-github-actions.md))

Un flujo de trabajo que corre en cada push y en cada pull request:

1. restaura y compila la solución con advertencias como errores,
2. corre todas las pruebas, incluidas las de contenedor,
3. verifica que el formato del código está aplicado.

Termina en verde o rojo, visible en GitHub. Las ramas `main` y `dev` se
protegen: sin tubería verde no entra la fusión.

La tubería no recibe ningún secreto de producción. La base de PostgreSQL que
usa es la del contenedor efímero, con credenciales de juguete.

### R7 — Logs

Registro estructurado con nivel y marca de tiempo. En el nodo, a consola y a
archivo rotado, porque ahí no hay nadie mirando una terminal el domingo; en la
nube, a consola, que es lo que el VPS recoge.

Las cadenas de conexión, contraseñas y tokens se filtran antes de escribirse.
Un fallo no atendido se registra completo; nada se traga en silencio.

## Estrategia de verificación

El módulo está cerrado cuando, **en una máquina limpia**:

1. `dotnet test` pasa en verde sin configuración previa más allá de Docker.
2. Aplicar las migraciones sobre una base vacía y sobre una base a medio migrar
   deja exactamente el mismo esquema. Hay una prueba que lo comprueba.
3. Borrar una variable de entorno requerida hace fallar el arranque, con el
   nombre de la variable en el mensaje. Hay una prueba que lo comprueba.
4. Un push a una rama abre la tubería y la tubería termina en verde.
5. Un push con una prueba rota termina en rojo y bloquea la fusión.

Cada punto de esta lista es una prueba automática, no una revisión a ojo. Un
módulo de andamiaje que se verifica a mano no sirve para nada.

## Decisiones registradas

| Decisión | Elegida | Alternativa descartada | ADR |
|---|---|---|---|
| Cómo se aplican las migraciones | SQL plano con ejecutor mínimo | Migraciones de Entity Framework Core | [0010](../../docs/adr/0010-migraciones-sql-planas.md) |
| Marco de pruebas y bases de prueba | xUnit + base real efímera | Sustituto en memoria o base compartida | [0011](../../docs/adr/0011-pruebas-con-base-real-efimera.md) |
| Plataforma de integración continua | GitHub Actions | Otro servicio externo | [0012](../../docs/adr/0012-integracion-continua-en-github-actions.md) |

Cada ADR lleva su razón y su costo aceptado. Lo que **no** se decide aquí: el
acceso a datos (EF Core, Dapper o SQL directo) es de 002, cuando existan
entidades reales.

## Fuera de este plan

Empaquetar el nodo como servicio de Windows, firmarlo y actualizarlo es de
009-nodo-empaquetado. Aquí el nodo solo tiene que compilar, arrancar y apagarse
limpiamente.
