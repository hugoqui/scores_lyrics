namespace Symphony.Migraciones;

/// <summary>Qué hizo una pasada del ejecutor. Sin pendientes, <see cref="Aplicadas"/> es vacío.</summary>
public sealed record ResultadoDeMigracion(IReadOnlyList<string> Aplicadas, IReadOnlyList<string> YaEstaban)
{
    public bool HuboCambios => Aplicadas.Count > 0;
}
