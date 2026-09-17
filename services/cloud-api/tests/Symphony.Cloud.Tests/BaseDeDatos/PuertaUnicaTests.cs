namespace Symphony.Cloud.Tests.BaseDeDatos;

/// <summary>
/// T3.3: que la puerta sea única no es algo que se pueda prometer en un
/// comentario. Nada en C# impide escribir <c>new NpgsqlConnection(...)</c> en
/// cualquier archivo, y el día que alguien lo haga la política de PostgreSQL
/// deja de proteger ese camino ([ADR 0015]).
///
/// Esta prueba lee el código fuente y exige que solo lo hagan los archivos de
/// <c>BaseDeDatos/</c>. Es una guardia, no una demostración: cubre el error de
/// distracción, que es el que de verdad ocurre.
/// </summary>
public class PuertaUnicaTests
{
    private static readonly string[] _archivosQuePuedenAbrirConexiones =
    [
        "AccesoALaNube.cs",      // la puerta
        "MigracionesDeLaNube.cs", // el arranque, antes de que exista una sesión
    ];

    [Fact]
    public void Solo_la_puerta_abre_conexiones_a_la_base_de_la_nube()
    {
        var infractores = new List<string>();

        foreach (var archivo in Directory.EnumerateFiles(CarpetaDelProyecto(), "*.cs", SearchOption.AllDirectories))
        {
            var nombre = Path.GetFileName(archivo);
            if (_archivosQuePuedenAbrirConexiones.Contains(nombre) || EsGenerado(archivo))
            {
                continue;
            }

            if (File.ReadAllText(archivo).Contains("NpgsqlConnection", StringComparison.Ordinal))
            {
                infractores.Add(nombre);
            }
        }

        Assert.True(
            infractores.Count == 0,
            $"Estos archivos abren conexiones por su cuenta, saltándose AccesoALaNube: " +
            $"{string.Join(", ", infractores)}. La iglesia se fija en la puerta, y una conexión " +
            "obtenida por fuera consulta sin filtrar.");
    }

    private static bool EsGenerado(string archivo) =>
        archivo.Contains($"{Path.DirectorySeparatorChar}obj{Path.DirectorySeparatorChar}", StringComparison.Ordinal)
        || archivo.Contains($"{Path.DirectorySeparatorChar}bin{Path.DirectorySeparatorChar}", StringComparison.Ordinal);

    /// <summary>
    /// Sube desde el binario hasta encontrar el proyecto. Si no lo encuentra,
    /// la prueba falla: una guardia que se desactiva sola cuando no halla lo
    /// que busca es peor que no tenerla, porque deja de avisar sin decirlo.
    /// </summary>
    private static string CarpetaDelProyecto()
    {
        var carpeta = new DirectoryInfo(AppContext.BaseDirectory);

        while (carpeta is not null)
        {
            var proyecto = Path.Combine(carpeta.FullName, "src", "Symphony.Cloud");
            if (Directory.Exists(proyecto))
            {
                return proyecto;
            }

            carpeta = carpeta.Parent;
        }

        throw new DirectoryNotFoundException(
            "No se encontró el proyecto Symphony.Cloud desde " + AppContext.BaseDirectory);
    }
}
