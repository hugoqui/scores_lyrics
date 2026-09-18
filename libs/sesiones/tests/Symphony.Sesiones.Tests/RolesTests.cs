using System.Text.RegularExpressions;

namespace Symphony.Sesiones.Tests;

/// <summary>
/// La lista de roles está escrita tres veces: aquí en C#, en la migración de la
/// nube y en la del nodo. No hay forma de tenerla una sola vez —el
/// <c>CHECK</c> de una migración aplicada no se puede editar ([ADR 0010])—, así
/// que lo que se puede hacer es que las tres se comparen solas.
///
/// Un rol que la base acepta y el código no conoce no autoriza ninguna
/// operación; uno que el código conoce y la base rechaza no se puede asignar a
/// nadie. Las dos formas de desfase fallan callando.
/// </summary>
public class RolesTests
{
    private static readonly Regex _listaDelCheck =
        new(@"CHECK\s*\(\s*rol\s+IN\s*\(([^)]*)\)", RegexOptions.Compiled | RegexOptions.IgnoreCase);

    [Theory]
    [InlineData("services/cloud-api/migrations")]
    [InlineData("apps/node-server/migrations")]
    public void La_lista_de_roles_es_la_misma_en_el_codigo_y_en_la_base(string carpeta)
    {
        var raiz = SinIglesiaPorParametroTests.RaizDelRepositorio();
        var migracion = Path.Combine(raiz, Path.Combine(carpeta.Split('/')), "0002_identidad.sql");

        var coincidencia = _listaDelCheck.Match(File.ReadAllText(migracion));
        Assert.True(coincidencia.Success, $"No se encontró el CHECK de roles en {migracion}.");

        var enLaBase = coincidencia.Groups[1].Value
            .Split(',')
            .Select(valor => valor.Trim().Trim('\''))
            .ToList();

        Assert.Equal(Roles.Todos, enLaBase);
    }
}
