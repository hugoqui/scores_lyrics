using Microsoft.AspNetCore.Mvc.Testing;
using Symphony.Node.Configuration;

namespace Symphony.Node.Tests;

/// <summary>
/// Pruebas de arranque (spec R3/R4): el nodo levanta con configuración válida
/// y falla, nombrando la variable que falta, con una incompleta.
/// </summary>
public class StartupTests
{
    [Fact]
    public async Task Arranca_con_configuracion_valida()
    {
        Environment.SetEnvironmentVariable(NodeOptions.SqlitePathVariable, "./nodo-prueba.sqlite");
        Environment.SetEnvironmentVariable(NodeOptions.CloudUrlVariable, "https://nube.prueba.local");
        try
        {
            await using var factory = new WebApplicationFactory<Program>();
            using var client = factory.CreateClient();

            var response = await client.GetAsync("/weatherforecast");

            Assert.True(response.IsSuccessStatusCode);
        }
        finally
        {
            Environment.SetEnvironmentVariable(NodeOptions.SqlitePathVariable, null);
            Environment.SetEnvironmentVariable(NodeOptions.CloudUrlVariable, null);
        }
    }

    [Fact]
    public void Falla_con_configuracion_incompleta_y_nombra_la_variable_faltante()
    {
        Environment.SetEnvironmentVariable(NodeOptions.SqlitePathVariable, null);
        Environment.SetEnvironmentVariable(NodeOptions.CloudUrlVariable, null);

        var excepcion = Assert.Throws<InvalidOperationException>(
            () => NodeOptions.FromEnvironment("Development"));

        Assert.Contains(NodeOptions.SqlitePathVariable, excepcion.Message);
        Assert.Contains(NodeOptions.CloudUrlVariable, excepcion.Message);
    }
}
