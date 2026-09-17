using System.Net;
using System.Net.Http.Json;
using Symphony.Cloud.Tests.Autenticacion;
using Symphony.Cloud.Tests.BaseDeDatos;
using Symphony.Cloud.Usuarios;
using Symphony.Sesiones;
using Symphony.Sesiones.Web;

namespace Symphony.Cloud.Tests.Usuarios;

/// <summary>
/// T6.1, T6.2, T6.3, T6.8, T6.10: alta, baja, readmisión, y la protección de
/// que ninguna iglesia se quede sin administrador.
/// </summary>
public sealed class EndpointsDeUsuariosTests : IClassFixture<NubeDePrueba>
{
    private readonly NubeDePrueba _nube;

    public EndpointsDeUsuariosTests(NubeDePrueba nube) => _nube = nube;

    [Fact]
    public async Task Un_administrador_da_de_alta_un_usuario_con_sus_roles()
    {
        await using var servidor = await Levantar();
        var admin = await LoginComoAdministrador(servidor);

        var respuesta = await servidor.Cliente.Con(
            HttpMethod.Post, "/usuarios", admin,
            new SolicitudDeAltaDeUsuario("nuevo@ejemplo.invalid", "Persona Nueva", "contraseña-nueva", [Roles.Musico]));

        Assert.Equal(HttpStatusCode.OK, respuesta.StatusCode);
        var cuerpo = await respuesta.Content.ReadFromJsonAsync<RespuestaDeUsuario>();
        Assert.NotNull(cuerpo);
        Assert.Equal("nuevo@ejemplo.invalid", cuerpo!.Correo);
        Assert.Equal([Roles.Musico], cuerpo.Roles);
        Assert.Equal("activo", cuerpo.Estado);
    }

    [Fact]
    public async Task Un_musico_no_puede_dar_de_alta_usuarios()
    {
        await using var servidor = await Levantar();
        var musico = await AyudasDeSesion.Login(servidor, _nube.Primera.Correo, _nube.Primera.Contrasena);

        var respuesta = await servidor.Cliente.Con(
            HttpMethod.Post, "/usuarios", musico,
            new SolicitudDeAltaDeUsuario("otro@ejemplo.invalid", "Otro", "contraseña", [Roles.Musico]));

        Assert.Equal(HttpStatusCode.Forbidden, respuesta.StatusCode);
    }

    [Fact]
    public async Task El_mismo_correo_dos_veces_en_la_misma_iglesia_es_un_conflicto()
    {
        await using var servidor = await Levantar();
        var admin = await LoginComoAdministrador(servidor);
        var solicitud = new SolicitudDeAltaDeUsuario("repetido@ejemplo.invalid", "Uno", "contraseña", [Roles.Musico]);

        await servidor.Cliente.Con(HttpMethod.Post, "/usuarios", admin, solicitud);
        var segunda = await servidor.Cliente.Con(HttpMethod.Post, "/usuarios", admin, solicitud);

        Assert.Equal(HttpStatusCode.Conflict, segunda.StatusCode);
    }

    [Fact]
    public async Task Un_rol_desconocido_se_rechaza()
    {
        await using var servidor = await Levantar();
        var admin = await LoginComoAdministrador(servidor);

        var respuesta = await servidor.Cliente.Con(
            HttpMethod.Post, "/usuarios", admin,
            new SolicitudDeAltaDeUsuario("con-rol-raro@ejemplo.invalid", "Nombre", "contraseña", ["superadministrador"]));

        Assert.Equal(HttpStatusCode.BadRequest, respuesta.StatusCode);
    }

    /// <summary>T6.8: baja y readmisión no borran instrumentos ni dispositivos.</summary>
    [Fact]
    public async Task Tras_baja_y_readmision_el_usuario_conserva_instrumentos_y_dispositivos()
    {
        await using var servidor = await Levantar();
        var admin = await LoginComoAdministrador(servidor);

        var alta = await (await servidor.Cliente.Con(
            HttpMethod.Post, "/usuarios", admin,
            new SolicitudDeAltaDeUsuario("musico-de-baja@ejemplo.invalid", "Músico", "contraseña", [Roles.Musico])))
            .Content.ReadFromJsonAsync<RespuestaDeUsuario>();

        var instrumentoPiano = await IdDelPiano();
        await servidor.Cliente.Con(HttpMethod.Post, $"/usuarios/{alta!.Id}/instrumentos/{instrumentoPiano}", admin);

        // Un login antes de la baja crea el dispositivo (spec R6).
        var sesionDelMusico = await AyudasDeSesion.Login(servidor, "musico-de-baja@ejemplo.invalid", "contraseña");

        await servidor.Cliente.Con(HttpMethod.Post, $"/usuarios/{alta.Id}/baja", admin);
        await servidor.Cliente.Con(HttpMethod.Post, $"/usuarios/{alta.Id}/readmitir", admin);

        var instrumentos = await _nube.ConsultarComoDueno<int>(
            "SELECT 1 FROM usuario_instrumento WHERE usuario_id = @id", new { id = alta.Id });
        var dispositivos = await _nube.ConsultarComoDueno<int>(
            "SELECT 1 FROM dispositivo WHERE id = @id", new { id = sesionDelMusico.DispositivoId });

        Assert.Single(instrumentos);
        Assert.Single(dispositivos);
    }

    /// <summary>T6.10: quitar el último administrador se rechaza.</summary>
    [Fact]
    public async Task Dar_de_baja_al_ultimo_administrador_se_rechaza()
    {
        await using var servidor = await Levantar();
        var admin = await LoginComoAdministrador(servidor);

        var respuesta = await servidor.Cliente.Con(
            HttpMethod.Post, $"/usuarios/{_nube.Primera.AdministradorId}/baja", admin);

        Assert.Equal(HttpStatusCode.Conflict, respuesta.StatusCode);
    }

    /// <summary>Con dos administradores, dar de baja a uno sí funciona.</summary>
    [Fact]
    public async Task Dar_de_baja_a_un_administrador_que_no_es_el_ultimo_funciona()
    {
        await using var servidor = await Levantar();
        var admin = await LoginComoAdministrador(servidor);

        var segundo = await (await servidor.Cliente.Con(
            HttpMethod.Post, "/usuarios", admin,
            new SolicitudDeAltaDeUsuario("segundo-admin@ejemplo.invalid", "Segundo", "contraseña", [Roles.Administrador])))
            .Content.ReadFromJsonAsync<RespuestaDeUsuario>();

        var respuesta = await servidor.Cliente.Con(HttpMethod.Post, $"/usuarios/{segundo!.Id}/baja", admin);

        Assert.Equal(HttpStatusCode.NoContent, respuesta.StatusCode);
    }

    [Fact]
    public async Task Dar_de_baja_un_usuario_de_otra_iglesia_se_responde_como_inexistente()
    {
        await using var servidor = await Levantar();
        var admin = await LoginComoAdministrador(servidor);

        var respuesta = await servidor.Cliente.Con(
            HttpMethod.Post, $"/usuarios/{_nube.Segunda.UsuarioId}/baja", admin);

        Assert.Equal(HttpStatusCode.NotFound, respuesta.StatusCode);
    }

    private Task<ServidorDeLaNubeDePrueba> Levantar() => ServidorDeLaNubeDePrueba.Levantar(_nube, ParDeClaves.Generar());

    private Task<RespuestaDeSesion> LoginComoAdministrador(ServidorDeLaNubeDePrueba servidor) =>
        AyudasDeSesion.Login(
            servidor, _nube.Primera.AdministradorCorreo, _nube.Primera.AdministradorContrasena,
            dispositivoId: _nube.Primera.AdministradorId);

    // El mismo identificador fijo que siembra 0002_identidad.sql: no hay
    // endpoint de catálogo en esta fase, así que se usa el mismo dato que ya
    // usan las migraciones.
    private static Task<Guid> IdDelPiano() => Task.FromResult(Guid.Parse("01999c1e-0000-7000-8000-000000000001"));
}
