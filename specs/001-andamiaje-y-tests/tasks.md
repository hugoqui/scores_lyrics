# 001-andamiaje-y-tests — tareas

Implementa [`plan.md`](plan.md). Cada tarea es atómica: se termina, se
verifica y se confirma en git por separado.

Regla: **ninguna tarea que añade comportamiento se cierra sin su prueba**
(constitución, punto 4). La prueba va en la misma tarea, no en una posterior.

Cada fase indica el **modelo sugerido**. Si el modelo en uso no es el sugerido,
hay que avisar y esperar antes de empezar, no decidirlo por cuenta propia.

## Fase 1 — Esqueleto de la solución

> **Modelo sugerido: Sonnet** — crear proyectos y archivos de configuración; el plan ya dice exactamente qué.

- [x] T1.1 Crear `Symphony.sln` en la raíz.
- [x] T1.2 Crear `Directory.Build.props`: versión de .NET, `Nullable` activo,
      advertencias como errores.
- [x] T1.3 Crear `.editorconfig` con el estilo del proyecto.
- [x] T1.4 Crear el proyecto `apps/node-server/src/Symphony.Node/`
      (ASP.NET Core) y añadirlo a la solución.
- [x] T1.5 Crear el proyecto `services/cloud-api/src/Symphony.Cloud/`
      (ASP.NET Core) y añadirlo a la solución.
- [x] T1.6 Crear `apps/node-server/tests/Symphony.Node.Tests/` (xUnit),
      referenciar el proyecto y dejar una prueba trivial que pase.
- [x] T1.7 Crear `services/cloud-api/tests/Symphony.Cloud.Tests/` igual.
- [x] T1.8 Verificar: `dotnet build` y `dotnet test` pasan desde la raíz.

> Al cerrar la fase 1, `dotnet test` corre en verde y no hay nada más que
> reportar. Es el mínimo sobre el que se apoya todo lo demás.

## Fase 2 — Configuración que falla ruidosamente (spec R3)

> **Modelo sugerido: Sonnet** — patrón conocido, y las pruebas fijan el comportamiento esperado.

- [x] T2.1 Definir la configuración del nodo: ruta del archivo SQLite, URL de
      la nube, entorno. Leída del entorno, sin valores por defecto de
      producción.
- [x] T2.2 Definir la configuración de la nube: cadena de conexión a
      PostgreSQL, entorno.
- [x] T2.3 Validar toda la configuración **al arrancar**, antes de atender la
      primera petición. Si falta una variable, el proceso muere nombrándola.
- [x] T2.4 Prueba: arranca con configuración válida.
- [x] T2.5 Prueba: falla con configuración incompleta, y el nombre de la
      variable que falta aparece en el mensaje.
- [x] T2.6 Añadir `.env.example` con los nombres y valores obviamente falsos.
- [x] T2.7 Confirmar que `.env` está en `.gitignore` y que ningún secreto real
      entró al repositorio.

## Fase 3 — Migraciones (spec R1, [ADR 0010](../../docs/adr/0010-migraciones-sql-planas.md))

> **Modelo sugerido: Opus** — es la pieza donde un error no se ve hasta que corrompe el esquema de una iglesia; la convergencia y la idempotencia hay que razonarlas, no copiarlas.

- [x] T3.1 Escribir el ejecutor de migraciones: lee los `.sql` de una carpeta,
      los ordena por número, aplica los pendientes en una transacción y anota
      cada uno en `migraciones_aplicadas`.
- [x] T3.2 Guardar el hash de cada migración aplicada; si un archivo ya
      aplicado cambió en disco, el arranque falla.
- [x] T3.3 Prueba: base vacía + todas las migraciones = esquema esperado.
- [x] T3.4 Prueba: base a medio migrar + migraciones restantes = **el mismo**
      esquema que T3.3.
- [x] T3.5 Prueba: aplicar dos veces no cambia nada ni falla.
- [x] T3.6 Prueba: alterar en disco una migración ya aplicada hace fallar el
      arranque.
- [x] T3.7 Conectar el ejecutor al arranque del nodo (SQLite) y de la nube
      (PostgreSQL), más un comando explícito para aplicarlas a mano.
- [x] T3.8 Crear `0001_inicial.sql` en cada carpeta: solo la tabla de control
      de migraciones. Sin tablas de dominio — eso es de 002.

## Fase 4 — Pruebas con base real ([ADR 0011](../../docs/adr/0011-pruebas-con-base-real-efimera.md))

> **Modelo sugerido: Opus** — el aislamiento entre pruebas es fácil de romper de formas que no fallan de inmediato.

- [ ] T4.1 Armazón para pruebas de PostgreSQL: levantar un contenedor efímero,
      aplicar migraciones, destruirlo al terminar.
- [ ] T4.2 Armazón para pruebas de SQLite: archivo temporal en carpeta propia,
      borrado al terminar. **No en memoria.**
- [ ] T4.3 Verificar que dos pruebas que usan base no comparten estado ni
      dependen del orden de ejecución.
- [ ] T4.4 Dejar documentado en el README de cada proyecto qué hace falta para
      correr las pruebas (Docker) y qué pasa si no está.

## Fase 5 — Integración continua ([ADR 0012](../../docs/adr/0012-integracion-continua-en-github-actions.md))

> **Modelo sugerido: Sonnet** — escribir el YAML del flujo y verificarlo con un push.

- [x] T5.1 Crear `.github/workflows/ci.yml`: compila con advertencias como
      errores, corre todas las pruebas, verifica el formato.
- [x] T5.2 Verificar que la tubería corre sin ningún secreto de producción.
- [x] T5.3 Verificar en verde con un push real.
- [x] T5.4 Verificar en rojo: romper una prueba a propósito, comprobar que
      falla, revertir.
- [x] T5.5 Proteger `main` y `dev`: sin tubería verde no entra la fusión.
      *(Se hace en la configuración de GitHub, no en el repositorio.)*

## Fase 6 — Logs (spec R7)

> **Modelo sugerido: Sonnet** — configuración con una prueba que verifica el filtrado de secretos.

- [x] T6.1 Registro estructurado en la nube: consola, con nivel y marca de
      tiempo.
- [x] T6.2 Registro estructurado en el nodo: consola **y** archivo rotado.
- [x] T6.3 Filtrar cadenas de conexión, contraseñas y tokens antes de
      escribirlos.
- [x] T6.4 Prueba: una cadena de conexión pasada al registro no aparece en la
      salida.
- [x] T6.5 Un fallo no atendido se registra completo, no se traga en silencio.

## Fase 7 — Base de datos nueva (spec R2)

> **Modelo sugerido: Sonnet** — la ejecuta el propietario en su VPS; el asistente solo documenta los pasos.

- [ ] T7.1 En el VPS: crear usuario, base y contraseña nuevos para PostgreSQL.
- [ ] T7.2 Verificar que PostgreSQL escucha solo en `localhost` y no es
      alcanzable desde internet (000-seguridad R3).
- [ ] T7.3 Documentar el procedimiento en `docs/operacion/` — **sin la
      contraseña**, solo los pasos.
- [ ] T7.4 Aplicar las migraciones contra esa base por primera vez.
- [ ] T7.5 Confirmar que la base MySQL actual no aparece en ninguna cadena de
      conexión del repositorio.

> La fase 7 la ejecuta el propietario en su VPS; es la única que toca una
> máquina real.

## Cierre del módulo

El módulo se cierra cuando, en una máquina limpia:

- [ ] C1 `dotnet test` pasa en verde sin más preparación que tener Docker.
- [ ] C2 Las pruebas de T3.3 y T3.4 demuestran que el esquema converge.
- [ ] C3 La prueba de T2.5 demuestra que falta de configuración = no arranca.
- [ ] C4 Un push abre la tubería y termina en verde; una prueba rota la pone en
      rojo y bloquea la fusión.
- [ ] C5 `docs/arquitectura/` actualizado: el hallazgo "ausencia de red de
      seguridad" en `estado-actual.md` queda resuelto y se dice cómo.
- [ ] C6 `specs/README.md` marca 001 como ✅ y nombra el módulo siguiente.
