using System.Net;
using System.Net.Http.Json;
using Symphony.Cloud.Tests.Autenticacion;
using Symphony.Cloud.Tests.BaseDeDatos;
using Symphony.Cloud.Usuarios;
using Symphony.Sesiones;
using Symphony.Sesiones.Web;

namespace Symphony.Cloud.Tests.Usuarios;

/// <summary>T6.6, T6.7, T6.9: listar y revocar dispositivos, y el límite de activos.</summary>
public sealed class EndpointsDeDispositivosTests : IClassFixture<NubeDePrueba>
{
    private readonly NubeDePrueba _nube;

    public EndpointsDeDispositivosTests(NubeDePrueba nube) => _nube = nube;

    [Fact]
    public async Task Un_administrador_lista_los_dispositivos_de_su_iglesia()
    {
        await using var servidor = await Levantar();
        var admin = await LoginComoAdministrador(servidor);

        var respuesta = await servidor.Cliente.Con(HttpMethod.Get, "/dispositivos", admin);

        Assert.Equal(HttpStatusCode.OK, respuesta.StatusCode);
        var dispositivos = await respuesta.Content.ReadFromJsonAsync<List<RespuestaDeDispositivo>>();
        // El sembrado ya trae uno del músico, y este login acaba de crear el del administrador.
        Assert.Contains(dispositivos!, d => d.Id == _nube.Primera.DispositivoId);
        Assert.Contains(dispositivos!, d => d.Id == _nube.Primera.AdministradorId);
    }

    /// <summary>T6.5: el nombre que puso quien entró es el que ve el administrador.</summary>
    [Fact]
    public async Task El_dispositivo_creado_en_el_primer_login_guarda_un_nombre_legible()
    {
        await using var servidor = await Levantar();
        var admin = await LoginComoAdministrador(servidor);
        var (correo, contrasena) = await _nube.SembrarUsuarioAdicional(_nube.Primera.Id, "con-nombre@ejemplo.invalid", "contraseña");

        var dispositivoId = Guid.CreateVersion7();
        var login = await servidor.Cliente.PostAsJsonAsync(
            "/autenticacion/iniciar-sesion",
            new SolicitudDeLogin(correo, contrasena, dispositivoId, "El teléfono de Ana", TiposDeDispositivo.Movil));
        login.EnsureSuccessStatusCode();

        var listado = await servidor.Cliente.Con(HttpMethod.Get, "/dispositivos", admin);
        var dispositivos = await listado.Content.ReadFromJsonAsync<List<RespuestaDeDispositivo>>();

        Assert.Contains(dispositivos!, d => d.Id == dispositivoId && d.Nombre == "El teléfono de Ana");
    }

    [Fact]
    public async Task Un_musico_no_puede_listar_dispositivos()
    {
        await using var servidor = await Levantar();
        var musico = await AyudasDeSesion.Login(servidor, _nube.Primera.Correo, _nube.Primera.Contrasena);

        var respuesta = await servidor.Cliente.Con(HttpMethod.Get, "/dispositivos", musico);

        Assert.Equal(HttpStatusCode.Forbidden, respuesta.StatusCode);
    }

    /// <summary>T6.9: revocar uno no afecta a los demás del mismo usuario.</summary>
    [Fact]
    public async Task Revocar_un_dispositivo_no_afecta_a_los_demas_del_mismo_usuario()
    {
        await using var servidor = await Levantar();
        var admin = await LoginComoAdministrador(servidor);
        var (correo, contrasena) = await _nube.SembrarUsuarioAdicional(_nube.Primera.Id, "dos-telefonos@ejemplo.invalid", "contraseña");

        var telefono1 = await AyudasDeSesion.Login(servidor, correo, contrasena);
        var telefono2 = await AyudasDeSesion.Login(servidor, correo, contrasena);
        Assert.NotEqual(telefono1.DispositivoId, telefono2.DispositivoId);

        var revocacion = await servidor.Cliente.Con(HttpMethod.Post, $"/dispositivos/{telefono1.DispositivoId}/revocar", admin);
        Assert.Equal(HttpStatusCode.NoContent, revocacion.StatusCode);

        // El revocado ya no renueva...
        var renovarRevocado = await servidor.Cliente.PostAsJsonAsync(
            "/autenticacion/renovar", new SolicitudDeRenovacion(telefono1.TokenDeRenovacion));
        Assert.Equal(HttpStatusCode.Unauthorized, renovarRevocado.StatusCode);

        // ...pero el otro teléfono del mismo usuario sigue sirviendo.
        var renovarElOtro = await servidor.Cliente.PostAsJsonAsync(
            "/autenticacion/renovar", new SolicitudDeRenovacion(telefono2.TokenDeRenovacion));
        Assert.Equal(HttpStatusCode.OK, renovarElOtro.StatusCode);
    }

    [Fact]
    public async Task Revocar_dos_veces_no_falla()
    {
        await using var servidor = await Levantar();
        var admin = await LoginComoAdministrador(servidor);

        await servidor.Cliente.Con(HttpMethod.Post, $"/dispositivos/{_nube.Primera.DispositivoId}/revocar", admin);
        var segunda = await servidor.Cliente.Con(HttpMethod.Post, $"/dispositivos/{_nube.Primera.DispositivoId}/revocar", admin);

        Assert.Equal(HttpStatusCode.NoContent, segunda.StatusCode);
    }

    [Fact]
    public async Task Revocar_un_dispositivo_de_otra_iglesia_se_responde_como_inexistente()
    {
        await using var servidor = await Levantar();
        var admin = await LoginComoAdministrador(servidor);

        var respuesta = await servidor.Cliente.Con(
            HttpMethod.Post, $"/dispositivos/{_nube.Segunda.DispositivoId}/revocar", admin);

        Assert.Equal(HttpStatusCode.NotFound, respuesta.StatusCode);
    }

    /// <summary>T6.7: alcanzar el límite no es un rechazo mudo, y trae los activos.</summary>
    [Fact]
    public async Task Al_alcanzar_el_limite_de_dispositivos_se_ofrece_cerrar_uno()
    {
        await using var servidor = await Levantar();
        var (correo, contrasena) = await _nube.SembrarUsuarioAdicional(_nube.Primera.Id, "con-muchos@ejemplo.invalid", "contraseña");

        for (var i = 0; i < LimiteDeDispositivos.Maximo; i++)
        {
            var respuesta = await AyudasDeSesion.LoginCrudo(servidor, correo, contrasena);
            Assert.Equal(HttpStatusCode.OK, respuesta.StatusCode);
        }

        var unoMas = await AyudasDeSesion.LoginCrudo(servidor, correo, contrasena);

        Assert.Equal(HttpStatusCode.Conflict, unoMas.StatusCode);
        var cuerpo = await unoMas.Content.ReadFromJsonAsync<RespuestaDeLimiteAlcanzado>();
        Assert.Equal("limite_de_dispositivos", cuerpo!.Error);
        Assert.Equal(LimiteDeDispositivos.Maximo, cuerpo.Dispositivos.Count);
    }

    private Task<ServidorDeLaNubeDePrueba> Levantar() => ServidorDeLaNubeDePrueba.Levantar(_nube, ParDeClaves.Generar());

    private Task<RespuestaDeSesion> LoginComoAdministrador(ServidorDeLaNubeDePrueba servidor) =>
        AyudasDeSesion.Login(
            servidor, _nube.Primera.AdministradorCorreo, _nube.Primera.AdministradorContrasena,
            dispositivoId: _nube.Primera.AdministradorId);
}

public sealed record RespuestaDeLimiteAlcanzado(string Error, IReadOnlyList<DispositivoActivo> Dispositivos);
