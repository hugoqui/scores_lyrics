using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using Org.BouncyCastle.Crypto.Signers;

namespace Symphony.Sesiones;

/// <summary>Por qué no se aceptó un token. Quien verifica no distingue matices hacia afuera.</summary>
public enum MotivoDeRechazo
{
    Ninguno,
    MalFormado,
    FirmaInvalida,
    Caducado,
    OtraIglesia,
    TipoEquivocado,
}

public sealed record ResultadoDeVerificacion(Sesion? Sesion, MotivoDeRechazo Motivo)
{
    public bool EsValida => Sesion is not null;
}

/// <summary>
/// Emite y verifica los tokens de sesión ([ADR 0016]).
///
/// El formato es compacto: <c>cuerpo.firma</c>, las dos partes en base64 sin
/// relleno. No hay negociación de algoritmo — el token no dice con qué se firmó
/// y aquí no se le pregunta: <b>siempre es Ed25519</b>. Es deliberado. Los
/// formatos que dejan al token elegir su algoritmo son los que permiten el
/// ataque clásico de pedir "ninguno" y que el servidor obedezca.
///
/// Quien verifica solo necesita la clave pública y su propio reloj. Sin red.
/// </summary>
public static class Tokens
{
    private static readonly JsonSerializerOptions _formato = new(JsonSerializerDefaults.Web);

    public static string Emitir(Sesion sesion, ParDeClaves claves)
    {
        var cuerpo = JsonSerializer.SerializeToUtf8Bytes(sesion, _formato);

        var firmador = new Ed25519Signer();
        firmador.Init(forSigning: true, claves.ParaFirmar());
        firmador.BlockUpdate(cuerpo, 0, cuerpo.Length);

        return $"{Base64Url(cuerpo)}.{Base64Url(firmador.GenerateSignature())}";
    }

    /// <summary>
    /// Verifica firma, caducidad, iglesia y tipo, en ese orden. El reloj es el
    /// de quien verifica: lo que diga el cliente sobre la fecha no interviene
    /// en ningún punto (000-seguridad R8).
    /// </summary>
    public static ResultadoDeVerificacion Verificar(
        string token,
        ClavePublicaDeFirma clave,
        DateTimeOffset ahora,
        Guid iglesiaEsperada,
        TipoDeToken tipoEsperado = TipoDeToken.Acceso) =>
        Comprobar(token, clave, ahora, iglesiaEsperada, tipoEsperado);

    /// <summary>
    /// Igual que <see cref="Verificar"/> pero sin exigir una iglesia concreta,
    /// porque la toma del token: <b>es solo para la nube</b>, que sirve a todas
    /// las iglesias y por tanto no tiene una propia contra la que comparar.
    ///
    /// <para>
    /// El nodo nunca usa esto. El nodo sirve a una sola iglesia (spec R1) y
    /// tiene su identificador en la configuración, así que dejar de comparar
    /// allí sería regalar la única comprobación que impide que un token de otra
    /// congregación abra sus datos.
    /// </para>
    /// <para>
    /// Que la iglesia salga del token y no de la petición es exactamente lo que
    /// pide spec R3. Quien llame a esto usa <c>sesion.IglesiaId</c> y no acepta
    /// ningún identificador de iglesia del cliente.
    /// </para>
    /// </summary>
    public static ResultadoDeVerificacion VerificarTomandoLaIglesiaDelToken(
        string token,
        ClavePublicaDeFirma clave,
        DateTimeOffset ahora,
        TipoDeToken tipoEsperado = TipoDeToken.Acceso) =>
        Comprobar(token, clave, ahora, iglesiaEsperada: null, tipoEsperado);

    private static ResultadoDeVerificacion Comprobar(
        string token,
        ClavePublicaDeFirma clave,
        DateTimeOffset ahora,
        Guid? iglesiaEsperada,
        TipoDeToken tipoEsperado)
    {
        var partes = token.Split('.');
        if (partes.Length != 2)
        {
            return new ResultadoDeVerificacion(null, MotivoDeRechazo.MalFormado);
        }

        byte[] cuerpo;
        byte[] firma;
        Sesion? sesion;
        try
        {
            cuerpo = DeBase64Url(partes[0]);
            firma = DeBase64Url(partes[1]);
            sesion = JsonSerializer.Deserialize<Sesion>(cuerpo, _formato);
        }
        catch (Exception excepcion) when (excepcion is FormatException or JsonException)
        {
            return new ResultadoDeVerificacion(null, MotivoDeRechazo.MalFormado);
        }

        if (sesion is null)
        {
            return new ResultadoDeVerificacion(null, MotivoDeRechazo.MalFormado);
        }

        var verificador = new Ed25519Signer();
        verificador.Init(forSigning: false, clave.ParaVerificar());
        verificador.BlockUpdate(cuerpo, 0, cuerpo.Length);
        if (!verificador.VerifySignature(firma))
        {
            return new ResultadoDeVerificacion(null, MotivoDeRechazo.FirmaInvalida);
        }

        if (ahora >= sesion.ExpiraEn)
        {
            return new ResultadoDeVerificacion(null, MotivoDeRechazo.Caducado);
        }

        // Un token emitido para una iglesia no sirve en otra, aunque su firma
        // sea impecable: la clave del nodo y la de la nube son válidas para
        // todas, y lo que ata la sesión a su congregación es esto.
        if (iglesiaEsperada is not null && sesion.IglesiaId != iglesiaEsperada)
        {
            return new ResultadoDeVerificacion(null, MotivoDeRechazo.OtraIglesia);
        }

        if (sesion.Tipo != tipoEsperado)
        {
            return new ResultadoDeVerificacion(null, MotivoDeRechazo.TipoEquivocado);
        }

        return new ResultadoDeVerificacion(sesion, MotivoDeRechazo.Ninguno);
    }

    /// <summary>
    /// Lo único que se guarda de un token de renovación ([ADR 0016]). Quien
    /// lea la tabla de sesiones —o su respaldo— no obtiene con qué entrar.
    /// </summary>
    public static string Huella(string token) =>
        Convert.ToHexStringLower(SHA256.HashData(Encoding.UTF8.GetBytes(token)));

    private static string Base64Url(byte[] datos) =>
        Convert.ToBase64String(datos).TrimEnd('=').Replace('+', '-').Replace('/', '_');

    private static byte[] DeBase64Url(string texto)
    {
        var base64 = texto.Replace('-', '+').Replace('_', '/');
        return Convert.FromBase64String(base64.PadRight((base64.Length + 3) / 4 * 4, '='));
    }
}
