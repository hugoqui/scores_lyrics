-- 0002_identidad — SQLite (nodo)
--
-- Las mismas tablas que la nube menos `propietario_saas`: esa identidad vive
-- solo arriba. Identificadores UUIDv7 en texto ([ADR 0005]), generados por
-- quien crea la fila.
--
-- Aquí el aislamiento no es una política, es físico: una base por iglesia
-- ([ADR 0015]). Lo que sostiene esa promesa son las dos reglas de abajo —una
-- sola fila en `iglesia`, y todo lo demás colgando de ella—, y la comparación
-- contra SYMPHONY_NODE_IGLESIA_ID al arrancar.
--
-- Usuarios, roles e instrumentos son réplicas de lo que manda la nube
-- ([ADR 0002]); cómo se replican es del módulo 008. Lo que el nodo escribe por
-- su cuenta son dispositivos y sesiones: es él quien autentica el domingo.

-- `fila` existe solo para que la base rechace la segunda iglesia: la clave
-- primaria admite un valor y el CHECK dice cuál. No es una convención que
-- alguien pueda olvidar en el código — un respaldo restaurado en el equipo
-- equivocado no puede colarse como una iglesia más.
CREATE TABLE iglesia (
    fila      INTEGER NOT NULL PRIMARY KEY CHECK (fila = 1),
    id        TEXT    NOT NULL UNIQUE,
    nombre    TEXT    NOT NULL,
    estado    TEXT    NOT NULL CHECK (estado IN ('activa', 'suspendida')),
    creada_en TEXT    NOT NULL
);

-- Cada tabla de dominio cuelga de esa única fila por clave foránea: insertar
-- algo de otra iglesia falla en el motor, no en una validación que alguien
-- puede olvidar escribir.
CREATE TABLE usuario (
    id              TEXT NOT NULL PRIMARY KEY,
    iglesia_id      TEXT NOT NULL REFERENCES iglesia (id),
    correo          TEXT NOT NULL,
    nombre          TEXT NOT NULL,
    hash_contrasena TEXT NOT NULL,
    estado          TEXT NOT NULL CHECK (estado IN ('activo', 'dado_de_baja')),
    creado_en       TEXT NOT NULL
);

-- El correo es único dentro de la iglesia, no global (spec R4).
CREATE UNIQUE INDEX usuario_correo_por_iglesia_idx ON usuario (iglesia_id, correo);

CREATE TABLE usuario_rol (
    usuario_id TEXT NOT NULL REFERENCES usuario (id),
    rol        TEXT NOT NULL CHECK (rol IN ('administrador', 'operador', 'musico')),
    PRIMARY KEY (usuario_id, rol)
);

CREATE TABLE instrumento (
    id        TEXT    NOT NULL PRIMARY KEY,
    codigo    TEXT    NOT NULL UNIQUE,
    afinacion TEXT    NOT NULL CHECK (afinacion IN ('c', 'bb')),
    orden     INTEGER NOT NULL
);

CREATE TABLE usuario_instrumento (
    usuario_id     TEXT NOT NULL REFERENCES usuario (id),
    instrumento_id TEXT NOT NULL REFERENCES instrumento (id),
    PRIMARY KEY (usuario_id, instrumento_id)
);

CREATE TABLE dispositivo (
    id              TEXT NOT NULL PRIMARY KEY,
    iglesia_id      TEXT NOT NULL REFERENCES iglesia (id),
    usuario_id      TEXT NULL REFERENCES usuario (id),
    tipo            TEXT NOT NULL CHECK (tipo IN ('movil', 'tableta', 'pantalla')),
    nombre          TEXT NOT NULL,
    creado_en       TEXT NOT NULL,
    ultimo_visto_en TEXT NULL,
    revocado_en     TEXT NULL
);

CREATE INDEX dispositivo_iglesia_idx ON dispositivo (iglesia_id);
CREATE INDEX dispositivo_usuario_idx ON dispositivo (usuario_id);

CREATE TABLE sesion (
    id             TEXT NOT NULL PRIMARY KEY,
    dispositivo_id TEXT NOT NULL REFERENCES dispositivo (id),
    iglesia_id     TEXT NOT NULL REFERENCES iglesia (id),
    huella_token   TEXT NOT NULL UNIQUE,
    emitida_en     TEXT NOT NULL,
    expira_en      TEXT NOT NULL,
    revocada_en    TEXT NULL
);

CREATE INDEX sesion_iglesia_idx ON sesion (iglesia_id);
CREATE INDEX sesion_dispositivo_idx ON sesion (dispositivo_id);

-- El mismo catálogo que la nube, con los mismos identificadores: es una
-- réplica, no una lista paralela. Se siembra aquí porque el nodo tiene que
-- servir el domingo aunque la sincronización del módulo 008 todavía no exista.
INSERT INTO instrumento (id, codigo, afinacion, orden) VALUES
    ('01999c1e-0000-7000-8000-000000000001', 'piano',      'c',  1),
    ('01999c1e-0000-7000-8000-000000000002', 'violin1',    'c',  2),
    ('01999c1e-0000-7000-8000-000000000003', 'violin2',    'c',  3),
    ('01999c1e-0000-7000-8000-000000000004', 'trompeta',   'bb', 4),
    ('01999c1e-0000-7000-8000-000000000005', 'flauta1',    'c',  5),
    ('01999c1e-0000-7000-8000-000000000006', 'flauta2',    'c',  6),
    ('01999c1e-0000-7000-8000-000000000007', 'clarinete1', 'bb', 7),
    ('01999c1e-0000-7000-8000-000000000008', 'clarinete2', 'bb', 8),
    ('01999c1e-0000-7000-8000-000000000009', 'viola',      'c',  9),
    ('01999c1e-0000-7000-8000-00000000000a', 'cello',      'c', 10);
