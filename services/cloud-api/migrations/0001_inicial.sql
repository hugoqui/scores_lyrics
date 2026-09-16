-- 0001_inicial — PostgreSQL (nube)
--
-- Solo la tabla de control de migraciones. Las tablas de dominio y las
-- políticas de row-level security entran en el módulo 002, no aquí.
--
-- Esta tabla la crea también el ejecutor antes de poder leerla: es un huevo y
-- la gallina inevitable. Se declara igual aquí para que el esquema real esté
-- escrito en git y no solo en el código, y por eso es IF NOT EXISTS.

CREATE TABLE IF NOT EXISTS migraciones_aplicadas (
    numero      INTEGER      NOT NULL PRIMARY KEY,
    nombre      TEXT         NOT NULL,
    hash        TEXT         NOT NULL,
    aplicada_en TIMESTAMPTZ  NOT NULL
);
