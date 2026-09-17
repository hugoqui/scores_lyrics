using Microsoft.AspNetCore.Mvc.Testing;
using Symphony.Migraciones;
using Symphony.Node.BaseDeDatos;
using Symphony.Node.Configuration;

namespace Symphony.Node.Tests;

/// <summary>
/// Pruebas de arranque (spec R3/R4): el nodo levanta con configuración válida,
/// aplica sus migraciones antes de atender nada (spec R1) y falla, nombrando
/// la variable que falta, con una configuración incompleta.
/// </summary>
[Collection(ConfiguracionDelProceso.Nombre)]
public class StartupTests
{
    [Fact]
    public async Task Arranca_con_configuracion_valida()
    {
        using var nodo = new NodoDePrueba();

        await using var factory = new WebApplicationFactory<Program>();
        using var client = factory.CreateClient();

        var response = await client.GetAsync("/weatherforecast");

        Assert.True(response.IsSuccessStatusCode);
    }

    [Fact]
    public async Task Al_arrancar_deja_aplicadas_las_migraciones_del_nodo()
    {
        using var nodo = new NodoDePrueba();

        await using var factory = new WebApplicationFactory<Program>();
        using var client = factory.CreateClient();
        await client.GetAsync("/weatherforecast");

        // Se compara contra lo que hay en disco, no contra una lista escrita
        // aquí: la propiedad que importa es "no queda ninguna pendiente", y una
        // lista fija obliga a tocar esta prueba en cada migración nueva.
        var enDisco = new EjecutorDeMigraciones(MigracionesDelNodo.CarpetaPorDefecto, DialectoSql.Sqlite)
            .LeerDeDisco()
            .Select(m => m.NombreCompleto);

        Assert.Equal(enDisco, nodo.MigracionesAplicadas());
    }

    [Fact]
    public void Falla_con_configuracion_incompleta_y_nombra_la_variable_faltante()
    {
        using var nodo = new NodoDePrueba();
        nodo.OlvidarConfiguracion();

        var excepcion = Assert.Throws<InvalidOperationException>(
            () => NodeOptions.FromEnvironment("Development"));

        Assert.Contains(NodeOptions.SqlitePathVariable, excepcion.Message);
        Assert.Contains(NodeOptions.CloudUrlVariable, excepcion.Message);
        Assert.Contains(NodeOptions.IglesiaIdVariable, excepcion.Message);
    }
}
