namespace Symphony.Sesiones;

/// <summary>
/// Emite las sesiones de un lado —la nube o un nodo— con su propia clave
/// ([ADR 0016]).
///
/// Dos duraciones con propósitos distintos: el token de <b>acceso</b> es corto
/// porque viaja en cada petición y no se consulta en la base; el de
/// <b>renovación</b> es largo, va atado a un dispositivo y es el que se revoca.
/// Un solo token de 30 días sería irrevocable en la práctica.
/// </summary>
public sealed class EmisorDeSesiones
{
    public static readonly TimeSpan DuracionDelAcceso = TimeSpan.FromHours(1);

    /// <summary>El techo del peor caso de 000-seguridad R8, no la duración normal de una sesión.</summary>
    public static readonly TimeSpan DuracionDeLaRenovacion = TimeSpan.FromDays(30);

    private readonly ParDeClaves _claves;
    private readonly Emisor _emisor;
    private readonly TimeProvider _reloj;

    public EmisorDeSesiones(ParDeClaves claves, Emisor emisor, TimeProvider? reloj = null)
    {
        _claves = claves;
        _emisor = emisor;
        _reloj = reloj ?? TimeProvider.System;
    }

    public (string Token, Sesion Sesion) Acceso(
        Guid usuarioId, Guid iglesiaId, IReadOnlyList<string> roles, Guid dispositivoId) =>
        Emitir(usuarioId, iglesiaId, roles, dispositivoId, TipoDeToken.Acceso, DuracionDelAcceso);

    public (string Token, Sesion Sesion) Renovacion(
        Guid usuarioId, Guid iglesiaId, IReadOnlyList<string> roles, Guid dispositivoId) =>
        Emitir(usuarioId, iglesiaId, roles, dispositivoId, TipoDeToken.Renovacion, DuracionDeLaRenovacion);

    private (string, Sesion) Emitir(
        Guid usuarioId,
        Guid iglesiaId,
        IReadOnlyList<string> roles,
        Guid dispositivoId,
        TipoDeToken tipo,
        TimeSpan duracion)
    {
        var ahora = _reloj.GetUtcNow();
        var sesion = new Sesion
        {
            UsuarioId = usuarioId,
            IglesiaId = iglesiaId,
            Roles = roles,
            DispositivoId = dispositivoId,
            Tipo = tipo,
            Emisor = _emisor,
            IdDeClave = _claves.Id,
            EmitidaEn = ahora,
            ExpiraEn = ahora + duracion,
        };

        return (Tokens.Emitir(sesion, _claves), sesion);
    }
}
