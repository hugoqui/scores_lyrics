using Symphony.Sesiones;

namespace Symphony.Cloud.Configuration;

/// <summary>
/// Configuración de la nube, leída de variables de entorno al arrancar.
/// Sin valores por defecto de producción: si falta una variable requerida,
/// el arranque falla nombrándola.
/// </summary>
public sealed class CloudOptions
{
    public const string PostgresConnectionStringVariable = "SYMPHONY_CLOUD_POSTGRES_CONNECTION_STRING";
    public const string ClavePrivadaVariable = "SYMPHONY_CLOUD_CLAVE_PRIVADA";

    /// <summary>Cadena de conexión a PostgreSQL.</summary>
    public required string PostgresConnectionString { get; init; }

    /// <summary>
    /// Con esta firma la nube las sesiones que emite. Los nodos solo conocen su
    /// mitad pública, que es todo lo que necesitan para verificar sin red
    /// ([ADR 0016]).
    /// </summary>
    public required ParDeClaves ClaveDeFirma { get; init; }

    /// <summary>Entorno de ejecución (Development/Production), tomado de ASPNETCORE_ENVIRONMENT.</summary>
    public required string Environment { get; init; }

    /// <summary>
    /// Lee y valida la configuración de la nube. Si falta una variable requerida,
    /// lanza <see cref="InvalidOperationException"/> nombrándola. Se llama al
    /// arrancar, antes de atender la primera petición.
    /// </summary>
    public static CloudOptions FromEnvironment(string environment)
    {
        var postgresConnectionString = System.Environment.GetEnvironmentVariable(PostgresConnectionStringVariable);
        var clavePrivada = System.Environment.GetEnvironmentVariable(ClavePrivadaVariable);

        var missing = new List<string>();
        if (string.IsNullOrWhiteSpace(postgresConnectionString))
        {
            missing.Add(PostgresConnectionStringVariable);
        }
        if (string.IsNullOrWhiteSpace(clavePrivada))
        {
            missing.Add(ClavePrivadaVariable);
        }

        if (missing.Count > 0)
        {
            throw new InvalidOperationException(
                $"Faltan variables de entorno requeridas para Symphony.Cloud: {string.Join(", ", missing)}.");
        }

        // Una clave mal copiada tiene que fallar al arrancar, no la primera vez
        // que alguien intente iniciar sesión.
        ParDeClaves claveDeFirma;
        try
        {
            claveDeFirma = ParDeClaves.DesdeBase64(clavePrivada!);
        }
        catch (ArgumentException excepcion)
        {
            throw new InvalidOperationException(
                $"La clave de firma de la nube ({ClavePrivadaVariable}) no es válida: {excepcion.Message}",
                excepcion);
        }

        return new CloudOptions
        {
            PostgresConnectionString = postgresConnectionString!,
            ClaveDeFirma = claveDeFirma,
            Environment = environment,
        };
    }
}
