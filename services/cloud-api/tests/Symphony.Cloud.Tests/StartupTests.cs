using Microsoft.AspNetCore.Mvc.Testing;
using Symphony.Cloud.Configuration;

namespace Symphony.Cloud.Tests;

/// <summary>
/// Pruebas de arranque (spec R3/R4): la nube levanta con configuración válida
/// y falla, nombrando la variable que falta, con una incompleta.
/// </summary>
public class StartupTests
{
    [Fact]
    public async Task Arranca_con_configuracion_valida()
    {
        Environment.SetEnvironmentVariable(
            CloudOptions.PostgresConnectionStringVariable,
            "Host=localhost;Database=symphony_prueba;Username=prueba;Password=prueba");
        try
        {
            await using var factory = new WebApplicationFactory<Program>();
            using var client = factory.CreateClient();

            var response = await client.GetAsync("/weatherforecast");

            Assert.True(response.IsSuccessStatusCode);
        }
        finally
        {
            Environment.SetEnvironmentVariable(CloudOptions.PostgresConnectionStringVariable, null);
        }
    }

    [Fact]
    public void Falla_con_configuracion_incompleta_y_nombra_la_variable_faltante()
    {
        Environment.SetEnvironmentVariable(CloudOptions.PostgresConnectionStringVariable, null);

        var excepcion = Assert.Throws<InvalidOperationException>(
            () => CloudOptions.FromEnvironment("Development"));

        Assert.Contains(CloudOptions.PostgresConnectionStringVariable, excepcion.Message);
    }
}
