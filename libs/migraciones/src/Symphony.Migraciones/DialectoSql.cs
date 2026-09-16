namespace Symphony.Migraciones;

/// <summary>
/// Lo único que cambia entre motores: el DDL de la tabla de control.
/// El SQL de las migraciones no se comparte ([ADR 0010]); cada motor tiene
/// su propia carpeta.
/// </summary>
public sealed class DialectoSql
{
    public required string Nombre { get; init; }

    /// <summary>
    /// DDL de <see cref="EjecutorDeMigraciones.TablaDeControl"/>. Es idempotente
    /// a propósito: el ejecutor la crea antes de saber qué se aplicó, y
    /// <c>0001_inicial.sql</c> la vuelve a declarar para que el archivo en git
    /// siga siendo la verdad del esquema.
    /// </summary>
    public required string DdlTablaDeControl { get; init; }

    public static readonly DialectoSql Sqlite = new()
    {
        Nombre = "SQLite",
        DdlTablaDeControl = """
            CREATE TABLE IF NOT EXISTS migraciones_aplicadas (
                numero      INTEGER  NOT NULL PRIMARY KEY,
                nombre      TEXT     NOT NULL,
                hash        TEXT     NOT NULL,
                aplicada_en TEXT     NOT NULL
            );
            """,
    };

    public static readonly DialectoSql PostgreSql = new()
    {
        Nombre = "PostgreSQL",
        DdlTablaDeControl = """
            CREATE TABLE IF NOT EXISTS migraciones_aplicadas (
                numero      INTEGER      NOT NULL PRIMARY KEY,
                nombre      TEXT         NOT NULL,
                hash        TEXT         NOT NULL,
                aplicada_en TIMESTAMPTZ  NOT NULL
            );
            """,
    };
}
