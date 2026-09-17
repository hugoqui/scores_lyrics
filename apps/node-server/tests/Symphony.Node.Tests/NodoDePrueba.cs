using Microsoft.Data.Sqlite;
using Microsoft.Extensions.Logging.Abstractions;
using Symphony.Migraciones;
using Symphony.Node.BaseDeDatos;
using Symphony.Node.Configuration;
using Symphony.Sesiones;

namespace Symphony.Node.Tests;

/// <summary>
/// Configuración válida apuntando a un SQLite temporal en carpeta propia
/// ([ADR 0011]). Al terminar limpia las variables y borra la carpeta, para que
/// ninguna prueba dependa de otra ni del orden.
/// </summary>
public sealed class NodoDePrueba : IDisposable
{
    private readonly string _raiz;

    public NodoDePrueba(Guid? iglesiaId = null)
    {
        IglesiaId = iglesiaId ?? Guid.CreateVersion7();
        _raiz = Path.Combine(Path.GetTempPath(), "symphony-nodo", Guid.NewGuid().ToString("N"));
        Directory.CreateDirectory(_raiz);
        ArchivoSqlite = Path.Combine(_raiz, "nodo.sqlite");

        Environment.SetEnvironmentVariable(NodeOptions.SqlitePathVariable, ArchivoSqlite);
        Environment.SetEnvironmentVariable(NodeOptions.CloudUrlVariable, "https://nube.prueba.local");
        Environment.SetEnvironmentVariable(NodeOptions.IglesiaIdVariable, IglesiaId.ToString());

        ClaveDelNodo = ParDeClaves.Generar();
        ClaveDeLaNube = ParDeClaves.Generar();
        Environment.SetEnvironmentVariable(NodeOptions.ClavePrivadaVariable, ClaveDelNodo.PrivadaEnBase64);
        Environment.SetEnvironmentVariable(
            NodeOptions.ClavePublicaDeLaNubeVariable, ClaveDeLaNube.PublicaEnBase64);
    }

    public string ArchivoSqlite { get; }

    public Guid IglesiaId { get; }

    public ParDeClaves ClaveDelNodo { get; }

    public ParDeClaves ClaveDeLaNube { get; }

    public void OlvidarConfiguracion()
    {
        Environment.SetEnvironmentVariable(NodeOptions.SqlitePathVariable, null);
        Environment.SetEnvironmentVariable(NodeOptions.CloudUrlVariable, null);
        Environment.SetEnvironmentVariable(NodeOptions.IglesiaIdVariable, null);
        Environment.SetEnvironmentVariable(NodeOptions.ClavePrivadaVariable, null);
        Environment.SetEnvironmentVariable(NodeOptions.ClavePublicaDeLaNubeVariable, null);
    }

    public SqliteConnection Abrir()
    {
        var conexion = new SqliteConnection(
            new SqliteConnectionStringBuilder { DataSource = ArchivoSqlite }.ToString());
        conexion.Open();
        return conexion;
    }

    /// <summary>Aplica las migraciones sin levantar el servidor.</summary>
    public void Migrar() =>
        MigracionesDelNodo.Aplicar(NodeOptions.FromEnvironment("Development"), NullLogger.Instance);

    public void SembrarIglesia(Guid id, string nombre = "Iglesia de prueba")
    {
        using var conexion = Abrir();
        using var comando = conexion.CreateCommand();
        comando.CommandText =
            """
            INSERT INTO iglesia (fila, id, nombre, estado, creada_en)
            VALUES (1, $id, $nombre, 'activa', '2026-01-01T00:00:00Z')
            """;
        comando.Parameters.AddWithValue("$id", id.ToString());
        comando.Parameters.AddWithValue("$nombre", nombre);
        comando.ExecuteNonQuery();
    }

    /// <summary>Un usuario con contraseña real, para las pruebas de login (T5.2).</summary>
    public (Guid Id, string Correo, string Contrasena) SembrarUsuario(
        string correo, string contrasena, bool activo = true, params string[] roles)
    {
        var id = Guid.CreateVersion7();
        using var conexion = Abrir();

        using (var comando = conexion.CreateCommand())
        {
            comando.CommandText =
                """
                INSERT INTO usuario (id, iglesia_id, correo, nombre, hash_contrasena, estado, creado_en)
                VALUES ($id, $iglesia, $correo, 'Persona de prueba', $hash, $estado, '2026-01-01T00:00:00Z')
                """;
            comando.Parameters.AddWithValue("$id", id.ToString());
            comando.Parameters.AddWithValue("$iglesia", IglesiaId.ToString());
            comando.Parameters.AddWithValue("$correo", correo);
            comando.Parameters.AddWithValue("$hash", Contrasenas.Guardar(contrasena));
            comando.Parameters.AddWithValue("$estado", activo ? "activo" : "dado_de_baja");
            comando.ExecuteNonQuery();
        }

        foreach (var rol in roles)
        {
            using var comando = conexion.CreateCommand();
            comando.CommandText = "INSERT INTO usuario_rol (usuario_id, rol) VALUES ($id, $rol)";
            comando.Parameters.AddWithValue("$id", id.ToString());
            comando.Parameters.AddWithValue("$rol", rol);
            comando.ExecuteNonQuery();
        }

        return (id, correo, contrasena);
    }

    public IReadOnlyList<string> MigracionesAplicadas()
    {
        using var conexion = Abrir();
        using var comando = conexion.CreateCommand();
        comando.CommandText = $"SELECT nombre FROM {EjecutorDeMigraciones.TablaDeControl} ORDER BY numero";

        var nombres = new List<string>();
        using var lector = comando.ExecuteReader();
        while (lector.Read())
        {
            nombres.Add(lector.GetString(0));
        }

        return nombres;
    }

    public void Dispose()
    {
        OlvidarConfiguracion();
        SqliteConnection.ClearAllPools();
        try
        {
            Directory.Delete(_raiz, recursive: true);
        }
        catch (IOException)
        {
            // Una carpeta temporal que no se pudo borrar no invalida la prueba.
        }
    }
}
