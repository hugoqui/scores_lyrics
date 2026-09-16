namespace Symphony.Cloud.Registro;

/// <summary>
/// spec R7: ningún fallo se traga en silencio. Registra la excepción completa
/// —con su rastro de pila— antes de dejarla seguir su curso, para que la
/// respuesta de error de ASP.NET Core no sea lo único que quede.
/// </summary>
public static class MiddlewareDeErroresNoAtendidos
{
    public static async Task Invocar(HttpContext contexto, RequestDelegate siguiente, ILogger logger)
    {
        try
        {
            await siguiente(contexto);
        }
        catch (Exception excepcion)
        {
            logger.LogError(excepcion, "Fallo no atendido en {Metodo} {Ruta}", contexto.Request.Method, contexto.Request.Path);
            throw;
        }
    }
}
