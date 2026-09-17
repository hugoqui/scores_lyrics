using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.TestHost;
using Microsoft.Extensions.DependencyInjection;
using Symphony.Cloud.Autenticacion;
using Symphony.Cloud.BaseDeDatos;
using Symphony.Cloud.Configuration;
using Symphony.Cloud.Tests.BaseDeDatos;
using Symphony.Cloud.Usuarios;
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
        app.MapearAutenticacion();
        app.MapearUsuarios();
        app.MapearInstrumentos();
        app.MapearDispositivos();

        await app.StartAsync();
        return new ServidorDeLaNubeDePrueba(app, app.GetTestClient());
    }

    public async ValueTask DisposeAsync()
    {
        Cliente.Dispose();
        await _app.DisposeAsync();
    }
}
