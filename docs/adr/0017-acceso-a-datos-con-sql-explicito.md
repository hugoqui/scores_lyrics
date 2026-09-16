# ADR 0017 — Acceso a datos con SQL explícito, no con un ORM

**Estado:** aceptada · **Fecha:** 2026-09-15

## Contexto

[ADR 0010](0010-migraciones-sql-planas.md) dejó esta decisión abierta a
propósito: "elegir entre EF Core, Dapper o SQL directo es asunto de 002, cuando
existan entidades reales". Ya existen: el módulo
[002-identidad-de-iglesia](../../specs/002-identidad-de-iglesia/spec.md) escribe
el primer esquema de dominio.

Hoy los proyectos usan los proveedores en crudo —`Npgsql` en la nube,
`Microsoft.Data.Sqlite` en el nodo— sin ninguna capa encima. La alternativa
natural en C# es Entity Framework Core.

## Decisión

**SQL escrito a mano, ejecutado por un mapeador delgado** (Dapper) sobre las
conexiones que ya existen. Sin ORM, sin generación de consultas, sin
seguimiento de cambios.

Reglas:

- Toda consulta usa parámetros. Ninguna se construye por concatenación
  (000-seguridad R5).
- Toda unidad de trabajo contra la nube abre transacción y fija su iglesia antes
  de consultar ([ADR 0015](0015-aislamiento-por-rls-y-nodo-atado-a-su-iglesia.md)).
  Eso vive en un solo sitio, no repartido por el código.
- El SQL de dominio vive junto al código que lo usa, no dentro de cadenas
  dispersas.

## Razones

- **Coherencia con ADR 0010.** Las migraciones ya son SQL plano, con el
  argumento de que lo que se lee es lo que corre. Poner un ORM encima recrea la
  traducción entre un modelo de clases y el esquema real, que es justo lo que se
  descartó.
- **La row-level security es el centro del diseño, y a EF Core le estorba.** La
  política necesita que cada transacción fije su variable de sesión sobre la
  misma conexión. Con un ORM que administra conexiones y las reutiliza del pozo
  por su cuenta, eso pasa de ser explícito a ser una suposición delicada.
  Aquí el aislamiento entre iglesias no puede depender de una suposición
  delicada (constitución, punto 3).
- **Dos motores con dialectos distintos** (ADR 0004). Un ORM que sirva a SQLite
  y a PostgreSQL a la vez tiende al mínimo común denominador, y la nube necesita
  cosas que SQLite no tiene.
- **La superficie es pequeña.** Iglesias, usuarios, roles, instrumentos,
  dispositivos y sesiones: decenas de consultas, no miles. El ahorro de un ORM
  se cobra en escala que este sistema no tiene.
- **El propietario es el único que mantiene esto.** SQL se lee sin conocer las
  convenciones de un ORM; una consulta generada, no.

## Costo aceptado

- **Se escribe más código a mano**: cada consulta y su mapeo. Sin migraciones
  generadas a partir de las clases (ya asumido en ADR 0010) y sin cargas
  relacionadas automáticas.
- **Nada impide escribir una consulta sin filtro de iglesia.** Por eso el
  aislamiento se impone abajo (ADR 0015) y se verifica con pruebas que intentan
  cruzarse (spec R10): el SQL a mano es seguro aquí *porque* el motor no
  depende de él.
- **Una dependencia más** (Dapper). Se acepta frente a mapear a mano cada fila:
  es una biblioteca pequeña, estable y sin opinión sobre el esquema, que no ata
  el diseño a nada.
