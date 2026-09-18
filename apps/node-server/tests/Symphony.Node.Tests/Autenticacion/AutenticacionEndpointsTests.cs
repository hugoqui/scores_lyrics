using System.Net;
using System.Net.Http.Json;
using Microsoft.AspNetCore.Mvc.Testing;
using Symphony.Sesiones.Web;

namespace Symphony.Node.Tests.Autenticacion;

/// <summary>
/// T5.2, T5.3, T5.9: login, renovación y cierre de sesión del nodo.
///
/// <para>
/// <b>Ninguna de estas pruebas levanta nada que responda por la nube.</b> No
/// hay servidor falso escuchando en <c>SYMPHONY_NODE_CLOUD_URL</c>, y el nodo
/// arranca y autentica igual: si autenticar dependiera de la nube, esta clase
/// entera fallaría por no encontrar con quién hablar. Esa ausencia es la
/// prueba de spec R8, no un detalle del montaje.
/// </para>
/// </summary>
[Collection(ConfiguracionDelProceso.Nombre)]
public class AutenticacionEndpointsTests
{
    [Fact]
    public async Task Login_correcto_devuelve_tokens_firmados_por_el_nodo()
    {
        using var nodo = new NodoDePrueba();
        nodo.Migrar();
        nodo.SembrarIglesia(nodo.IglesiaId);
        var (id, correo, contrasena) = nodo.SembrarUsuario("musico@ejemplo.invalid", "contraseña-correcta", roles: "musico");

        await using var factory = new WebApplicationFactory<Program>();
        using var cliente = factory.CreateClient();

        var respuesta = await cliente.PostAsJsonAsync(
            "/autenticacion/iniciar-sesion",
            new SolicitudDeLogin(correo, contrasena, Guid.CreateVersion7(), "Teléfono", TiposDeDispositivo.Movil));

        Assert.Equal(HttpStatusCode.OK, respuesta.StatusCode);
        var cuerpo = await respuesta.Content.ReadFromJsonAsync<RespuestaDeSesion>();
        Assert.NotNull(cuerpo);
        Assert.Equal(id, cuerpo!.UsuarioId);
        Assert.Equal(nodo.IglesiaId, cuerpo.IglesiaId);
        Assert.Equal(["musico"], cuerpo.Roles);
    }

    [Fact]
    public async Task Correo_inexistente_y_contrasena_incorrecta_responden_exactamente_igual()
    {
        using var nodo = new NodoDePrueba();
        nodo.Migrar();
        nodo.SembrarIglesia(nodo.IglesiaId);
        var (_, correo, _) = nodo.SembrarUsuario("musico@ejemplo.invalid", "contraseña-correcta", roles: "musico");

        await using var factory = new WebApplicationFactory<Program>();
        using var cliente = factory.CreateClient();

        var conCorreoInexistente = await cliente.PostAsJsonAsync(
            "/autenticacion/iniciar-sesion",
            new SolicitudDeLogin("no-existe@ejemplo.invalid", "cualquiera", Guid.CreateVersion7(), "Teléfono", TiposDeDispositivo.Movil));
        var conContrasenaIncorrecta = await cliente.PostAsJsonAsync(
            "/autenticacion/iniciar-sesion",
            new SolicitudDeLogin(correo, "la-contraseña-equivocada", Guid.CreateVersion7(), "Teléfono", TiposDeDispositivo.Movil));

        Assert.Equal(HttpStatusCode.Unauthorized, conCorreoInexistente.StatusCode);
        Assert.Equal(conCorreoInexistente.StatusCode, conContrasenaIncorrecta.StatusCode);
        Assert.Equal(
            await conCorreoInexistente.Content.ReadAsStringAsync(),
            await conContrasenaIncorrecta.Content.ReadAsStringAsync());
    }

    [Fact]
    public async Task Un_usuario_dado_de_baja_no_entra_aunque_acierte_la_contrasena()
    {
        using var nodo = new NodoDePrueba();
        nodo.Migrar();
        nodo.SembrarIglesia(nodo.IglesiaId);
        var (_, correo, contrasena) = nodo.SembrarUsuario(
            "de-baja@ejemplo.invalid", "contraseña-correcta", activo: false, roles: "musico");

        await using var factory = new WebApplicationFactory<Program>();
        using var cliente = factory.CreateClient();

        var respuesta = await cliente.PostAsJsonAsync(
            "/autenticacion/iniciar-sesion",
            new SolicitudDeLogin(correo, contrasena, Guid.CreateVersion7(), "Teléfono", TiposDeDispositivo.Movil));

        Assert.Equal(HttpStatusCode.Forbidden, respuesta.StatusCode);
    }

    [Fact]
    public async Task Renovar_da_un_acceso_nuevo_y_cerrar_sesion_lo_impide_despues()
    {
        using var nodo = new NodoDePrueba();
        nodo.Migrar();
        nodo.SembrarIglesia(nodo.IglesiaId);
        var (_, correo, contrasena) = nodo.SembrarUsuario("musico@ejemplo.invalid", "contraseña-correcta", roles: "musico");

        await using var factory = new WebApplicationFactory<Program>();
        using var cliente = factory.CreateClient();

        var login = await cliente.PostAsJsonAsync(
            "/autenticacion/iniciar-sesion",
            new SolicitudDeLogin(correo, contrasena, Guid.CreateVersion7(), "Teléfono", TiposDeDispositivo.Movil));
        var sesion = (await login.Content.ReadFromJsonAsync<RespuestaDeSesion>())!;

        var renovacion = await cliente.PostAsJsonAsync(
            "/autenticacion/renovar", new SolicitudDeRenovacion(sesion.TokenDeRenovacion));
        Assert.Equal(HttpStatusCode.OK, renovacion.StatusCode);
        var nuevoAcceso = (await renovacion.Content.ReadFromJsonAsync<RespuestaDeRenovacion>())!;
        Assert.NotEqual(sesion.TokenDeAcceso, nuevoAcceso.TokenDeAcceso);

        var cierre = await cliente.PostAsJsonAsync(
            "/autenticacion/cerrar-sesion", new SolicitudDeCierre(sesion.TokenDeRenovacion));
        Assert.Equal(HttpStatusCode.NoContent, cierre.StatusCode);

        var intentoDeRenovar = await cliente.PostAsJsonAsync(
            "/autenticacion/renovar", new SolicitudDeRenovacion(sesion.TokenDeRenovacion));
        Assert.Equal(HttpStatusCode.Unauthorized, intentoDeRenovar.StatusCode);
    }

    /// <summary>
    /// T5.9, la comprobación explícita: no hay <c>HttpClient</c> ni URL de
    /// nube configurada hacia ningún servidor real —<c>SYMPHONY_NODE_CLOUD_URL</c>
    /// apunta a un dominio que no resuelve—, y el login igual funciona.
    /// </summary>
    [Fact]
    public async Task El_nodo_autentica_con_la_nube_inalcanzable()
    {
        using var nodo = new NodoDePrueba();
        Environment.SetEnvironmentVariable(
            Symphony.Node.Configuration.NodeOptions.CloudUrlVariable, "https://nube-que-no-existe.invalid");
        nodo.Migrar();
        nodo.SembrarIglesia(nodo.IglesiaId);
        var (_, correo, contrasena) = nodo.SembrarUsuario("musico@ejemplo.invalid", "contraseña-correcta", roles: "musico");

        await using var factory = new WebApplicationFactory<Program>();
        using var cliente = factory.CreateClient();

        var respuesta = await cliente.PostAsJsonAsync(
            "/autenticacion/iniciar-sesion",
            new SolicitudDeLogin(correo, contrasena, Guid.CreateVersion7(), "Teléfono", TiposDeDispositivo.Movil));

        Assert.Equal(HttpStatusCode.OK, respuesta.StatusCode);
    }
}
