# ADR 0004 — SQLite en el nodo, motor completo en la nube

**Estado:** aceptada · **Fecha:** 2026-09-14

## Contexto

El nodo local corre en hardware heterogéneo: en una iglesia hay un servidor
dedicado, en otra es la misma PC que proyecta. En ninguna hay personal técnico.

La nube es lo contrario: un VPS Linux administrado por el propietario, que
guarda identidad, licencias y catálogo maestro de **todas** las iglesias en una
sola base. Ahí el riesgo no es el soporte técnico, es que una consulta mal
filtrada deje ver a una congregación los datos de otra.

El sistema actual usa MySQL en los dos lados, así que la alternativa real era
seguir con MySQL en la nube.

## Decisión

- **Nodo local: SQLite embebido** en el proceso.
- **Nube: motor completo** (PostgreSQL).

## Razones

- Cero instalación, cero servicio que arrancar, cero contraseña, cero puerto
  abierto. Cada instalación de un servidor de base de datos en una PC de iglesia
  es una llamada de soporte futura garantizada.
- **Respaldar es copiar un archivo, y restaurar es copiarlo de vuelta.** Eso se
  le puede explicar a cualquiera por teléfono.
- La carga real es un operador y unas veinte personas con el teléfono,
  dominada por lecturas. SQLite sobra.
- La búsqueda bíblica con índice de texto completo es mejor que el `LIKE '%…%'`
  actual.

**Por qué PostgreSQL y no MySQL en la nube:**

- **El aislamiento entre iglesias se puede imponer en el motor.** Con
  *row-level security*, la regla "esta sesión solo ve filas de su iglesia" vive
  en la base, no en cada consulta. La constitución (punto 3) exige que el
  aislamiento se verifique, no se suponga; con MySQL dependería de que jamás se
  olvide un `WHERE`. En multi-iglesia, ese olvido es fuga entre congregaciones.
- **Es estricto por defecto.** Rechaza el dato que no cabe en vez de truncarlo
  en silencio.
- **JSON y texto completo** de primera clase, que es lo que pide el catálogo de
  partituras.
- **Licencia permisiva** (tipo BSD): instalación propia en el VPS, uso
  comercial, sin obligaciones ni doble licencia que revisar más adelante.

## Costo aceptado

- Sin acceso remoto a la base del nodo por red —irrelevante, porque todo pasa
  por el proceso del servidor— y herramientas gráficas menos familiares.
- **Dos motores distintos que mantener.** Las migraciones del nodo y las de la
  nube son dos juegos separados, no uno compartido (001-andamiaje-y-tests, R1).
- **El propietario conoce MySQL, no PostgreSQL.** Hay una curva de aprendizaje
  en operación: respaldos, usuarios, herramientas. Se acepta a cambio del
  aislamiento impuesto por el motor.

## Notas de implementación

- La Biblia va en un archivo aparte, en solo lectura: así se actualiza sin tocar
  los datos de la iglesia y el respaldo no la arrastra.
- **PostgreSQL no queda expuesto a internet**: escucha solo en local y lo único
  alcanzable desde fuera es la API de nube (000-seguridad, R3).
- **La base no puede quedar dentro de una carpeta sincronizada** (OneDrive,
  Drive): es corrupción garantizada. Se instala en almacenamiento local y se
  verifica la ruta al arrancar.
