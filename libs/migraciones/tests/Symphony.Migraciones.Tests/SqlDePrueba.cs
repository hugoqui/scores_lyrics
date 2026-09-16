namespace Symphony.Migraciones.Tests;

/// <summary>
/// Migraciones ficticias y evidentes (spec R5). No salen de ninguna base real.
/// </summary>
public static class SqlDePrueba
{
    public const string Inicial = """
        CREATE TABLE IF NOT EXISTS migraciones_aplicadas (
            numero      INTEGER  NOT NULL PRIMARY KEY,
            nombre      TEXT     NOT NULL,
            hash        TEXT     NOT NULL,
            aplicada_en TEXT     NOT NULL
        );
        """;

    public const string Cantos = """
        CREATE TABLE cantos (
            id     INTEGER NOT NULL PRIMARY KEY,
            titulo TEXT    NOT NULL
        );
        """;

    public const string Musicos = """
        CREATE TABLE musicos (
            id     INTEGER NOT NULL PRIMARY KEY,
            correo TEXT    NOT NULL
        );
        CREATE INDEX ix_musicos_correo ON musicos (correo);
        """;

    /// <summary>Deja las tres migraciones de ejemplo en la carpeta.</summary>
    public static void EscribirTodas(CarpetaDePrueba carpeta)
    {
        carpeta.EscribirMigracion("0001_inicial.sql", Inicial);
        carpeta.EscribirMigracion("0002_cantos.sql", Cantos);
        carpeta.EscribirMigracion("0003_musicos.sql", Musicos);
    }
}
