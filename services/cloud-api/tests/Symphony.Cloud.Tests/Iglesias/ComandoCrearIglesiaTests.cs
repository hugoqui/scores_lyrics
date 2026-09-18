using Symphony.Cloud.BaseDeDatos;
using Symphony.Cloud.Configuration;
using Symphony.Cloud.Iglesias;
using Symphony.Cloud.Tests.Autenticacion;
using Symphony.Cloud.Tests.BaseDeDatos;
using Symphony.Cloud.Tests.Usuarios;
using Symphony.Sesiones;

namespace Symphony.Cloud.Tests.Iglesias;

/// <summary>T7.5: el comando deja una iglesia utilizable, con administrador y sin credenciales adivinables.</summary>
public sealed class ComandoCrearIglesiaTests : IClassFixture<NubeDePrueba>
{
    private readonly NubeDePrueba _nube;

    public ComandoCrearIglesiaTests(NubeDePrueba nube) => _nube = nube;

    [Fact]
    public async Task Deja_una_iglesia_utilizable_con_su_administrador()
    {
        var salida = new StringWriter();
        var codigo = await ComandoCrearIglesia.Ejecutar(
            [ComandoCrearIglesia.Nombre, "Iglesia recién creada", "admin@nueva.invalid", "Administradora Nueva"],
            Propietario(), new StringReader("contraseña-inicial-del-alta\n"), salida);

        Assert.Equal(0, codigo);

        var iglesiaId = ExtraerIglesiaId(salida.ToString());

        // Utilizable de verdad: el administrador entra con la contraseña que
        // se le dio, y no antes de que exista una iglesia detrás.
        await using var servidor = await ServidorDeLaNubeDePrueba.Levantar(_nube, ParDeClaves.Generar());
        var sesion = await AyudasDeSesion.Login(servidor, "admin@nueva.invalid", "contraseña-inicial-del-alta");

        Assert.Equal(iglesiaId, sesion.IglesiaId);
        Assert.Equal([Roles.Administrador], sesion.Roles);
    }

    [Fact]
    public async Task Sin_contrasena_no_crea_nada()
    {
        var antes = await ContarIglesias();

        var codigo = await ComandoCrearIglesia.Ejecutar(
            [ComandoCrearIglesia.Nombre, "Iglesia sin contraseña", "sin-contrasena@nueva.invalid", "Nadie"],
            Propietario(), new StringReader("\n"), new StringWriter());

        Assert.Equal(1, codigo);
        Assert.Equal(antes, await ContarIglesias());
    }

    [Fact]
    public async Task Dos_altas_con_la_misma_contrasena_guardan_hashes_distintos()
    {
        await ComandoCrearIglesia.Ejecutar(
            [ComandoCrearIglesia.Nombre, "Iglesia una", "una@duplicada.invalid", "Admin Una"],
            Propietario(), new StringReader("misma-contraseña\n"), new StringWriter());
        await ComandoCrearIglesia.Ejecutar(
            [ComandoCrearIglesia.Nombre, "Iglesia dos", "dos@duplicada.invalid", "Admin Dos"],
            Propietario(), new StringReader("misma-contraseña\n"), new StringWriter());

        var hashes = await _nube.ConsultarComoDueno<string>(
            "SELECT hash_contrasena FROM usuario WHERE correo IN ('una@duplicada.invalid', 'dos@duplicada.invalid')");

        // La sal por usuario (ADR 0016) hace que la misma contraseña nunca deje
        // el mismo hash: no hay ningún valor fijo que adivinar y reconocer.
        Assert.Equal(2, hashes.Count);
        Assert.NotEqual(hashes[0], hashes[1]);
    }

    private AccesoComoPropietario Propietario() => new(new CloudOptions
    {
        PostgresConnectionString = _nube.CadenaDeLaAplicacion,
        PostgresPropietarioConnectionString = _nube.CadenaDelPropietario,
        ClaveDeFirma = ParDeClaves.Generar(),
        Environment = "Development",
    });

    private async Task<int> ContarIglesias() =>
        (await _nube.ConsultarComoDueno<int>("SELECT count(*) FROM iglesia"))[0];

    private static Guid ExtraerIglesiaId(string salida)
    {
        var linea = salida.Split('\n').Single(l => l.StartsWith("SYMPHONY_NODE_IGLESIA_ID=", StringComparison.Ordinal));
        return Guid.Parse(linea["SYMPHONY_NODE_IGLESIA_ID=".Length..].Trim());
    }
}
