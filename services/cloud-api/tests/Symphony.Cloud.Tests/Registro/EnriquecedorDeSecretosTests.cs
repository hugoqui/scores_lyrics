using Serilog.Core;
using Serilog.Events;
using Serilog.Parsing;
using Symphony.Cloud.Registro;

namespace Symphony.Cloud.Tests.Registro;

/// <summary>
/// spec R7: ni contraseñas, ni tokens, ni cadenas de conexión sobreviven al
/// registro, sin importar si llegan como propiedad nombrada o dentro de un
/// texto libre.
/// </summary>
public class EnriquecedorDeSecretosTests
{
    [Fact]
    public void Una_propiedad_llamada_como_un_secreto_se_redacta_por_completo()
    {
        var evento = CrearEvento("CadenaConexion", "Host=localhost;Password=super-secreta;");

        new EnriquecedorDeSecretos().Enrich(evento, new FabricaDePropiedadesDePrueba());

        Assert.Equal("[REDACTADO]", ValorDe(evento, "CadenaConexion"));
    }

    [Fact]
    public void Una_contrasena_dentro_de_un_texto_libre_se_redacta_sin_tocar_el_resto()
    {
        var evento = CrearEvento("Detalle", "Conectando con Password=super-secreta;Host=localhost");

        new EnriquecedorDeSecretos().Enrich(evento, new FabricaDePropiedadesDePrueba());

        var valor = ValorDe(evento, "Detalle");
        Assert.DoesNotContain("super-secreta", valor);
        Assert.Contains("Host=localhost", valor);
    }

    [Fact]
    public void Un_texto_sin_secretos_no_se_toca()
    {
        var evento = CrearEvento("Mensaje", "Migraciones aplicadas: 1");

        new EnriquecedorDeSecretos().Enrich(evento, new FabricaDePropiedadesDePrueba());

        Assert.Equal("Migraciones aplicadas: 1", ValorDe(evento, "Mensaje"));
    }

    private static LogEvent CrearEvento(string nombreDePropiedad, string valor) => new(
        DateTimeOffset.Now,
        LogEventLevel.Information,
        exception: null,
        new MessageTemplateParser().Parse("{" + nombreDePropiedad + "}"),
        [new LogEventProperty(nombreDePropiedad, new ScalarValue(valor))]);

    private static string ValorDe(LogEvent evento, string nombreDePropiedad) =>
        (string)((ScalarValue)evento.Properties[nombreDePropiedad]).Value!;

    private sealed class FabricaDePropiedadesDePrueba : ILogEventPropertyFactory
    {
        public LogEventProperty CreateProperty(string name, object? value, bool destructureObjects = false) =>
            new(name, new ScalarValue(value));
    }
}
