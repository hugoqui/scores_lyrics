using System.Text.RegularExpressions;

namespace Symphony.Sesiones.Tests;

/// <summary>
/// T5.6: <b>ninguna API acepta un identificador de iglesia por parámetro</b>
/// (spec R3). La iglesia sale del token y de ningún otro sitio.
///
/// <para>
/// No es una promesa que se pueda dejar en un comentario. Añadir
/// <c>Guid iglesiaId</c> a un endpoint es de las cosas más naturales que se
/// pueden escribir, y a partir de ese momento cualquier cliente puede pedir los
/// datos de la congregación de al lado con solo cambiar un número. Esta prueba
/// lee el código de los dos servidores y lo prohíbe.
/// </para>
/// <para>
/// Se permite en <c>BaseDeDatos/</c> y <c>Configuration/</c>, que son
/// justamente los sitios donde la iglesia se recibe una vez: la puerta a la
/// base, que la fija en la transacción, y la configuración del nodo, que dice a
/// qué iglesia sirve. Todo lo demás la saca de la sesión.
/// </para>
/// </summary>
public class SinIglesiaPorParametroTests
{
    private static readonly string[] _proyectosServidores =
    [
        Path.Combine("services", "cloud-api", "src", "Symphony.Cloud"),
        Path.Combine("apps", "node-server", "src", "Symphony.Node"),
        Path.Combine("libs", "sesiones", "src", "Symphony.Sesiones.Web"),
    ];

    /// <summary>Donde recibir la iglesia es el trabajo, no un descuido.</summary>
    private static readonly string[] _carpetasQuePuedenRecibirla = ["BaseDeDatos", "Configuration"];

    private static readonly (Regex Patron, string Queja)[] _prohibiciones =
    [
        (new Regex(@"\b(?:Guid|string)\??\s+iglesiaId\b", RegexOptions.Compiled),
            "recibe la iglesia como argumento"),
        (new Regex(@"\bIglesiaId\s*\{\s*get\b", RegexOptions.Compiled),
            "declara una propiedad de iglesia en un tipo de petición"),
        (new Regex(@"\bGuid\s+IglesiaId\b", RegexOptions.Compiled),
            "declara la iglesia en un record de petición"),
        // Solo cadenas que empiezan por «/» y no cruzan líneas: lo que se busca
        // es una plantilla de ruta, no cualquier texto que hable de iglesias.
        (new Regex(@"""/[^""\r\n]*\{[^""}\r\n]*[Ii]glesia[^""}\r\n]*\}", RegexOptions.Compiled),
            "tiene la iglesia en la ruta"),
        (new Regex(@"""/[^""\r\n]*[?&]iglesia", RegexOptions.Compiled | RegexOptions.IgnoreCase),
            "tiene la iglesia en la cadena de consulta"),
    ];

    [Fact]
    public void Ninguna_api_acepta_un_identificador_de_iglesia_por_parametro()
    {
        var raiz = RaizDelRepositorio();
        var infracciones = new List<string>();

        foreach (var proyecto in _proyectosServidores)
        {
            var carpeta = Path.Combine(raiz, proyecto);
            Assert.True(Directory.Exists(carpeta), $"No existe {carpeta}: esta guardia dejó de mirar donde debía.");

            foreach (var archivo in Directory.EnumerateFiles(carpeta, "*.cs", SearchOption.AllDirectories))
            {
                if (EsGenerado(archivo) || PuedeRecibirla(archivo))
                {
                    continue;
                }

                var texto = File.ReadAllText(archivo);
                foreach (var (patron, queja) in _prohibiciones)
                {
                    if (patron.IsMatch(texto))
                    {
                        infracciones.Add($"{Path.GetFileName(archivo)} {queja}");
                    }
                }
            }
        }

        Assert.True(
            infracciones.Count == 0,
            "La iglesia tiene que salir de la sesión firmada, nunca de la petición (spec R3). " +
            $"Esto la acepta por parámetro: {string.Join("; ", infracciones)}");
    }

    private static bool PuedeRecibirla(string archivo) =>
        _carpetasQuePuedenRecibirla.Any(carpeta =>
            archivo.Contains($"{Path.DirectorySeparatorChar}{carpeta}{Path.DirectorySeparatorChar}", StringComparison.Ordinal));

    private static bool EsGenerado(string archivo) =>
        archivo.Contains($"{Path.DirectorySeparatorChar}obj{Path.DirectorySeparatorChar}", StringComparison.Ordinal)
        || archivo.Contains($"{Path.DirectorySeparatorChar}bin{Path.DirectorySeparatorChar}", StringComparison.Ordinal);

    /// <summary>
    /// Sube hasta la solución. Si no la encuentra, falla: una guardia que no
    /// halla lo que vigila y se da por buena deja de avisar sin decirlo.
    /// </summary>
    internal static string RaizDelRepositorio()
    {
        var carpeta = new DirectoryInfo(AppContext.BaseDirectory);

        while (carpeta is not null)
        {
            if (File.Exists(Path.Combine(carpeta.FullName, "Symphony.sln")))
            {
                return carpeta.FullName;
            }

            carpeta = carpeta.Parent;
        }

        throw new DirectoryNotFoundException(
            "No se encontró Symphony.sln subiendo desde " + AppContext.BaseDirectory);
    }
}
