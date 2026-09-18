using System.Net;
using Symphony.Cloud.Tests.Autenticacion;
using Symphony.Cloud.Tests.BaseDeDatos;
using Symphony.Sesiones;
using Symphony.Sesiones.Web;

namespace Symphony.Cloud.Tests.Usuarios;

/// <summary>
/// T6.4: asignar y quitar instrumentos a un músico.
///
/// Cada prueba siembra su propio usuario en vez de compartir
/// <c>_nube.Primera</c>: son operaciones que mutan la misma tabla, y las
/// pruebas de esta clase corren contra el mismo Postgres ([ADR 0011]).
/// </summary>
public sealed class EndpointsDeInstrumentosTests : IClassFixture<NubeDePrueba>
{
    // Los mismos identificadores fijos que siembra 0002_identidad.sql.
    private static readonly Guid _piano = Guid.Parse("01999c1e-0000-7000-8000-000000000001");
    private static readonly Guid _violin2 = Guid.Parse("01999c1e-0000-7000-8000-000000000003");

    private readonly NubeDePrueba _nube;

    public EndpointsDeInstrumentosTests(NubeDePrueba nube) => _nube = nube;

    [Fact]
    public async Task Un_administrador_asigna_un_instrumento_a_un_musico()
    {
        await using var servidor = await Levantar();
        var admin = await LoginComoAdministrador(servidor);
        var musicoId = await SembrarMusico("con-violin@ejemplo.invalid");

        var respuesta = await servidor.Cliente.Con(HttpMethod.Post, $"/usuarios/{musicoId}/instrumentos/{_violin2}", admin);

        Assert.Equal(HttpStatusCode.NoContent, respuesta.StatusCode);
        var asignados = await _nube.ConsultarComoDueno<Guid>(
            "SELECT instrumento_id FROM usuario_instrumento WHERE usuario_id = @id", new { id = musicoId });
        Assert.Equal([_violin2], asignados);
    }

    [Fact]
    public async Task Un_musico_puede_tener_varios_instrumentos_a_la_vez()
    {
        await using var servidor = await Levantar();
        var admin = await LoginComoAdministrador(servidor);
        var musicoId = await SembrarMusico("con-dos-instrumentos@ejemplo.invalid");

        await servidor.Cliente.Con(HttpMethod.Post, $"/usuarios/{musicoId}/instrumentos/{_piano}", admin);
        await servidor.Cliente.Con(HttpMethod.Post, $"/usuarios/{musicoId}/instrumentos/{_violin2}", admin);

        var asignados = await _nube.ConsultarComoDueno<Guid>(
            "SELECT instrumento_id FROM usuario_instrumento WHERE usuario_id = @id ORDER BY instrumento_id",
            new { id = musicoId });
        Assert.Equal([_piano, _violin2], asignados);
    }

    [Fact]
    public async Task Asignar_el_mismo_instrumento_dos_veces_no_falla()
    {
        await using var servidor = await Levantar();
        var admin = await LoginComoAdministrador(servidor);
        var musicoId = await SembrarMusico("repetido@ejemplo.invalid");

        await servidor.Cliente.Con(HttpMethod.Post, $"/usuarios/{musicoId}/instrumentos/{_piano}", admin);
        var segunda = await servidor.Cliente.Con(HttpMethod.Post, $"/usuarios/{musicoId}/instrumentos/{_piano}", admin);

        Assert.Equal(HttpStatusCode.NoContent, segunda.StatusCode);
    }

    [Fact]
    public async Task Quitar_un_instrumento_que_no_tenia_no_falla()
    {
        await using var servidor = await Levantar();
        var admin = await LoginComoAdministrador(servidor);
        var musicoId = await SembrarMusico("sin-nada@ejemplo.invalid");

        var respuesta = await servidor.Cliente.Con(HttpMethod.Delete, $"/usuarios/{musicoId}/instrumentos/{_violin2}", admin);

        Assert.Equal(HttpStatusCode.NoContent, respuesta.StatusCode);
    }

    [Fact]
    public async Task Quitar_un_instrumento_lo_saca_de_la_lista()
    {
        await using var servidor = await Levantar();
        var admin = await LoginComoAdministrador(servidor);
        var musicoId = await SembrarMusico("para-quitar@ejemplo.invalid");
        await servidor.Cliente.Con(HttpMethod.Post, $"/usuarios/{musicoId}/instrumentos/{_piano}", admin);

        await servidor.Cliente.Con(HttpMethod.Delete, $"/usuarios/{musicoId}/instrumentos/{_piano}", admin);

        var asignados = await _nube.ConsultarComoDueno<Guid>(
            "SELECT instrumento_id FROM usuario_instrumento WHERE usuario_id = @id", new { id = musicoId });
        Assert.Empty(asignados);
    }

    [Fact]
    public async Task Asignar_a_un_usuario_de_otra_iglesia_se_responde_como_inexistente()
    {
        await using var servidor = await Levantar();
        var admin = await LoginComoAdministrador(servidor);

        var respuesta = await servidor.Cliente.Con(
            HttpMethod.Post, $"/usuarios/{_nube.Segunda.UsuarioId}/instrumentos/{_piano}", admin);

        Assert.Equal(HttpStatusCode.NotFound, respuesta.StatusCode);
    }

    [Fact]
    public async Task Un_musico_no_puede_asignarse_instrumentos()
    {
        await using var servidor = await Levantar();
        var musico = await AyudasDeSesion.Login(servidor, _nube.Primera.Correo, _nube.Primera.Contrasena);

        var respuesta = await servidor.Cliente.Con(
            HttpMethod.Post, $"/usuarios/{_nube.Primera.UsuarioId}/instrumentos/{_violin2}", musico);

        Assert.Equal(HttpStatusCode.Forbidden, respuesta.StatusCode);
    }

    private Task<ServidorDeLaNubeDePrueba> Levantar() => ServidorDeLaNubeDePrueba.Levantar(_nube, ParDeClaves.Generar());

    private Task<RespuestaDeSesion> LoginComoAdministrador(ServidorDeLaNubeDePrueba servidor) =>
        AyudasDeSesion.Login(
            servidor, _nube.Primera.AdministradorCorreo, _nube.Primera.AdministradorContrasena,
            dispositivoId: _nube.Primera.AdministradorId);

    private async Task<Guid> SembrarMusico(string correo)
    {
        var (_, _) = await _nube.SembrarUsuarioAdicional(_nube.Primera.Id, correo, "contraseña-de-prueba");
        var id = await _nube.ConsultarComoDueno<Guid>("SELECT id FROM usuario WHERE correo = @correo", new { correo });
        return id[0];
    }
}
