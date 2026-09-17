using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.TestHost;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Time.Testing;
using Symphony.Sesiones.Web;

namespace Symphony.Sesiones.Web.Tests;

/// <summary>
/// Un servidor mínimo con los mismos dos endpoints en todas las pruebas: uno
/// que exige operar el servicio y otro que exige administrar usuarios. No hay
/// endpoints reales todavía —llegan en T5.1–T5.3—, y esperar a que existan para
/// comprobar la puerta sería fijar la regla después de haberla usado.
/// </summary>
public sealed class ServidorDePrueba : IAsyncDisposable
{
    /// <summary>Un domingo cualquiera. El reloj es fijo para que nada dependa de cuándo corren las pruebas.</summary>
    public static readonly DateTimeOffset Domingo = new(2026, 9, 20, 10, 0, 0, TimeSpan.Zero);

    private readonly WebApplication _app;

    private ServidorDePrueba(WebApplication app, HttpClient cliente)
    {
        _app = app;
        Cliente = cliente;
    }

    public HttpClient Cliente { get; }

    public static async Task<ServidorDePrueba> Levantar(VerificadorDeSesiones verificador)
    {
        var builder = WebApplication.CreateSlimBuilder();
        builder.WebHost.UseTestServer();
        builder.Services.AddSingleton(verificador);

        var app = builder.Build();
        app.UsarSesionesFirmadas();

        app.MapGet("/operar", (HttpContext contexto) =>
            Results.Ok(new { iglesia = contexto.SesionObligatoria().IglesiaId }))
            .Exige(Operaciones.OperarElServicio);

        app.MapGet("/usuarios", (HttpContext contexto) =>
            Results.Ok(new { iglesia = contexto.SesionObligatoria().IglesiaId }))
            .Exige(Operaciones.AdministrarUsuarios);

        await app.StartAsync();
        return new ServidorDePrueba(app, app.GetTestClient());
    }

    public static EmisorDeSesiones Emisor(ParDeClaves claves, Emisor emisor = Sesiones.Emisor.Nube) =>
        new(claves, emisor, new FakeTimeProvider(Domingo));

    public static FakeTimeProvider Reloj() => new(Domingo);

    public async ValueTask DisposeAsync()
    {
        Cliente.Dispose();
        await _app.DisposeAsync();
    }
}
