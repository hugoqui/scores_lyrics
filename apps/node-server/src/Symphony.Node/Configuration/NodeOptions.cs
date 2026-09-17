using Symphony.Sesiones;

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
    public const string ClavePrivadaVariable = "SYMPHONY_NODE_CLAVE_PRIVADA";
    public const string ClavePublicaDeLaNubeVariable = "SYMPHONY_NODE_CLAVE_PUBLICA_NUBE";

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

    /// <summary>
    /// Con esta firma el nodo las sesiones que emite el domingo, sin consultar
    /// a la nube ([ADR 0016]).
    /// </summary>
    public required ParDeClaves ClaveDeFirma { get; init; }

    /// <summary>
    /// Con esta verifica las sesiones que emitió la nube, sin red. Es media
    /// clave: no sirve para firmar nada.
    /// </summary>
    public required ClavePublicaDeFirma ClavePublicaDeLaNube { get; init; }

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
        var clavePrivada = System.Environment.GetEnvironmentVariable(ClavePrivadaVariable);
        var clavePublicaDeLaNube = System.Environment.GetEnvironmentVariable(ClavePublicaDeLaNubeVariable);

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
        if (string.IsNullOrWhiteSpace(clavePrivada))
        {
            missing.Add(ClavePrivadaVariable);
        }
        if (string.IsNullOrWhiteSpace(clavePublicaDeLaNube))
        {
            missing.Add(ClavePublicaDeLaNubeVariable);
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

        // Una clave mal copiada tiene que fallar aquí y no el domingo, cuando
        // alguien intente entrar: se interpreta al arrancar, no al usarla.
        ParDeClaves claveDeFirma;
        ClavePublicaDeFirma claveDeLaNube;
        try
        {
            claveDeFirma = ParDeClaves.DesdeBase64(clavePrivada!);
            claveDeLaNube = ClavePublicaDeFirma.DesdeBase64(clavePublicaDeLaNube!);
        }
        catch (ArgumentException excepcion)
        {
            throw new InvalidOperationException(
                $"Las claves de firma del nodo no son válidas ({ClavePrivadaVariable}, " +
                $"{ClavePublicaDeLaNubeVariable}): {excepcion.Message}", excepcion);
        }

        return new NodeOptions
        {
            SqlitePath = sqlitePath!,
            CloudUrl = cloudUrl!,
            IglesiaId = identificadorDeIglesia,
            ClaveDeFirma = claveDeFirma,
            ClavePublicaDeLaNube = claveDeLaNube,
            Environment = environment,
        };
    }
}
