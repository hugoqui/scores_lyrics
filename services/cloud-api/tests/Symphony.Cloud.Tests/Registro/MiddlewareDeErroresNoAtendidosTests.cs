using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Logging;
using Symphony.Cloud.Registro;

namespace Symphony.Cloud.Tests.Registro;

/// <summary>
/// spec R7: un fallo no atendido se registra completo, no se traga en
/// silencio. La excepción debe seguir su curso (ASP.NET Core la convierte en
/// una respuesta de error) pero antes queda anotada con lo necesario para
/// entenderla.
/// </summary>
public class MiddlewareDeErroresNoAtendidosTests
{
    [Fact]
    public async Task Registra_la_excepcion_completa_y_la_deja_seguir_su_curso()
    {
        var registrador = new RegistradorDePrueba();
        var esperada = new InvalidOperationException("la base no respondió");
        var contexto = new DefaultHttpContext();
        contexto.Request.Method = "GET";
        contexto.Request.Path = "/falla";

        var excepcion = await Assert.ThrowsAsync<InvalidOperationException>(() =>
            MiddlewareDeErroresNoAtendidos.Invocar(contexto, _ => throw esperada, registrador));

        Assert.Same(esperada, excepcion);
        Assert.Same(esperada, registrador.UltimaExcepcionRegistrada);
        Assert.Equal(LogLevel.Error, registrador.UltimoNivelRegistrado);
    }

    [Fact]
    public async Task No_registra_nada_cuando_la_peticion_no_falla()
    {
        var registrador = new RegistradorDePrueba();
        var contexto = new DefaultHttpContext();

        await MiddlewareDeErroresNoAtendidos.Invocar(contexto, _ => Task.CompletedTask, registrador);

        Assert.Null(registrador.UltimaExcepcionRegistrada);
    }

    private sealed class RegistradorDePrueba : ILogger
    {
        public Exception? UltimaExcepcionRegistrada { get; private set; }
        public LogLevel? UltimoNivelRegistrado { get; private set; }

        public void Log<TState>(LogLevel logLevel, EventId eventId, TState state, Exception? exception, Func<TState, Exception?, string> formatter)
        {
            UltimoNivelRegistrado = logLevel;
            UltimaExcepcionRegistrada = exception;
        }

        public bool IsEnabled(LogLevel logLevel) => true;

        public IDisposable? BeginScope<TState>(TState state) where TState : notnull => null;
    }
}
