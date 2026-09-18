using Microsoft.Data.Sqlite;
using Symphony.Node.BaseDeDatos;
using Symphony.Node.Configuration;

namespace Symphony.Node.Tests.Aislamiento;

/// <summary>
/// T8.3 en el nodo. Aquí no hay políticas que comprobar: el aislamiento es
/// físico —una base por iglesia ([ADR 0015])— y lo que lo sostiene es que
/// <b>toda tabla de dominio cuelgue de la única fila de <c>iglesia</c></b>, de
/// forma directa o a través de otra que sí lo hace.
///
/// <para>
/// Se le pregunta al esquema, no a una lista escrita a mano: una tabla nueva
/// que llegue mañana en una migración aparece aquí sola, y si no cuelga de la
/// iglesia deja la prueba en rojo. Es la contraparte exacta de la guardia de
/// políticas de la nube — el mismo descuido, impedido con lo que cada motor
/// tiene.
/// </para>
/// </summary>
[Collection(ConfiguracionDelProceso.Nombre)]
public class TodaTablaCuelgaDeLaIglesiaTests
{
    /// <summary>Las excepciones cerradas, con su motivo (spec R2).</summary>
    private static readonly IReadOnlyDictionary<string, string> _noCuelgan = new Dictionary<string, string>
    {
        ["iglesia"] = "es la iglesia: de ella cuelga todo lo demás",
        ["instrumento"] = "catálogo compartido y de solo lectura, réplica del de la nube (spec R2, R5)",
        ["migraciones_aplicadas"] = "tabla de control de las migraciones (001 R1), no es de dominio",
    };

    [Fact]
    public void Toda_tabla_de_dominio_cuelga_de_la_unica_iglesia()
    {
        using var nodo = new NodoDePrueba();
        nodo.Migrar();
        using var conexion = nodo.Abrir();

        var sueltas = Tablas(conexion)
            .Where(tabla => !_noCuelgan.ContainsKey(tabla))
            .Where(tabla => !LlegaALaIglesia(conexion, tabla))
            .ToList();

        Assert.True(
            sueltas.Count == 0,
            "En el nodo el aislamiento es la clave foránea: una tabla que no cuelga de `iglesia` acepta " +
            $"filas de otra congregación sin que el motor diga nada. Estas no cuelgan: {string.Join(", ", sueltas)}");
    }

    [Fact]
    public void Las_excepciones_declaradas_siguen_existiendo()
    {
        using var nodo = new NodoDePrueba();
        nodo.Migrar();
        using var conexion = nodo.Abrir();

        var existentes = Tablas(conexion).ToHashSet(StringComparer.Ordinal);

        Assert.DoesNotContain(_noCuelgan.Keys, tabla => !existentes.Contains(tabla));
    }

    /// <summary>
    /// Las claves foráneas de SQLite <b>no se aplican si nadie las enciende</b>,
    /// y encenderlas es cosa de cada conexión. Que el esquema las declare no
    /// prueba nada por sí solo: lo que protege el domingo es que la puerta real
    /// (<see cref="AccesoAlNodo"/>) las tenga puestas.
    /// </summary>
    [Fact]
    public async Task La_puerta_real_del_nodo_rechaza_una_fila_de_otra_iglesia()
    {
        using var nodo = new NodoDePrueba();
        nodo.Migrar();
        nodo.SembrarIglesia(nodo.IglesiaId);
        var acceso = new AccesoAlNodo(NodeOptions.FromEnvironment("Development"));

        var error = await Assert.ThrowsAsync<SqliteException>(() => acceso.EnTransaccion(unidad => unidad.Ejecutar(
            """
            INSERT INTO usuario (id, iglesia_id, correo, nombre, hash_contrasena, estado, creado_en)
            VALUES (@id, @ajena, 'intruso@ejemplo.invalid', 'Intruso', 'no-es-un-hash', 'activo', '2026-01-01T00:00:00Z')
            """,
            new { id = Guid.CreateVersion7().ToString(), ajena = Guid.CreateVersion7().ToString() })));

        Assert.Contains("FOREIGN KEY", error.Message, StringComparison.OrdinalIgnoreCase);
    }

    private static IReadOnlyList<string> Tablas(SqliteConnection conexion)
    {
        using var comando = conexion.CreateCommand();
        comando.CommandText =
            "SELECT name FROM sqlite_master WHERE type = 'table' AND name NOT LIKE 'sqlite_%' ORDER BY name";

        var nombres = new List<string>();
        using var lector = comando.ExecuteReader();
        while (lector.Read())
        {
            nombres.Add(lector.GetString(0));
        }

        return nombres;
    }

    /// <summary>
    /// Sigue las claves foráneas hasta <c>iglesia</c>. Vale llegar por el
    /// camino largo: <c>usuario_rol</c> cuelga de <c>usuario</c>, y
    /// <c>usuario</c> de la iglesia, así que una fila de otra congregación no
    /// tiene de dónde agarrarse.
    /// </summary>
    private static bool LlegaALaIglesia(SqliteConnection conexion, string tabla)
    {
        var porVisitar = new Queue<string>([tabla]);
        var vistas = new HashSet<string>(StringComparer.Ordinal);

        while (porVisitar.Count > 0)
        {
            var actual = porVisitar.Dequeue();
            if (!vistas.Add(actual))
            {
                continue;
            }

            foreach (var referida in Referidas(conexion, actual))
            {
                if (string.Equals(referida, "iglesia", StringComparison.Ordinal))
                {
                    return true;
                }

                porVisitar.Enqueue(referida);
            }
        }

        return false;
    }

    private static IReadOnlyList<string> Referidas(SqliteConnection conexion, string tabla)
    {
        using var comando = conexion.CreateCommand();

        // El nombre sale de sqlite_master, no de fuera, y aun así va entre
        // comillas: un PRAGMA no admite parámetros.
        comando.CommandText = $"PRAGMA foreign_key_list(\"{tabla.Replace("\"", "\"\"", StringComparison.Ordinal)}\")";

        var referidas = new List<string>();
        using var lector = comando.ExecuteReader();
        while (lector.Read())
        {
            referidas.Add(lector.GetString(lector.GetOrdinal("table")));
        }

        return referidas;
    }
}
