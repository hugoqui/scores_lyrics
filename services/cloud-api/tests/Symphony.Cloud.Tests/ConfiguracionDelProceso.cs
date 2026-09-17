namespace Symphony.Cloud.Tests;

/// <summary>
/// Las pruebas que arrancan la nube escriben variables de entorno, que son del
/// proceso entero. Dos clases corriendo en paralelo se pisan la configuración y
/// una termina apuntando a la base de la otra, así que van en la misma
/// colección: xunit no las solapa.
/// </summary>
[CollectionDefinition(Nombre)]
public sealed class ConfiguracionDelProceso
{
    public const string Nombre = "configuración del proceso";
}
