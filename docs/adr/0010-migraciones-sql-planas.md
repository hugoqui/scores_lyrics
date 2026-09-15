# ADR 0010 — Migraciones en SQL plano, no en el ORM

**Estado:** aceptada · **Fecha:** 2026-09-15

## Contexto

El sistema nuevo tiene dos bases con dialectos distintos: SQLite embebido en el
nodo y PostgreSQL en la nube ([ADR 0004](0004-sqlite-en-el-nodo.md)). Hoy
ninguna iglesia sabe en qué versión de esquema está, porque cada instalación se
hizo a mano (`docs/arquitectura/estado-actual.md`).

El módulo [001-andamiaje-y-tests](../../specs/001-andamiaje-y-tests/spec.md)
exige (R1) que el esquema solo cambie por migraciones versionadas. Faltaba
decidir con qué.

La alternativa natural en C# es dejar que Entity Framework Core genere las
migraciones a partir del modelo de clases.

## Decisión

Las migraciones son **archivos `.sql` escritos a mano**, numerados y
versionados en git, aplicados en orden por un ejecutor mínimo que registra en
una tabla qué se aplicó ya.

Dos carpetas independientes, una por motor. No se comparte SQL entre SQLite y
PostgreSQL.

Reglas:

- Una migración aplicada nunca se edita; se corrige con una nueva.
- Solo hacia adelante. No hay `down`: revertir es restaurar el respaldo, que en
  el nodo es copiar un archivo.
- El ejecutor verifica el contenido de lo ya aplicado; si un archivo cambió en
  disco, el arranque falla en vez de seguir.

## Razones

- **El aislamiento entre iglesias se impone con SQL que el ORM no modela.** La
  razón de elegir PostgreSQL es el *row-level security* (ADR 0004), y eso se
  escribe en SQL explícito. Un generador de migraciones lo dejaría fuera o lo
  metería como fragmento suelto, que es lo peor de los dos mundos.
- **Lo que se lee es lo que corre.** No hay traducción entre un modelo de
  clases y el esquema real: el archivo que está en git es el que se ejecutó en
  la iglesia.
- **Dos motores, dos dialectos.** Obligar a un generador a servir a SQLite y a
  PostgreSQL a la vez produce el mínimo común denominador de ambos.
- **No obliga a decidir hoy el acceso a datos.** Elegir entre EF Core, Dapper o
  SQL directo es asunto de 002, cuando existan entidades reales. Atar las
  migraciones al ORM sería decidirlo por adelantado y a ciegas.

## Costo aceptado

El SQL se escribe a mano: no hay autogeneración a partir de las clases, y un
cambio de esquema exige acordarse de escribir su migración. A cambio, nada
ocurre en la base que no esté escrito explícitamente en un archivo.

Tampoco hay reversión automática de una migración. Se acepta porque el respaldo
del nodo es copiar un archivo, y porque una reversión automática sobre datos
reales de una iglesia es más peligrosa que restaurar.
