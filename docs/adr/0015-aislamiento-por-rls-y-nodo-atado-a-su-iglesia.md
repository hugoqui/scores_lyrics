# ADR 0015 — El aislamiento entre iglesias lo impone el motor, no la consulta

**Estado:** aceptada · **Fecha:** 2026-09-15

## Contexto

La constitución (punto 3) exige que ninguna iglesia vea datos de otra y que eso
se **verifique, no se suponga**. El módulo
[002-identidad-de-iglesia](../../specs/002-identidad-de-iglesia/spec.md) (R2,
R3) es donde esa regla se convierte en esquema.

Hoy el riesgo está acotado porque cada iglesia es una instalación manual
separada (`docs/arquitectura/estado-actual.md`). Al juntarlas en una sola base
en la nube, un `WHERE` olvidado deja de ser un bug local y pasa a ser fuga
entre congregaciones.

[ADR 0004](0004-sqlite-en-el-nodo.md) ya eligió PostgreSQL en la nube
**precisamente por su row-level security**, y SQLite en el nodo, que no la
tiene. Faltaba decidir cómo se impone el aislamiento en cada lado.

La alternativa era confiar en la disciplina: que toda consulta lleve su filtro,
revisado en code review.

## Decisión

**Dos mecanismos distintos, porque los dos lados son distintos.**

### En la nube: row-level security, activada y forzada

- Toda tabla de dominio lleva `iglesia_id uuid not null`.
- Cada una tiene `ENABLE ROW LEVEL SECURITY` y **`FORCE ROW LEVEL SECURITY`**,
  para que la política aplique también al dueño de la tabla.
- La política compara `iglesia_id` con una variable de sesión que fija la
  aplicación al abrir la transacción, con el valor sacado **del token**
  (ADR 0016), nunca de un parámetro de la petición.
- La aplicación se conecta con un rol sin privilegios especiales y
  **`NOBYPASSRLS`**. No es dueña de las tablas ni puede saltarse la política.
- El propietario del SaaS usa un **rol de base de datos distinto**, con permiso
  para ver todas las iglesias, y solo en los caminos de administración
  explícitamente marcados.

Consecuencia buscada: **olvidar el filtro devuelve cero filas, no filas de otra
congregación.**

### En el nodo: identidad fija, verificada al arrancar

SQLite no tiene RLS, y no hace falta: un nodo sirve a una sola iglesia
([ADR 0002](0002-arquitectura-hibrida-nube-nodo-local.md)), así que el
aislamiento es físico —una base por iglesia— y se refuerza con tres cosas:

- Una tabla `iglesia` con **exactamente una fila**, garantizado por el esquema.
- La identidad de esa iglesia también en la configuración del proceso. Al
  arrancar se comparan; **si no coinciden, el nodo no arranca**. Un archivo de
  base de datos copiado de otra iglesia se detecta al instante, en vez de
  servir datos ajenos en silencio.
- Las tablas de dominio llevan igualmente `iglesia_id`, con clave foránea a esa
  única fila: insertar algo de otra iglesia **falla en el motor**, no en una
  validación que alguien puede olvidar escribir.

### En los dos lados

- Un identificador válido con la iglesia equivocada responde **como si no
  existiera**. No se distingue "no existe" de "no es tuyo": confirmar la
  existencia de datos ajenos ya es filtrar información.
- Cambiar la iglesia de una fila ya creada no es una operación del sistema.

## Razones

- **La disciplina no es un mecanismo.** "Acordarse del `WHERE` siempre" falla
  una vez cada varios miles de consultas, y esa vez es una fuga entre
  congregaciones. La política en el motor falla cerrada.
- **Es la razón por la que ya se eligió PostgreSQL** (ADR 0004). No usarla sería
  pagar el costo de aprender un motor nuevo sin cobrar el beneficio.
- **`FORCE` importa.** Sin él, el dueño de la tabla —que es quien corre las
  migraciones— se salta la política, y es fácil que la aplicación termine
  conectándose con ese mismo rol sin que nadie lo note.
- **Es verificable, que es lo que pide la constitución.** Se puede escribir una
  prueba que lanza una consulta sin filtro y exige cero filas (spec R10). Con
  disciplina no hay nada que probar salvo la buena intención.
- **En el nodo, la verificación al arrancar cubre el error real que va a pasar:**
  restaurar el respaldo equivocado. Con dos iglesias y un solo responsable que
  hace las dos instalaciones a mano, copiar un archivo al equipo que no era es
  el fallo más probable de todos.

## Costo aceptado

- **La conexión deja de ser apátrida.** Cada unidad de trabajo tiene que fijar
  su iglesia dentro de una transacción antes de consultar, y una conexión
  reutilizada del pozo sin fijarla sería un error. Se contiene poniendo eso en
  un solo lugar y probándolo, no repartido por el código.
- **Un segundo rol de base de datos que administrar**, y el riesgo concentrado
  de que un camino de administración quede usándolo por descuido. A cambio, ese
  riesgo es auditable: son unos pocos caminos marcados, no todas las consultas.
- **Depurar es menos obvio**: una consulta correcta puede devolver cero filas
  porque la sesión no fijó su iglesia. Se acepta: el modo de fallo es no ver
  datos, nunca ver los de otro.
- **Dos mecanismos distintos que mantener**, uno por lado. Es el mismo costo ya
  aceptado en ADR 0004 y ADR 0010: dos motores, dos juegos de migraciones.
