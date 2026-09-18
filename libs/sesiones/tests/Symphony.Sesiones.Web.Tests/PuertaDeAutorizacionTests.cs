using System.Net;
using System.Net.Http.Headers;

namespace Symphony.Sesiones.Web.Tests;

/// <summary>
/// T5.4, T5.7 y T5.8 sobre HTTP: que la decisión de
/// <see cref="Autorizacion"/> llegue de verdad hasta la respuesta, y que lo que
/// el cliente afirme sobre sí mismo no la mueva ni un milímetro.
/// </summary>
public class PuertaDeAutorizacionTests
{
    private static readonly Guid _iglesia = Guid.CreateVersion7();
    private static readonly Guid _usuario = Guid.CreateVersion7();
    private static readonly Guid _dispositivo = Guid.CreateVersion7();

    [Fact]
    public async Task Sin_sesion_no_se_entra()
    {
        var claves = ParDeClaves.Generar();
        await using var servidor = await Levantar(claves);

        var respuesta = await servidor.Cliente.GetAsync("/operar");

        Assert.Equal(HttpStatusCode.Unauthorized, respuesta.StatusCode);
    }

    /// <summary>
    /// T5.7. Lo que se compara no es «ambas fallan», que sería trivial: es que
    /// las dos respuestas son <b>idénticas</b>, código y cuerpo. Si afirmar un
    /// rol cambiara aunque fuera el texto del error, ya sería información: le
    /// diría a quien lo intenta que por ahí hay algo que probar.
    /// </summary>
    [Fact]
    public async Task Un_musico_que_afirma_ser_administrador_recibe_el_mismo_rechazo_que_si_callara()
    {
        var claves = ParDeClaves.Generar();
        await using var servidor = await Levantar(claves);
        var token = TokenCon(claves, Roles.Musico);

        var callado = new HttpRequestMessage(HttpMethod.Get, "/usuarios");
        callado.Headers.Authorization = new AuthenticationHeaderValue("Bearer", token);

        var fanfarron = new HttpRequestMessage(HttpMethod.Get, "/usuarios");
        fanfarron.Headers.Authorization = new AuthenticationHeaderValue("Bearer", token);
        fanfarron.Headers.Add("X-Rol", Roles.Administrador);
        fanfarron.Headers.Add("X-Roles", "administrador,operador");

        var respuestaCallado = await servidor.Cliente.SendAsync(callado);
        var respuestaFanfarron = await servidor.Cliente.SendAsync(fanfarron);

        Assert.Equal(HttpStatusCode.Forbidden, respuestaCallado.StatusCode);
        Assert.Equal(respuestaCallado.StatusCode, respuestaFanfarron.StatusCode);
        Assert.Equal(
            await respuestaCallado.Content.ReadAsStringAsync(),
            await respuestaFanfarron.Content.ReadAsStringAsync());
    }

    /// <summary>T5.8: ser administrador no es ser operador, ni en el servidor ni en ningún sitio.</summary>
    [Fact]
    public async Task Un_administrador_no_opera_el_servicio_sin_el_rol_de_operador()
    {
        var claves = ParDeClaves.Generar();
        await using var servidor = await Levantar(claves);

        var soloAdministrador = await Pedir(servidor, "/operar", TokenCon(claves, Roles.Administrador));
        var tambienOperador = await Pedir(servidor, "/operar", TokenCon(claves, Roles.Administrador, Roles.Operador));

        Assert.Equal(HttpStatusCode.Forbidden, soloAdministrador.StatusCode);
        Assert.Equal(HttpStatusCode.OK, tambienOperador.StatusCode);
    }

    [Fact]
    public async Task Una_firma_de_otra_clave_no_entra()
    {
        var claves = ParDeClaves.Generar();
        await using var servidor = await Levantar(claves);

        // Un token impecable, con los roles correctos, firmado por alguien que
        // no es quien este servidor acepta.
        var impostor = TokenCon(ParDeClaves.Generar(), Roles.Operador);

        var respuesta = await Pedir(servidor, "/operar", impostor);

        Assert.Equal(HttpStatusCode.Unauthorized, respuesta.StatusCode);
    }

    [Fact]
    public async Task Un_token_de_renovacion_no_abre_endpoints()
    {
        var claves = ParDeClaves.Generar();
        await using var servidor = await Levantar(claves);
        var (renovacion, _) = ServidorDePrueba.Emisor(claves)
            .Renovacion(_usuario, _iglesia, [Roles.Operador], _dispositivo);

        var respuesta = await Pedir(servidor, "/operar", renovacion);

        Assert.Equal(HttpStatusCode.Unauthorized, respuesta.StatusCode);
    }

    /// <summary>
    /// El nodo sirve a una sola iglesia: un token de otra, con firma buena y
    /// rol de sobra, no entra (spec R1, R3).
    /// </summary>
    [Fact]
    public async Task En_un_nodo_no_entra_un_token_de_otra_iglesia()
    {
        var claves = ParDeClaves.Generar();
        await using var servidor = await ServidorDePrueba.Levantar(
            VerificadorDeSesiones.ParaUnNodo(Guid.CreateVersion7(), [claves.ClavePublica], ServidorDePrueba.Reloj()));

        var respuesta = await Pedir(servidor, "/operar", TokenCon(claves, Roles.Operador));

        Assert.Equal(HttpStatusCode.Unauthorized, respuesta.StatusCode);
    }

    /// <summary>
    /// El nodo acepta las dos firmas ([ADR 0016]) y ninguna sale a la red: la de
    /// la nube y la suya propia.
    /// </summary>
    [Fact]
    public async Task Un_nodo_acepta_lo_que_emitio_la_nube_y_lo_que_emitio_el_mismo()
    {
        var deLaNube = ParDeClaves.Generar();
        var delNodo = ParDeClaves.Generar();
        await using var servidor = await ServidorDePrueba.Levantar(VerificadorDeSesiones.ParaUnNodo(
            _iglesia, [deLaNube.ClavePublica, delNodo.ClavePublica], ServidorDePrueba.Reloj()));

        var conLaDeLaNube = await Pedir(servidor, "/operar", TokenCon(deLaNube, Roles.Operador));
        var conLaDelNodo = await Pedir(
            servidor, "/operar", TokenCon(delNodo, Emisor.Nodo, Roles.Operador));

        Assert.Equal(HttpStatusCode.OK, conLaDeLaNube.StatusCode);
        Assert.Equal(HttpStatusCode.OK, conLaDelNodo.StatusCode);
    }

    private static async Task<ServidorDePrueba> Levantar(ParDeClaves claves) =>
        await ServidorDePrueba.Levantar(
            VerificadorDeSesiones.ParaLaNube([claves.ClavePublica], ServidorDePrueba.Reloj()));

    private static string TokenCon(ParDeClaves claves, params string[] roles) =>
        TokenCon(claves, Emisor.Nube, roles);

    private static string TokenCon(ParDeClaves claves, Emisor emisor, params string[] roles) =>
        ServidorDePrueba.Emisor(claves, emisor).Acceso(_usuario, _iglesia, roles, _dispositivo).Token;

    private static async Task<HttpResponseMessage> Pedir(ServidorDePrueba servidor, string ruta, string token)
    {
        var peticion = new HttpRequestMessage(HttpMethod.Get, ruta);
        peticion.Headers.Authorization = new AuthenticationHeaderValue("Bearer", token);
        return await servidor.Cliente.SendAsync(peticion);
    }
}
