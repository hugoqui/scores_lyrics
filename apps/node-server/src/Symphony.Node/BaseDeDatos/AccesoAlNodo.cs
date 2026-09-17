using System.Data.Common;
using Dapper;
using Microsoft.Data.Sqlite;
using Symphony.Node.Configuration;

namespace Symphony.Node.BaseDeDatos;

/// <summary>
/// La puerta al SQLite del nodo ([ADR 0017]). No hay una variable de sesión
/// que fijar aquí —el nodo sirve a una sola iglesia, y esa es la única que hay
/// en el archivo (ADR 0015)—, pero sigue siendo la única puerta: centraliza
/// las claves foráneas encendidas y evita que cada archivo abra su propia
/// conexión con su propia configuración.
/// </summary>
public sealed class AccesoAlNodo
{
    private readonly string _cadenaDeConexion;

    public AccesoAlNodo(NodeOptions opciones) =>
        _cadenaDeConexion = new SqliteConnectionStringBuilder { DataSource = opciones.SqlitePath }.ToString();

    public async Task<T> EnTransaccion<T>(Func<UnidadDeTrabajoDelNodo, Task<T>> trabajo)
    {
        await using var conexion = new SqliteConnection(_cadenaDeConexion);
        await conexion.OpenAsync();
        await conexion.ExecuteAsync("PRAGMA foreign_keys = ON");

        await using var transaccion = await conexion.BeginTransactionAsync();
        var resultado = await trabajo(new UnidadDeTrabajoDelNodo(conexion, transaccion));
        await transaccion.CommitAsync();
        return resultado;
    }
}

/// <summary>Lo que recibe el código de dominio: una transacción abierta, sin la conexión en crudo.</summary>
public sealed class UnidadDeTrabajoDelNodo
{
    private readonly DbConnection _conexion;
    private readonly DbTransaction _transaccion;

    internal UnidadDeTrabajoDelNodo(DbConnection conexion, DbTransaction transaccion)
    {
        _conexion = conexion;
        _transaccion = transaccion;
    }

    public async Task<IReadOnlyList<T>> Consultar<T>(string sql, object? parametros = null) =>
        (await _conexion.QueryAsync<T>(sql, parametros, _transaccion)).ToList();

    public Task<T?> ConsultarUno<T>(string sql, object? parametros = null) =>
        _conexion.QuerySingleOrDefaultAsync<T?>(sql, parametros, _transaccion);

    public Task<int> Ejecutar(string sql, object? parametros = null) =>
        _conexion.ExecuteAsync(sql, parametros, _transaccion);
}
