using Microsoft.Data.Sqlite;

namespace Symphony.Migraciones.Tests;

/// <summary>
/// Una carpeta temporal propia con su archivo SQLite dentro. Archivo de
/// verdad, no base en memoria ([ADR 0011]): el modo en memoria se comporta
/// distinto y probaría algo que no es lo que corre en la iglesia.
/// Cada prueba crea la suya y la destruye al terminar: ninguna comparte
/// estado ni depende del orden.
/// </summary>
public sealed class CarpetaDePrueba : IDisposable
{
    public CarpetaDePrueba()
    {
        Raiz = Path.Combine(Path.GetTempPath(), "symphony-migraciones", Guid.NewGuid().ToString("N"));
        Migraciones = Path.Combine(Raiz, "migrations");
        Directory.CreateDirectory(Migraciones);
        ArchivoSqlite = Path.Combine(Raiz, "prueba.sqlite");
    }

    public string Raiz { get; }

    public string Migraciones { get; }

    public string ArchivoSqlite { get; }

    public void EscribirMigracion(string archivo, string sql) =>
        File.WriteAllText(Path.Combine(Migraciones, archivo), sql);

    public void BorrarMigracion(string archivo) =>
        File.Delete(Path.Combine(Migraciones, archivo));

    public SqliteConnection Abrir()
    {
        var conexion = new SqliteConnection(
            new SqliteConnectionStringBuilder { DataSource = ArchivoSqlite }.ToString());
        conexion.Open();
        return conexion;
    }

    public EjecutorDeMigraciones Ejecutor() => new(Migraciones, DialectoSql.Sqlite);

    /// <summary>Esquema real de la base, en texto comparable.</summary>
    public string Esquema()
    {
        using var conexion = Abrir();
        using var comando = conexion.CreateCommand();
        comando.CommandText =
            "SELECT type, name, COALESCE(sql, '') FROM sqlite_master " +
            "WHERE name NOT LIKE 'sqlite_%' ORDER BY type, name";

        var lineas = new List<string>();
        using var lector = comando.ExecuteReader();
        while (lector.Read())
        {
            lineas.Add($"{lector.GetString(0)} {lector.GetString(1)}: {lector.GetString(2)}");
        }

        return string.Join("\n", lineas);
    }

    /// <summary>Contenido de la tabla de control, sin la fecha (que sí cambia entre corridas).</summary>
    public IReadOnlyList<string> MigracionesAnotadas()
    {
        using var conexion = Abrir();
        using var comando = conexion.CreateCommand();
        comando.CommandText =
            $"SELECT numero, nombre, hash FROM {EjecutorDeMigraciones.TablaDeControl} ORDER BY numero";

        var filas = new List<string>();
        using var lector = comando.ExecuteReader();
        while (lector.Read())
        {
            filas.Add($"{lector.GetInt32(0):D4} {lector.GetString(1)} {lector.GetString(2)}");
        }

        return filas;
    }

    public void Dispose()
    {
        SqliteConnection.ClearAllPools();
        try
        {
            Directory.Delete(Raiz, recursive: true);
        }
        catch (IOException)
        {
            // Una carpeta temporal que no se pudo borrar no invalida la prueba.
        }
    }
}
