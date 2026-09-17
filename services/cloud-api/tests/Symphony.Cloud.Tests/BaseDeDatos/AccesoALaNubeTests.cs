using Npgsql;
using Symphony.Cloud.BaseDeDatos;
using Symphony.Cloud.Configuration;

namespace Symphony.Cloud.Tests.BaseDeDatos;

/// <summary>
/// La puerta única es lo que sostiene la fase 1: si se pudiera obtener una
/// conexión sin pasar por ella, la row-level security dejaría de proteger nada
/// ([ADR 0017]).
/// </summary>
public sealed class AccesoALaNubeTests : IClassFixture<NubeDePrueba>
{
    private readonly NubeDePrueba _nube;

    public AccesoALaNubeTests(NubeDePrueba nube) => _nube = nube;

    [Fact]
    public async Task Pedir_trabajo_sin_iglesia_falla_en_vez_de_consultar_sin_filtrar()
    {
        var acceso = Acceso();

        // Lo que no puede pasar es que devuelva algo utilizable: una unidad de
        // trabajo sin iglesia sería una consulta sin filtrar.
        await Assert.ThrowsAsync<ArgumentException>(
            () => acceso.EnLaIglesia(Guid.Empty, unidad => unidad.Consultar<int>("SELECT 1")));
    }

    [Fact]
    public async Task La_unidad_de_trabajo_llega_con_su_iglesia_ya_fijada()
    {
        var acceso = Acceso();

        var nombres = await acceso.EnLaIglesia(
            _nube.Primera.Id,
            unidad => unidad.Consultar<string>("SELECT nombre FROM iglesia"));

        // Sin WHERE: lo que filtra es la política, no la consulta.
        Assert.Equal([_nube.Primera.Nombre], nombres);
    }

    [Fact]
    public async Task Dos_unidades_de_trabajo_seguidas_no_heredan_la_iglesia_de_la_anterior()
    {
        // Con una sola conexión en el pozo, la segunda unidad de trabajo usa
        // por fuerza la misma conexión física que la primera. Si la iglesia se
        // fijara para la sesión en vez de para la transacción, aquí se vería la
        // iglesia equivocada: es el costo que ADR 0015 aceptó y contuvo en un
        // solo sitio.
        var acceso = Acceso(unaSolaConexion: true);

        var deLaPrimera = await acceso.EnLaIglesia(
            _nube.Primera.Id,
            unidad => unidad.Consultar<string>("SELECT nombre FROM iglesia"));

        var deLaSegunda = await acceso.EnLaIglesia(
            _nube.Segunda.Id,
            unidad => unidad.Consultar<string>("SELECT nombre FROM iglesia"));

        Assert.Equal([_nube.Primera.Nombre], deLaPrimera);
        Assert.Equal([_nube.Segunda.Nombre], deLaSegunda);
    }

    [Fact]
    public async Task La_iglesia_muere_con_la_transaccion_y_no_con_la_conexion()
    {
        // Esta prueba desactiva a propósito la limpieza que Npgsql hace al
        // devolver una conexión al pozo. Con la limpieza puesta, fijar la
        // iglesia para toda la sesión en vez de para la transacción parecería
        // funcionar: el fallo quedaría tapado por una cortesía del cliente, no
        // por el diseño. Sin ella se ve lo que de verdad sostiene el
        // aislamiento, que es que la iglesia caduca con la transacción.
        var cadena = CadenaDeLaAplicacion(unaSolaConexion: true, sinLimpiarAlCerrar: true);
        var acceso = new AccesoALaNube(new CloudOptions
        {
            PostgresConnectionString = cadena,
            Environment = "Development",
        });

        await acceso.EnLaIglesia(
            _nube.Primera.Id,
            unidad => unidad.Consultar<string>("SELECT nombre FROM iglesia"));

        // La misma conexión física, ahora fuera de la puerta.
        await using var conexion = new NpgsqlConnection(cadena);
        await conexion.OpenAsync();

        await using var comando = new NpgsqlCommand("SELECT current_setting('app.iglesia_id', TRUE)", conexion);
        var fijada = await comando.ExecuteScalarAsync();

        Assert.True(
            fijada is null or DBNull || (string)fijada == string.Empty,
            $"La conexión volvió al pozo con la iglesia '{fijada}' puesta. La siguiente unidad de " +
            "trabajo que olvide fijarla consultaría con la iglesia de la anterior.");
    }

    private AccesoALaNube Acceso(bool unaSolaConexion = false) =>
        new(new CloudOptions
        {
            PostgresConnectionString = CadenaDeLaAplicacion(unaSolaConexion),
            Environment = "Development",
        });

    private string CadenaDeLaAplicacion(bool unaSolaConexion, bool sinLimpiarAlCerrar = false)
    {
        var constructor = new NpgsqlConnectionStringBuilder(_nube.CadenaDeLaAplicacion)
        {
            Pooling = true,
            NoResetOnClose = sinLimpiarAlCerrar,
        };

        if (unaSolaConexion)
        {
            constructor.MinPoolSize = 1;
            constructor.MaxPoolSize = 1;
        }

        return constructor.ConnectionString;
    }
}
