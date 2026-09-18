using Dapper;
using Npgsql;
using Symphony.Migraciones;
using Symphony.Sesiones;
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
///
/// <para>
/// <b>T8.1: la semilla es completa a propósito.</b> Las dos iglesias tienen
/// fila en cada tabla de dominio y en cada variante que cambia el camino del
/// código —los tres roles, un músico con dos instrumentos, un dispositivo de
/// persona, una pantalla sin dueño y uno ya revocado—, porque un intento de
/// cruce contra una tabla vacía pasa sin probar nada. Todo es inventado y se
/// nota: nombres «de prueba» y correos en <c>.invalid</c>, que es un dominio
/// que no existe (001 R5, constitución punto 3).
/// </para>
/// </summary>
public sealed class NubeDePrueba : IAsyncLifetime
{
    /// <summary>Del catálogo que siembra <c>0002_identidad.sql</c>, con sus identificadores fijos.</summary>
    public static readonly Guid Piano = Guid.Parse("01999c1e-0000-7000-8000-000000000001");

    public static readonly Guid Flauta1 = Guid.Parse("01999c1e-0000-7000-8000-000000000005");

    private readonly PostgreSqlContainer _contenedor = new PostgreSqlBuilder("postgres:16-alpine").Build();

    public string CadenaDelDueno => _contenedor.GetConnectionString();

    public string CadenaDeLaAplicacion { get; private set; } = string.Empty;

    /// <summary>
    /// El rol que usa el login para encontrar un correo sin saber todavía su
    /// iglesia (spec R4, <c>docs/operacion/roles-de-base-de-datos.md</c>).
    /// </summary>
    public string CadenaDelPropietario { get; private set; } = string.Empty;

    public IglesiaSembrada Primera { get; } = IglesiaSembrada.Nueva("Iglesia de prueba A", "ana@ejemplo.invalid");

    public IglesiaSembrada Segunda { get; } = IglesiaSembrada.Nueva("Iglesia de prueba B", "beto@ejemplo.invalid");

    public async Task InitializeAsync()
    {
        // Obviamente falsas: es un contenedor que vive lo que dura la prueba.
        const string contrasenaDeLaAplicacion = "contrasena-de-prueba";
        const string contrasenaDelPropietario = "contrasena-de-prueba-propietario";

        await _contenedor.StartAsync();

        await using var conexion = new NpgsqlConnection(CadenaDelDueno);
        await conexion.OpenAsync();

        new EjecutorDeMigraciones(CarpetaDeMigraciones(), DialectoSql.PostgreSql).Aplicar(conexion);

        // La migración crea los roles sin contraseña a propósito
        // (constitución, punto 7); aquí se les pone una para poder conectarse.
        await Ejecutar(conexion, $"ALTER ROLE symphony_app WITH PASSWORD '{contrasenaDeLaAplicacion}'");
        await Ejecutar(conexion, $"ALTER ROLE symphony_propietario WITH PASSWORD '{contrasenaDelPropietario}'");

        CadenaDeLaAplicacion = new NpgsqlConnectionStringBuilder(CadenaDelDueno)
        {
            Username = "symphony_app",
            Password = contrasenaDeLaAplicacion,

            // Sin pozo: una conexión reciclada podría traer fijada la iglesia
            // de la prueba anterior y hacer pasar una prueba que debería
            // fallar. Resolver eso de verdad es la fase 3 (T3.5).
            Pooling = false,
        }.ConnectionString;

        CadenaDelPropietario = new NpgsqlConnectionStringBuilder(CadenaDelDueno)
        {
            Username = "symphony_propietario",
            Password = contrasenaDelPropietario,
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

    /// <summary>
    /// Un usuario más, en la iglesia que se indique, con una contraseña real
    /// y sin dispositivos ni sesiones. Para las pruebas que necesitan un
    /// segundo usuario —correos duplicados entre iglesias, usuarios dados de
    /// baja— sin tocar el que ya siembra cada iglesia.
    /// </summary>
    public async Task<(string Correo, string Contrasena)> SembrarUsuarioAdicional(
        Guid iglesiaId, string correo, string contrasena, bool activo = true)
    {
        await using var conexion = new NpgsqlConnection(CadenaDelDueno);
        await conexion.OpenAsync();

        await Ejecutar(
            conexion,
            """
            INSERT INTO usuario (id, iglesia_id, correo, nombre, hash_contrasena, estado, creado_en)
                VALUES (@usuario, @iglesia, @correo, 'Persona adicional de prueba', @hashContrasena, @estado, now());
            INSERT INTO usuario_rol (usuario_id, rol) VALUES (@usuario, 'musico');
            """,
            ("usuario", Guid.CreateVersion7()),
            ("iglesia", iglesiaId),
            ("correo", correo),
            ("hashContrasena", Contrasenas.Guardar(contrasena)),
            ("estado", activo ? "activo" : "dado_de_baja"));

        return (correo, contrasena);
    }

    /// <summary>
    /// Consulta con el rol del dueño —se salta la política a propósito—, para
    /// comprobar en la base lo que un endpoint hizo, sin depender de que
    /// exista un endpoint de lectura para eso.
    /// </summary>
    public async Task<IReadOnlyList<T>> ConsultarComoDueno<T>(string sql, object? parametros = null)
    {
        await using var conexion = new NpgsqlConnection(CadenaDelDueno);
        await conexion.OpenAsync();
        return (await conexion.QueryAsync<T>(sql, parametros)).ToList();
    }

    private static async Task Sembrar(NpgsqlConnection conexion, IglesiaSembrada iglesia)
    {
        await Ejecutar(
            conexion,
            """
            INSERT INTO iglesia (id, nombre, estado, creada_en)
                VALUES (@iglesia, @nombre, 'activa', now());
            INSERT INTO usuario (id, iglesia_id, correo, nombre, hash_contrasena, estado, creado_en)
                VALUES (@usuario, @iglesia, @correo, 'Persona de prueba', @hashContrasena, 'activo', now());
            INSERT INTO usuario_rol (usuario_id, rol) VALUES (@usuario, 'musico');

            -- Dos, no uno: un músico toca varios instrumentos (spec R5), y con
            -- uno solo nunca se vería un borrado que se lleva de más.
            INSERT INTO usuario_instrumento (usuario_id, instrumento_id)
                SELECT @usuario, id FROM instrumento WHERE codigo IN ('piano', 'flauta1');

            INSERT INTO dispositivo (id, iglesia_id, usuario_id, tipo, nombre, creado_en)
                VALUES (@dispositivo, @iglesia, @usuario, 'movil', 'Teléfono de prueba', now());

            -- Una pantalla de proyección: pertenece a la iglesia y a ninguna
            -- persona (spec R7), así que es la fila que descubre a quien filtre
            -- por usuario creyendo que filtra por iglesia.
            INSERT INTO dispositivo (id, iglesia_id, usuario_id, tipo, nombre, creado_en)
                VALUES (@pantalla, @iglesia, NULL, 'pantalla', 'Pantalla del templo de prueba', now());

            -- Y uno ya revocado, para que revocar de nuevo y listar tengan que
            -- distinguir el estado además de la iglesia.
            INSERT INTO dispositivo (id, iglesia_id, usuario_id, tipo, nombre, creado_en, revocado_en)
                VALUES (@revocado, @iglesia, @usuario, 'tableta', 'Tableta perdida de prueba', now(), now());

            INSERT INTO sesion (id, dispositivo_id, iglesia_id, huella_token, emitida_en, expira_en)
                VALUES (@sesion, @dispositivo, @iglesia, @huella, now(), now() + interval '30 days');
            INSERT INTO usuario (id, iglesia_id, correo, nombre, hash_contrasena, estado, creado_en)
                VALUES (@administrador, @iglesia, @correoAdministrador, 'Administrador de prueba', @hashAdministrador, 'activo', now());
            INSERT INTO usuario_rol (usuario_id, rol) VALUES (@administrador, 'administrador');

            -- El tercer rol de la lista cerrada (spec R7). Ninguno incluye a
            -- otro, así que hace falta alguien que solo sea operador.
            INSERT INTO usuario (id, iglesia_id, correo, nombre, hash_contrasena, estado, creado_en)
                VALUES (@operador, @iglesia, @correoOperador, 'Operador de prueba', @hashOperador, 'activo', now());
            INSERT INTO usuario_rol (usuario_id, rol) VALUES (@operador, 'operador');
            """,
            ("iglesia", iglesia.Id),
            ("nombre", iglesia.Nombre),
            ("usuario", iglesia.UsuarioId),
            ("correo", iglesia.Correo),
            ("hashContrasena", Contrasenas.Guardar(iglesia.Contrasena)),
            ("dispositivo", iglesia.DispositivoId),
            ("pantalla", iglesia.PantallaId),
            ("revocado", iglesia.DispositivoRevocadoId),
            ("sesion", iglesia.SesionId),
            ("huella", iglesia.SesionId.ToString()),
            ("administrador", iglesia.AdministradorId),
            ("correoAdministrador", iglesia.AdministradorCorreo),
            ("hashAdministrador", Contrasenas.Guardar(iglesia.AdministradorContrasena)),
            ("operador", iglesia.OperadorId),
            ("correoOperador", iglesia.OperadorCorreo),
            ("hashOperador", Contrasenas.Guardar(iglesia.OperadorContrasena)));
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

/// <summary>
/// Todo lo que una iglesia sembrada tiene a mano. Las pruebas de cruce (T8.2)
/// usan estos identificadores <b>de la iglesia ajena</b> a propósito: el
/// aislamiento se prueba con los datos correctos en la mano, no adivinando.
/// </summary>
public sealed record IglesiaSembrada(
    Guid Id,
    string Nombre,
    string Correo,
    string Contrasena,
    Guid UsuarioId,
    Guid DispositivoId,
    Guid SesionId,
    Guid AdministradorId,
    string AdministradorCorreo,
    string AdministradorContrasena,
    Guid OperadorId,
    string OperadorCorreo,
    string OperadorContrasena,
    Guid PantallaId,
    Guid DispositivoRevocadoId)
{
    public static IglesiaSembrada Nueva(string nombre, string correo) => new(
        Id: Guid.CreateVersion7(),
        Nombre: nombre,
        Correo: correo,
        Contrasena: ContrasenaInventada(),
        UsuarioId: Guid.CreateVersion7(),
        DispositivoId: Guid.CreateVersion7(),
        SesionId: Guid.CreateVersion7(),
        AdministradorId: Guid.CreateVersion7(),
        AdministradorCorreo: "administrador-" + correo,
        AdministradorContrasena: ContrasenaInventada(),
        OperadorId: Guid.CreateVersion7(),
        OperadorCorreo: "operador-" + correo,
        OperadorContrasena: ContrasenaInventada(),
        PantallaId: Guid.CreateVersion7(),
        DispositivoRevocadoId: Guid.CreateVersion7());

    private static string ContrasenaInventada() => "contrasena-de-prueba-" + Guid.NewGuid().ToString("N")[..8];
}
