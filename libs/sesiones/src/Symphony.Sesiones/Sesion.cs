using System.Text.Json.Serialization;

namespace Symphony.Sesiones;

/// <summary>Para qué sirve el token. Un token de acceso no renueva y uno de renovación no da acceso.</summary>
[JsonConverter(typeof(JsonStringEnumConverter))]
public enum TipoDeToken
{
    Acceso,
    Renovacion,
}

/// <summary>Quién emitió el token. El nodo emite sin consultar a la nube ([ADR 0016]).</summary>
[JsonConverter(typeof(JsonStringEnumConverter))]
public enum Emisor
{
    Nube,
    Nodo,
}

/// <summary>
/// Lo que va firmado dentro de un token. <b>El rol viaja aquí</b>, así que no
/// hay nada que el cliente pueda declarar sobre sí mismo: mata de raíz el
/// `localStorage` que hoy permite autoproclamarse operador ([ADR 0016]).
///
/// La iglesia también viaja aquí, y es de donde la saca el servidor: nunca de
/// un parámetro de la petición (spec R3).
/// </summary>
public sealed record Sesion
{
    public required Guid UsuarioId { get; init; }

    public required Guid IglesiaId { get; init; }

    public required IReadOnlyList<string> Roles { get; init; }

    public required Guid DispositivoId { get; init; }

    public required TipoDeToken Tipo { get; init; }

    public required Emisor Emisor { get; init; }

    /// <summary>
    /// Qué clave firmó. Sin esto, rotar una clave obliga a invalidar todas las
    /// sesiones vivas a la vez; la rotación en sí es del módulo 008.
    /// </summary>
    public required string IdDeClave { get; init; }

    public required DateTimeOffset EmitidaEn { get; init; }

    public required DateTimeOffset ExpiraEn { get; init; }
}
