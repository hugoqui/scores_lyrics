using System.Net;
using System.Net.Http.Json;
using Symphony.Cloud.Tests.BaseDeDatos;
using Symphony.Sesiones;
using Symphony.Sesiones.Web;

namespace Symphony.Cloud.Tests.Autenticacion;

/// <summary>
/// T5.1, T5.3, T5.5: los endpoints de login, renovación y cierre de sesión de
/// la nube, de punta a punta contra el PostgreSQL efímero ([ADR 0011]).
/// </summary>
public sealed class AutenticacionEndpointsTests : IClassFixture<NubeDePrueba>
{
    private readonly NubeDePrueba _nube;

    public AutenticacionEndpointsTests(NubeDePrueba nube) => _nube = nube;

    [Fact]
    public async Task Login_correcto_devuelve_tokens_y_los_roles_del_usuario()
    {
        await using var servidor = await Levantar();

        var respuesta = await servidor.Cliente.PostAsJsonAsync("/autenticacion/iniciar-sesion", Solicitud(_nube.Primera));

        Assert.Equal(HttpStatusCode.OK, respuesta.StatusCode);
        var cuerpo = await respuesta.Content.ReadFromJsonAsync<RespuestaDeSesion>();
        Assert.NotNull(cuerpo);
        Assert.Equal(_nube.Primera.UsuarioId, cuerpo!.UsuarioId);
        Assert.Equal(_nube.Primera.Id, cuerpo.IglesiaId);
        Assert.Equal(["musico"], cuerpo.Roles);
        Assert.NotEmpty(cuerpo.TokenDeAcceso);
        Assert.NotEmpty(cuerpo.TokenDeRenovacion);
    }

    [Fact]
    public async Task Correo_inexistente_y_contrasena_incorrecta_responden_exactamente_igual()
    {
        await using var servidor = await Levantar();

        var conCorreoInexistente = await servidor.Cliente.PostAsJsonAsync(
            "/autenticacion/iniciar-sesion",
            Solicitud(_nube.Primera) with { Correo = "no-existe@ejemplo.invalid" });

        var conContrasenaIncorrecta = await servidor.Cliente.PostAsJsonAsync(
            "/autenticacion/iniciar-sesion",
            Solicitud(_nube.Primera) with { Contrasena = "la-contraseña-equivocada" });

        Assert.Equal(HttpStatusCode.Unauthorized, conCorreoInexistente.StatusCode);
        Assert.Equal(conCorreoInexistente.StatusCode, conContrasenaIncorrecta.StatusCode);
        Assert.Equal(
            await conCorreoInexistente.Content.ReadAsStringAsync(),
            await conContrasenaIncorrecta.Content.ReadAsStringAsync());
    }

    /// <summary>
    /// El mismo correo en dos iglesias (spec R4) no se puede resolver sin
    /// preguntar cuál: se rechaza como si no existiera, no con un error que
    /// delate la ambigüedad.
    /// </summary>
    [Fact]
    public async Task Un_correo_que_coincide_en_dos_iglesias_se_rechaza_como_invalido()
    {
        await using var servidor = await Levantar();
        const string correoCompartido = "compartido@ejemplo.invalid";
        await _nube.SembrarUsuarioAdicional(_nube.Primera.Id, correoCompartido, "contraseña-de-a");
        await _nube.SembrarUsuarioAdicional(_nube.Segunda.Id, correoCompartido, "contraseña-de-b");

        var respuesta = await servidor.Cliente.PostAsJsonAsync(
            "/autenticacion/iniciar-sesion",
            new SolicitudDeLogin(correoCompartido, "contraseña-de-a", Guid.CreateVersion7(), "Teléfono", TiposDeDispositivo.Movil));

        Assert.Equal(HttpStatusCode.Unauthorized, respuesta.StatusCode);
    }

    [Fact]
    public async Task Un_usuario_dado_de_baja_no_entra_aunque_acierte_la_contrasena()
    {
        await using var servidor = await Levantar();
        var (correo, contrasena) = await _nube.SembrarUsuarioAdicional(
            _nube.Primera.Id, "de-baja@ejemplo.invalid", "contraseña-correcta", activo: false);

        var respuesta = await servidor.Cliente.PostAsJsonAsync(
            "/autenticacion/iniciar-sesion",
            new SolicitudDeLogin(correo, contrasena, Guid.CreateVersion7(), "Teléfono", TiposDeDispositivo.Movil));

        Assert.Equal(HttpStatusCode.Forbidden, respuesta.StatusCode);
    }

    [Fact]
    public async Task Renovar_con_un_token_de_acceso_no_funciona()
    {
        await using var servidor = await Levantar();
        var sesion = await IniciarSesion(servidor, _nube.Primera);

        var respuesta = await servidor.Cliente.PostAsJsonAsync(
            "/autenticacion/renovar", new SolicitudDeRenovacion(sesion.TokenDeAcceso));

        Assert.Equal(HttpStatusCode.Unauthorized, respuesta.StatusCode);
    }

    [Fact]
    public async Task Renovar_con_el_token_de_renovacion_da_un_acceso_nuevo()
    {
        await using var servidor = await Levantar();
        var sesion = await IniciarSesion(servidor, _nube.Primera);

        var respuesta = await servidor.Cliente.PostAsJsonAsync(
            "/autenticacion/renovar", new SolicitudDeRenovacion(sesion.TokenDeRenovacion));

        Assert.Equal(HttpStatusCode.OK, respuesta.StatusCode);
        var cuerpo = await respuesta.Content.ReadFromJsonAsync<RespuestaDeRenovacion>();
        Assert.NotEqual(sesion.TokenDeAcceso, cuerpo!.TokenDeAcceso);
    }

    /// <summary>T5.3: cerrar sesión revoca la renovación, no solo el acceso.</summary>
    [Fact]
    public async Task Cerrar_sesion_impide_renovar_despues()
    {
        await using var servidor = await Levantar();
        var sesion = await IniciarSesion(servidor, _nube.Primera);

        var cierre = await servidor.Cliente.PostAsJsonAsync(
            "/autenticacion/cerrar-sesion", new SolicitudDeCierre(sesion.TokenDeRenovacion));
        Assert.Equal(HttpStatusCode.NoContent, cierre.StatusCode);

        var intentoDeRenovar = await servidor.Cliente.PostAsJsonAsync(
            "/autenticacion/renovar", new SolicitudDeRenovacion(sesion.TokenDeRenovacion));

        Assert.Equal(HttpStatusCode.Unauthorized, intentoDeRenovar.StatusCode);
    }

    /// <summary>Cerrar una sesión ya cerrada no es un error: es idempotente a propósito.</summary>
    [Fact]
    public async Task Cerrar_sesion_dos_veces_no_falla()
    {
        await using var servidor = await Levantar();
        var sesion = await IniciarSesion(servidor, _nube.Primera);
        var solicitud = new SolicitudDeCierre(sesion.TokenDeRenovacion);

        await servidor.Cliente.PostAsJsonAsync("/autenticacion/cerrar-sesion", solicitud);
        var segundoCierre = await servidor.Cliente.PostAsJsonAsync("/autenticacion/cerrar-sesion", solicitud);

        Assert.Equal(HttpStatusCode.NoContent, segundoCierre.StatusCode);
    }

    /// <summary>
    /// T5.5 en la práctica: el identificador de dispositivo que trajo el
    /// cliente ya es de un usuario de la <b>otra</b> iglesia. La política deja
    /// esa fila invisible, así que el conflicto solo se descubre al insertar —
    /// y la respuesta no dice nada de otra iglesia, ni distingue este caso del
    /// de un dispositivo ya usado por otra persona en la propia.
    /// </summary>
    [Fact]
    public async Task Un_dispositivo_ya_usado_en_otra_iglesia_no_se_puede_reclamar()
    {
        await using var servidor = await Levantar();

        var deLaOtraIglesia = await IniciarSesion(servidor, _nube.Segunda);

        var respuesta = await servidor.Cliente.PostAsJsonAsync(
            "/autenticacion/iniciar-sesion",
            Solicitud(_nube.Primera) with { DispositivoId = deLaOtraIglesia.DispositivoId });

        Assert.Equal(HttpStatusCode.Conflict, respuesta.StatusCode);
    }

    private Task<ServidorDeLaNubeDePrueba> Levantar() => ServidorDeLaNubeDePrueba.Levantar(_nube, ParDeClaves.Generar());

    private static SolicitudDeLogin Solicitud(IglesiaSembrada iglesia) =>
        new(iglesia.Correo, iglesia.Contrasena, Guid.CreateVersion7(), "Teléfono de prueba", TiposDeDispositivo.Movil);

    private static async Task<RespuestaDeSesion> IniciarSesion(ServidorDeLaNubeDePrueba servidor, IglesiaSembrada iglesia)
    {
        var respuesta = await servidor.Cliente.PostAsJsonAsync("/autenticacion/iniciar-sesion", Solicitud(iglesia));
        respuesta.EnsureSuccessStatusCode();
        return (await respuesta.Content.ReadFromJsonAsync<RespuestaDeSesion>())!;
    }
}
