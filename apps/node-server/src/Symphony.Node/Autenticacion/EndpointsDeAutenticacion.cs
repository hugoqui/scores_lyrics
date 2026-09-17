using Symphony.Node.BaseDeDatos;
using Symphony.Node.Configuration;
using Symphony.Sesiones;
using Symphony.Sesiones.Web;

namespace Symphony.Node.Autenticacion;

/// <summary>
/// Login, renovación y cierre de sesión del nodo (spec R7, R8, T5.2, T5.9).
///
/// <b>No consulta a la nube en ningún punto.</b> El nodo tiene su propia copia
/// de usuarios y roles —una réplica, cómo llega es del módulo 008— y firma con
/// su propia clave (ADR 0016): el domingo, sin internet, esto es todo lo que
/// hace falta para que un músico entre.
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
        SolicitudDeLogin solicitud, AccesoAlNodo nodo, NodeOptions opciones, EmisorDeSesiones emisor)
    {
        if (!TiposDeDispositivo.Todos.Contains(solicitud.DispositivoTipo))
        {
            return Results.BadRequest(new { error = "tipo_de_dispositivo_invalido" });
        }

        return await nodo.EnTransaccion(async unidad =>
        {
            var usuario = await BuscarUsuario(unidad, solicitud.Correo, opciones);

            return VerificacionDeCredenciales.Verificar(solicitud.Contrasena, usuario) switch
            {
                ResultadoDeCredenciales.Invalidas => RespuestasDeAcceso.CredencialesInvalidas(),
                ResultadoDeCredenciales.DadoDeBaja => RespuestasDeAcceso.UsuarioDadoDeBaja(),
                _ => await AbrirSesion(unidad, emisor, usuario!, solicitud),
            };
        });
    }

    private static async Task<UsuarioParaAutenticar?> BuscarUsuario(UnidadDeTrabajoDelNodo unidad, string correo, NodeOptions opciones)
    {
        var fila = await unidad.ConsultarUno<FilaDeUsuario>(
            "SELECT id, hash_contrasena AS HashContrasena, estado FROM usuario WHERE correo = @correo",
            new { correo });

        if (fila is null)
        {
            return null;
        }

        var roles = await unidad.Consultar<string>(
            "SELECT rol FROM usuario_rol WHERE usuario_id = @id", new { id = fila.Id });

        return new UsuarioParaAutenticar(Guid.Parse(fila.Id), opciones.IglesiaId, fila.HashContrasena, fila.Estado, roles);
    }

    private static async Task<IResult> AbrirSesion(
        UnidadDeTrabajoDelNodo unidad, EmisorDeSesiones emisor, UsuarioParaAutenticar usuario, SolicitudDeLogin solicitud)
    {
        var resultado = await FijarDispositivo(unidad, usuario, solicitud);
        if (resultado == ResultadoDeDispositivo.NoDisponible)
        {
            return RespuestasDeAcceso.DispositivoNoDisponible();
        }
        if (resultado == ResultadoDeDispositivo.LimiteAlcanzado)
        {
            return RespuestasDeAcceso.LimiteDeDispositivosAlcanzado(await DispositivosActivos(unidad, usuario.Id));
        }

        var (tokenAcceso, _) = emisor.Acceso(usuario.Id, usuario.IglesiaId, usuario.Roles, solicitud.DispositivoId);
        var (tokenRenovacion, sesionRenovacion) =
            emisor.Renovacion(usuario.Id, usuario.IglesiaId, usuario.Roles, solicitud.DispositivoId);

        await unidad.Ejecutar(
            """
            INSERT INTO sesion (id, dispositivo_id, iglesia_id, huella_token, emitida_en, expira_en)
            VALUES (@id, @dispositivoId, @iglesiaId, @huella, @emitidaEn, @expiraEn)
            """,
            new
            {
                id = Guid.CreateVersion7().ToString(),
                dispositivoId = solicitud.DispositivoId.ToString(),
                iglesiaId = usuario.IglesiaId.ToString(),
                huella = Tokens.Huella(tokenRenovacion),
                emitidaEn = sesionRenovacion.EmitidaEn.ToString("O"),
                expiraEn = sesionRenovacion.ExpiraEn.ToString("O"),
            });

        return Results.Ok(new RespuestaDeSesion(
            tokenAcceso, tokenRenovacion, usuario.Id, usuario.IglesiaId, usuario.Roles, solicitud.DispositivoId));
    }

    private enum ResultadoDeDispositivo
    {
        Fijado,
        NoDisponible,
        LimiteAlcanzado,
    }

    /// <summary>
    /// Igual que en la nube, pero sin el caso de "existe en otra iglesia": en
    /// este archivo no hay otra (ADR 0015). Solo queda el choque entre dos
    /// usuarios de la misma iglesia con el mismo identificador de dispositivo,
    /// y el límite de dispositivos activos (spec R6, T6.7).
    /// </summary>
    private static async Task<ResultadoDeDispositivo> FijarDispositivo(
        UnidadDeTrabajoDelNodo unidad, UsuarioParaAutenticar usuario, SolicitudDeLogin solicitud)
    {
        var id = solicitud.DispositivoId.ToString();
        var existente = await unidad.ConsultarUno<DispositivoFila>(
            "SELECT usuario_id AS UsuarioId, revocado_en AS RevocadoEn FROM dispositivo WHERE id = @id",
            new { id });

        if (existente is not null)
        {
            if (existente.UsuarioId != usuario.Id.ToString() || existente.RevocadoEn is not null)
            {
                return ResultadoDeDispositivo.NoDisponible;
            }

            await unidad.Ejecutar("UPDATE dispositivo SET ultimo_visto_en = @ahora WHERE id = @id",
                new { id, ahora = DateTimeOffset.UtcNow.ToString("O") });
            return ResultadoDeDispositivo.Fijado;
        }

        var usuarioId = usuario.Id.ToString();
        var activos = await unidad.ConsultarUno<int>(
            "SELECT count(*) FROM dispositivo WHERE usuario_id = @usuarioId AND revocado_en IS NULL",
            new { usuarioId });
        if (activos >= LimiteDeDispositivos.Maximo)
        {
            return ResultadoDeDispositivo.LimiteAlcanzado;
        }

        await unidad.Ejecutar(
            """
            INSERT INTO dispositivo (id, iglesia_id, usuario_id, tipo, nombre, creado_en, ultimo_visto_en)
            VALUES (@id, @iglesia, @usuario, @tipo, @nombre, @ahora, @ahora)
            """,
            new
            {
                id,
                iglesia = usuario.IglesiaId.ToString(),
                usuario = usuario.Id.ToString(),
                tipo = solicitud.DispositivoTipo,
                nombre = solicitud.DispositivoNombre,
                ahora = DateTimeOffset.UtcNow.ToString("O"),
            });

        return ResultadoDeDispositivo.Fijado;
    }

    private static async Task<IReadOnlyList<DispositivoActivo>> DispositivosActivos(UnidadDeTrabajoDelNodo unidad, Guid usuarioId)
    {
        var id = usuarioId.ToString();
        var filas = await unidad.Consultar<DispositivoActivoFila>(
            """
            SELECT id AS Id, nombre AS Nombre, tipo AS Tipo, ultimo_visto_en AS UltimoVistoEn
            FROM dispositivo
            WHERE usuario_id = @id AND revocado_en IS NULL
            ORDER BY ultimo_visto_en
            """,
            new { id });

        return filas
            .Select(fila => new DispositivoActivo(
                Guid.Parse(fila.Id), fila.Nombre, fila.Tipo,
                fila.UltimoVistoEn is { } valor ? DateTimeOffset.Parse(valor) : null))
            .ToList();
    }

    private static async Task<IResult> Renovar(
        SolicitudDeRenovacion solicitud, VerificadorDeSesiones verificador, AccesoAlNodo nodo, EmisorDeSesiones emisor)
    {
        var resultado = verificador.Verificar(solicitud.TokenDeRenovacion, TipoDeToken.Renovacion);
        if (resultado.Sesion is not { } sesion)
        {
            return RespuestasDeAcceso.SesionInvalida();
        }

        return await nodo.EnTransaccion(async unidad =>
        {
            var huella = Tokens.Huella(solicitud.TokenDeRenovacion);
            if (!await EsSesionVigente(unidad, huella, sesion.DispositivoId))
            {
                return RespuestasDeAcceso.SesionInvalida();
            }

            var estadoYRoles = await EstadoYRolesActuales(unidad, sesion.UsuarioId);
            if (estadoYRoles is not { Estado: "activo" })
            {
                return RespuestasDeAcceso.SesionInvalida();
            }

            var (tokenAcceso, _) = emisor.Acceso(sesion.UsuarioId, sesion.IglesiaId, estadoYRoles.Roles, sesion.DispositivoId);
            return Results.Ok(new RespuestaDeRenovacion(tokenAcceso));
        });
    }

    private static async Task<IResult> CerrarSesion(SolicitudDeCierre solicitud, VerificadorDeSesiones verificador, AccesoAlNodo nodo)
    {
        var resultado = verificador.Verificar(solicitud.TokenDeRenovacion, TipoDeToken.Renovacion);
        if (!resultado.EsValida)
        {
            return RespuestasDeAcceso.SesionInvalida();
        }

        await nodo.EnTransaccion(unidad => unidad.Ejecutar(
            "UPDATE sesion SET revocada_en = @ahora WHERE huella_token = @huella AND revocada_en IS NULL",
            new { huella = Tokens.Huella(solicitud.TokenDeRenovacion), ahora = DateTimeOffset.UtcNow.ToString("O") }));

        return Results.NoContent();
    }

    private static async Task<bool> EsSesionVigente(UnidadDeTrabajoDelNodo unidad, string huella, Guid dispositivoId)
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
            new { id = dispositivoId.ToString() });

        return dispositivo is not null && dispositivo.RevocadoEn is null;
    }

    private static async Task<EstadoYRoles?> EstadoYRolesActuales(UnidadDeTrabajoDelNodo unidad, Guid usuarioId)
    {
        var id = usuarioId.ToString();
        var estado = await unidad.ConsultarUno<string>("SELECT estado FROM usuario WHERE id = @id", new { id });
        if (estado is null)
        {
            return null;
        }

        var roles = await unidad.Consultar<string>("SELECT rol FROM usuario_rol WHERE usuario_id = @id", new { id });
        return new EstadoYRoles(estado, roles);
    }

    private sealed record FilaDeUsuario(string Id, string HashContrasena, string Estado);

    private sealed record DispositivoFila(string UsuarioId, string? RevocadoEn);

    private sealed record SesionFila(string? RevocadaEn);

    private sealed record EstadoYRoles(string Estado, IReadOnlyList<string> Roles);

    private sealed record DispositivoActivoFila(string Id, string Nombre, string Tipo, string? UltimoVistoEn);
}
