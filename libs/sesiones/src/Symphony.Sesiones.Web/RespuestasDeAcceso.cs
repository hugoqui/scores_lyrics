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

    /// <summary>
    /// Correo o contraseña incorrectos. La misma respuesta para las dos causas
    /// (spec R7): decir cuál de las dos falló es decirle a quien lo intenta si
    /// el correo existe.
    /// </summary>
    public static IResult CredencialesInvalidas() =>
        Results.Json(new { error = "credenciales_invalidas" }, statusCode: StatusCodes.Status401Unauthorized);

    /// <summary>La contraseña era correcta, pero el usuario está dado de baja.</summary>
    public static IResult UsuarioDadoDeBaja() =>
        Results.Json(new { error = "usuario_dado_de_baja" }, statusCode: StatusCodes.Status403Forbidden);

    /// <summary>
    /// El identificador de dispositivo que trajo el cliente no se puede usar
    /// aquí —ya es de otro usuario, o de otra iglesia—. La respuesta no dice
    /// cuál de las dos cosas pasó (spec R2: un identificador de otra iglesia
    /// se responde como si no existiera, no como prohibido).
    /// </summary>
    public static IResult DispositivoNoDisponible() =>
        Results.Json(new { error = "dispositivo_no_disponible" }, statusCode: StatusCodes.Status409Conflict);

    /// <summary>El token de renovación no sirve: caducó, se revocó, o nunca fue uno de renovación.</summary>
    public static IResult SesionInvalida() =>
        Results.Json(new { error = "sesion_invalida" }, statusCode: StatusCodes.Status401Unauthorized);

    /// <summary>
    /// Alcanzó el límite de dispositivos activos (spec R6, T6.7). Nunca es un
    /// rechazo mudo: trae los dispositivos activos para que el propio cliente
    /// ofrezca cerrar uno.
    /// </summary>
    public static IResult LimiteDeDispositivosAlcanzado(IReadOnlyList<DispositivoActivo> dispositivos) =>
        Results.Json(
            new { error = "limite_de_dispositivos", dispositivos },
            statusCode: StatusCodes.Status409Conflict);
}
