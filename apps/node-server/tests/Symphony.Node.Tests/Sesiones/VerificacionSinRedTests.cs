using Microsoft.Extensions.Time.Testing;
using Symphony.Node.Configuration;
using Symphony.Sesiones;

namespace Symphony.Node.Tests.Sesiones;

/// <summary>
/// El domingo el login no puede depender de internet (constitución, punto 2).
/// Esto es lo que lo hace posible: el nodo verifica una sesión emitida por la
/// nube con la clave pública que ya tiene, sin preguntarle a nadie
/// ([ADR 0016]).
/// </summary>
[Collection(ConfiguracionDelProceso.Nombre)]
public class VerificacionSinRedTests
{
    private static readonly DateTimeOffset _domingo = new(2026, 9, 20, 9, 0, 0, TimeSpan.Zero);

    [Fact]
    public void El_nodo_verifica_un_token_de_la_nube_con_la_nube_inalcanzable()
    {
        using var nodo = new NodoDePrueba();

        // La nube apunta a una dirección que no existe: si la verificación
        // intentara hablar con ella, esta prueba fallaría o se colgaría.
        Environment.SetEnvironmentVariable(NodeOptions.CloudUrlVariable, "https://nube.invalid:1/");

        var opciones = NodeOptions.FromEnvironment("Development");
        var laNube = new EmisorDeSesiones(nodo.ClaveDeLaNube, Emisor.Nube, new FakeTimeProvider(_domingo));
        var (token, _) = laNube.Acceso(Guid.CreateVersion7(), nodo.IglesiaId, ["musico"], Guid.CreateVersion7());

        var resultado = Tokens.Verificar(token, opciones.ClavePublicaDeLaNube, _domingo, nodo.IglesiaId);

        Assert.True(resultado.EsValida);
        Assert.Equal(Emisor.Nube, resultado.Sesion!.Emisor);
    }

    [Fact]
    public void El_nodo_emite_con_su_propia_clave_y_la_nube_no_la_verifica_con_la_suya()
    {
        // Cada lado firma con la suya: comprometer un nodo no permite
        // falsificar sesiones de otra iglesia, que es la razón de que la firma
        // sea asimétrica y no un secreto compartido.
        using var nodo = new NodoDePrueba();
        var opciones = NodeOptions.FromEnvironment("Development");

        var emisorDelNodo = new EmisorDeSesiones(opciones.ClaveDeFirma, Emisor.Nodo, new FakeTimeProvider(_domingo));
        var (token, _) = emisorDelNodo.Acceso(
            Guid.CreateVersion7(), nodo.IglesiaId, ["operador"], Guid.CreateVersion7());

        Assert.Equal(
            MotivoDeRechazo.FirmaInvalida,
            Tokens.Verificar(token, opciones.ClavePublicaDeLaNube, _domingo, nodo.IglesiaId).Motivo);

        var suPropiaPublica = ClavePublicaDeFirma.DesdeBase64(nodo.ClaveDelNodo.PublicaEnBase64);
        Assert.True(Tokens.Verificar(token, suPropiaPublica, _domingo, nodo.IglesiaId).EsValida);
    }
}
