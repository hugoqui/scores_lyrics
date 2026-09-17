namespace Symphony.Sesiones.Web;

/// <summary>
/// Convierte el token que trae una petición en la sesión que hay detrás, o en
/// nada. Es el mismo componente en la nube y en el nodo a propósito: dos
/// implementaciones de esto es la forma más fácil de que una de las dos se
/// quede sin una comprobación.
///
/// <para>
/// Acepta <b>varias claves públicas</b> porque hay dos emisores ([ADR 0016]):
/// la nube y el nodo del templo. El nodo tiene que aceptar las dos —la suya
/// para lo que emitió el domingo sin internet, y la de la nube para lo que se
/// emitió desde fuera—, y ninguna de las dos verificaciones usa la red.
/// </para>
/// </summary>
public sealed class VerificadorDeSesiones
{
    private readonly IReadOnlyList<ClavePublicaDeFirma> _claves;
    private readonly Guid? _iglesiaDelServidor;
    private readonly TimeProvider _reloj;

    private VerificadorDeSesiones(
        IReadOnlyList<ClavePublicaDeFirma> claves, Guid? iglesiaDelServidor, TimeProvider? reloj)
    {
        if (claves.Count == 0)
        {
            throw new ArgumentException(
                "Un verificador sin claves rechazaría toda sesión válida en silencio.", nameof(claves));
        }

        _claves = claves;
        _iglesiaDelServidor = iglesiaDelServidor;
        _reloj = reloj ?? TimeProvider.System;
    }

    /// <summary>
    /// El nodo sirve a una sola iglesia (spec R1) y la tiene en su
    /// configuración: todo token que no sea de ella se rechaza aquí, antes de
    /// llegar a ninguna consulta.
    /// </summary>
    public static VerificadorDeSesiones ParaUnNodo(
        Guid iglesiaDelNodo, IReadOnlyList<ClavePublicaDeFirma> claves, TimeProvider? reloj = null)
    {
        if (iglesiaDelNodo == Guid.Empty)
        {
            throw new ArgumentException("Un nodo sin iglesia no puede verificar nada.", nameof(iglesiaDelNodo));
        }

        return new VerificadorDeSesiones(claves, iglesiaDelNodo, reloj);
    }

    /// <summary>
    /// La nube sirve a todas las iglesias, así que no tiene una propia contra
    /// la que comparar: la iglesia de la petición sale del token y de ningún
    /// otro sitio (spec R3).
    /// </summary>
    public static VerificadorDeSesiones ParaLaNube(
        IReadOnlyList<ClavePublicaDeFirma> claves, TimeProvider? reloj = null) =>
        new(claves, iglesiaDelServidor: null, reloj);

    public ResultadoDeVerificacion Verificar(string token, TipoDeToken tipoEsperado = TipoDeToken.Acceso)
    {
        var ahora = _reloj.GetUtcNow();
        var ultimo = new ResultadoDeVerificacion(null, MotivoDeRechazo.FirmaInvalida);

        foreach (var clave in _claves)
        {
            var resultado = _iglesiaDelServidor is Guid iglesia
                ? Tokens.Verificar(token, clave, ahora, iglesia, tipoEsperado)
                : Tokens.VerificarTomandoLaIglesiaDelToken(token, clave, ahora, tipoEsperado);

            if (resultado.EsValida)
            {
                return resultado;
            }

            // Que la firma no sea de esta clave solo significa que hay que
            // probar la siguiente. Cualquier otro motivo —caducado, de otra
            // iglesia, del tipo equivocado— ya es definitivo: probar más claves
            // no lo va a arreglar, y conservarlo da el motivo real.
            if (resultado.Motivo != MotivoDeRechazo.FirmaInvalida)
            {
                return resultado;
            }

            ultimo = resultado;
        }

        return ultimo;
    }
}
