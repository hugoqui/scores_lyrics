using Microsoft.Extensions.Time.Testing;

namespace Symphony.Sesiones.Tests;

/// <summary>
/// Un token es lo único que separa a un músico de los datos de su iglesia, así
/// que estas pruebas están escritas para intentar colarse: firma cambiada,
/// token caducado, token de otra iglesia ([ADR 0016]).
/// </summary>
public class TokensTests
{
    private static readonly DateTimeOffset _domingo = new(2026, 9, 20, 9, 0, 0, TimeSpan.Zero);

    [Fact]
    public void Un_token_recien_emitido_se_acepta()
    {
        var iglesia = Guid.CreateVersion7();
        var (token, claves, _) = Emitir(iglesia);

        var resultado = Tokens.Verificar(token, Publica(claves), _domingo, iglesia);

        Assert.True(resultado.EsValida);
        Assert.Equal(["musico"], resultado.Sesion!.Roles);
    }

    [Fact]
    public void Un_token_con_la_firma_alterada_se_rechaza()
    {
        var iglesia = Guid.CreateVersion7();
        var (token, claves, _) = Emitir(iglesia);

        var partes = token.Split('.');
        var firmaAlterada = partes[1][..^2] + (partes[1][^2] == 'A' ? "BB" : "AA");

        var resultado = Tokens.Verificar($"{partes[0]}.{firmaAlterada}", Publica(claves), _domingo, iglesia);

        Assert.False(resultado.EsValida);
    }

    [Fact]
    public void Cambiar_el_cuerpo_invalida_la_firma()
    {
        // El caso que de verdad importa: no alterar la firma al azar, sino
        // reescribir los roles y conservar la firma original.
        var iglesia = Guid.CreateVersion7();
        var (token, claves, sesion) = Emitir(iglesia);

        var conRolesInflados = sesion with { Roles = ["administrador", "operador"] };
        var cuerpoFalso = Tokens.Emitir(conRolesInflados, ParDeClaves.Generar()).Split('.')[0];

        var resultado = Tokens.Verificar(
            $"{cuerpoFalso}.{token.Split('.')[1]}", Publica(claves), _domingo, iglesia);

        Assert.Equal(MotivoDeRechazo.FirmaInvalida, resultado.Motivo);
    }

    [Fact]
    public void Un_token_caducado_se_rechaza_aunque_el_cliente_afirme_otra_fecha()
    {
        var iglesia = Guid.CreateVersion7();
        var (token, claves, _) = Emitir(iglesia);

        // El reloj que manda es el de quien verifica. Que el cliente insista
        // con una fecha anterior no entra en la cuenta: no hay ningún dato del
        // cliente en esta llamada salvo el propio token.
        var muchoDespues = _domingo + EmisorDeSesiones.DuracionDelAcceso + TimeSpan.FromMinutes(1);

        var resultado = Tokens.Verificar(token, Publica(claves), muchoDespues, iglesia);

        Assert.Equal(MotivoDeRechazo.Caducado, resultado.Motivo);
    }

    [Fact]
    public void Un_token_de_una_iglesia_no_sirve_en_otra()
    {
        var suya = Guid.CreateVersion7();
        var ajena = Guid.CreateVersion7();
        var (token, claves, _) = Emitir(suya);

        var resultado = Tokens.Verificar(token, Publica(claves), _domingo, ajena);

        Assert.Equal(MotivoDeRechazo.OtraIglesia, resultado.Motivo);
    }

    [Fact]
    public void Un_token_firmado_por_otra_clave_se_rechaza()
    {
        var iglesia = Guid.CreateVersion7();
        var (token, _, _) = Emitir(iglesia);

        var resultado = Tokens.Verificar(token, Publica(ParDeClaves.Generar()), _domingo, iglesia);

        Assert.Equal(MotivoDeRechazo.FirmaInvalida, resultado.Motivo);
    }

    [Fact]
    public void Un_token_de_renovacion_no_sirve_como_token_de_acceso()
    {
        var iglesia = Guid.CreateVersion7();
        var claves = ParDeClaves.Generar();
        var emisor = new EmisorDeSesiones(claves, Emisor.Nodo, Reloj());

        var (token, _) = emisor.Renovacion(Guid.CreateVersion7(), iglesia, ["musico"], Guid.CreateVersion7());

        Assert.Equal(
            MotivoDeRechazo.TipoEquivocado,
            Tokens.Verificar(token, Publica(claves), _domingo, iglesia).Motivo);
        Assert.True(
            Tokens.Verificar(token, Publica(claves), _domingo, iglesia, TipoDeToken.Renovacion).EsValida);
    }

    [Theory]
    [InlineData("")]
    [InlineData("sin-punto")]
    [InlineData("demasiadas.partes.aqui")]
    [InlineData("no-es-base64!.tampoco-esto!")]
    public void Un_token_mal_formado_se_rechaza_sin_reventar(string token)
    {
        var resultado = Tokens.Verificar(
            token, Publica(ParDeClaves.Generar()), _domingo, Guid.CreateVersion7());

        Assert.Equal(MotivoDeRechazo.MalFormado, resultado.Motivo);
    }

    [Fact]
    public void De_la_renovacion_se_guarda_la_huella_y_nunca_el_token()
    {
        var (token, _, _) = Emitir(Guid.CreateVersion7());

        var huella = Tokens.Huella(token);

        Assert.DoesNotContain(huella, token, StringComparison.Ordinal);
        Assert.Equal(64, huella.Length);
        Assert.Equal(huella, Tokens.Huella(token));
        Assert.NotEqual(huella, Tokens.Huella(token + "x"));
    }

    private static (string Token, ParDeClaves Claves, Sesion Sesion) Emitir(Guid iglesia)
    {
        var claves = ParDeClaves.Generar();
        var emisor = new EmisorDeSesiones(claves, Emisor.Nube, Reloj());
        var (token, sesion) = emisor.Acceso(Guid.CreateVersion7(), iglesia, ["musico"], Guid.CreateVersion7());
        return (token, claves, sesion);
    }

    private static TimeProvider Reloj() => new FakeTimeProvider(_domingo);

    private static ClavePublicaDeFirma Publica(ParDeClaves claves) =>
        ClavePublicaDeFirma.DesdeBase64(claves.PublicaEnBase64);
}
