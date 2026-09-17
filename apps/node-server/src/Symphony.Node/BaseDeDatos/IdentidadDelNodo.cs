using Microsoft.Data.Sqlite;
using Symphony.Node.Configuration;

namespace Symphony.Node.BaseDeDatos;

/// <summary>
/// Comprueba al arrancar que la base que el nodo tiene delante es la de su
/// iglesia y no la de otra ([ADR 0015]).
///
/// Es el mecanismo que cubre el error que de verdad va a pasar: con dos
/// iglesias instaladas a mano por la misma persona, restaurar el respaldo
/// equivocado es el fallo más probable de todos. Sin esta comprobación el nodo
/// serviría datos ajenos en silencio, que es exactamente lo que la constitución
/// (punto 3) prohíbe.
/// </summary>
public static class IdentidadDelNodo
{
    public static void Verificar(NodeOptions opciones, ILogger logger)
    {
        using var conexion = new SqliteConnection(new SqliteConnectionStringBuilder
        {
            DataSource = opciones.SqlitePath,
        }.ToString());
        conexion.Open();

        using var comando = conexion.CreateCommand();
        comando.CommandText = "SELECT id, nombre FROM iglesia";

        using var lector = comando.ExecuteReader();
        if (!lector.Read())
        {
            // Base recién creada: la iglesia llega con la configuración inicial
            // o con la primera sincronización (módulo 008). No hay nada que
            // contradiga la configuración, y tampoco hay datos que servir:
            // todas las tablas de dominio cuelgan de esta fila.
            logger.LogWarning(
                "El nodo todavía no tiene su iglesia en la base. Esperando la iglesia {IglesiaEsperada}.",
                opciones.IglesiaId);
            return;
        }

        var enLaBase = Guid.Parse(lector.GetString(0));
        var nombre = lector.GetString(1);

        if (enLaBase != opciones.IglesiaId)
        {
            throw new InvalidOperationException(
                $"Esta base de datos es de otra iglesia. {NodeOptions.IglesiaIdVariable} dice " +
                $"'{opciones.IglesiaId}', pero el archivo '{opciones.SqlitePath}' contiene la iglesia " +
                $"'{enLaBase}' ({nombre}). El nodo no arranca: servir esos datos sería entregar los de " +
                "otra congregación. Revisa de qué iglesia es el respaldo que restauraste.");
        }

        logger.LogInformation("Nodo atado a la iglesia {Iglesia} ({Nombre}).", enLaBase, nombre);
    }
}
