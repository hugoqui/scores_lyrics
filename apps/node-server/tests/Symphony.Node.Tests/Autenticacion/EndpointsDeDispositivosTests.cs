using System.Net;
using System.Net.Http.Json;
using Microsoft.AspNetCore.Mvc.Testing;
using Symphony.Sesiones.Web;

namespace Symphony.Node.Tests.Autenticacion;

/// <summary>
/// T6.6, T6.9: listar y revocar dispositivos desde el nodo, sin depender de la
/// nube (spec R6). Es lo que le queda a un administrador si el domingo se cae
/// el internet y hay que cerrar un teléfono perdido de todas formas.
/// </summary>
[Collection(ConfiguracionDelProceso.Nombre)]
public class EndpointsDeDispositivosTests
{
    [Fact]
    public async Task Un_administrador_lista_y_revoca_dispositivos_del_nodo()
    {
        using var nodo = new NodoDePrueba();
        nodo.Migrar();
        nodo.SembrarIglesia(nodo.IglesiaId);
        var (_, correoAdmin, contrasenaAdmin) = nodo.SembrarUsuario(
            "admin@ejemplo.invalid", "contraseña-admin", roles: "administrador");
        var (_, correoMusico, contrasenaMusico) = nodo.SembrarUsuario(
            "musico@ejemplo.invalid", "contraseña-musico", roles: "musico");

        await using var factory = new WebApplicationFactory<Program>();
        using var cliente = factory.CreateClient();

        var admin = await Login(cliente, correoAdmin, contrasenaAdmin);
        var musico = await Login(cliente, correoMusico, contrasenaMusico);

        var listado = await ConToken(cliente, HttpMethod.Get, "/dispositivos", admin.TokenDeAcceso);
        Assert.Equal(HttpStatusCode.OK, listado.StatusCode);
        var dispositivos = await listado.Content.ReadFromJsonAsync<List<Node.Autenticacion.RespuestaDeDispositivo>>();
        Assert.Contains(dispositivos!, d => d.Id == musico.DispositivoId.ToString());

        var revocacion = await ConToken(cliente, HttpMethod.Post, $"/dispositivos/{musico.DispositivoId}/revocar", admin.TokenDeAcceso);
        Assert.Equal(HttpStatusCode.NoContent, revocacion.StatusCode);

        var renovarRevocado = await cliente.PostAsJsonAsync(
            "/autenticacion/renovar", new SolicitudDeRenovacion(musico.TokenDeRenovacion));
        Assert.Equal(HttpStatusCode.Unauthorized, renovarRevocado.StatusCode);

        // El del administrador, que no se tocó, sigue sirviendo (T6.9).
        var renovarAdmin = await cliente.PostAsJsonAsync(
            "/autenticacion/renovar", new SolicitudDeRenovacion(admin.TokenDeRenovacion));
        Assert.Equal(HttpStatusCode.OK, renovarAdmin.StatusCode);
    }

    [Fact]
    public async Task Un_musico_no_puede_listar_dispositivos_del_nodo()
    {
        using var nodo = new NodoDePrueba();
        nodo.Migrar();
        nodo.SembrarIglesia(nodo.IglesiaId);
        var (_, correo, contrasena) = nodo.SembrarUsuario("musico@ejemplo.invalid", "contraseña", roles: "musico");

        await using var factory = new WebApplicationFactory<Program>();
        using var cliente = factory.CreateClient();
        var musico = await Login(cliente, correo, contrasena);

        var respuesta = await ConToken(cliente, HttpMethod.Get, "/dispositivos", musico.TokenDeAcceso);

        Assert.Equal(HttpStatusCode.Forbidden, respuesta.StatusCode);
    }

    private static async Task<RespuestaDeSesion> Login(HttpClient cliente, string correo, string contrasena)
    {
        var respuesta = await cliente.PostAsJsonAsync(
            "/autenticacion/iniciar-sesion",
            new SolicitudDeLogin(correo, contrasena, Guid.CreateVersion7(), "Teléfono", TiposDeDispositivo.Movil));
        respuesta.EnsureSuccessStatusCode();
        return (await respuesta.Content.ReadFromJsonAsync<RespuestaDeSesion>())!;
    }

    private static Task<HttpResponseMessage> ConToken(HttpClient cliente, HttpMethod metodo, string ruta, string token)
    {
        var peticion = new HttpRequestMessage(metodo, ruta);
        peticion.Headers.Add("Authorization", $"Bearer {token}");
        return cliente.SendAsync(peticion);
    }
}
