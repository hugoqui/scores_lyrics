using Npgsql;
using Symphony.Cloud.Configuration;
using Symphony.Migraciones;

namespace Symphony.Cloud.BaseDeDatos;

/// <summary>
/// Conecta el ejecutor de migraciones ([ADR 0010]) con el PostgreSQL de la nube.
/// Se llama al arrancar y desde el comando <c>migrar</c>.
/// </summary>
public static class MigracionesDeLaNube
{
    /// <summary>Las migraciones se copian junto al ejecutable, no se buscan en el repositorio.</summary>
    public static string CarpetaPorDefecto => Path.Combine(AppContext.BaseDirectory, "migrations");

    public static ResultadoDeMigracion Aplicar(CloudOptions opciones, ILogger logger, string? carpeta = null)
    {
        carpeta ??= CarpetaPorDefecto;

        using var conexion = new NpgsqlConnection(opciones.PostgresConnectionString);

        var resultado = new EjecutorDeMigraciones(carpeta, DialectoSql.PostgreSql).Aplicar(conexion);

        if (resultado.HuboCambios)
        {
            logger.LogInformation(
                "Migraciones aplicadas a la nube: {Migraciones}", string.Join(", ", resultado.Aplicadas));
        }
        else
        {
            logger.LogInformation("Nube al día: {Cantidad} migraciones ya aplicadas.", resultado.YaEstaban.Count);
        }

        return resultado;
    }
}
