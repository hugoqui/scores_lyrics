using Org.BouncyCastle.Crypto;
using Org.BouncyCastle.Crypto.Generators;
using Org.BouncyCastle.Crypto.Parameters;
using Org.BouncyCastle.Security;

namespace Symphony.Sesiones;

/// <summary>
/// Un par de claves Ed25519 ([ADR 0016]). Quien firma necesita la privada;
/// quien verifica, solo la pública — ese es el punto entero, porque permite que
/// el nodo valide una sesión emitida por la nube sin llamar a nadie.
///
/// Las claves se transportan en base64 y se leen del entorno. <b>Ninguna clave
/// privada entra al repositorio</b> (constitución, punto 7).
/// </summary>
public sealed class ParDeClaves
{
    private ParDeClaves(byte[] privada, byte[] publica)
    {
        Privada = privada;
        Publica = publica;
    }

    public byte[] Privada { get; }

    public byte[] Publica { get; }

    public string PrivadaEnBase64 => Convert.ToBase64String(Privada);

    public string PublicaEnBase64 => Convert.ToBase64String(Publica);

    /// <summary>
    /// Qué clave firmó, derivado de la propia clave pública en vez de
    /// configurarse aparte: una variable menos que se pueda poner mal, y dos
    /// claves distintas nunca comparten identificador.
    /// </summary>
    public string Id => IdDe(Publica);

    /// <summary>
    /// La mitad con la que se verifica lo que este par firma. Quien emite
    /// también verifica lo suyo —la nube acepta sus propias sesiones— y sin
    /// esto tendría que pasearse la privada hasta el verificador.
    /// </summary>
    public ClavePublicaDeFirma ClavePublica => ClavePublicaDeFirma.DesdeBytes(Publica);

    internal static string IdDe(byte[] publica) =>
        Convert.ToHexStringLower(System.Security.Cryptography.SHA256.HashData(publica))[..8];

    public static ParDeClaves Generar()
    {
        var generador = new Ed25519KeyPairGenerator();
        generador.Init(new Ed25519KeyGenerationParameters(new SecureRandom()));

        var par = generador.GenerateKeyPair();
        return new ParDeClaves(
            ((Ed25519PrivateKeyParameters)par.Private).GetEncoded(),
            ((Ed25519PublicKeyParameters)par.Public).GetEncoded());
    }

    public static ParDeClaves DesdeBase64(string privada)
    {
        var bytes = Leer(privada, Ed25519PrivateKeyParameters.KeySize, "privada");
        var clave = new Ed25519PrivateKeyParameters(bytes);
        return new ParDeClaves(bytes, clave.GeneratePublicKey().GetEncoded());
    }

    internal ICipherParameters ParaFirmar() => new Ed25519PrivateKeyParameters(Privada);

    internal static byte[] Leer(string base64, int tamanoEsperado, string cual)
    {
        byte[] bytes;
        try
        {
            bytes = Convert.FromBase64String(base64);
        }
        catch (FormatException)
        {
            throw new ArgumentException($"La clave {cual} no está en base64.", nameof(base64));
        }

        if (bytes.Length != tamanoEsperado)
        {
            throw new ArgumentException(
                $"La clave {cual} mide {bytes.Length} bytes y Ed25519 son {tamanoEsperado}.", nameof(base64));
        }

        return bytes;
    }
}

/// <summary>La mitad que basta para verificar. Es la que viaja a los nodos.</summary>
public sealed class ClavePublicaDeFirma
{
    private readonly byte[] _bytes;

    private ClavePublicaDeFirma(byte[] bytes) => _bytes = bytes;

    public static ClavePublicaDeFirma DesdeBase64(string publica) =>
        new(ParDeClaves.Leer(publica, Ed25519PublicKeyParameters.KeySize, "pública"));

    internal static ClavePublicaDeFirma DesdeBytes(byte[] publica) => new(publica);

    /// <summary>El mismo identificador que expone <see cref="ParDeClaves.Id"/> para su par.</summary>
    public string Id => ParDeClaves.IdDe(_bytes);

    internal ICipherParameters ParaVerificar() => new Ed25519PublicKeyParameters(_bytes);
}
