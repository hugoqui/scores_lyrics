using Dapper;
using Npgsql;
using Symphony.Cloud.Configuration;
using Symphony.Sesiones;
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

    /// <summary>
    /// Crea una iglesia y su primer administrador en una sola transacción
    /// (spec R9, fase 7): el comando que la levanta sin panel. No hay
    /// sobrecarga sin contraseña — quien llama siempre tiene que traer una, sin
    /// valor por defecto ni cuenta de fábrica.
    /// </summary>
    public async Task<AltaDeIglesia> CrearIglesiaConAdministrador(
        string nombreIglesia, string correoAdministrador, string nombreAdministrador, string contrasena)
    {
        if (string.IsNullOrWhiteSpace(contrasena))
        {
            throw new ArgumentException(
                "La contraseña del primer administrador es obligatoria.", nameof(contrasena));
        }

        await using var conexion = new NpgsqlConnection(_cadenaDeConexion);
        await conexion.OpenAsync();
        await using var transaccion = await conexion.BeginTransactionAsync();

        var iglesiaId = Guid.CreateVersion7();
        await conexion.ExecuteAsync(
            "INSERT INTO iglesia (id, nombre, estado, creada_en) VALUES (@id, @nombre, 'activa', now())",
            new { id = iglesiaId, nombre = nombreIglesia },
            transaccion);

        var administradorId = Guid.CreateVersion7();
        await conexion.ExecuteAsync(
            """
            INSERT INTO usuario (id, iglesia_id, correo, nombre, hash_contrasena, estado, creado_en)
            VALUES (@id, @iglesiaId, @correo, @nombre, @hash, 'activo', now())
            """,
            new
            {
                id = administradorId,
                iglesiaId,
                correo = correoAdministrador,
                nombre = nombreAdministrador,
                hash = Contrasenas.Guardar(contrasena),
            },
            transaccion);

        await conexion.ExecuteAsync(
            "INSERT INTO usuario_rol (usuario_id, rol) VALUES (@id, @rol)",
            new { id = administradorId, rol = Roles.Administrador },
            transaccion);

        await transaccion.CommitAsync();

        return new AltaDeIglesia(iglesiaId, administradorId);
    }

    private sealed record FilaDeUsuario(Guid Id, Guid IglesiaId, string HashContrasena, string Estado);
}

/// <summary>Lo que deja <see cref="AccesoComoPropietario.CrearIglesiaConAdministrador"/>.</summary>
public sealed record AltaDeIglesia(Guid IglesiaId, Guid AdministradorId);
