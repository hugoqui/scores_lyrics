using System.Net;
using Microsoft.AspNetCore.Mvc.Testing;
using Npgsql;
using Symphony.Cloud.BaseDeDatos;
using Symphony.Cloud.Configuration;
using Symphony.Migraciones;
using Symphony.Sesiones;
using Testcontainers.PostgreSql;

namespace Symphony.Cloud.Tests;

/// <summary>
/// Pruebas de arranque (spec R3/R4): la nube levanta con configuración válida,
/// aplica sus migraciones antes de atender nada (spec R1) y falla, nombrando
/// la variable que falta, con una configuración incompleta.
///
/// El PostgreSQL es un contenedor efímero de esta clase de pruebas
/// ([ADR 0011]): se crea al empezar y se destruye al terminar. Hace falta
/// Docker corriendo; sin él, estas pruebas no pueden correr.
/// </summary>
public class StartupTests : IAsyncLifetime
{
    private readonly PostgreSqlContainer _postgres = new PostgreSqlBuilder("postgres:17-alpine")
        .WithDatabase("symphony_de_prueba")
        .WithUsername("usuario_de_prueba")
        .WithPassword("contrasena_de_prueba")
        .Build();

    public async Task InitializeAsync()
    {
        await _postgres.StartAsync();
        Environment.SetEnvironmentVariable(
            CloudOptions.PostgresConnectionStringVariable, _postgres.GetConnectionString());
        Environment.SetEnvironmentVariable(
            CloudOptions.ClavePrivadaVariable, ParDeClaves.Generar().PrivadaEnBase64);
    }

    public async Task DisposeAsync()
    {
        Environment.SetEnvironmentVariable(CloudOptions.PostgresConnectionStringVariable, null);
        Environment.SetEnvironmentVariable(CloudOptions.ClavePrivadaVariable, null);
        await _postgres.DisposeAsync();
    }

    [Fact]
    public async Task Arranca_con_configuracion_valida()
    {
        await using var factory = new WebApplicationFactory<Program>();
        using var client = factory.CreateClient();

        // Todavía no hay endpoints propios —el `weatherforecast` de la
        // plantilla se borró en 002 T3.6—, así que lo que se comprueba es que
        // la aplicación levanta y responde: un 404 ya es una respuesta suya.
        var response = await client.GetAsync("/");

        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
    }

    [Fact]
    public async Task Al_arrancar_deja_aplicadas_las_migraciones_de_la_nube()
    {
        await using var factory = new WebApplicationFactory<Program>();
        using var client = factory.CreateClient();
        await client.GetAsync("/");

        // Se compara contra lo que hay en disco, no contra una lista escrita
        // aquí: la propiedad que importa es "no queda ninguna pendiente", y una
        // lista fija obliga a tocar esta prueba en cada migración nueva.
        var enDisco = new EjecutorDeMigraciones(MigracionesDeLaNube.CarpetaPorDefecto, DialectoSql.PostgreSql)
            .LeerDeDisco()
            .Select(m => m.NombreCompleto);

        Assert.Equal(enDisco, await MigracionesAplicadas());
    }

    [Fact]
    public void Falla_con_configuracion_incompleta_y_nombra_la_variable_faltante()
    {
        var conexion = Environment.GetEnvironmentVariable(CloudOptions.PostgresConnectionStringVariable);
        var clave = Environment.GetEnvironmentVariable(CloudOptions.ClavePrivadaVariable);
        Environment.SetEnvironmentVariable(CloudOptions.PostgresConnectionStringVariable, null);
        Environment.SetEnvironmentVariable(CloudOptions.ClavePrivadaVariable, null);
        try
        {
            var excepcion = Assert.Throws<InvalidOperationException>(
                () => CloudOptions.FromEnvironment("Development"));

            // Las nombra todas de una vez: arrancar tres veces para descubrir
            // tres variables que faltan es una forma tonta de perder una tarde.
            Assert.Contains(CloudOptions.PostgresConnectionStringVariable, excepcion.Message);
            Assert.Contains(CloudOptions.ClavePrivadaVariable, excepcion.Message);
        }
        finally
        {
            Environment.SetEnvironmentVariable(CloudOptions.PostgresConnectionStringVariable, conexion);
            Environment.SetEnvironmentVariable(CloudOptions.ClavePrivadaVariable, clave);
        }
    }

    private async Task<IReadOnlyList<string>> MigracionesAplicadas()
    {
        await using var conexion = new NpgsqlConnection(_postgres.GetConnectionString());
        await conexion.OpenAsync();

        await using var comando = conexion.CreateCommand();
        comando.CommandText = $"SELECT nombre FROM {EjecutorDeMigraciones.TablaDeControl} ORDER BY numero";

        var nombres = new List<string>();
        await using var lector = await comando.ExecuteReaderAsync();
        while (await lector.ReadAsync())
        {
            nombres.Add(lector.GetString(0));
        }

        return nombres;
    }
}
