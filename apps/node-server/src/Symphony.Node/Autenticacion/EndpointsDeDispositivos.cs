using Symphony.Node.BaseDeDatos;
using Symphony.Sesiones;
using Symphony.Sesiones.Web;

namespace Symphony.Node.Autenticacion;

/// <summary>
/// Listar y revocar dispositivos desde el nodo (spec R6, T6.6, T6.9). Los
/// dispositivos y sesiones son lo que el nodo escribe por su cuenta —no una
/// réplica de la nube—, así que un administrador que se quedó sin internet en
/// medio de un culto puede cerrar un teléfono perdido igual.
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

    private static async Task<IResult> Listar(AccesoAlNodo nodo) =>
        Results.Ok(await nodo.EnTransaccion(unidad => unidad.Consultar<RespuestaDeDispositivo>(
            """
            SELECT id AS Id, usuario_id AS UsuarioId, tipo AS Tipo, nombre AS Nombre,
                   ultimo_visto_en AS UltimoVistoEn, revocado_en AS RevocadoEn
            FROM dispositivo
            ORDER BY creado_en
            """)));

    private static Task<IResult> Revocar(Guid id, AccesoAlNodo nodo) =>
        nodo.EnTransaccion(async unidad =>
        {
            var idTexto = id.ToString();
            var afectadas = await unidad.Ejecutar(
                "UPDATE dispositivo SET revocado_en = @ahora WHERE id = @id AND revocado_en IS NULL",
                new { id = idTexto, ahora = DateTimeOffset.UtcNow.ToString("O") });

            if (afectadas == 0)
            {
                var existe = await unidad.ConsultarUno<int?>(
                    "SELECT 1 FROM dispositivo WHERE id = @id", new { id = idTexto });
                if (existe is null)
                {
                    return RespuestasDeAcceso.NoExiste();
                }
            }

            return Results.NoContent();
        });
}

public sealed record RespuestaDeDispositivo(
    string Id, string? UsuarioId, string Tipo, string Nombre, string? UltimoVistoEn, string? RevocadoEn);
