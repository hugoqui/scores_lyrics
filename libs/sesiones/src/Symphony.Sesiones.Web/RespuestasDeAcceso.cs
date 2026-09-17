using Microsoft.AspNetCore.Http;

namespace Symphony.Sesiones.Web;

/// <summary>
/// Las tres formas de decir que no, y cuál toca en cada caso.
///
/// <para>
/// La distinción que importa es entre <see cref="SinPermiso"/> y
/// <see cref="NoExiste"/>. <b>Un dato de otra iglesia no está prohibido: no
/// existe</b> (spec R2). Responder «prohibido» a un identificador ajeno
/// confirma que ese identificador es de algo, y con eso solo se puede ir
/// tanteando identificadores hasta dibujar los datos de la congregación de al
/// lado. La respuesta es la misma que para un identificador inventado.
/// </para>
/// <para>
/// «Prohibido» se reserva para lo que sí es del usuario ver que existe: una
/// operación de su propia iglesia para la que le falta el rol.
/// </para>
/// </summary>
public static class RespuestasDeAcceso
{
    /// <summary>No trajo sesión válida, o venía caducada. 401.</summary>
    public static IResult SinSesion() =>
        Results.Json(new { error = "sesion_requerida" }, statusCode: StatusCodes.Status401Unauthorized);

    /// <summary>Es de su iglesia, pero le falta el rol. 403.</summary>
    public static IResult SinPermiso() =>
        Results.Json(new { error = "sin_permiso" }, statusCode: StatusCodes.Status403Forbidden);

    /// <summary>
    /// No está en su iglesia. 404, con la misma respuesta exacta que daría un
    /// identificador inventado: es lo que impide confirmar datos ajenos.
    /// </summary>
    public static IResult NoExiste() =>
        Results.Json(new { error = "no_existe" }, statusCode: StatusCodes.Status404NotFound);
}
