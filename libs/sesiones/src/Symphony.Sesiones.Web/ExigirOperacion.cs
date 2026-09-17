using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Http;

namespace Symphony.Sesiones.Web;

/// <summary>
/// La comprobación de autorización del servidor, una por operación (spec R7).
///
/// <para>
/// Se rechaza aquí aunque la interfaz haya mostrado el botón, y se rechaza
/// mirando <b>solo</b> los roles que vienen firmados en la sesión. Lo que el
/// cliente diga de sí mismo —una cabecera, un campo del cuerpo, un rol en el
/// <c>localStorage</c>— no llega hasta aquí, porque no hay nada que lo lea. Un
/// músico que se declara administrador recibe exactamente el mismo rechazo que
/// si no hubiera declarado nada (spec R7).
/// </para>
/// </summary>
public sealed class ExigirOperacion : IEndpointFilter
{
    private readonly Operacion _operacion;

    public ExigirOperacion(Operacion operacion) => _operacion = operacion;

    public async ValueTask<object?> InvokeAsync(EndpointFilterInvocationContext contexto, EndpointFilterDelegate siguiente)
    {
        var sesion = contexto.HttpContext.Sesion();

        if (sesion is null)
        {
            return RespuestasDeAcceso.SinSesion();
        }

        if (!Autorizacion.Permite(sesion, _operacion))
        {
            return RespuestasDeAcceso.SinPermiso();
        }

        return await siguiente(contexto);
    }
}

public static class ExigenciasDeEndpoint
{
    /// <summary>
    /// Ata un endpoint a la operación que realiza. Sin esta llamada el endpoint
    /// queda abierto, así que la guardia <c>SinIglesiaPorParametroTests</c> y la
    /// revisión son lo que impide que se olvide.
    /// </summary>
    public static RouteHandlerBuilder Exige(this RouteHandlerBuilder endpoint, Operacion operacion) =>
        endpoint.AddEndpointFilter(new ExigirOperacion(operacion));
}
