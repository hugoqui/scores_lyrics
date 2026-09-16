namespace Symphony.Migraciones;

/// <summary>
/// Una migración leída de disco. El <paramref name="Hash"/> es la huella del
/// contenido: es lo que permite detectar que un archivo ya aplicado cambió.
/// </summary>
public sealed record Migracion(int Numero, string Nombre, string Archivo, string Sql, string Hash)
{
    /// <summary>Nombre canónico, como aparece en la tabla de control: <c>0001_inicial</c>.</summary>
    public string NombreCompleto => $"{Numero:D4}_{Nombre}";
}
