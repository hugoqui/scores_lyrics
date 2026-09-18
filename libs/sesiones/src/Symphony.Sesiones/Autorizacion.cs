namespace Symphony.Sesiones;

/// <summary>
/// Una operación sensible y la lista —cerrada y explícita— de roles que la
/// permiten (spec R7: «cada operación sensible dice qué rol la permite»).
///
/// <para>
/// <b>La lista es exhaustiva, no un mínimo.</b> No hay ningún rol que quede
/// autorizado por estar «por encima» de otro, porque no hay encima: la
/// comprobación es pertenencia a esta lista y nada más.
/// </para>
/// </summary>
public sealed record Operacion(string Nombre, IReadOnlyList<string> RolesQueLaPermiten);

/// <summary>
/// El catálogo de operaciones sensibles. Crece con cada módulo que añade
/// operaciones; lo que no puede crecer es la forma de decidir, que es siempre
/// <see cref="Autorizacion.Permite"/>.
/// </summary>
public static class Operaciones
{
    /// <summary>Altas, bajas, roles e instrumentos de la gente de la iglesia (spec R4, R5).</summary>
    public static readonly Operacion AdministrarUsuarios =
        new("administrar_usuarios", [Roles.Administrador]);

    /// <summary>Ver y revocar los dispositivos de la iglesia (spec R6).</summary>
    public static readonly Operacion AdministrarDispositivos =
        new("administrar_dispositivos", [Roles.Administrador]);

    /// <summary>
    /// Conducir el culto: proyectar, cambiar de canto, mandar a los teléfonos.
    /// <b>El administrador no está aquí</b>, y esa ausencia es la regla, no un
    /// olvido (spec R7): administrar músicos y dirigir un culto son cosas
    /// distintas, y la segunda se asigna aparte.
    /// </summary>
    public static readonly Operacion OperarElServicio =
        new("operar_el_servicio", [Roles.Operador]);

    /// <summary>Lo que hace un músico el domingo: ver su repertorio y sus partituras.</summary>
    public static readonly Operacion VerLoMioDeMusico =
        new("ver_lo_mio_de_musico", [Roles.Musico]);

    public static readonly IReadOnlyList<Operacion> Todas =
    [
        AdministrarUsuarios,
        AdministrarDispositivos,
        OperarElServicio,
        VerLoMioDeMusico,
    ];
}

/// <summary>
/// Decide si una sesión permite una operación (spec R7).
///
/// <para>
/// Es a propósito la única función que decide, y es a propósito tan corta:
/// toda la jerarquía que podría colarse —«el administrador también puede», «el
/// operador es un músico con extras»— tendría que escribirse aquí, y aquí no
/// hay dónde escribirla. Los roles de un usuario son los que le dieron, y los
/// que le dieron viajan firmados en el token, nunca los declara el cliente.
/// </para>
/// </summary>
public static class Autorizacion
{
    public static bool Permite(Sesion sesion, Operacion operacion)
    {
        // Un token de renovación sirve para pedir otro token, no para hacer
        // cosas. Si autorizara operaciones, los 30 días de la renovación serían
        // en la práctica la duración de un token de acceso.
        if (sesion.Tipo != TipoDeToken.Acceso)
        {
            return false;
        }

        foreach (var rol in sesion.Roles)
        {
            if (operacion.RolesQueLaPermiten.Contains(rol, StringComparer.Ordinal))
            {
                return true;
            }
        }

        return false;
    }
}
