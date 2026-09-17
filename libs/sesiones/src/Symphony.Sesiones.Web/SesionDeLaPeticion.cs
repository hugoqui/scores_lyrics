using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Http;

namespace Symphony.Sesiones.Web;

/// <summary>
/// Pone la sesión firmada al alcance de cada petición, y no deja ningún otro
/// sitio de donde sacarla.
///
/// <para>
/// El middleware <b>no rechaza nada</b>: solo traduce el token en sesión. Quien
/// rechaza es <see cref="ExigirOperacion"/>, endpoint por endpoint, porque hay
/// endpoints que tienen que atender sin sesión —el login, justamente— y una
/// puerta que rechaza por defecto obliga a abrir agujeros con excepciones, que
/// es como se abren de más.
/// </para>
/// </summary>
public static class SesionDeLaPeticion
{
    private const string _clave = "symphony.sesion";

    public static IApplicationBuilder UsarSesionesFirmadas(this IApplicationBuilder app) =>
        app.Use(async (contexto, siguiente) =>
        {
            var verificador = contexto.RequestServices.GetService(typeof(VerificadorDeSesiones))
                as VerificadorDeSesiones
                ?? throw new InvalidOperationException(
                    "No hay VerificadorDeSesiones registrado: sin él ninguna petición tendría sesión " +
                    "y todo endpoint protegido respondería 401 sin decir por qué.");

            var cabecera = contexto.Request.Headers.Authorization.ToString();
            const string prefijo = "Bearer ";

            if (cabecera.StartsWith(prefijo, StringComparison.Ordinal))
            {
                var resultado = verificador.Verificar(cabecera[prefijo.Length..].Trim());
                if (resultado.Sesion is not null)
                {
                    contexto.Items[_clave] = resultado.Sesion;
                }
            }

            await siguiente();
        });

    /// <summary>La sesión de esta petición, o <c>null</c> si no trajo una válida.</summary>
    public static Sesion? Sesion(this HttpContext contexto) => contexto.Items[_clave] as Sesion;

    /// <summary>
    /// La sesión de esta petición, en un endpoint que ya exigió una operación y
    /// por tanto no puede llegar aquí sin ella. Si falta, es un error de
    /// cableado y se grita: devolver una iglesia vacía sería consultar sin
    /// filtro.
    /// </summary>
    public static Sesion SesionObligatoria(this HttpContext contexto) =>
        contexto.Sesion() ?? throw new InvalidOperationException(
            "Este endpoint se ejecutó sin sesión. Le falta .Exige(...) o el middleware de sesiones.");
}
