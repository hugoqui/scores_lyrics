using System.Net;
using System.Net.Http.Json;
using System.Text;
using Symphony.Cloud.Tests.Autenticacion;
using Symphony.Cloud.Tests.BaseDeDatos;
using Symphony.Cloud.Tests.Usuarios;
using Symphony.Cloud.Usuarios;
using Symphony.Sesiones;
using Symphony.Sesiones.Web;

namespace Symphony.Cloud.Tests.Aislamiento;

/// <summary>
/// T8.2: <b>recorrer todas las operaciones de la nube intentando cruzarse de
/// iglesia</b>, con los identificadores correctos de la otra en la mano (spec
/// R10).
///
/// <para>
/// Quien ataca aquí no es un desconocido tanteando: es el administrador de la
/// primera iglesia, con sesión legítima, usando identificadores reales de la
/// segunda. Cada prueba comprueba dos cosas, y la segunda es la que de verdad
/// importa: qué respondió el endpoint, y que <b>la fila ajena siguió como
/// estaba</b>. Un 404 sobre un borrado que sí ocurrió sería el peor resultado
/// posible, y sin la segunda comprobación pasaría por bueno.
/// </para>
/// <para>
/// Las dos guardias de arriba son las que mantienen esto honesto con el tiempo:
/// un endpoint nuevo sin intento de cruce, o sin sesión exigida, rompe la
/// prueba en vez de pasar desapercibido.
/// </para>
/// </summary>
public sealed class CruceDeIglesiasEnLaNubeTests : IClassFixture<NubeDePrueba>
{
    private static readonly Guid _violin2 = Guid.Parse("01999c1e-0000-7000-8000-000000000003");

    /// <summary>
    /// Toda ruta de la nube, con el intento de cruce que la recorre en este
    /// archivo. Se compara contra la tabla de rutas del servidor: añadir un
    /// endpoint y no añadirlo aquí deja la prueba en rojo, que es justo lo que
    /// se quiere —lo contrario es una fase 8 que caduca en silencio.
    /// </summary>
    private static readonly IReadOnlyList<string> _rutasConIntentoDeCruce =
    [
        "DELETE /usuarios/{id:guid}/instrumentos/{instrumentoId:guid}",
        "GET /dispositivos",
        "POST /autenticacion/cerrar-sesion",
        "POST /autenticacion/iniciar-sesion",
        "POST /autenticacion/renovar",
        "POST /dispositivos/{id:guid}/revocar",
        "POST /usuarios",
        "POST /usuarios/{id:guid}/baja",
        "POST /usuarios/{id:guid}/instrumentos/{instrumentoId:guid}",
        "POST /usuarios/{id:guid}/readmitir",
    ];

    /// <summary>
    /// Las tres que atienden sin sesión porque son las que la reparten. Toda
    /// otra ruta tiene que rechazar a quien no trae una.
    /// </summary>
    private static readonly IReadOnlyList<string> _rutasSinSesion =
    [
        "POST /autenticacion/cerrar-sesion",
        "POST /autenticacion/iniciar-sesion",
        "POST /autenticacion/renovar",
    ];

    private readonly NubeDePrueba _nube;

    public CruceDeIglesiasEnLaNubeTests(NubeDePrueba nube) => _nube = nube;

    [Fact]
    public async Task Toda_ruta_de_la_nube_tiene_su_intento_de_cruce()
    {
        await using var servidor = await Levantar();

        Assert.Equal(_rutasConIntentoDeCruce, servidor.Rutas);
    }

    [Fact]
    public async Task Ninguna_ruta_sirve_datos_sin_sesion_firmada()
    {
        await using var servidor = await Levantar();
        var sinRechazar = new List<string>();

        foreach (var ruta in servidor.Rutas.Except(_rutasSinSesion, StringComparer.Ordinal))
        {
            var respuesta = await servidor.Cliente.SendAsync(SinToken(ruta));
            if (respuesta.StatusCode != HttpStatusCode.Unauthorized)
            {
                sinRechazar.Add($"{ruta} respondió {(int)respuesta.StatusCode}");
            }
        }

        Assert.True(
            sinRechazar.Count == 0,
            "Una ruta que atiende sin sesión no tiene de dónde sacar la iglesia (spec R3). " +
            $"Estas no pidieron sesión: {string.Join("; ", sinRechazar)}");
    }

    [Fact]
    public async Task Dar_de_alta_con_el_correo_de_otra_iglesia_no_toca_a_esa_persona()
    {
        await using var servidor = await Levantar();
        var admin = await LoginComoAdministradorDeLaPrimera(servidor);

        var respuesta = await servidor.Cliente.Con(
            HttpMethod.Post, "/usuarios", admin,
            new SolicitudDeAltaDeUsuario(_nube.Segunda.Correo, "Homónima", "contraseña-nueva", [Roles.Musico]));

        // El mismo correo en dos iglesias son dos personas distintas (spec R4):
        // el alta es legítima. Lo que se comprueba es dónde cae.
        Assert.Equal(HttpStatusCode.OK, respuesta.StatusCode);
        var creado = await respuesta.Content.ReadFromJsonAsync<RespuestaDeUsuario>();

        var iglesiaDelNuevo = await _nube.ConsultarComoDueno<Guid>(
            "SELECT iglesia_id FROM usuario WHERE id = @id", new { id = creado!.Id });
        Assert.Equal([_nube.Primera.Id], iglesiaDelNuevo);

        // Y en la otra iglesia ese correo sigue siendo una sola persona, la suya.
        var enLaSegunda = await _nube.ConsultarComoDueno<Guid>(
            "SELECT id FROM usuario WHERE iglesia_id = @iglesia AND correo = @correo",
            new { iglesia = _nube.Segunda.Id, correo = _nube.Segunda.Correo });
        Assert.Equal([_nube.Segunda.UsuarioId], enLaSegunda);
    }

    [Fact]
    public async Task Dar_de_baja_a_un_usuario_de_otra_iglesia_no_lo_toca()
    {
        await using var servidor = await Levantar();
        var admin = await LoginComoAdministradorDeLaPrimera(servidor);

        var respuesta = await servidor.Cliente.Con(
            HttpMethod.Post, $"/usuarios/{_nube.Segunda.UsuarioId}/baja", admin);

        Assert.Equal(HttpStatusCode.NotFound, respuesta.StatusCode);
        Assert.Equal(["activo"], await EstadoDe(_nube.Segunda.UsuarioId));
    }

    [Fact]
    public async Task Readmitir_a_un_usuario_de_otra_iglesia_no_lo_devuelve()
    {
        await using var servidor = await Levantar();
        var admin = await LoginComoAdministradorDeLaPrimera(servidor);
        var ajenoDeBaja = await SembrarDadoDeBajaEnLaSegunda();

        var respuesta = await servidor.Cliente.Con(HttpMethod.Post, $"/usuarios/{ajenoDeBaja}/readmitir", admin);

        Assert.Equal(HttpStatusCode.NotFound, respuesta.StatusCode);
        Assert.Equal(["dado_de_baja"], await EstadoDe(ajenoDeBaja));
    }

    [Fact]
    public async Task Asignar_un_instrumento_a_un_musico_de_otra_iglesia_no_le_añade_nada()
    {
        await using var servidor = await Levantar();
        var admin = await LoginComoAdministradorDeLaPrimera(servidor);

        var respuesta = await servidor.Cliente.Con(
            HttpMethod.Post, $"/usuarios/{_nube.Segunda.UsuarioId}/instrumentos/{_violin2}", admin);

        Assert.Equal(HttpStatusCode.NotFound, respuesta.StatusCode);
        Assert.Equal(
            [NubeDePrueba.Piano, NubeDePrueba.Flauta1],
            await InstrumentosDe(_nube.Segunda.UsuarioId));
    }

    /// <summary>
    /// El intento que más daño haría: un borrado que cruza de iglesia no deja
    /// un mensaje raro, deja a un músico sin su papel el domingo.
    /// </summary>
    [Fact]
    public async Task Quitarle_un_instrumento_a_un_musico_de_otra_iglesia_no_se_lo_quita()
    {
        await using var servidor = await Levantar();
        var admin = await LoginComoAdministradorDeLaPrimera(servidor);

        var respuesta = await servidor.Cliente.Con(
            HttpMethod.Delete, $"/usuarios/{_nube.Segunda.UsuarioId}/instrumentos/{NubeDePrueba.Piano}", admin);

        Assert.Equal(HttpStatusCode.NotFound, respuesta.StatusCode);
        Assert.Equal(
            [NubeDePrueba.Piano, NubeDePrueba.Flauta1],
            await InstrumentosDe(_nube.Segunda.UsuarioId));
    }

    [Fact]
    public async Task Listar_dispositivos_no_trae_ninguno_de_la_otra_iglesia()
    {
        await using var servidor = await Levantar();
        var admin = await LoginComoAdministradorDeLaPrimera(servidor);

        var respuesta = await servidor.Cliente.Con(HttpMethod.Get, "/dispositivos", admin);
        var dispositivos = await respuesta.Content.ReadFromJsonAsync<List<RespuestaDeDispositivo>>();

        Assert.Equal(HttpStatusCode.OK, respuesta.StatusCode);
        Assert.DoesNotContain(dispositivos!, d => d.Id == _nube.Segunda.DispositivoId);
        Assert.DoesNotContain(dispositivos!, d => d.Id == _nube.Segunda.PantallaId);
        Assert.DoesNotContain(dispositivos!, d => d.Id == _nube.Segunda.DispositivoRevocadoId);

        // La contraparte: si el listado viniera vacío por cualquier motivo, lo
        // de arriba pasaría sin probar nada.
        Assert.Contains(dispositivos!, d => d.Id == _nube.Primera.PantallaId);
        Assert.Contains(dispositivos!, d => d.Id == _nube.Primera.DispositivoRevocadoId);
    }

    /// <summary>
    /// Contra la pantalla ajena a propósito: no tiene dueño, así que es la fila
    /// que se le escaparía a quien filtrara por usuario creyendo que filtra por
    /// iglesia.
    /// </summary>
    [Fact]
    public async Task Revocar_un_dispositivo_de_otra_iglesia_no_lo_revoca()
    {
        await using var servidor = await Levantar();
        var admin = await LoginComoAdministradorDeLaPrimera(servidor);

        var respuesta = await servidor.Cliente.Con(
            HttpMethod.Post, $"/dispositivos/{_nube.Segunda.PantallaId}/revocar", admin);

        Assert.Equal(HttpStatusCode.NotFound, respuesta.StatusCode);
        var revocado = await _nube.ConsultarComoDueno<DateTime?>(
            "SELECT revocado_en FROM dispositivo WHERE id = @id", new { id = _nube.Segunda.PantallaId });
        Assert.Null(Assert.Single(revocado));
    }

    [Fact]
    public async Task Una_sesion_legitima_de_la_otra_iglesia_solo_alcanza_lo_suyo()
    {
        await using var servidor = await Levantar();
        var deLaSegunda = await AyudasDeSesion.Login(
            servidor, _nube.Segunda.AdministradorCorreo, _nube.Segunda.AdministradorContrasena,
            dispositivoId: _nube.Segunda.AdministradorId);

        Assert.Equal(_nube.Segunda.Id, deLaSegunda.IglesiaId);

        var respuesta = await servidor.Cliente.Con(HttpMethod.Get, "/dispositivos", deLaSegunda);
        var dispositivos = await respuesta.Content.ReadFromJsonAsync<List<RespuestaDeDispositivo>>();

        Assert.DoesNotContain(dispositivos!, d => d.Id == _nube.Primera.DispositivoId);
        Assert.DoesNotContain(dispositivos!, d => d.Id == _nube.Primera.PantallaId);
        Assert.Contains(dispositivos!, d => d.Id == _nube.Segunda.DispositivoId);
    }

    [Fact]
    public async Task Renovar_el_token_de_otra_iglesia_sigue_dando_acceso_a_esa_iglesia_y_no_a_esta()
    {
        var claves = ParDeClaves.Generar();
        await using var servidor = await ServidorDeLaNubeDePrueba.Levantar(_nube, claves);
        var deLaSegunda = await AyudasDeSesion.Login(
            servidor, _nube.Segunda.AdministradorCorreo, _nube.Segunda.AdministradorContrasena,
            dispositivoId: _nube.Segunda.AdministradorId);

        var respuesta = await servidor.Cliente.PostAsJsonAsync(
            "/autenticacion/renovar", new SolicitudDeRenovacion(deLaSegunda.TokenDeRenovacion));

        // Renovar un token propio es legítimo; lo que no puede pasar es que la
        // renovación devuelva una sesión de otra congregación.
        Assert.Equal(HttpStatusCode.OK, respuesta.StatusCode);
        var renovada = await respuesta.Content.ReadFromJsonAsync<RespuestaDeRenovacion>();
        var sesion = VerificadorDeSesiones.ParaLaNube([claves.ClavePublica])
            .Verificar(renovada!.TokenDeAcceso).Sesion;

        Assert.Equal(_nube.Segunda.Id, sesion!.IglesiaId);
    }

    [Fact]
    public async Task Cerrar_la_sesion_de_una_iglesia_no_cierra_las_de_la_otra()
    {
        await using var servidor = await Levantar();
        var deLaPrimera = await LoginComoAdministradorDeLaPrimera(servidor);
        var deLaSegunda = await AyudasDeSesion.Login(
            servidor, _nube.Segunda.AdministradorCorreo, _nube.Segunda.AdministradorContrasena,
            dispositivoId: _nube.Segunda.AdministradorId);

        var cierre = await servidor.Cliente.PostAsJsonAsync(
            "/autenticacion/cerrar-sesion", new SolicitudDeCierre(deLaSegunda.TokenDeRenovacion));
        Assert.Equal(HttpStatusCode.NoContent, cierre.StatusCode);

        // La sesión sembrada de la primera sigue viva...
        var revocada = await _nube.ConsultarComoDueno<DateTime?>(
            "SELECT revocada_en FROM sesion WHERE id = @id", new { id = _nube.Primera.SesionId });
        Assert.Null(Assert.Single(revocada));

        // ...y su administrador sigue entrando.
        var renovacion = await servidor.Cliente.PostAsJsonAsync(
            "/autenticacion/renovar", new SolicitudDeRenovacion(deLaPrimera.TokenDeRenovacion));
        Assert.Equal(HttpStatusCode.OK, renovacion.StatusCode);
    }

    /// <summary>
    /// Un token perfectamente firmado, con los datos correctos de su iglesia,
    /// pero firmado por el nodo de esa congregación ([ADR 0016]). La nube solo
    /// conoce su propia clave: repartir las de los nodos es del módulo 008, y
    /// hasta entonces —y también después— esto no puede abrir nada.
    /// </summary>
    [Fact]
    public async Task Un_token_firmado_por_otra_clave_no_abre_ninguna_puerta()
    {
        await using var servidor = await Levantar();
        var otroEmisor = new EmisorDeSesiones(ParDeClaves.Generar(), Emisor.Nodo);
        var (token, _) = otroEmisor.Acceso(
            _nube.Segunda.AdministradorId, _nube.Segunda.Id, [Roles.Administrador], _nube.Segunda.DispositivoId);

        var peticion = new HttpRequestMessage(HttpMethod.Get, "/dispositivos");
        peticion.Headers.Add("Authorization", $"Bearer {token}");
        var respuesta = await servidor.Cliente.SendAsync(peticion);

        Assert.Equal(HttpStatusCode.Unauthorized, respuesta.StatusCode);
    }

    private Task<ServidorDeLaNubeDePrueba> Levantar() =>
        ServidorDeLaNubeDePrueba.Levantar(_nube, ParDeClaves.Generar());

    private Task<RespuestaDeSesion> LoginComoAdministradorDeLaPrimera(ServidorDeLaNubeDePrueba servidor) =>
        AyudasDeSesion.Login(
            servidor, _nube.Primera.AdministradorCorreo, _nube.Primera.AdministradorContrasena,
            dispositivoId: _nube.Primera.AdministradorId);

    private Task<IReadOnlyList<string>> EstadoDe(Guid usuarioId) =>
        _nube.ConsultarComoDueno<string>("SELECT estado FROM usuario WHERE id = @id", new { id = usuarioId });

    private Task<IReadOnlyList<Guid>> InstrumentosDe(Guid usuarioId) =>
        _nube.ConsultarComoDueno<Guid>(
            "SELECT instrumento_id FROM usuario_instrumento WHERE usuario_id = @id ORDER BY instrumento_id",
            new { id = usuarioId });

    private async Task<Guid> SembrarDadoDeBajaEnLaSegunda()
    {
        var correo = $"ajeno-de-baja-{Guid.NewGuid():N}@ejemplo.invalid";
        await _nube.SembrarUsuarioAdicional(_nube.Segunda.Id, correo, "contraseña-de-prueba", activo: false);

        var ids = await _nube.ConsultarComoDueno<Guid>(
            "SELECT id FROM usuario WHERE iglesia_id = @iglesia AND correo = @correo",
            new { iglesia = _nube.Segunda.Id, correo });

        return Assert.Single(ids);
    }

    /// <summary>
    /// La misma ruta, sin cabecera de sesión y con los huecos rellenos con
    /// identificadores válidos. El cuerpo vacío basta: el filtro de autorización
    /// corre después de enlazar los parámetros, así que sin cuerpo la respuesta
    /// sería un 400 de enlace y no diría nada sobre la sesión.
    /// </summary>
    private static HttpRequestMessage SinToken(string ruta)
    {
        var partes = ruta.Split(' ', 2);
        var metodo = new HttpMethod(partes[0].Split(',')[0]);
        var plantilla = partes[1];

        var camino = new StringBuilder();
        foreach (var segmento in plantilla.Split('/'))
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

        return peticion;
    }
}
