# ADR 0005 — Identificadores

**Estado:** aceptada · **Fecha:** 2026-09-14

## Contexto

Se crean filas sin conexión en muchas iglesias a la vez, y después se
sincronizan. Los enteros autoincrementales chocarían entre iglesias.

## Decisión

**UUIDv7 (o ULID) generado por quien crea la fila.**

Excepciones deliberadas:

- **La Biblia conserva claves naturales** `(traducción, libro, capítulo,
  versículo)`. Es lo que hace que una referencia sea portable entre traducciones.
- **Los archivos se identifican por su hash** (`sha256`), no por un UUID. El
  identificador de la entidad y el del contenido son cosas distintas.
- Cada canto lleva además un **código corto legible** por iglesia, para el
  soporte por teléfono: "el canto 214".

## Razones

UUIDv7 es ordenable por tiempo, así que los índices no se fragmentan y la
paginación por identificador funciona. Evita el problema clásico de UUIDv4.

## Costo aceptado

16 bytes por clave en vez de 4. Irrelevante a escala de decenas de miles de
filas.

## Consecuencia importante

**Un hash no es una autorización.** Que dos iglesias compartan el archivo de un
canto no implica que ambas puedan descargarlo: el permiso se deriva de la
pertenencia a la iglesia, nunca de conocer el hash o la URL (constitución,
punto 3).
