namespace Symphony.Sesiones.Web;

/// <summary>Lo que hace falta de un usuario para decidir si sus credenciales son válidas.</summary>
public sealed record UsuarioParaAutenticar(
    Guid Id, Guid IglesiaId, string HashContrasena, string Estado, IReadOnlyList<string> Roles);

public enum ResultadoDeCredenciales
{
    /// <summary>Correo inexistente o contraseña incorrecta: la misma respuesta para las dos (spec R2, R7).</summary>
    Invalidas,

    /// <summary>Contraseña correcta, pero al usuario se le cerró el acceso (spec R4).</summary>
    DadoDeBaja,

    Validas,
}

/// <summary>
/// La comprobación de credenciales, compartida por nube y nodo para que exista
/// una sola vez el detalle que la hace segura: cuánto tarda en decir que no.
///
/// <para>
/// Sin el señuelo, un correo que no existe se rechaza al instante y uno que sí
/// existe tarda lo que tarda Argon2id —cientos de milisegundos—: esa
/// diferencia le dice a quien prueba correos al azar cuáles están dados de
/// alta, sin haber acertado ninguna contraseña.
/// </para>
/// </summary>
public static class VerificacionDeCredenciales
{
    private static readonly string _hashSenuelo = Contrasenas.Guardar(Guid.NewGuid().ToString());

    public static ResultadoDeCredenciales Verificar(string contrasena, UsuarioParaAutenticar? usuario)
    {
        // Se calcula siempre, exista o no el usuario: es el paso lento, y es
        // el que no puede saltarse cuando no hay nadie a quien comparar.
        var coincide = Contrasenas.Coinciden(contrasena, usuario?.HashContrasena ?? _hashSenuelo);

        if (usuario is null || !coincide)
        {
            return ResultadoDeCredenciales.Invalidas;
        }

        return usuario.Estado == "activo" ? ResultadoDeCredenciales.Validas : ResultadoDeCredenciales.DadoDeBaja;
    }
}

/// <summary>Los tipos de dispositivo, la misma lista cerrada que el <c>CHECK</c> de las migraciones.</summary>
public static class TiposDeDispositivo
{
    public const string Movil = "movil";
    public const string Tableta = "tableta";
    public const string Pantalla = "pantalla";

    public static readonly IReadOnlyList<string> Todos = [Movil, Tableta, Pantalla];
}

public sealed record SolicitudDeLogin(string Correo, string Contrasena, Guid DispositivoId, string DispositivoNombre, string DispositivoTipo);

public sealed record RespuestaDeSesion(
    string TokenDeAcceso, string TokenDeRenovacion, Guid UsuarioId, Guid IglesiaId, IReadOnlyList<string> Roles, Guid DispositivoId);

public sealed record SolicitudDeRenovacion(string TokenDeRenovacion);

public sealed record RespuestaDeRenovacion(string TokenDeAcceso);

public sealed record SolicitudDeCierre(string TokenDeRenovacion);
