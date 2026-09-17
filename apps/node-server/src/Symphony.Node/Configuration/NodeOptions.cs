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
    public const string IglesiaIdVariable = "SYMPHONY_NODE_IGLESIA_ID";

    /// <summary>Ruta al archivo SQLite del nodo.</summary>
    public required string SqlitePath { get; init; }

    /// <summary>URL base de Symphony.Cloud a la que este nodo se sincroniza.</summary>
    public required string CloudUrl { get; init; }

    /// <summary>
    /// La iglesia a la que sirve este nodo (spec R1). Un nodo sirve a una sola
    /// ([ADR 0002]), y conocer su identidad desde la configuración es lo que
    /// permite detectar al arrancar una base que es de otra.
    /// </summary>
    public required Guid IglesiaId { get; init; }

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
        var iglesiaId = System.Environment.GetEnvironmentVariable(IglesiaIdVariable);

        var missing = new List<string>();
        if (string.IsNullOrWhiteSpace(sqlitePath))
        {
            missing.Add(SqlitePathVariable);
        }
        if (string.IsNullOrWhiteSpace(cloudUrl))
        {
            missing.Add(CloudUrlVariable);
        }
        if (string.IsNullOrWhiteSpace(iglesiaId))
        {
            missing.Add(IglesiaIdVariable);
        }

        if (missing.Count > 0)
        {
            throw new InvalidOperationException(
                $"Faltan variables de entorno requeridas para Symphony.Node: {string.Join(", ", missing)}.");
        }

        if (!Guid.TryParse(iglesiaId, out var identificadorDeIglesia))
        {
            throw new InvalidOperationException(
                $"{IglesiaIdVariable} no es un identificador válido: '{iglesiaId}'.");
        }

        return new NodeOptions
        {
            SqlitePath = sqlitePath!,
            CloudUrl = cloudUrl!,
            IglesiaId = identificadorDeIglesia,
            Environment = environment,
        };
    }
}
