using Microsoft.Data.Sqlite;
using Symphony.Migraciones;
using Symphony.Node.Configuration;

namespace Symphony.Node.BaseDeDatos;

/// <summary>
/// Conecta el ejecutor de migraciones ([ADR 0010]) con el SQLite del nodo.
/// Se llama al arrancar y desde el comando <c>migrar</c>.
/// </summary>
public static class MigracionesDelNodo
{
    /// <summary>Las migraciones se copian junto al ejecutable, no se buscan en el repositorio.</summary>
    public static string CarpetaPorDefecto => Path.Combine(AppContext.BaseDirectory, "migrations");

    public static ResultadoDeMigracion Aplicar(NodeOptions opciones, ILogger logger, string? carpeta = null)
    {
        carpeta ??= CarpetaPorDefecto;

        // SQLite crea el archivo solo, pero no la carpeta que lo contiene.
        var directorio = Path.GetDirectoryName(Path.GetFullPath(opciones.SqlitePath));
        if (!string.IsNullOrEmpty(directorio))
        {
            Directory.CreateDirectory(directorio);
        }

        using var conexion = new SqliteConnection(new SqliteConnectionStringBuilder
        {
            DataSource = opciones.SqlitePath,
        }.ToString());

        var resultado = new EjecutorDeMigraciones(carpeta, DialectoSql.Sqlite).Aplicar(conexion);

        if (resultado.HuboCambios)
        {
            logger.LogInformation(
                "Migraciones aplicadas al nodo: {Migraciones}", string.Join(", ", resultado.Aplicadas));
        }
        else
        {
            logger.LogInformation("Nodo al día: {Cantidad} migraciones ya aplicadas.", resultado.YaEstaban.Count);
        }

        return resultado;
    }
}
