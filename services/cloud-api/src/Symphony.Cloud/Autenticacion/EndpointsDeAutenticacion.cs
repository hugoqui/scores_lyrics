using Dapper;
using Npgsql;
using Symphony.Cloud.BaseDeDatos;
using Symphony.Sesiones;
using Symphony.Sesiones.Web;

namespace Symphony.Cloud.Autenticacion;

/// <summary>
/// Login, renovación y cierre de sesión de la nube (spec R7, R8, T5.1, T5.3).
///
/// <para>
/// El login es el único momento en que la nube no sabe todavía a qué iglesia
/// pertenece la petición —el correo es único solo dentro de su iglesia (spec
/// R4)—, así que es el único que consulta con <see cref="AccesoComoPropietario"/>.
/// En cuanto se sabe la iglesia, todo lo demás —dispositivo, sesión, roles—
/// pasa por <see cref="AccesoALaNube"/> como cualquier otro camino.
/// </para>
/// </summary>
public static class EndpointsDeAutenticacion
{
    public static void MapearAutenticacion(this IEndpointRouteBuilder app)
    {
        app.MapPost("/autenticacion/iniciar-sesion", IniciarSesion);
        app.MapPost("/autenticacion/renovar", Renovar);
        app.MapPost("/autenticacion/cerrar-sesion", CerrarSesion);
    }

    private static async Task<IResult> IniciarSesion(
        SolicitudDeLogin solicitud,
        AccesoComoPropietario propietario,
        AccesoALaNube nube,
        EmisorDeSesiones emisor,
        ILogger<Program> logger)
    {
        if (!TiposDeDispositivo.Todos.Contains(solicitud.DispositivoTipo))
        {
            return Results.BadRequest(new { error = "tipo_de_dispositivo_invalido" });
        }

        var candidatos = await propietario.BuscarPorCorreo(solicitud.Correo);
        if (candidatos.Count > 1)
        {
            // Pasa cuando el mismo correo se dio de alta en dos iglesias
            // (spec R4 lo permite). El login no puede adivinar cuál se quiso
            // decir, y decir "hay dos" ya sería confirmar que el correo
            // existe: se trata exactamente igual que un correo inexistente.
            logger.LogWarning("Login rechazado: el correo coincide con más de una iglesia.");
        }

        var usuario = candidatos.Count == 1 ? candidatos[0] : null;

        return VerificacionDeCredenciales.Verificar(solicitud.Contrasena, usuario) switch
        {
            ResultadoDeCredenciales.Invalidas => RespuestasDeAcceso.CredencialesInvalidas(),
            ResultadoDeCredenciales.DadoDeBaja => RespuestasDeAcceso.UsuarioDadoDeBaja(),
            _ => await AbrirSesion(nube, emisor, usuario!, solicitud),
        };
    }

    private static async Task<IResult> AbrirSesion(
        AccesoALaNube nube, EmisorDeSesiones emisor, UsuarioParaAutenticar usuario, SolicitudDeLogin solicitud) =>
        await nube.EnLaIglesia(usuario.IglesiaId, async unidad =>
        {
            var resultado = await FijarDispositivo(unidad, usuario.Id, solicitud);
            if (resultado == ResultadoDeDispositivo.NoDisponible)
            {
                return RespuestasDeAcceso.DispositivoNoDisponible();
            }
            if (resultado == ResultadoDeDispositivo.LimiteAlcanzado)
            {
                return RespuestasDeAcceso.LimiteDeDispositivosAlcanzado(await DispositivosActivos(unidad, usuario.Id));
            }

            var (tokenAcceso, sesionAcceso) = emisor.Acceso(usuario.Id, usuario.IglesiaId, usuario.Roles, solicitud.DispositivoId);
            var (tokenRenovacion, sesionRenovacion) =
                emisor.Renovacion(usuario.Id, usuario.IglesiaId, usuario.Roles, solicitud.DispositivoId);

            await unidad.Ejecutar(
                """
                INSERT INTO sesion (id, dispositivo_id, iglesia_id, huella_token, emitida_en, expira_en)
                VALUES (@id, @dispositivoId, @iglesiaId, @huella, @emitidaEn, @expiraEn)
                """,
                new
                {
                    id = Guid.CreateVersion7(),
                    dispositivoId = solicitud.DispositivoId,
                    iglesiaId = unidad.IglesiaId,
                    huella = Tokens.Huella(tokenRenovacion),
                    emitidaEn = sesionRenovacion.EmitidaEn,
                    expiraEn = sesionRenovacion.ExpiraEn,
                });

            return Results.Ok(new RespuestaDeSesion(
                tokenAcceso, tokenRenovacion, usuario.Id, usuario.IglesiaId, usuario.Roles, solicitud.DispositivoId));
        });

    private enum ResultadoDeDispositivo
    {
        Fijado,
        NoDisponible,
        LimiteAlcanzado,
    }

    /// <summary>
    /// Deja listo el dispositivo de este login: lo reutiliza si ya es suyo, lo
    /// crea si es nuevo, y rechaza el identificador si no se puede usar —sea
    /// porque ya es de otro usuario de esta iglesia, sea porque ya existe en
    /// otra iglesia y por eso la política ni lo dejó ver (spec R2: se
    /// responde igual en los dos casos, nunca como "prohibido"). Si es nuevo y
    /// ya se alcanzó el límite de activos, tampoco se crea (spec R6, T6.7).
    /// </summary>
    private static async Task<ResultadoDeDispositivo> FijarDispositivo(
        UnidadDeTrabajo unidad, Guid usuarioId, SolicitudDeLogin solicitud)
    {
        var existente = await unidad.ConsultarUno<DispositivoFila>(
            "SELECT usuario_id AS UsuarioId, revocado_en AS RevocadoEn FROM dispositivo WHERE id = @id",
            new { id = solicitud.DispositivoId });

        if (existente is not null)
        {
            if (existente.UsuarioId != usuarioId || existente.RevocadoEn is not null)
            {
                return ResultadoDeDispositivo.NoDisponible;
            }

            await unidad.Ejecutar(
                "UPDATE dispositivo SET ultimo_visto_en = now() WHERE id = @id",
                new { id = solicitud.DispositivoId });
            return ResultadoDeDispositivo.Fijado;
        }

        var activos = await unidad.ConsultarUno<int>(
            "SELECT count(*) FROM dispositivo WHERE usuario_id = @usuarioId AND revocado_en IS NULL",
            new { usuarioId });
        if (activos >= LimiteDeDispositivos.Maximo)
        {
            return ResultadoDeDispositivo.LimiteAlcanzado;
        }

        try
        {
            await unidad.Ejecutar(
                """
                INSERT INTO dispositivo (id, iglesia_id, usuario_id, tipo, nombre, creado_en, ultimo_visto_en)
                VALUES (@id, @iglesiaId, @usuarioId, @tipo, @nombre, now(), now())
                """,
                new
                {
                    id = solicitud.DispositivoId,
                    iglesiaId = unidad.IglesiaId,
                    usuarioId,
                    tipo = solicitud.DispositivoTipo,
                    nombre = solicitud.DispositivoNombre,
                });
        }
        catch (PostgresException excepcion) when (excepcion.SqlState == PostgresErrorCodes.UniqueViolation)
        {
            // Existe, pero en otra iglesia: la RLS lo hizo invisible al SELECT
            // de arriba, y solo se descubre al chocar con la clave primaria.
            return ResultadoDeDispositivo.NoDisponible;
        }

        return ResultadoDeDispositivo.Fijado;
    }

    private static async Task<IReadOnlyList<DispositivoActivo>> DispositivosActivos(UnidadDeTrabajo unidad, Guid usuarioId)
    {
        var filas = await unidad.Consultar<DispositivoActivoFila>(
            """
            SELECT id AS Id, nombre AS Nombre, tipo AS Tipo, ultimo_visto_en AS UltimoVistoEn
            FROM dispositivo
            WHERE usuario_id = @usuarioId AND revocado_en IS NULL
            ORDER BY ultimo_visto_en
            """,
            new { usuarioId });

        return filas
            .Select(fila => new DispositivoActivo(
                fila.Id, fila.Nombre, fila.Tipo,
                fila.UltimoVistoEn is { } valor ? new DateTimeOffset(valor, TimeSpan.Zero) : null))
            .ToList();
    }

    private sealed record DispositivoActivoFila(Guid Id, string Nombre, string Tipo, DateTime? UltimoVistoEn);

    private static async Task<IResult> Renovar(
        SolicitudDeRenovacion solicitud, VerificadorDeSesiones verificador, AccesoALaNube nube, EmisorDeSesiones emisor)
    {
        var resultado = verificador.Verificar(solicitud.TokenDeRenovacion, TipoDeToken.Renovacion);
        if (resultado.Sesion is not { } sesion)
        {
            return RespuestasDeAcceso.SesionInvalida();
        }

        return await nube.EnLaIglesia(sesion.IglesiaId, async unidad =>
        {
            var huella = Tokens.Huella(solicitud.TokenDeRenovacion);
            if (!await EsSesionVigente(unidad, huella, sesion.DispositivoId))
            {
                return RespuestasDeAcceso.SesionInvalida();
            }

            // Los roles se releen: si a alguien le quitaron un rol después de
            // haber entrado, la renovación es donde deja de arrastrarlo.
            var estadoYRoles = await EstadoYRolesActuales(unidad, sesion.UsuarioId);
            if (estadoYRoles is not { Estado: "activo" })
            {
                return RespuestasDeAcceso.SesionInvalida();
            }

            var (tokenAcceso, _) = emisor.Acceso(sesion.UsuarioId, sesion.IglesiaId, estadoYRoles.Roles, sesion.DispositivoId);
            return Results.Ok(new RespuestaDeRenovacion(tokenAcceso));
        });
    }

    private static async Task<IResult> CerrarSesion(SolicitudDeCierre solicitud, VerificadorDeSesiones verificador, AccesoALaNube nube)
    {
        var resultado = verificador.Verificar(solicitud.TokenDeRenovacion, TipoDeToken.Renovacion);
        if (resultado.Sesion is not { } sesion)
        {
            return RespuestasDeAcceso.SesionInvalida();
        }

        // Idempotente a propósito: cerrar una sesión ya cerrada no es un
        // error, es lo mismo que se pidió.
        await nube.EnLaIglesia(sesion.IglesiaId, unidad => unidad.Ejecutar(
            "UPDATE sesion SET revocada_en = now() WHERE huella_token = @huella AND revocada_en IS NULL",
            new { huella = Tokens.Huella(solicitud.TokenDeRenovacion) }));

        return Results.NoContent();
    }

    private static async Task<bool> EsSesionVigente(UnidadDeTrabajo unidad, string huella, Guid dispositivoId)
    {
        var sesion = await unidad.ConsultarUno<SesionFila>(
            "SELECT revocada_en AS RevocadaEn FROM sesion WHERE huella_token = @huella",
            new { huella });
        if (sesion is null || sesion.RevocadaEn is not null)
        {
            return false;
        }

        var dispositivo = await unidad.ConsultarUno<DispositivoFila>(
            "SELECT usuario_id AS UsuarioId, revocado_en AS RevocadoEn FROM dispositivo WHERE id = @id",
            new { id = dispositivoId });

        return dispositivo is not null && dispositivo.RevocadoEn is null;
    }

    private static async Task<EstadoYRoles?> EstadoYRolesActuales(UnidadDeTrabajo unidad, Guid usuarioId)
    {
        var estado = await unidad.ConsultarUno<string>("SELECT estado FROM usuario WHERE id = @id", new { id = usuarioId });
        if (estado is null)
        {
            return null;
        }

        var roles = await unidad.Consultar<string>("SELECT rol FROM usuario_rol WHERE usuario_id = @id", new { id = usuarioId });
        return new EstadoYRoles(estado, roles);
    }

    // Npgsql mapea timestamptz a DateTime, no DateTimeOffset, salvo que se
    // pida explícitamente: aquí solo importa si hay valor, no la zona.
    private sealed record DispositivoFila(Guid UsuarioId, DateTime? RevocadoEn);

    private sealed record SesionFila(DateTime? RevocadaEn);

    private sealed record EstadoYRoles(string Estado, IReadOnlyList<string> Roles);
}
