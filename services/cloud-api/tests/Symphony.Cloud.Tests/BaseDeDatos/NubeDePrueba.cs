using Npgsql;
using Symphony.Migraciones;
using Testcontainers.PostgreSql;

namespace Symphony.Cloud.Tests.BaseDeDatos;

/// <summary>
/// Un PostgreSQL efímero con las migraciones aplicadas y dos iglesias
/// sembradas ([ADR 0011]). La row-level security solo se puede probar contra el
/// motor real: contra un doble no hay nada que probar.
///
/// Expone dos cadenas de conexión porque la diferencia entre ellas es
/// justamente lo que se prueba: la del dueño siembra —es superusuario y se
/// salta la política— y la de la aplicación es la que tiene que quedar
/// encerrada en su iglesia.
/// </summary>
public sealed class NubeDePrueba : IAsyncLifetime
{
    private readonly PostgreSqlContainer _contenedor = new PostgreSqlBuilder("postgres:16-alpine").Build();

    public string CadenaDelDueno => _contenedor.GetConnectionString();

    public string CadenaDeLaAplicacion { get; private set; } = string.Empty;

    public IglesiaSembrada Primera { get; } = IglesiaSembrada.Nueva("Iglesia de prueba A", "ana@ejemplo.invalid");

    public IglesiaSembrada Segunda { get; } = IglesiaSembrada.Nueva("Iglesia de prueba B", "beto@ejemplo.invalid");

    public async Task InitializeAsync()
    {
        // Obviamente falsa: es un contenedor que vive lo que dura la prueba.
        const string contrasenaDeLaAplicacion = "contrasena-de-prueba";

        await _contenedor.StartAsync();

        await using var conexion = new NpgsqlConnection(CadenaDelDueno);
        await conexion.OpenAsync();

        new EjecutorDeMigraciones(CarpetaDeMigraciones(), DialectoSql.PostgreSql).Aplicar(conexion);

        // La migración crea el rol sin contraseña a propósito (constitución,
        // punto 7); aquí se le pone una para poder conectarse como él.
        await Ejecutar(conexion, $"ALTER ROLE symphony_app WITH PASSWORD '{contrasenaDeLaAplicacion}'");

        CadenaDeLaAplicacion = new NpgsqlConnectionStringBuilder(CadenaDelDueno)
        {
            Username = "symphony_app",
            Password = contrasenaDeLaAplicacion,

            // Sin pozo: una conexión reciclada podría traer fijada la iglesia
            // de la prueba anterior y hacer pasar una prueba que debería
            // fallar. Resolver eso de verdad es la fase 3 (T3.5).
            Pooling = false,
        }.ConnectionString;

        await Sembrar(conexion, Primera);
        await Sembrar(conexion, Segunda);
    }

    public async Task DisposeAsync() => await _contenedor.DisposeAsync();

    /// <summary>
    /// Abre una conexión de la aplicación con la iglesia de la sesión fijada,
    /// que es la única forma en que el código de dominio podrá consultar
    /// ([ADR 0015]). Con <paramref name="iglesiaId"/> nulo no se fija nada: es
    /// el caso de la consulta que se olvidó de todo.
    /// </summary>
    public async Task<NpgsqlConnection> AbrirComoAplicacion(Guid? iglesiaId)
    {
        var conexion = new NpgsqlConnection(CadenaDeLaAplicacion);
        await conexion.OpenAsync();

        if (iglesiaId is not null)
        {
            await using var comando = new NpgsqlCommand("SELECT set_config('app.iglesia_id', @id, FALSE)", conexion);
            comando.Parameters.AddWithValue("id", iglesiaId.Value.ToString());
            await comando.ExecuteNonQueryAsync();
        }

        return conexion;
    }

    private static async Task Sembrar(NpgsqlConnection conexion, IglesiaSembrada iglesia)
    {
        await Ejecutar(
            conexion,
            """
            INSERT INTO iglesia (id, nombre, estado, creada_en)
                VALUES (@iglesia, @nombre, 'activa', now());
            INSERT INTO usuario (id, iglesia_id, correo, nombre, hash_contrasena, estado, creado_en)
                VALUES (@usuario, @iglesia, @correo, 'Persona de prueba', 'no-es-un-hash', 'activo', now());
            INSERT INTO usuario_rol (usuario_id, rol) VALUES (@usuario, 'musico');
            INSERT INTO usuario_instrumento (usuario_id, instrumento_id)
                SELECT @usuario, id FROM instrumento WHERE codigo = 'piano';
            INSERT INTO dispositivo (id, iglesia_id, usuario_id, tipo, nombre, creado_en)
                VALUES (@dispositivo, @iglesia, @usuario, 'movil', 'Teléfono de prueba', now());
            INSERT INTO sesion (id, dispositivo_id, iglesia_id, huella_token, emitida_en, expira_en)
                VALUES (@sesion, @dispositivo, @iglesia, @huella, now(), now() + interval '30 days');
            """,
            ("iglesia", iglesia.Id),
            ("nombre", iglesia.Nombre),
            ("usuario", iglesia.UsuarioId),
            ("correo", iglesia.Correo),
            ("dispositivo", iglesia.DispositivoId),
            ("sesion", iglesia.SesionId),
            ("huella", iglesia.SesionId.ToString()));
    }

    private static async Task Ejecutar(NpgsqlConnection conexion, string sql, params (string Nombre, object Valor)[] parametros)
    {
        await using var comando = new NpgsqlCommand(sql, conexion);
        foreach (var (nombre, valor) in parametros)
        {
            comando.Parameters.AddWithValue(nombre, valor);
        }

        await comando.ExecuteNonQueryAsync();
    }

    /// <summary>
    /// Las migraciones viajan junto al binario, igual que en producción: se
    /// prueba el mismo SQL que se despliega, no una copia del repositorio.
    /// </summary>
    private static string CarpetaDeMigraciones() => Path.Combine(AppContext.BaseDirectory, "migrations");
}

public sealed record IglesiaSembrada(Guid Id, string Nombre, string Correo, Guid UsuarioId, Guid DispositivoId, Guid SesionId)
{
    public static IglesiaSembrada Nueva(string nombre, string correo) =>
        new(Guid.CreateVersion7(), nombre, correo, Guid.CreateVersion7(), Guid.CreateVersion7(), Guid.CreateVersion7());
}
