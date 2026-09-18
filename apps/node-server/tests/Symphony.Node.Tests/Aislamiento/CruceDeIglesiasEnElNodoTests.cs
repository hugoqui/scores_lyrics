using System.Net;
using System.Net.Http.Json;
using System.Text;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.AspNetCore.Routing;
using Microsoft.Extensions.DependencyInjection;
using Symphony.Sesiones;
using Symphony.Sesiones.Web;

namespace Symphony.Node.Tests.Aislamiento;

/// <summary>
/// T8.2 en el nodo: <b>cruzarse de iglesia contra el equipo del templo</b>.
///
/// <para>
/// Aquí el intento no puede ser un identificador ajeno —en este archivo no hay
/// más que una iglesia (ADR 0015)—, así que es el que de verdad existe: un
/// token de <b>otra</b> congregación, emitido por la nube, firmado con la clave
/// que este nodo sí acepta y sin caducar. Es lo que pasaría si el
/// administrador de la iglesia de al lado apuntara su aplicación a esta red
/// (spec R1, 000-seguridad R6: estar en la red del templo no autoriza nada).
/// </para>
/// <para>
/// Por eso cada rechazo va con su contraparte: el mismo emisor y la misma clave,
/// pero con la iglesia de este nodo, tienen que abrir. Sin ella, un nodo que
/// rechazara todo pasaría estas pruebas sin aislar nada.
/// </para>
/// </summary>
[Collection(ConfiguracionDelProceso.Nombre)]
public class CruceDeIglesiasEnElNodoTests
{
    private static readonly IReadOnlyList<string> _rutasConIntentoDeCruce =
    [
        "GET /dispositivos",
        "POST /autenticacion/cerrar-sesion",
        "POST /autenticacion/iniciar-sesion",
        "POST /autenticacion/renovar",
        "POST /dispositivos/{id:guid}/revocar",
    ];

    private static readonly IReadOnlyList<string> _rutasSinSesion =
    [
        "POST /autenticacion/cerrar-sesion",
        "POST /autenticacion/iniciar-sesion",
        "POST /autenticacion/renovar",
    ];

    [Fact]
    public async Task Toda_ruta_del_nodo_tiene_su_intento_de_cruce()
    {
        using var nodo = NodoListo();
        await using var factory = Levantar();
        using var cliente = factory.CreateClient();

        Assert.Equal(_rutasConIntentoDeCruce, Rutas(factory));
    }

    [Fact]
    public async Task Ninguna_ruta_del_nodo_sirve_datos_sin_sesion_firmada()
    {
        using var nodo = NodoListo();
        await using var factory = Levantar();
        using var cliente = factory.CreateClient();
        var sinRechazar = new List<string>();

        foreach (var ruta in Rutas(factory).Except(_rutasSinSesion, StringComparer.Ordinal))
        {
            var respuesta = await cliente.SendAsync(Peticion(ruta, token: null));
            if (respuesta.StatusCode != HttpStatusCode.Unauthorized)
            {
                sinRechazar.Add($"{ruta} respondió {(int)respuesta.StatusCode}");
            }
        }

        Assert.True(
            sinRechazar.Count == 0,
            $"Estas rutas del nodo atendieron sin sesión firmada: {string.Join("; ", sinRechazar)}");
    }

    [Fact]
    public async Task Un_token_de_otra_iglesia_no_abre_ninguna_ruta_protegida()
    {
        using var nodo = NodoListo();
        await using var factory = Levantar();
        using var cliente = factory.CreateClient();

        var deOtraIglesia = TokenDeLaNubePara(nodo, Guid.CreateVersion7());
        var abiertas = new List<string>();

        foreach (var ruta in Rutas(factory).Except(_rutasSinSesion, StringComparer.Ordinal))
        {
            var respuesta = await cliente.SendAsync(Peticion(ruta, deOtraIglesia));
            if (respuesta.StatusCode != HttpStatusCode.Unauthorized)
            {
                abiertas.Add($"{ruta} respondió {(int)respuesta.StatusCode}");
            }
        }

        Assert.True(
            abiertas.Count == 0,
            "Un nodo sirve a una sola iglesia (spec R1): un token de otra congregación no puede pasar " +
            $"de la puerta, aunque esté bien firmado. Estas lo dejaron entrar: {string.Join("; ", abiertas)}");
    }

    [Fact]
    public async Task El_mismo_token_para_la_iglesia_del_nodo_si_abre()
    {
        // La contraparte: si el nodo rechazara todo token de la nube, la prueba
        // de arriba pasaría sin demostrar que lo que rechaza es la iglesia.
        using var nodo = NodoListo();
        await using var factory = Levantar();
        using var cliente = factory.CreateClient();

        var respuesta = await cliente.SendAsync(
            Peticion("GET /dispositivos", TokenDeLaNubePara(nodo, nodo.IglesiaId)));

        Assert.Equal(HttpStatusCode.OK, respuesta.StatusCode);
    }

    [Fact]
    public async Task Renovar_con_un_token_de_otra_iglesia_no_da_acceso()
    {
        using var nodo = NodoListo();
        await using var factory = Levantar();
        using var cliente = factory.CreateClient();

        var emisorDeLaNube = new EmisorDeSesiones(nodo.ClaveDeLaNube, Emisor.Nube);
        var (renovacionAjena, _) = emisorDeLaNube.Renovacion(
            Guid.CreateVersion7(), Guid.CreateVersion7(), [Roles.Administrador], Guid.CreateVersion7());

        var respuesta = await cliente.PostAsJsonAsync(
            "/autenticacion/renovar", new SolicitudDeRenovacion(renovacionAjena));

        Assert.Equal(HttpStatusCode.Unauthorized, respuesta.StatusCode);
    }

    [Fact]
    public async Task Cerrar_sesion_con_un_token_de_otra_iglesia_no_toca_la_sesion_del_templo()
    {
        using var nodo = NodoListo();
        var (_, correo, contrasena) = nodo.SembrarUsuario(
            "musico@ejemplo.invalid", "contraseña-musico", roles: Roles.Musico);

        await using var factory = Levantar();
        using var cliente = factory.CreateClient();
        var propia = await Login(cliente, correo, contrasena);

        var emisorDeLaNube = new EmisorDeSesiones(nodo.ClaveDeLaNube, Emisor.Nube);
        var (renovacionAjena, _) = emisorDeLaNube.Renovacion(
            Guid.CreateVersion7(), Guid.CreateVersion7(), [Roles.Administrador], Guid.CreateVersion7());

        var cierre = await cliente.PostAsJsonAsync(
            "/autenticacion/cerrar-sesion", new SolicitudDeCierre(renovacionAjena));
        Assert.Equal(HttpStatusCode.Unauthorized, cierre.StatusCode);

        // Ninguna sesión del templo quedó revocada...
        Assert.Empty(SesionesRevocadas(nodo));

        // ...y quien estaba dentro sigue dentro, que es lo que se nota el domingo.
        var renovacion = await cliente.PostAsJsonAsync(
            "/autenticacion/renovar", new SolicitudDeRenovacion(propia.TokenDeRenovacion));
        Assert.Equal(HttpStatusCode.OK, renovacion.StatusCode);
    }

    /// <summary>
    /// En Production a propósito: es lo que corre en el templo, y es donde la
    /// superficie del nodo son exactamente sus operaciones. En Development se
    /// suma el documento de OpenAPI, que es herramienta de desarrollo y no una
    /// operación del módulo.
    /// </summary>
    private static WebApplicationFactory<Program> Levantar() =>
        new WebApplicationFactory<Program>().WithWebHostBuilder(constructor => constructor.UseEnvironment("Production"));

    private static NodoDePrueba NodoListo()
    {
        var nodo = new NodoDePrueba();
        nodo.Migrar();
        nodo.SembrarIglesia(nodo.IglesiaId);
        nodo.SembrarUsuario("admin@ejemplo.invalid", "contraseña-admin", roles: Roles.Administrador);
        return nodo;
    }

    /// <summary>
    /// Un token de acceso emitido por la nube —con la clave que este nodo tiene
    /// configurada como suya— para la iglesia que se le pida.
    /// </summary>
    private static string TokenDeLaNubePara(NodoDePrueba nodo, Guid iglesiaId)
    {
        var emisor = new EmisorDeSesiones(nodo.ClaveDeLaNube, Emisor.Nube);
        var (token, _) = emisor.Acceso(
            Guid.CreateVersion7(), iglesiaId, [Roles.Administrador], Guid.CreateVersion7());
        return token;
    }

    private static IReadOnlyList<string> Rutas(WebApplicationFactory<Program> factory) =>
        factory.Services.GetRequiredService<EndpointDataSource>().Endpoints
            .OfType<RouteEndpoint>()
            .Select(endpoint =>
                $"{string.Join(',', endpoint.Metadata.GetMetadata<HttpMethodMetadata>()?.HttpMethods ?? [])} " +
                $"{endpoint.RoutePattern.RawText}")
            .Distinct(StringComparer.Ordinal)
            .OrderBy(ruta => ruta, StringComparer.Ordinal)
            .ToList();

    private static IReadOnlyList<string> SesionesRevocadas(NodoDePrueba nodo)
    {
        using var conexion = nodo.Abrir();
        using var comando = conexion.CreateCommand();
        comando.CommandText = "SELECT id FROM sesion WHERE revocada_en IS NOT NULL";

        var ids = new List<string>();
        using var lector = comando.ExecuteReader();
        while (lector.Read())
        {
            ids.Add(lector.GetString(0));
        }

        return ids;
    }

    private static async Task<RespuestaDeSesion> Login(HttpClient cliente, string correo, string contrasena)
    {
        var respuesta = await cliente.PostAsJsonAsync(
            "/autenticacion/iniciar-sesion",
            new SolicitudDeLogin(correo, contrasena, Guid.CreateVersion7(), "Teléfono", TiposDeDispositivo.Movil));
        respuesta.EnsureSuccessStatusCode();
        return (await respuesta.Content.ReadFromJsonAsync<RespuestaDeSesion>())!;
    }

    /// <summary>
    /// La ruta con los huecos rellenos y, si se le da, la sesión en la cabecera.
    /// El cuerpo vacío importa: el filtro de autorización corre después de
    /// enlazar los parámetros, así que sin cuerpo un POST respondería 400 y no
    /// diría nada sobre la sesión.
    /// </summary>
    private static HttpRequestMessage Peticion(string ruta, string? token)
    {
        var partes = ruta.Split(' ', 2);
        var metodo = new HttpMethod(partes[0].Split(',')[0]);

        var camino = new StringBuilder();
        foreach (var segmento in partes[1].Split('/'))
        {
            if (segmento.Length == 0)
            {
                continue;
            }

            camino.Append('/').Append(segmento.StartsWith('{') ? Guid.CreateVersion7().ToString() : segmento);
        }

        var peticion = new HttpRequestMessage(metodo, camino.ToString());
        if (metodo != HttpMethod.Get && metodo != HttpMethod.Delete)
        {
            peticion.Content = new StringContent("{}", Encoding.UTF8, "application/json");
        }

        if (token is not null)
        {
            peticion.Headers.Add("Authorization", $"Bearer {token}");
        }

        return peticion;
    }
}
