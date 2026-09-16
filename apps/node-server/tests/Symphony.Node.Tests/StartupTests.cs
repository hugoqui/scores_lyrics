using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.Data.Sqlite;
using Symphony.Migraciones;
using Symphony.Node.Configuration;

namespace Symphony.Node.Tests;

/// <summary>
/// Pruebas de arranque (spec R3/R4): el nodo levanta con configuración válida,
/// aplica sus migraciones antes de atender nada (spec R1) y falla, nombrando
/// la variable que falta, con una configuración incompleta.
/// </summary>
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

        Assert.Equal(["0001_inicial"], nodo.MigracionesAplicadas());
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
    }

    /// <summary>
    /// Configuración válida apuntando a un SQLite temporal en carpeta propia
    /// ([ADR 0011]). Al terminar limpia las variables y borra la carpeta, para
    /// que ninguna prueba dependa de otra ni del orden.
    /// </summary>
    private sealed class NodoDePrueba : IDisposable
    {
        private readonly string _raiz;

        public NodoDePrueba()
        {
            _raiz = Path.Combine(Path.GetTempPath(), "symphony-nodo", Guid.NewGuid().ToString("N"));
            Directory.CreateDirectory(_raiz);
            ArchivoSqlite = Path.Combine(_raiz, "nodo.sqlite");

            Environment.SetEnvironmentVariable(NodeOptions.SqlitePathVariable, ArchivoSqlite);
            Environment.SetEnvironmentVariable(NodeOptions.CloudUrlVariable, "https://nube.prueba.local");
        }

        public string ArchivoSqlite { get; }

        public void OlvidarConfiguracion()
        {
            Environment.SetEnvironmentVariable(NodeOptions.SqlitePathVariable, null);
            Environment.SetEnvironmentVariable(NodeOptions.CloudUrlVariable, null);
        }

        public IReadOnlyList<string> MigracionesAplicadas()
        {
            using var conexion = new SqliteConnection(
                new SqliteConnectionStringBuilder { DataSource = ArchivoSqlite }.ToString());
            conexion.Open();

            using var comando = conexion.CreateCommand();
            comando.CommandText =
                $"SELECT nombre FROM {EjecutorDeMigraciones.TablaDeControl} ORDER BY numero";

            var nombres = new List<string>();
            using var lector = comando.ExecuteReader();
            while (lector.Read())
            {
                nombres.Add(lector.GetString(0));
            }

            return nombres;
        }

        public void Dispose()
        {
            OlvidarConfiguracion();
            SqliteConnection.ClearAllPools();
            try
            {
                Directory.Delete(_raiz, recursive: true);
            }
            catch (IOException)
            {
                // Una carpeta temporal que no se pudo borrar no invalida la prueba.
            }
        }
    }
}
