using Dapper;
using Npgsql;
using Symphony.Cloud.Configuration;
using Symphony.Sesiones.Web;

namespace Symphony.Cloud.BaseDeDatos;

/// <summary>
/// El único camino que ve más allá de una iglesia a la vez (ADR 0015,
/// <c>docs/operacion/roles-de-base-de-datos.md</c>). Usa
/// <c>symphony_propietario</c> (<c>BYPASSRLS</c>), y solo lo usa el login: es
/// el único momento en que la aplicación todavía no sabe a qué iglesia
/// pertenece la petición, porque el correo es único dentro de su iglesia, no
/// globalmente (spec R4).
///
/// <para>
/// <b>Cada camino que use este rol se lista en ese documento, uno por uno.</b>
/// Uno que lo use y no esté ahí es un defecto: ve todas las iglesias sin que
/// nadie lo haya revisado.
/// </para>
/// </summary>
public sealed class AccesoComoPropietario
{
    private readonly string _cadenaDeConexion;

    public AccesoComoPropietario(CloudOptions opciones) =>
        _cadenaDeConexion = opciones.PostgresPropietarioConnectionString;

    /// <summary>
    /// Todas las filas de <c>usuario</c> con este correo, en cualquier
    /// iglesia. Normalmente son cero o una; más de una significa que el mismo
    /// correo se dio de alta en dos iglesias distintas (spec R4 lo permite:
    /// son dos personas sin nada compartido), y el login no puede adivinar
    /// cuál de las dos se quiso decir, así que quien llame trata eso como
    /// credenciales inválidas, igual que un correo que no existe.
    /// </summary>
    public async Task<IReadOnlyList<UsuarioParaAutenticar>> BuscarPorCorreo(string correo)
    {
        await using var conexion = new NpgsqlConnection(_cadenaDeConexion);
        await conexion.OpenAsync();

        var filas = (await conexion.QueryAsync<FilaDeUsuario>(
            """
            SELECT id AS Id, iglesia_id AS IglesiaId, hash_contrasena AS HashContrasena, estado AS Estado
            FROM usuario
            WHERE correo = @correo
            """,
            new { correo })).ToList();

        var resultado = new List<UsuarioParaAutenticar>();
        foreach (var fila in filas)
        {
            var roles = await conexion.QueryAsync<string>(
                "SELECT rol FROM usuario_rol WHERE usuario_id = @id", new { fila.Id });
            resultado.Add(new UsuarioParaAutenticar(fila.Id, fila.IglesiaId, fila.HashContrasena, fila.Estado, roles.ToList()));
        }

        return resultado;
    }

    private sealed record FilaDeUsuario(Guid Id, Guid IglesiaId, string HashContrasena, string Estado);
}
