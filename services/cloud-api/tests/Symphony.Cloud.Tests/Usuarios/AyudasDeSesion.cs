using System.Net.Http.Json;
using Symphony.Cloud.Tests.Autenticacion;
using Symphony.Sesiones.Web;

namespace Symphony.Cloud.Tests.Usuarios;

/// <summary>Login simple, sin dispositivo específico, para las pruebas de endpoints protegidos.</summary>
public static class AyudasDeSesion
{
    /// <summary>
    /// <paramref name="dispositivoId"/> por defecto es uno nuevo cada vez. Para
    /// un usuario que hace login repetidas veces a lo largo de una misma
    /// clase de pruebas —el administrador compartido, típicamente—, conviene
    /// pasar un identificador fijo: así cada login reutiliza el mismo
    /// dispositivo en vez de agotar el límite de activos (T6.7) sin que
    /// ninguna prueba individual esté probando ese límite.
    /// </summary>
    public static async Task<RespuestaDeSesion> Login(
        ServidorDeLaNubeDePrueba servidor, string correo, string contrasena, Guid? dispositivoId = null)
    {
        var respuesta = await servidor.Cliente.PostAsJsonAsync(
            "/autenticacion/iniciar-sesion",
            new SolicitudDeLogin(
                correo, contrasena, dispositivoId ?? Guid.CreateVersion7(), "Dispositivo de prueba", TiposDeDispositivo.Movil));
        respuesta.EnsureSuccessStatusCode();
        return (await respuesta.Content.ReadFromJsonAsync<RespuestaDeSesion>())!;
    }

    /// <summary>
    /// Igual que <see cref="Login"/> pero sin exigir éxito: para las pruebas
    /// que esperan que el login falle (límite de dispositivos, credenciales
    /// inválidas) y necesitan inspeccionar la respuesta.
    /// </summary>
    public static Task<HttpResponseMessage> LoginCrudo(
        ServidorDeLaNubeDePrueba servidor, string correo, string contrasena, Guid? dispositivoId = null) =>
        servidor.Cliente.PostAsJsonAsync(
            "/autenticacion/iniciar-sesion",
            new SolicitudDeLogin(
                correo, contrasena, dispositivoId ?? Guid.CreateVersion7(), "Dispositivo de prueba", TiposDeDispositivo.Movil));

    /// <summary>Una petición con el token de acceso de esta sesión, sin tocar los headers por defecto del cliente.</summary>
    public static Task<HttpResponseMessage> Con(
        this HttpClient cliente, HttpMethod metodo, string ruta, RespuestaDeSesion sesion, object? cuerpo = null)
    {
        var peticion = new HttpRequestMessage(metodo, ruta);
        peticion.Headers.Add("Authorization", $"Bearer {sesion.TokenDeAcceso}");
        if (cuerpo is not null)
        {
            peticion.Content = JsonContent.Create(cuerpo);
        }

        return cliente.SendAsync(peticion);
    }
}
