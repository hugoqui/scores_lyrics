using Dapper;
using Npgsql;
using Symphony.Cloud.Configuration;

namespace Symphony.Cloud.BaseDeDatos;

/// <summary>
/// La <b>única</b> puerta a la base de la nube ([ADR 0017]). Abre la
/// transacción, fija la iglesia de la sesión y recién entonces deja consultar.
///
/// El aislamiento lo impone PostgreSQL ([ADR 0015]), pero su política compara
/// contra una variable que alguien tiene que fijar, en la misma conexión y
/// dentro de la misma transacción. Si eso quedara repartido por el código, el
/// día que se olvide en un sitio la política no protege nada ahí. Por eso el
/// código de dominio no recibe nunca una conexión: recibe una unidad de trabajo
/// que ya tiene su iglesia puesta.
///
/// La consecuencia buscada es que <b>no exista la forma de consultar sin
/// iglesia</b>. No es una convención: no hay ningún método que la devuelva.
/// </summary>
public sealed class AccesoALaNube
{
    private readonly string _cadenaDeConexion;

    public AccesoALaNube(CloudOptions opciones) => _cadenaDeConexion = opciones.PostgresConnectionString;

    public async Task<T> EnLaIglesia<T>(Guid iglesiaId, Func<UnidadDeTrabajo, Task<T>> trabajo)
    {
        if (iglesiaId == Guid.Empty)
        {
            // Un identificador vacío es un error de programación, no una
            // sesión sin iglesia: la iglesia sale del token ([ADR 0016]), y si
            // no hay token no hay nada que consultar. Se corta aquí en vez de
            // abrir una transacción que no vería ninguna fila y dejar a quien
            // depure buscando por qué su consulta correcta no devuelve nada.
            throw new ArgumentException(
                "No se puede trabajar contra la base de la nube sin una iglesia. " +
                "La iglesia sale del token de la sesión, nunca de la petición.",
                nameof(iglesiaId));
        }

        await using var conexion = new NpgsqlConnection(_cadenaDeConexion);
        await conexion.OpenAsync();

        await using var transaccion = await conexion.BeginTransactionAsync();

        // SET LOCAL: vale hasta el fin de esta transacción y ni una consulta
        // más. Una conexión que vuelve al pozo no se lleva la iglesia puesta.
        await conexion.ExecuteAsync(
            "SELECT set_config('app.iglesia_id', @iglesia, TRUE)",
            new { iglesia = iglesiaId.ToString() },
            transaccion);

        var resultado = await trabajo(new UnidadDeTrabajo(conexion, transaccion, iglesiaId));

        await transaccion.CommitAsync();
        return resultado;
    }

    public Task EnLaIglesia(Guid iglesiaId, Func<UnidadDeTrabajo, Task> trabajo) =>
        EnLaIglesia<object?>(iglesiaId, async unidad =>
        {
            await trabajo(unidad);
            return null;
        });
}
