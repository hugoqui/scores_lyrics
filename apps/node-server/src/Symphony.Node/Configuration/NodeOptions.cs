namespace Symphony.Node.Configuration;

/// <summary>
/// Configuración del nodo, leída de variables de entorno al arrancar.
/// Sin valores por defecto de producción: si falta una variable requerida,
/// el arranque falla nombrándola.
/// </summary>
public sealed class NodeOptions
{
    public const string SqlitePathVariable = "SYMPHONY_NODE_SQLITE_PATH";
    public const string CloudUrlVariable = "SYMPHONY_NODE_CLOUD_URL";

    /// <summary>Ruta al archivo SQLite del nodo.</summary>
    public required string SqlitePath { get; init; }

    /// <summary>URL base de Symphony.Cloud a la que este nodo se sincroniza.</summary>
    public required string CloudUrl { get; init; }

    /// <summary>Entorno de ejecución (Development/Production), tomado de ASPNETCORE_ENVIRONMENT.</summary>
    public required string Environment { get; init; }

    /// <summary>
    /// Lee y valida la configuración del nodo. Si falta una variable requerida,
    /// lanza <see cref="InvalidOperationException"/> nombrándola. Se llama al
    /// arrancar, antes de atender la primera petición.
    /// </summary>
    public static NodeOptions FromEnvironment(string environment)
    {
        var sqlitePath = System.Environment.GetEnvironmentVariable(SqlitePathVariable);
        var cloudUrl = System.Environment.GetEnvironmentVariable(CloudUrlVariable);

        var missing = new List<string>();
        if (string.IsNullOrWhiteSpace(sqlitePath))
        {
            missing.Add(SqlitePathVariable);
        }
        if (string.IsNullOrWhiteSpace(cloudUrl))
        {
            missing.Add(CloudUrlVariable);
        }

        if (missing.Count > 0)
        {
            throw new InvalidOperationException(
                $"Faltan variables de entorno requeridas para Symphony.Node: {string.Join(", ", missing)}.");
        }

        return new NodeOptions
        {
            SqlitePath = sqlitePath!,
            CloudUrl = cloudUrl!,
            Environment = environment,
        };
    }
}
