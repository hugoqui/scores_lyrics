using Npgsql;
using Symphony.Cloud.BaseDeDatos;
using Symphony.Sesiones;
using Symphony.Sesiones.Web;

namespace Symphony.Cloud.Usuarios;

/// <summary>
/// Altas y bajas de usuario dentro de la iglesia de quien llama (spec R4, R7).
///
/// <b>La iglesia sale siempre de la sesión</b> (<see cref="HttpContext.SesionObligatoria"/>),
/// nunca de la ruta ni del cuerpo (spec R3): todas las consultas van dentro de
/// <see cref="AccesoALaNube.EnLaIglesia{T}"/>, así que un identificador de otro
/// usuario u otra iglesia no puede ni intentarse fuera de ese filtro.
/// </summary>
public static class EndpointsDeUsuarios
{
    public static void MapearUsuarios(this IEndpointRouteBuilder app)
    {
        app.MapPost("/usuarios", DarDeAlta)
            .Exige(Operaciones.AdministrarUsuarios);

        app.MapPost("/usuarios/{id:guid}/baja", DarDeBaja)
            .Exige(Operaciones.AdministrarUsuarios);

        app.MapPost("/usuarios/{id:guid}/readmitir", Readmitir)
            .Exige(Operaciones.AdministrarUsuarios);
    }

    private static async Task<IResult> DarDeAlta(
        SolicitudDeAltaDeUsuario solicitud, HttpContext contexto, AccesoALaNube nube)
    {
        if (string.IsNullOrWhiteSpace(solicitud.Contrasena))
        {
            return Results.BadRequest(new { error = "contrasena_requerida" });
        }

        var rolesInvalidos = solicitud.Roles.Where(rol => !Roles.Todos.Contains(rol)).ToList();
        if (solicitud.Roles.Count == 0 || rolesInvalidos.Count > 0)
        {
            return Results.BadRequest(new { error = "roles_invalidos", invalidos = rolesInvalidos });
        }

        var sesion = contexto.SesionObligatoria();

        return await nube.EnLaIglesia(sesion.IglesiaId, async unidad =>
        {
            var id = Guid.CreateVersion7();

            try
            {
                await unidad.Ejecutar(
                    """
                    INSERT INTO usuario (id, iglesia_id, correo, nombre, hash_contrasena, estado, creado_en)
                    VALUES (@id, @iglesiaId, @correo, @nombre, @hash, 'activo', now())
                    """,
                    new
                    {
                        id,
                        iglesiaId = unidad.IglesiaId,
                        correo = solicitud.Correo,
                        nombre = solicitud.Nombre,
                        hash = Contrasenas.Guardar(solicitud.Contrasena),
                    });
            }
            catch (PostgresException excepcion) when (excepcion.SqlState == PostgresErrorCodes.UniqueViolation)
            {
                // El mismo correo ya existe en esta iglesia (spec R4): dentro
                // de ella sí es un conflicto real, a diferencia del login,
                // donde el mismo correo en otra iglesia no se distingue.
                return Results.Conflict(new { error = "correo_ya_existe" });
            }

            foreach (var rol in solicitud.Roles)
            {
                await unidad.Ejecutar(
                    "INSERT INTO usuario_rol (usuario_id, rol) VALUES (@id, @rol)", new { id, rol });
            }

            return Results.Ok(new RespuestaDeUsuario(id, solicitud.Correo, solicitud.Nombre, solicitud.Roles, "activo"));
        });
    }

    private static Task<IResult> DarDeBaja(Guid id, HttpContext contexto, AccesoALaNube nube) =>
        CambiarEstado(id, contexto, nube, activo: false);

    private static Task<IResult> Readmitir(Guid id, HttpContext contexto, AccesoALaNube nube) =>
        CambiarEstado(id, contexto, nube, activo: true);

    /// <summary>
    /// Cambia el estado, nunca borra la fila ni lo que cuelga de ella
    /// (constitución, punto 5; spec R4): instrumentos y dispositivos siguen
    /// intactos, y readmitir es volver a cambiar el mismo campo.
    /// </summary>
    private static Task<IResult> CambiarEstado(Guid id, HttpContext contexto, AccesoALaNube nube, bool activo)
    {
        var sesion = contexto.SesionObligatoria();

        return nube.EnLaIglesia(sesion.IglesiaId, async unidad =>
        {
            var existe = await unidad.ConsultarUno<int?>("SELECT 1 FROM usuario WHERE id = @id", new { id });
            if (existe is null)
            {
                // Ajeno a esta iglesia o inventado: la misma respuesta para
                // los dos (spec R2).
                return RespuestasDeAcceso.NoExiste();
            }

            if (!activo && await EsElUltimoAdministrador(unidad, id))
            {
                return Results.Conflict(new { error = "ultimo_administrador" });
            }

            await unidad.Ejecutar(
                "UPDATE usuario SET estado = @estado WHERE id = @id",
                new { id, estado = activo ? "activo" : "dado_de_baja" });

            return Results.NoContent();
        });
    }

    /// <summary>
    /// T6.3: ninguna iglesia se queda sin administrador. Cuenta los
    /// administradores activos que no sean este usuario; si no queda
    /// ninguno, dar de baja a este es dejarla sin uno.
    /// </summary>
    private static async Task<bool> EsElUltimoAdministrador(UnidadDeTrabajo unidad, Guid usuarioId)
    {
        var esAdministrador = await unidad.ConsultarUno<int?>(
            "SELECT 1 FROM usuario_rol WHERE usuario_id = @usuarioId AND rol = @rol",
            new { usuarioId, rol = Roles.Administrador });
        if (esAdministrador is null)
        {
            return false;
        }

        var otrosAdministradoresActivos = await unidad.ConsultarUno<int?>(
            """
            SELECT 1 FROM usuario_rol ur
            JOIN usuario u ON u.id = ur.usuario_id
            WHERE ur.rol = @rol AND u.estado = 'activo' AND u.id <> @usuarioId
            LIMIT 1
            """,
            new { usuarioId, rol = Roles.Administrador });

        return otrosAdministradoresActivos is null;
    }
}

public sealed record SolicitudDeAltaDeUsuario(string Correo, string Nombre, string Contrasena, IReadOnlyList<string> Roles);

public sealed record RespuestaDeUsuario(Guid Id, string Correo, string Nombre, IReadOnlyList<string> Roles, string Estado);
