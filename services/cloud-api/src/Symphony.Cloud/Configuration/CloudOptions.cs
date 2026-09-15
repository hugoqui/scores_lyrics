namespace Symphony.Cloud.Configuration;

/// <summary>
/// Configuración de la nube, leída de variables de entorno al arrancar.
/// Sin valores por defecto de producción: si falta una variable requerida,
/// el arranque falla nombrándola.
/// </summary>
public sealed class CloudOptions
{
    public const string PostgresConnectionStringVariable = "SYMPHONY_CLOUD_POSTGRES_CONNECTION_STRING";

    /// <summary>Cadena de conexión a PostgreSQL.</summary>
    public required string PostgresConnectionString { get; init; }

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

        var missing = new List<string>();
        if (string.IsNullOrWhiteSpace(postgresConnectionString))
        {
            missing.Add(PostgresConnectionStringVariable);
        }

        if (missing.Count > 0)
        {
            throw new InvalidOperationException(
                $"Faltan variables de entorno requeridas para Symphony.Cloud: {string.Join(", ", missing)}.");
        }

        return new CloudOptions
        {
            PostgresConnectionString = postgresConnectionString!,
            Environment = environment,
        };
    }
}
