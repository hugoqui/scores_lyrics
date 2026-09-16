using System.Data.Common;
using System.Globalization;
using System.Security.Cryptography;
using System.Text;
using System.Text.RegularExpressions;

namespace Symphony.Migraciones;

/// <summary>
/// Aplica migraciones en SQL plano ([ADR 0010]): lee los <c>.sql</c> de una
/// carpeta, los ordena por número y aplica los pendientes en una transacción,
/// anotando cada uno en <see cref="TablaDeControl"/>.
///
/// Las dos propiedades que tiene que cumplir, y que las pruebas fijan:
/// <list type="bullet">
///   <item><description><b>Convergencia</b>: base vacía y base a medio migrar
///   terminan en el mismo esquema.</description></item>
///   <item><description><b>Idempotencia</b>: aplicar dos veces no cambia nada
///   ni falla.</description></item>
/// </list>
/// Ante cualquier duda sobre el estado del esquema, lanza
/// <see cref="ErrorDeMigracion"/> en vez de seguir.
/// </summary>
public sealed partial class EjecutorDeMigraciones
{
    public const string TablaDeControl = "migraciones_aplicadas";

    private readonly string _carpeta;
    private readonly DialectoSql _dialecto;

    public EjecutorDeMigraciones(string carpeta, DialectoSql dialecto)
    {
        _carpeta = carpeta;
        _dialecto = dialecto;
    }

    /// <summary>
    /// Lee la carpeta y devuelve las migraciones ordenadas por número.
    /// Un archivo que no siga <c>NNNN_nombre.sql</c> es un error, no algo que
    /// se ignore en silencio: un archivo ignorado es una migración que nadie
    /// aplicó y nadie notó.
    /// </summary>
    public IReadOnlyList<Migracion> LeerDeDisco()
    {
        if (!Directory.Exists(_carpeta))
        {
            throw new ErrorDeMigracion($"No existe la carpeta de migraciones '{_carpeta}'.");
        }

        var migraciones = new List<Migracion>();
        var porNumero = new Dictionary<int, string>();

        foreach (var ruta in Directory.EnumerateFiles(_carpeta, "*.sql").OrderBy(r => r, StringComparer.Ordinal))
        {
            var archivo = Path.GetFileName(ruta);
            var coincidencia = PatronDeArchivo().Match(archivo);
            if (!coincidencia.Success)
            {
                throw new ErrorDeMigracion(
                    $"El archivo '{archivo}' no sigue el formato NNNN_nombre.sql. " +
                    "Renómbralo o sácalo de la carpeta de migraciones.");
            }

            var numero = int.Parse(coincidencia.Groups[1].Value, CultureInfo.InvariantCulture);
            if (porNumero.TryGetValue(numero, out var yaVisto))
            {
                throw new ErrorDeMigracion(
                    $"Hay dos migraciones con el número {numero:D4}: '{yaVisto}' y '{archivo}'.");
            }

            porNumero[numero] = archivo;
            var sql = Normalizar(File.ReadAllText(ruta));
            migraciones.Add(new Migracion(numero, coincidencia.Groups[2].Value, archivo, sql, Huella(sql)));
        }

        return migraciones.OrderBy(m => m.Numero).ToList();
    }

    /// <summary>
    /// Aplica lo pendiente sobre <paramref name="conexion"/>. Devuelve qué
    /// aplicó y qué ya estaba. Si no hay nada pendiente, no toca la base.
    /// </summary>
    public ResultadoDeMigracion Aplicar(DbConnection conexion)
    {
        var enDisco = LeerDeDisco();

        if (conexion.State != System.Data.ConnectionState.Open)
        {
            conexion.Open();
        }

        Ejecutar(conexion, _dialecto.DdlTablaDeControl);
        var aplicadas = LeerAplicadas(conexion);

        VerificarLoYaAplicado(enDisco, aplicadas);

        var pendientes = enDisco.Where(m => !aplicadas.ContainsKey(m.Numero)).ToList();
        if (pendientes.Count == 0)
        {
            return new ResultadoDeMigracion([], enDisco.Select(m => m.NombreCompleto).ToList());
        }

        // Una migración con número menor al último aplicado rompería la
        // convergencia: una base nueva la aplicaría y una base vieja nunca.
        if (aplicadas.Count > 0)
        {
            var ultimoAplicado = aplicadas.Keys.Max();
            var fueraDeOrden = pendientes.Where(m => m.Numero < ultimoAplicado).ToList();
            if (fueraDeOrden.Count > 0)
            {
                throw new ErrorDeMigracion(
                    $"Estas migraciones son anteriores a la última aplicada ({ultimoAplicado:D4}): " +
                    $"{string.Join(", ", fueraDeOrden.Select(m => m.Archivo))}. " +
                    "Renumérala por encima de la última; una migración aplicada no se reordena.");
            }
        }

        using var transaccion = conexion.BeginTransaction();
        foreach (var migracion in pendientes)
        {
            Ejecutar(conexion, migracion.Sql, transaccion);
            Anotar(conexion, transaccion, migracion);
        }

        transaccion.Commit();

        return new ResultadoDeMigracion(
            pendientes.Select(m => m.NombreCompleto).ToList(),
            aplicadas.Values.Select(a => a.Nombre).ToList());
    }

    private static void VerificarLoYaAplicado(
        IReadOnlyList<Migracion> enDisco,
        IReadOnlyDictionary<int, (string Nombre, string Hash)> aplicadas)
    {
        var porNumero = enDisco.ToDictionary(m => m.Numero);

        foreach (var (numero, aplicada) in aplicadas.OrderBy(p => p.Key))
        {
            if (!porNumero.TryGetValue(numero, out var enArchivo))
            {
                throw new ErrorDeMigracion(
                    $"La migración '{aplicada.Nombre}' está aplicada en la base pero ya no está en disco. " +
                    "Una migración aplicada no se borra.");
            }

            if (!string.Equals(enArchivo.Hash, aplicada.Hash, StringComparison.Ordinal))
            {
                throw new ErrorDeMigracion(
                    $"La migración '{enArchivo.Archivo}' cambió en disco después de haberse aplicado. " +
                    "Una migración aplicada no se edita: corrígela con una migración nueva.");
            }
        }
    }

    private static Dictionary<int, (string Nombre, string Hash)> LeerAplicadas(DbConnection conexion)
    {
        using var comando = conexion.CreateCommand();
        comando.CommandText = $"SELECT numero, nombre, hash FROM {TablaDeControl} ORDER BY numero";

        var aplicadas = new Dictionary<int, (string, string)>();
        using var lector = comando.ExecuteReader();
        while (lector.Read())
        {
            aplicadas[lector.GetInt32(0)] = (lector.GetString(1), lector.GetString(2));
        }

        return aplicadas;
    }

    private static void Anotar(DbConnection conexion, DbTransaction transaccion, Migracion migracion)
    {
        using var comando = conexion.CreateCommand();
        comando.Transaction = transaccion;
        comando.CommandText =
            $"INSERT INTO {TablaDeControl} (numero, nombre, hash, aplicada_en) " +
            "VALUES (@numero, @nombre, @hash, @aplicada_en)";
        AgregarParametro(comando, "@numero", migracion.Numero);
        AgregarParametro(comando, "@nombre", migracion.NombreCompleto);
        AgregarParametro(comando, "@hash", migracion.Hash);
        AgregarParametro(comando, "@aplicada_en", DateTime.UtcNow);
        comando.ExecuteNonQuery();
    }

    private static void AgregarParametro(DbCommand comando, string nombre, object valor)
    {
        var parametro = comando.CreateParameter();
        parametro.ParameterName = nombre;
        parametro.Value = valor;
        comando.Parameters.Add(parametro);
    }

    private static void Ejecutar(DbConnection conexion, string sql, DbTransaction? transaccion = null)
    {
        using var comando = conexion.CreateCommand();
        comando.Transaction = transaccion;
        comando.CommandText = sql;
        comando.ExecuteNonQuery();
    }

    /// <summary>
    /// El hash se calcula sobre el texto normalizado, no sobre los bytes: un
    /// clon en Windows con finales de línea CRLF no puede invalidar una
    /// migración que ya corrió en una iglesia.
    /// </summary>
    private static string Normalizar(string texto) =>
        texto.TrimStart('﻿').Replace("\r\n", "\n", StringComparison.Ordinal);

    private static string Huella(string sql) =>
        Convert.ToHexStringLower(SHA256.HashData(Encoding.UTF8.GetBytes(sql)));

    [GeneratedRegex(@"^(\d{4})_(.+)\.sql$", RegexOptions.CultureInvariant)]
    private static partial Regex PatronDeArchivo();
}
