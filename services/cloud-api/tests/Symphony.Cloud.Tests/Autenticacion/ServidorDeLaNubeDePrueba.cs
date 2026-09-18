using System.Reflection;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Routing;
using Microsoft.AspNetCore.TestHost;
using Microsoft.Extensions.DependencyInjection;
using Symphony.Cloud.BaseDeDatos;
using Symphony.Cloud.Configuration;
using Symphony.Cloud.Tests.BaseDeDatos;
using Symphony.Sesiones;
using Symphony.Sesiones.Web;

namespace Symphony.Cloud.Tests.Autenticacion;

/// <summary>
/// Un servidor mínimo con los endpoints de autenticación, usuarios,
/// instrumentos y dispositivos, contra el PostgreSQL ya migrado de
/// <see cref="NubeDePrueba"/>.
///
/// <para>
/// <b>No pasa por <c>Program.cs</c>.</b> El arranque real vuelve a aplicar las
/// migraciones en cada arranque (spec R1), con la misma cadena de conexión que
/// usa para atender peticiones —hoy, la del rol de la aplicación—, y ese rol
/// no es dueño de nada a propósito (<c>docs/operacion/roles-de-base-de-datos.md</c>):
/// no tiene permiso para tocar la tabla de control de migraciones, aunque no
/// haya nada pendiente. Levantar el <c>Program</c> completo aquí chocaría con
/// eso. Lo que se prueba en este archivo es la autenticación, no el arranque
/// —eso ya lo cubre <c>StartupTests</c>—, así que basta con levantar los
/// mismos componentes que <c>Program.cs</c> cablea para ella.
/// </para>
/// </summary>
public sealed class ServidorDeLaNubeDePrueba : IAsyncDisposable
{
    private readonly WebApplication _app;

    private ServidorDeLaNubeDePrueba(WebApplication app, HttpClient cliente)
    {
        _app = app;
        Cliente = cliente;
    }

    public HttpClient Cliente { get; }

    /// <summary>
    /// Las rutas que este servidor atiende, leídas de la tabla de rutas y no de
    /// una lista escrita a mano. La guardia de cruces (T8.2) compara contra
    /// esto: un endpoint nuevo sin intento de cruce tiene que romper la prueba.
    /// </summary>
    public IReadOnlyList<string> Rutas =>
        ((IEndpointRouteBuilder)_app).DataSources
            .SelectMany(fuente => fuente.Endpoints)
            .OfType<RouteEndpoint>()
            .Select(Describir)
            .Distinct(StringComparer.Ordinal)
            .OrderBy(ruta => ruta, StringComparer.Ordinal)
            .ToList();

    public static async Task<ServidorDeLaNubeDePrueba> Levantar(NubeDePrueba nube, ParDeClaves claves)
    {
        var opciones = new CloudOptions
        {
            PostgresConnectionString = nube.CadenaDeLaAplicacion,
            PostgresPropietarioConnectionString = nube.CadenaDelPropietario,
            ClaveDeFirma = claves,
            Environment = "Development",
        };

        var builder = WebApplication.CreateSlimBuilder();
        builder.WebHost.UseTestServer();
        builder.Services.AddSingleton(opciones);
        builder.Services.AddSingleton<AccesoALaNube>();
        builder.Services.AddSingleton<AccesoComoPropietario>();
        builder.Services.AddSingleton(new EmisorDeSesiones(claves, Emisor.Nube));
        builder.Services.AddSingleton(VerificadorDeSesiones.ParaLaNube([claves.ClavePublica]));

        var app = builder.Build();
        app.UsarSesionesFirmadas();

        // Los grupos de endpoints se mapean por reflexión, no uno a uno a mano:
        // si alguien añade uno nuevo en Program.cs y se olvida de añadirlo
        // aquí, la guardia de cruces (T8.2) no lo vería y ese grupo quedaría
        // sin ningún intento de cruzarse de iglesia. Así no se puede quedar
        // fuera: lo que exista en el ensamblado, se mapea.
        foreach (var mapear in MetodosDeMapeo())
        {
            mapear.Invoke(null, [app]);
        }

        await app.StartAsync();
        return new ServidorDeLaNubeDePrueba(app, app.GetTestClient());
    }

    /// <summary>
    /// Todo método <c>Mapear…(this IEndpointRouteBuilder)</c> que declare el
    /// ensamblado de la nube, sea público o interno: <c>Program.cs</c> vive en
    /// ese mismo ensamblado y puede llamar a los internos igual, así que
    /// mirar solo los públicos dejaría un grupo de endpoints fuera de la
    /// guardia sin que nadie lo notara.
    /// </summary>
    internal static IReadOnlyList<MethodInfo> MetodosDeMapeo() =>
        typeof(AccesoALaNube).Assembly.GetTypes()
            .Where(tipo => tipo is { IsAbstract: true, IsSealed: true })
            .SelectMany(tipo => tipo.GetMethods(BindingFlags.Public | BindingFlags.NonPublic | BindingFlags.Static))
            .Where(metodo =>
                metodo.Name.StartsWith("Mapear", StringComparison.Ordinal)
                && metodo.GetParameters() is [{ ParameterType: var primero }]
                && primero == typeof(IEndpointRouteBuilder))
            .OrderBy(metodo => metodo.Name, StringComparer.Ordinal)
            .ToList();

    private static string Describir(RouteEndpoint endpoint)
    {
        var metodos = endpoint.Metadata.GetMetadata<HttpMethodMetadata>()?.HttpMethods ?? [];
        return $"{string.Join(',', metodos)} {endpoint.RoutePattern.RawText}";
    }

    public async ValueTask DisposeAsync()
    {
        Cliente.Dispose();
        await _app.DisposeAsync();
    }
}
