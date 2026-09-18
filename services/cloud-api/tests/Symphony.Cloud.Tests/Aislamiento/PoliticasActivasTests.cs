using Symphony.Cloud.Tests.BaseDeDatos;

namespace Symphony.Cloud.Tests.Aislamiento;

/// <summary>
/// T8.3: <b>ninguna tabla de dominio puede entrar sin su política</b>. No se
/// comprueba una lista de tablas conocidas, se le pregunta al motor cuáles hay:
/// una tabla nueva que llegue mañana en una migración aparece aquí sola, y si
/// viene sin row-level security deja la prueba en rojo.
///
/// <para>
/// Es la guardia que hace que el aislamiento no dependa de que alguien se
/// acuerde. Olvidar <c>ENABLE</c>, olvidar <c>FORCE</c> o crear la tabla sin
/// política son tres despistes de una línea, y los tres se descubren el día que
/// una congregación ve los datos de la otra ([ADR 0015]).
/// </para>
/// </summary>
public sealed class PoliticasActivasTests : IClassFixture<NubeDePrueba>
{
    /// <summary>
    /// Las excepciones cerradas, cada una con su motivo (spec R2). Que estén
    /// escritas aquí es el punto: sumar una tabla a esta lista es una decisión
    /// visible en la revisión, no un olvido.
    /// </summary>
    private static readonly IReadOnlyDictionary<string, string> _sinPolitica = new Dictionary<string, string>
    {
        ["instrumento"] = "catálogo compartido por todas las iglesias y de solo lectura (spec R2, R5)",
        ["propietario_saas"] = "identidad global, no pertenece a ninguna iglesia (spec R4)",
        ["migraciones_aplicadas"] = "tabla de control de las migraciones (001 R1), no es de dominio",
    };

    private readonly NubeDePrueba _nube;

    public PoliticasActivasTests(NubeDePrueba nube) => _nube = nube;

    [Fact]
    public async Task Toda_tabla_de_dominio_tiene_la_politica_activada_y_forzada()
    {
        var defectos = new List<string>();

        foreach (var tabla in await Tablas())
        {
            if (_sinPolitica.ContainsKey(tabla.Nombre))
            {
                continue;
            }

            if (!tabla.Activada)
            {
                defectos.Add($"{tabla.Nombre} no tiene ENABLE ROW LEVEL SECURITY");
            }

            // Sin FORCE, el dueño de la tabla —que es quien corre las
            // migraciones— se salta la política entera.
            if (!tabla.Forzada)
            {
                defectos.Add($"{tabla.Nombre} no tiene FORCE ROW LEVEL SECURITY");
            }

            // Con RLS activada y sin políticas, la tabla no devuelve nada a
            // nadie: no es aislamiento, es una tabla rota que alguien va a
            // «arreglar» desactivando la política.
            if (tabla.Politicas == 0)
            {
                defectos.Add($"{tabla.Nombre} no tiene ninguna política");
            }
        }

        Assert.True(
            defectos.Count == 0,
            "Una tabla de dominio sin política deja de estar aislada aunque el resto lo esté " +
            $"(spec R3, [ADR 0015]): {string.Join("; ", defectos)}");
    }

    [Fact]
    public async Task Las_excepciones_declaradas_siguen_existiendo()
    {
        // Una excepción que ya no corresponde a ninguna tabla es una puerta
        // abierta esperando a que alguien cree una tabla con ese nombre.
        var existentes = (await Tablas()).Select(t => t.Nombre).ToHashSet(StringComparer.Ordinal);

        Assert.DoesNotContain(_sinPolitica.Keys, tabla => !existentes.Contains(tabla));
    }

    [Fact]
    public async Task El_rol_de_la_aplicacion_no_se_salta_la_politica_ni_es_dueño_de_nada()
    {
        // Las dos condiciones que sostienen todo lo demás: con BYPASSRLS la
        // política no le aplica, y siendo dueña tampoco le aplicaría sin FORCE.
        var seSalta = await _nube.ConsultarComoDueno<bool>(
            "SELECT rolbypassrls FROM pg_roles WHERE rolname = 'symphony_app'");
        Assert.Equal([false], seSalta);

        var suyas = await _nube.ConsultarComoDueno<string>(
            """
            SELECT c.relname
            FROM pg_class c
            JOIN pg_namespace n ON n.oid = c.relnamespace
            JOIN pg_roles r ON r.oid = c.relowner
            WHERE n.nspname = 'public' AND c.relkind = 'r' AND r.rolname = 'symphony_app'
            """);
        Assert.Empty(suyas);
    }

    private Task<IReadOnlyList<TablaDeLaNube>> Tablas() =>
        _nube.ConsultarComoDueno<TablaDeLaNube>(
            """
            SELECT c.relname                AS Nombre,
                   c.relrowsecurity         AS Activada,
                   c.relforcerowsecurity    AS Forzada,
                   (SELECT count(*) FROM pg_policy p WHERE p.polrelid = c.oid) AS Politicas
            FROM pg_class c
            JOIN pg_namespace n ON n.oid = c.relnamespace
            WHERE n.nspname = 'public' AND c.relkind = 'r'
            ORDER BY c.relname
            """);

    private sealed record TablaDeLaNube(string Nombre, bool Activada, bool Forzada, long Politicas);
}
