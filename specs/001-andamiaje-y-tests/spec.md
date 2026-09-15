# 001-andamiaje-y-tests — spec

**Estado:** 📝 especificado · **Depende de:** nada

## Alcance

Construye el piso sobre el que se levantan todos los módulos siguientes:
esquema de base de datos versionado, base de datos nueva creada desde cero,
configuración por entorno, armazón de pruebas, integración continua y logs
legibles.

No implementa ninguna funcionalidad del producto: ni iglesias, ni cantos, ni
proyección. Cuando este módulo cierre, el repositorio sabrá **crear su base de
datos, correr sus pruebas y decir que todo pasó** — nada más.

Aquí se materializan los requisitos R1 (secretos fuera del repo) y R2 (base de
datos nueva) de [000-seguridad](../000-seguridad/spec.md), y se prepara el
terreno para que R5 (SQL parametrizado) sea verificable por pruebas.

`apps/node-server/` y `services/cloud-api/` hoy contienen solo un README: este
módulo es el que los convierte en proyectos reales.

## Qué (requisitos)

### R1 — El esquema de base de datos solo cambia por migraciones versionadas
- Toda modificación de esquema vive en un archivo de migración, versionado en
  git, con orden determinista. Nunca se altera una base a mano.
- Las migraciones se aplican solas al arrancar, o por un comando explícito; de
  las dos formas, el resultado es el mismo.
- La base registra qué migraciones tiene aplicadas. En cualquier instalación se
  puede responder **en qué versión de esquema está** sin adivinar.
- Aplicar las migraciones sobre una base vacía produce exactamente el mismo
  esquema que sobre una base ya migrada a medias.
- Aplica a los dos motores: SQLite en el nodo y PostgreSQL en la nube
  ([ADR 0004](../../docs/adr/0004-sqlite-en-el-nodo.md)). Son dos juegos de
  migraciones distintos, no uno compartido.

> Hoy nadie sabe qué esquema tiene la base de cada iglesia, porque cada
> instalación se hizo a mano (`estado-actual.md`). Este requisito es el que
> impide repetirlo.

### R2 — La base de datos nueva se crea desde cero, por migraciones
- La base de datos nueva ([ADR 0008](../../docs/adr/0008-no-tocar-bd-existente.md))
  se provisiona aquí, vacía, con credenciales nuevas, y se construye
  íntegramente aplicando las migraciones. No se restaura un volcado de la base
  actual.
- La base actual no se toca en ningún paso, ni siquiera de lectura, mientras
  este módulo esté abierto. Si más adelante hace falta migrar datos, será un
  trabajo explícito de otro módulo, y solo de lectura.

### R3 — La configuración vive fuera del código y falla ruidosamente
- Credenciales, cadenas de conexión y claves se leen del entorno, no del
  repositorio (000-seguridad R1, constitución punto 7).
- Si falta una variable requerida, el proceso **no arranca** y dice cuál falta.
  Nunca cae a un valor por defecto de producción.
- El repositorio incluye un ejemplo de configuración con los nombres de las
  variables y valores falsos, para que se sepa qué hace falta sin filtrar nada.
- Un desarrollador nuevo levanta el entorno completo siguiendo el README, sin
  pedirle nada a nadie salvo los secretos.

### R4 — Cada proyecto nace con su proyecto de pruebas
- `apps/node-server` y `services/cloud-api` se crean junto con su proyecto de
  pruebas. No existe el paso intermedio de "ya le pondremos pruebas".
- Desde el primer día hay al menos una prueba real que se ejecuta y pasa: que
  la aplicación arranca con una configuración válida y que falla con una
  inválida.
- Hay forma de correr una prueba contra una base de datos real, creada y
  destruida por la propia prueba. Las pruebas no comparten base entre sí ni
  dependen del orden en que corren.
- Un comando único corre todas las pruebas del repositorio.

### R5 — Ninguna prueba usa datos reales de una iglesia
- Las pruebas se alimentan de datos fabricados en la propia prueba o de
  semillas versionadas y ficticias.
- Ningún volcado de producción, ni siquiera anonimizado, entra al repositorio
  ni a la tubería de integración continua (constitución, punto 3).

### R6 — La integración continua corre sola y puede decir que no
- En cada push y en cada pull request se compila todo y se corren todas las
  pruebas, automáticamente.
- El resultado es visible: se sabe si el commit está sano sin ejecutarlo a
  mano.
- Una prueba que falla bloquea la fusión hacia `dev` y `main`. Una tubería roja
  no se ignora; se arregla o se revierte.
- La tubería no necesita secretos de producción para correr.

### R7 — Los procesos dejan rastro legible
- El nodo y la nube escriben logs estructurados, con nivel y marca de tiempo,
  no `console.log` suelto.
- Un error no se traga en silencio: si una operación falla, queda registrada
  con lo necesario para entenderla.
- Los logs nunca contienen contraseñas, tokens ni cadenas de conexión.
- Sirve para lo que pase un domingo: poder mirar después qué ocurrió en el
  nodo sin tener que reproducirlo (constitución, punto 1).

## Por qué

Hoy no hay pruebas en ningún componente, ni integración continua, ni
migraciones versionadas, ni logs estructurados (`estado-actual.md`). La
consecuencia práctica no es teórica: nadie sabe qué esquema tiene la base de
cada iglesia, no hay forma de revertir un cambio, y los bugs que tumban el
proceso —el `throw` dentro de un callback, el índice sin validar, la promesa
que se resuelve después de rechazarse— llevan meses ahí porque nada los
detecta.

La constitución exige que ningún módulo se cierre sin pruebas (punto 4). Ese
requisito es papel mojado si no existe dónde escribirlas ni quién las corra.
001 construye ese dónde.

Va primero junto con 000 porque todo lo demás toca datos de iglesias reales que
se usan cada domingo. Sin migraciones no hay marcha atrás, y sin pruebas no hay
manera de saber que un cambio rompió algo antes de que lo descubra el músico en
el culto.

Este módulo no produce nada visible, y por eso será el primer candidato a
saltarse bajo presión. Saltárselo significa construir a ciegas.

## Fuera de alcance

- Cualquier entidad del dominio —iglesia, usuario, canto, lista— aunque tenga
  que existir una tabla vacía para probar la maquinaria → 002 en adelante.
- Autenticación y roles → 002-identidad-de-iglesia.
- Empaquetado, instalador, actualizaciones y respaldo del nodo →
  009-nodo-empaquetado. Aquí solo se compila y se prueba.
- Migrar datos de la base actual a la nueva. Esta spec provisiona la base
  vacía; mover datos, si hace falta, es trabajo aparte y solo de lectura.
- Pruebas de la app Flutter: se conserva
  ([ADR 0006](../../docs/adr/0006-conservar-la-app-flutter.md)) y su armazón de
  pruebas entra con la reescritura de su capa de datos → 007-app-movil.
- Pruebas del panel Vue: no se escriben. El panel se retira
  ([ADR 0013](../../docs/adr/0013-app-de-escritorio-en-vez-de-panel-web.md)); el
  armazón de la app de escritorio que lo reemplaza entra con su propio módulo.

## Abierto / bloqueante

- ~~Dónde vive la base de datos nueva de la nube.~~ **Resuelto:** PostgreSQL
  instalado por el propietario en su propio VPS Linux, escuchando solo en local
  ([ADR 0004](../../docs/adr/0004-sqlite-en-el-nodo.md)). En las iglesias no se
  instala ningún servidor de base de datos.
- Elegir herramienta de migraciones, marco de pruebas y plataforma de
  integración continua es decisión de arquitectura y va en `plan.md` con su ADR
  (constitución, punto 6).
