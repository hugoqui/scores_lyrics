using System.Text.RegularExpressions;
using Serilog.Core;
using Serilog.Events;

namespace Symphony.Node.Registro;

/// <summary>
/// Antes de que un evento se escriba (spec R7): las propiedades cuyo nombre
/// delata un secreto se reemplazan por completo, y cualquier valor de texto
/// que contenga un patrón tipo "password=..." se redacta igual, por si el
/// secreto viaja dentro de un mensaje libre en vez de una propiedad nombrada.
/// </summary>
public sealed partial class EnriquecedorDeSecretos : ILogEventEnricher
{
    private const string _redactado = "[REDACTADO]";

    private static readonly string[] _nombresSensibles =
    [
        "password", "contraseña", "contrasena", "pwd", "token", "secret",
        "clave", "connectionstring", "cadenaconexion", "cadenadeconexion",
    ];

    public void Enrich(LogEvent logEvent, ILogEventPropertyFactory propertyFactory)
    {
        foreach (var (nombre, valor) in logEvent.Properties.ToArray())
        {
            if (EsNombreSensible(nombre))
            {
                logEvent.AddOrUpdateProperty(propertyFactory.CreateProperty(nombre, _redactado));
                continue;
            }

            if (valor is ScalarValue { Value: string texto } && PatronDeSecretoEnTexto().IsMatch(texto))
            {
                var redactado = PatronDeSecretoEnTexto().Replace(texto, "$1=" + _redactado);
                logEvent.AddOrUpdateProperty(propertyFactory.CreateProperty(nombre, redactado));
            }
        }
    }

    private static bool EsNombreSensible(string nombreDePropiedad)
    {
        var enMinusculas = nombreDePropiedad.ToLowerInvariant();
        return _nombresSensibles.Any(enMinusculas.Contains);
    }

    [GeneratedRegex(@"(?i)(password|pwd|contrase[ñn]a|token|secret|clave)\s*=\s*[^;]+")]
    private static partial Regex PatronDeSecretoEnTexto();
}
