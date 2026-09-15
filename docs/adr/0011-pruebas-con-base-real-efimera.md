# ADR 0011 — Pruebas contra base de datos real y efímera

**Estado:** aceptada · **Fecha:** 2026-09-15

## Contexto

Hoy no hay una sola prueba en ningún componente
(`docs/arquitectura/estado-actual.md`). La constitución (punto 4) prohíbe
cerrar un módulo sin pruebas, y el módulo
[001-andamiaje-y-tests](../../specs/001-andamiaje-y-tests/spec.md) (R4) exige
que cada proyecto nazca con el suyo.

La pregunta era contra qué prueba el código que toca la base: un sustituto en
memoria, una base de pruebas compartida levantada aparte, o una base real
creada y destruida por cada prueba.

## Decisión

**xUnit** como marco, y las pruebas que tocan datos corren contra el motor real:

- **PostgreSQL** en un contenedor efímero que la propia prueba levanta y tira.
- **SQLite** sobre un archivo temporal en carpeta propia, no en memoria.

Cada prueba crea su base, le aplica las migraciones y la destruye al terminar.
Ninguna comparte estado con otra ni depende del orden de ejecución.

Un solo comando en la raíz corre todo: `dotnet test`.

## Razones

- **Un sustituto en memoria prueba otra cosa.** El modo en memoria de SQLite se
  comporta distinto del archivo que corre en la iglesia, y el proveedor en
  memoria de EF Core no es SQL. Pasar esas pruebas no dice nada sobre el
  domingo.
- **Lo que hay que probar solo existe en el motor real.** El *row-level
  security* que aísla iglesias (ADR 0004) y las migraciones en SQL plano
  (ADR 0010) no se pueden verificar contra un sustituto.
- **Una base compartida acumula estado.** Las pruebas empiezan a depender del
  orden, y la que falla sola no falla en grupo. Crear y destruir por prueba
  elimina esa clase entera de problemas.
- **El entorno ya lo permite.** Docker 29.7.2 está instalado en la máquina del
  propietario, verificado, y GitHub Actions lo trae de fábrica.

## Costo aceptado

Las pruebas de integración son más lentas que las unitarias y **exigen Docker
corriendo**: sin Docker, esa capa no se puede ejecutar en local. Las unitarias
sí corren siempre.

Se acepta porque la alternativa es una suite verde que no dice nada sobre lo
que pasa en producción.
