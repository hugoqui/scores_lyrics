namespace Symphony.Sesiones;

/// <summary>
/// La lista cerrada de roles dentro de una iglesia (spec R7).
///
/// Son las mismas cadenas que acepta el <c>CHECK</c> de <c>usuario_rol</c> en
/// las migraciones de nube y nodo. Si alguien añade un rol, se añade en los
/// tres sitios o no existe: un rol que la base acepta y el código no conoce no
/// autoriza nada, y uno que el código conoce y la base rechaza no se puede
/// asignar.
///
/// Fuera de esta lista queda el propietario del SaaS (spec R4), que no es un
/// rol de iglesia sino una identidad aparte.
/// </summary>
public static class Roles
{
    public const string Administrador = "administrador";

    public const string Operador = "operador";

    public const string Musico = "musico";

    public static readonly IReadOnlyList<string> Todos = [Administrador, Operador, Musico];
}
