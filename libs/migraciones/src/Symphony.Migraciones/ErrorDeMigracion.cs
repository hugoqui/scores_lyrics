namespace Symphony.Migraciones;

/// <summary>
/// Algo impide aplicar las migraciones con seguridad. Siempre es motivo para
/// no arrancar: seguir adelante con un esquema del que no se sabe nada es
/// peor que no arrancar.
/// </summary>
public sealed class ErrorDeMigracion(string mensaje) : Exception(mensaje);
