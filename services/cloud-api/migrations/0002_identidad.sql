-- 0002_identidad — PostgreSQL (nube)
--
-- Las tablas de identidad del módulo 002. Identificadores UUIDv7 generados por
-- quien crea la fila ([ADR 0005]): la base no tiene valor por defecto, para que
-- el nodo pueda crear filas sin conexión y sincronizarlas después.
--
-- El aislamiento entre iglesias lo impone el motor, no la consulta
-- ([ADR 0015]): row-level security activada y forzada, con la iglesia sacada de
-- una variable de sesión que fija la aplicación al abrir la transacción.

CREATE TABLE iglesia (
    id          UUID        NOT NULL PRIMARY KEY,
    nombre      TEXT        NOT NULL,
    estado      TEXT        NOT NULL CHECK (estado IN ('activa', 'suspendida')),
    creada_en   TIMESTAMPTZ NOT NULL
);

-- El propietario del SaaS no pertenece a ninguna iglesia (spec R4): es una
-- identidad aparte, no un usuario con más permisos. Por eso no lleva
-- iglesia_id y queda fuera del aislamiento.
CREATE TABLE propietario_saas (
    id              UUID        NOT NULL PRIMARY KEY,
    correo          TEXT        NOT NULL UNIQUE,
    hash_contrasena TEXT        NOT NULL,
    creado_en       TIMESTAMPTZ NOT NULL
);

CREATE TABLE usuario (
    id              UUID        NOT NULL PRIMARY KEY,
    iglesia_id      UUID        NOT NULL REFERENCES iglesia (id),
    correo          TEXT        NOT NULL,
    nombre          TEXT        NOT NULL,
    hash_contrasena TEXT        NOT NULL,
    estado          TEXT        NOT NULL CHECK (estado IN ('activo', 'dado_de_baja')),
    creado_en       TIMESTAMPTZ NOT NULL
);

-- El correo es único dentro de la iglesia, no global (spec R4): el mismo correo
-- en dos iglesias son dos personas distintas, sin nada compartido.
CREATE UNIQUE INDEX usuario_correo_por_iglesia_idx ON usuario (iglesia_id, correo);

-- Un usuario puede tener varios roles y ninguno incluye a otro: ser
-- administrador no concede operar el servicio (spec R7).
CREATE TABLE usuario_rol (
    usuario_id UUID NOT NULL REFERENCES usuario (id),
    rol        TEXT NOT NULL CHECK (rol IN ('administrador', 'operador', 'musico')),
    PRIMARY KEY (usuario_id, rol)
);

-- Catálogo compartido por todas las iglesias y de solo lectura para ellas
-- (spec R2, excepción cerrada). El nombre visible no se guarda: sale del
-- archivo de traducciones (constitución, punto 9).
CREATE TABLE instrumento (
    id        UUID    NOT NULL PRIMARY KEY,
    codigo    TEXT    NOT NULL UNIQUE,
    afinacion TEXT    NOT NULL CHECK (afinacion IN ('c', 'bb')),
    orden     INTEGER NOT NULL
);

CREATE TABLE usuario_instrumento (
    usuario_id     UUID NOT NULL REFERENCES usuario (id),
    instrumento_id UUID NOT NULL REFERENCES instrumento (id),
    PRIMARY KEY (usuario_id, instrumento_id)
);

-- usuario_id es nulo cuando el dispositivo es una pantalla de proyección, que
-- pertenece a la iglesia y no a una persona.
CREATE TABLE dispositivo (
    id              UUID        NOT NULL PRIMARY KEY,
    iglesia_id      UUID        NOT NULL REFERENCES iglesia (id),
    usuario_id      UUID        NULL REFERENCES usuario (id),
    tipo            TEXT        NOT NULL CHECK (tipo IN ('movil', 'tableta', 'pantalla')),
    nombre          TEXT        NOT NULL,
    creado_en       TIMESTAMPTZ NOT NULL,
    ultimo_visto_en TIMESTAMPTZ NULL,
    revocado_en     TIMESTAMPTZ NULL
);

CREATE INDEX dispositivo_iglesia_idx ON dispositivo (iglesia_id);
CREATE INDEX dispositivo_usuario_idx ON dispositivo (usuario_id);

-- De la sesión se guarda solo la huella del token de renovación, nunca el
-- token ([ADR 0016]).
CREATE TABLE sesion (
    id             UUID        NOT NULL PRIMARY KEY,
    dispositivo_id UUID        NOT NULL REFERENCES dispositivo (id),
    iglesia_id     UUID        NOT NULL REFERENCES iglesia (id),
    huella_token   TEXT        NOT NULL UNIQUE,
    emitida_en     TIMESTAMPTZ NOT NULL,
    expira_en      TIMESTAMPTZ NOT NULL,
    revocada_en    TIMESTAMPTZ NULL
);

CREATE INDEX sesion_iglesia_idx ON sesion (iglesia_id);
CREATE INDEX sesion_dispositivo_idx ON sesion (dispositivo_id);

-- ---------------------------------------------------------------------------
-- Roles de base de datos
-- ---------------------------------------------------------------------------
-- Ninguno lleva contraseña aquí: las contraseñas no entran al repositorio
-- (constitución, punto 7). Se fijan con ALTER ROLE ... PASSWORD en el servidor,
-- documentado en docs/operacion/roles-de-base-de-datos.md.
--
-- Los roles son del clúster, no de la base, así que se crean solo si faltan:
-- una segunda base en el mismo servidor no puede hacer fallar esta migración.

DO $$
BEGIN
    -- El rol de la aplicación: NOBYPASSRLS y no dueño de las tablas. Sin las
    -- dos cosas la política de más abajo no protege nada ([ADR 0015]).
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'symphony_app') THEN
        CREATE ROLE symphony_app LOGIN NOBYPASSRLS;
    END IF;

    -- El propietario del SaaS ve todas las iglesias. Es un rol aparte, usado
    -- solo en los caminos de administración marcados, nunca por la aplicación.
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'symphony_propietario') THEN
        CREATE ROLE symphony_propietario LOGIN BYPASSRLS;
    END IF;
END
$$;

-- Aunque alguien le conceda otra cosa después, estos dos atributos son los que
-- sostienen el aislamiento; se reafirman en cada aplicación de la migración.
ALTER ROLE symphony_app NOBYPASSRLS;
ALTER ROLE symphony_propietario BYPASSRLS;

GRANT USAGE ON SCHEMA public TO symphony_app, symphony_propietario;

-- La aplicación solo alcanza lo que necesita. `propietario_saas` queda fuera a
-- propósito: esa identidad no se administra desde el camino de las iglesias.
GRANT SELECT                         ON iglesia             TO symphony_app;
GRANT SELECT, INSERT, UPDATE         ON usuario             TO symphony_app;
GRANT SELECT, INSERT, DELETE         ON usuario_rol         TO symphony_app;
GRANT SELECT                         ON instrumento         TO symphony_app;
GRANT SELECT, INSERT, DELETE         ON usuario_instrumento TO symphony_app;
GRANT SELECT, INSERT, UPDATE         ON dispositivo         TO symphony_app;
GRANT SELECT, INSERT, UPDATE, DELETE ON sesion              TO symphony_app;

GRANT SELECT, INSERT, UPDATE, DELETE ON
    iglesia, propietario_saas, usuario, usuario_rol,
    instrumento, usuario_instrumento, dispositivo, sesion
    TO symphony_propietario;

-- ---------------------------------------------------------------------------
-- Aislamiento: row-level security activada y forzada
-- ---------------------------------------------------------------------------
-- FORCE no es opcional: sin él, el dueño de las tablas —que es quien corre las
-- migraciones— se salta la política ([ADR 0015]).
--
-- La iglesia sale de la variable de sesión `app.iglesia_id`, que fija la
-- aplicación al abrir la transacción con el valor del token, nunca de un
-- parámetro de la petición. Si nadie la fijó, `current_setting` devuelve nulo y
-- la comparación no es cierta para ninguna fila: olvidar el filtro da cero
-- filas, no filas de otra congregación.

ALTER TABLE iglesia     ENABLE ROW LEVEL SECURITY;
ALTER TABLE iglesia     FORCE  ROW LEVEL SECURITY;
ALTER TABLE usuario     ENABLE ROW LEVEL SECURITY;
ALTER TABLE usuario     FORCE  ROW LEVEL SECURITY;
ALTER TABLE dispositivo ENABLE ROW LEVEL SECURITY;
ALTER TABLE dispositivo FORCE  ROW LEVEL SECURITY;
ALTER TABLE sesion      ENABLE ROW LEVEL SECURITY;
ALTER TABLE sesion      FORCE  ROW LEVEL SECURITY;

CREATE POLICY iglesia_de_la_sesion ON iglesia
    USING      (id = NULLIF(current_setting('app.iglesia_id', TRUE), '')::UUID)
    WITH CHECK (id = NULLIF(current_setting('app.iglesia_id', TRUE), '')::UUID);

CREATE POLICY usuario_de_la_sesion ON usuario
    USING      (iglesia_id = NULLIF(current_setting('app.iglesia_id', TRUE), '')::UUID)
    WITH CHECK (iglesia_id = NULLIF(current_setting('app.iglesia_id', TRUE), '')::UUID);

CREATE POLICY dispositivo_de_la_sesion ON dispositivo
    USING      (iglesia_id = NULLIF(current_setting('app.iglesia_id', TRUE), '')::UUID)
    WITH CHECK (iglesia_id = NULLIF(current_setting('app.iglesia_id', TRUE), '')::UUID);

CREATE POLICY sesion_de_la_sesion ON sesion
    USING      (iglesia_id = NULLIF(current_setting('app.iglesia_id', TRUE), '')::UUID)
    WITH CHECK (iglesia_id = NULLIF(current_setting('app.iglesia_id', TRUE), '')::UUID);

-- `usuario_rol` y `usuario_instrumento` no llevan iglesia_id: su pertenencia es
-- la del usuario. Sin política propia, un `SELECT * FROM usuario_rol` no visita
-- `usuario` y devolvería los roles de todas las iglesias. La política pregunta
-- por el usuario contra una tabla que ya está filtrada, así que una fila de
-- otra congregación no existe para esta sesión.

ALTER TABLE usuario_rol         ENABLE ROW LEVEL SECURITY;
ALTER TABLE usuario_rol         FORCE  ROW LEVEL SECURITY;
ALTER TABLE usuario_instrumento ENABLE ROW LEVEL SECURITY;
ALTER TABLE usuario_instrumento FORCE  ROW LEVEL SECURITY;

CREATE POLICY usuario_rol_de_la_sesion ON usuario_rol
    USING      (EXISTS (SELECT 1 FROM usuario u WHERE u.id = usuario_rol.usuario_id))
    WITH CHECK (EXISTS (SELECT 1 FROM usuario u WHERE u.id = usuario_rol.usuario_id));

CREATE POLICY usuario_instrumento_de_la_sesion ON usuario_instrumento
    USING      (EXISTS (SELECT 1 FROM usuario u WHERE u.id = usuario_instrumento.usuario_id))
    WITH CHECK (EXISTS (SELECT 1 FROM usuario u WHERE u.id = usuario_instrumento.usuario_id));

-- `instrumento` y `propietario_saas` quedan sin política a propósito: son la
-- excepción cerrada de spec R2, catálogo compartido y identidad global.

-- ---------------------------------------------------------------------------
-- Catálogo de instrumentos
-- ---------------------------------------------------------------------------
-- Los diez de hoy (apps/mobile/lib/core/services/instruments_service.dart) con
-- su afinación: bb para trompeta y clarinetes, c para el resto. El nombre
-- visible no se guarda: sale del archivo de traducciones (constitución, punto
-- 9). Los identificadores están escritos porque una migración tiene que dar el
-- mismo resultado en las dos iglesias y en las pruebas.

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
