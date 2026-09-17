using Npgsql;
using Symphony.Cloud.BaseDeDatos;
using Symphony.Sesiones;
using Symphony.Sesiones.Web;

namespace Symphony.Cloud.Usuarios;

/// <summary>
/// Asignar y quitar instrumentos a un músico (spec R5, T6.4). Un usuario puede
/// tener varios a la vez —piano y flauta, por ejemplo—; cambiarlos es una
/// operación de administración, no algo que el músico haga desde la app.
/// </summary>
public static class EndpointsDeInstrumentos
{
    public static void MapearInstrumentos(this IEndpointRouteBuilder app)
    {
        app.MapPost("/usuarios/{id:guid}/instrumentos/{instrumentoId:guid}", Asignar)
            .Exige(Operaciones.AdministrarUsuarios);

        app.MapDelete("/usuarios/{id:guid}/instrumentos/{instrumentoId:guid}", Quitar)
            .Exige(Operaciones.AdministrarUsuarios);
    }

    private static async Task<IResult> Asignar(Guid id, Guid instrumentoId, HttpContext contexto, AccesoALaNube nube)
    {
        var sesion = contexto.SesionObligatoria();

        return await nube.EnLaIglesia(sesion.IglesiaId, async unidad =>
        {
            // El usuario tiene que ser de esta iglesia; el catálogo de
            // instrumentos es compartido por todas (spec R2, R5), así que no
            // hace falta —ni se puede— comprobarlo con el mismo filtro.
            if (await unidad.ConsultarUno<int?>("SELECT 1 FROM usuario WHERE id = @id", new { id }) is null)
            {
                return RespuestasDeAcceso.NoExiste();
            }

            try
            {
                await unidad.Ejecutar(
                    "INSERT INTO usuario_instrumento (usuario_id, instrumento_id) VALUES (@id, @instrumentoId)",
                    new { id, instrumentoId });
            }
            catch (PostgresException excepcion) when (excepcion.SqlState == PostgresErrorCodes.UniqueViolation)
            {
                // Ya lo tenía asignado: no es un error, es lo mismo que se pidió.
            }
            catch (PostgresException excepcion) when (excepcion.SqlState == PostgresErrorCodes.ForeignKeyViolation)
            {
                // El instrumento no existe en el catálogo.
                return RespuestasDeAcceso.NoExiste();
            }

            return Results.NoContent();
        });
    }

    private static Task<IResult> Quitar(Guid id, Guid instrumentoId, HttpContext contexto, AccesoALaNube nube)
    {
        var sesion = contexto.SesionObligatoria();

        return nube.EnLaIglesia(sesion.IglesiaId, async unidad =>
        {
            if (await unidad.ConsultarUno<int?>("SELECT 1 FROM usuario WHERE id = @id", new { id }) is null)
            {
                return RespuestasDeAcceso.NoExiste();
            }

            // Quitar uno que no tenía tampoco es un error: el estado final
            // pedido —que no lo tenga— ya es el que hay.
            await unidad.Ejecutar(
                "DELETE FROM usuario_instrumento WHERE usuario_id = @id AND instrumento_id = @instrumentoId",
                new { id, instrumentoId });

            return Results.NoContent();
        });
    }
}
