using System.Data.Common;
using Dapper;

namespace Symphony.Cloud.BaseDeDatos;

/// <summary>
/// Lo que el código de dominio recibe de <see cref="AccesoALaNube"/>: una
/// transacción abierta con su iglesia ya fijada.
///
/// No expone la conexión a propósito. Quien la tuviera podría abrir su propia
/// transacción, sin fijar iglesia, y la política de PostgreSQL dejaría de
/// proteger por ese camino ([ADR 0015]).
/// </summary>
public sealed class UnidadDeTrabajo
{
    private readonly DbConnection _conexion;
    private readonly DbTransaction _transaccion;

    internal UnidadDeTrabajo(DbConnection conexion, DbTransaction transaccion, Guid iglesiaId)
    {
        _conexion = conexion;
        _transaccion = transaccion;
        IglesiaId = iglesiaId;
    }

    /// <summary>La iglesia de esta unidad de trabajo, para no repetirla al llamar.</summary>
    public Guid IglesiaId { get; }

    public async Task<IReadOnlyList<T>> Consultar<T>(string sql, object? parametros = null) =>
        (await _conexion.QueryAsync<T>(sql, parametros, _transaccion)).ToList();

    public Task<T?> ConsultarUno<T>(string sql, object? parametros = null) =>
        _conexion.QuerySingleOrDefaultAsync<T?>(sql, parametros, _transaccion);

    public Task<int> Ejecutar(string sql, object? parametros = null) =>
        _conexion.ExecuteAsync(sql, parametros, _transaccion);
}
