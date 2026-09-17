using System.Globalization;
using System.Security.Cryptography;
using System.Text;
using Org.BouncyCastle.Crypto.Generators;
using Org.BouncyCastle.Crypto.Parameters;

namespace Symphony.Sesiones;

/// <summary>
/// Guarda y verifica contraseñas con Argon2id ([ADR 0016], [ADR 0018]).
///
/// El hash resultante es una cadena que se describe a sí misma, en el formato
/// PHC que usa la herramienta de referencia:
/// <c>$argon2id$v=19$m=65536,t=3,p=1$sal$hash</c>. Lleva dentro sus propios
/// parámetros, y por eso se pueden subir mañana sin invalidar las contraseñas
/// de hoy: cada una se verifica con los suyos.
/// </summary>
public static class Contrasenas
{
    private const int _tamanoDeSalEnBytes = 16;
    private const int _tamanoDeHashEnBytes = 32;
    private const int _versionDeArgon = 19;

    public static string Guardar(string contrasena, ParametrosArgon2id? parametros = null)
    {
        parametros ??= ParametrosArgon2id.PorDefecto;

        // Sal por usuario, de azar criptográfico: dos personas con la misma
        // contraseña no comparten hash, así que una tabla precalculada no
        // sirve de nada.
        var sal = RandomNumberGenerator.GetBytes(_tamanoDeSalEnBytes);
        var hash = Derivar(contrasena, sal, parametros);

        return $"$argon2id$v={_versionDeArgon}$" +
            $"m={parametros.MemoriaEnKib},t={parametros.Iteraciones},p={parametros.Paralelismo}$" +
            $"{Base64SinRelleno(sal)}${Base64SinRelleno(hash)}";
    }

    /// <summary>
    /// Verifica con los parámetros que trae el propio hash, no con los de hoy.
    /// La comparación es en tiempo constante: cuánto tarda en decir que no, no
    /// puede depender de cuánto acertó quien lo intenta.
    /// </summary>
    public static bool Coinciden(string contrasena, string guardado)
    {
        if (!Interpretar(guardado, out var parametros, out var sal, out var esperado))
        {
            return false;
        }

        var calculado = Derivar(contrasena, sal, parametros, esperado.Length);
        return CryptographicOperations.FixedTimeEquals(calculado, esperado);
    }

    /// <summary>
    /// Si los parámetros con los que se guardó se quedaron cortos frente a los
    /// de hoy, conviene rehacerlo la próxima vez que su dueño entre —que es el
    /// único momento en que la contraseña está disponible en claro.
    /// </summary>
    public static bool ConvieneRehacer(string guardado, ParametrosArgon2id? objetivo = null)
    {
        objetivo ??= ParametrosArgon2id.PorDefecto;

        return !Interpretar(guardado, out var parametros, out _, out _)
            || parametros.MemoriaEnKib < objetivo.MemoriaEnKib
            || parametros.Iteraciones < objetivo.Iteraciones;
    }

    private static byte[] Derivar(string contrasena, byte[] sal, ParametrosArgon2id parametros, int tamano = _tamanoDeHashEnBytes)
    {
        var generador = new Argon2BytesGenerator();
        generador.Init(new Argon2Parameters.Builder(Argon2Parameters.Argon2id)
            .WithVersion(Argon2Parameters.Version13)
            .WithSalt(sal)
            .WithMemoryAsKB(parametros.MemoriaEnKib)
            .WithIterations(parametros.Iteraciones)
            .WithParallelism(parametros.Paralelismo)
            .Build());

        var resultado = new byte[tamano];
        generador.GenerateBytes(Encoding.UTF8.GetBytes(contrasena), resultado);
        return resultado;
    }

    private static bool Interpretar(
        string guardado,
        out ParametrosArgon2id parametros,
        out byte[] sal,
        out byte[] hash)
    {
        parametros = ParametrosArgon2id.PorDefecto;
        sal = [];
        hash = [];

        var partes = guardado.Split('$');
        if (partes.Length != 6 || partes[1] != "argon2id")
        {
            return false;
        }

        var costos = partes[3].Split(',');
        if (costos.Length != 3)
        {
            return false;
        }

        try
        {
            parametros = new ParametrosArgon2id(
                Numero(costos[0], "m="),
                Numero(costos[1], "t="),
                Numero(costos[2], "p="));
            sal = DeBase64SinRelleno(partes[4]);
            hash = DeBase64SinRelleno(partes[5]);
        }
        catch (Exception excepcion) when (excepcion is FormatException or ArgumentException)
        {
            return false;
        }

        return sal.Length > 0 && hash.Length > 0;
    }

    private static int Numero(string parte, string prefijo) =>
        int.Parse(parte[prefijo.Length..], CultureInfo.InvariantCulture);

    private static string Base64SinRelleno(byte[] datos) => Convert.ToBase64String(datos).TrimEnd('=');

    private static byte[] DeBase64SinRelleno(string texto) =>
        Convert.FromBase64String(texto.PadRight((texto.Length + 3) / 4 * 4, '='));
}
