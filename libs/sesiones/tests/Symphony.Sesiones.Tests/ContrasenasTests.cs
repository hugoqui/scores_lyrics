namespace Symphony.Sesiones.Tests;

/// <summary>
/// La tabla de usuarios actual se considera comprometida ([ADR 0008]): guardaba
/// SHA1 sin sal. Estas pruebas fijan lo que hace que la nueva no lo sea.
///
/// Corren con parámetros bajos a propósito: Argon2id es lento por diseño y los
/// de producción harían la suite inutilizable. Lo que se prueba aquí es el
/// comportamiento, no el costo; el costo se calibra contra la PC de la iglesia
/// (002 T4.2).
/// </summary>
public class ContrasenasTests
{
    private static readonly ParametrosArgon2id _rapidos = new(MemoriaEnKib: 1024, Iteraciones: 1, Paralelismo: 1);

    [Fact]
    public void Una_contrasena_correcta_coincide()
    {
        var guardado = Contrasenas.Guardar("el gozo del Señor", _rapidos);

        Assert.True(Contrasenas.Coinciden("el gozo del Señor", guardado));
    }

    [Theory]
    [InlineData("el gozo del señor")]
    [InlineData("el gozo del Señor ")]
    [InlineData("")]
    public void Una_contrasena_equivocada_no_coincide(string intento)
    {
        var guardado = Contrasenas.Guardar("el gozo del Señor", _rapidos);

        Assert.False(Contrasenas.Coinciden(intento, guardado));
    }

    [Fact]
    public void La_misma_contrasena_dos_veces_da_hash_distintos()
    {
        // Sal por usuario: dos personas con la misma contraseña no comparten
        // hash, así que una tabla precalculada no sirve de nada.
        var primero = Contrasenas.Guardar("aleluya", _rapidos);
        var segundo = Contrasenas.Guardar("aleluya", _rapidos);

        Assert.NotEqual(primero, segundo);
        Assert.True(Contrasenas.Coinciden("aleluya", primero));
        Assert.True(Contrasenas.Coinciden("aleluya", segundo));
    }

    [Fact]
    public void El_hash_guardado_no_contiene_la_contrasena()
    {
        var guardado = Contrasenas.Guardar("aleluya", _rapidos);

        Assert.DoesNotContain("aleluya", guardado, StringComparison.OrdinalIgnoreCase);
        Assert.StartsWith("$argon2id$v=19$", guardado, StringComparison.Ordinal);
    }

    [Fact]
    public void Subir_los_parametros_no_invalida_las_contrasenas_ya_guardadas()
    {
        // Es la razón de guardar los parámetros junto al hash: el día que se
        // suban, nadie se queda fuera.
        var conLosViejos = Contrasenas.Guardar("aleluya", _rapidos);
        var masCaros = _rapidos with { MemoriaEnKib = 2048, Iteraciones = 2 };

        Assert.True(Contrasenas.Coinciden("aleluya", conLosViejos));
        Assert.True(Contrasenas.ConvieneRehacer(conLosViejos, masCaros));
        Assert.False(Contrasenas.ConvieneRehacer(Contrasenas.Guardar("aleluya", masCaros), masCaros));
    }

    [Theory]
    [InlineData("")]
    [InlineData("no es un hash")]
    [InlineData("$argon2id$v=19$m=1024$sal$hash")]
    [InlineData("$sha1$loquesea$hash")]
    public void Un_hash_ilegible_no_deja_entrar_a_nadie(string guardado)
    {
        // El modo de fallo tiene que ser "no entra", nunca "entra cualquiera"
        // ni una excepción que alguien atrape y confunda con un sí.
        Assert.False(Contrasenas.Coinciden("lo que sea", guardado));
    }
}
