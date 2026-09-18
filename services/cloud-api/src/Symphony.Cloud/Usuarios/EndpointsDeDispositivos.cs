using Symphony.Cloud.BaseDeDatos;
using Symphony.Sesiones;
using Symphony.Sesiones.Web;

namespace Symphony.Cloud.Usuarios;

/// <summary>
/// Listar y revocar dispositivos, por separado (spec R6, T6.6). Revocar
/// cierra el acceso de ese dispositivo y de ninguno más (T6.9): no borra lo
/// descargado en él (constitución, punto 5), y los demás del mismo usuario
/// siguen sirviendo hasta que se cierren uno por uno.
/// </summary>
public static class EndpointsDeDispositivos
{
    public static void MapearDispositivos(this IEndpointRouteBuilder app)
    {
        app.MapGet("/dispositivos", Listar)
            .Exige(Operaciones.AdministrarDispositivos);

        app.MapPost("/dispositivos/{id:guid}/revocar", Revocar)
            .Exige(Operaciones.AdministrarDispositivos);
    }

    private static async Task<IResult> Listar(HttpContext contexto, AccesoALaNube nube)
    {
        var sesion = contexto.SesionObligatoria();

        return await nube.EnLaIglesia(sesion.IglesiaId, async unidad =>
        {
            var dispositivos = await unidad.Consultar<RespuestaDeDispositivo>(
                """
                SELECT id AS Id, usuario_id AS UsuarioId, tipo AS Tipo, nombre AS Nombre,
                       ultimo_visto_en AS UltimoVistoEn, revocado_en AS RevocadoEn
                FROM dispositivo
                ORDER BY creado_en
                """);

            return Results.Ok(dispositivos);
        });
    }

    private static Task<IResult> Revocar(Guid id, HttpContext contexto, AccesoALaNube nube)
    {
        var sesion = contexto.SesionObligatoria();

        return nube.EnLaIglesia(sesion.IglesiaId, async unidad =>
        {
            var afectadas = await unidad.Ejecutar(
                "UPDATE dispositivo SET revocado_en = now() WHERE id = @id AND revocado_en IS NULL",
                new { id });

            if (afectadas == 0)
            {
                // O no existe en esta iglesia (spec R2), o ya estaba
                // revocado: revocar dos veces no es un error, así que solo se
                // distingue con una consulta aparte, y no hace falta —el
                // resultado que importa (el dispositivo queda revocado) ya es
                // cierto en los dos casos salvo que no exista.
                var existe = await unidad.ConsultarUno<int?>("SELECT 1 FROM dispositivo WHERE id = @id", new { id });
                if (existe is null)
                {
                    return RespuestasDeAcceso.NoExiste();
                }
            }

            return Results.NoContent();
        });
    }
}

public sealed record RespuestaDeDispositivo(
    Guid Id, Guid? UsuarioId, string Tipo, string Nombre, DateTime? UltimoVistoEn, DateTime? RevocadoEn);
