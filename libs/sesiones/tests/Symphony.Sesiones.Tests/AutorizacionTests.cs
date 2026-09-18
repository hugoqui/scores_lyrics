namespace Symphony.Sesiones.Tests;

/// <summary>
/// T5.4: la regla de que <b>ningún rol incluye a otro</b> (spec R7).
///
/// No se comprueba con dos o tres ejemplos elegidos a mano, porque la forma en
/// que esta regla se rompe es añadiendo una operación nueva y olvidando el caso
/// —y un ejemplo escrito hoy no cubre una operación de mañana. Se comprueba
/// recorriendo el catálogo entero: para toda operación y todo rol, se permite
/// exactamente si el rol está en su lista.
/// </summary>
public class AutorizacionTests
{
    private static readonly Guid _iglesia = Guid.CreateVersion7();

    [Fact]
    public void Ningun_rol_autoriza_una_operacion_que_no_lo_nombra()
    {
        foreach (var operacion in Operaciones.Todas)
        {
            foreach (var rol in Roles.Todos)
            {
                var esperado = operacion.RolesQueLaPermiten.Contains(rol);

                Assert.Equal(esperado, Autorizacion.Permite(SesionCon(rol), operacion));
            }
        }
    }

    /// <summary>
    /// T5.8 en su forma pura: el caso concreto que la spec nombra, escrito
    /// aparte del recorrido de arriba para que se lea qué se está prometiendo.
    /// </summary>
    [Fact]
    public void Un_administrador_no_puede_operar_el_servicio()
    {
        Assert.False(Autorizacion.Permite(SesionCon(Roles.Administrador), Operaciones.OperarElServicio));

        // Y con los dos roles sí: la regla es que no se hereda, no que sean
        // incompatibles. Quien dirige la alabanza suele tener ambos.
        Assert.True(Autorizacion.Permite(
            SesionCon(Roles.Administrador, Roles.Operador), Operaciones.OperarElServicio));
    }

    [Fact]
    public void Un_musico_no_administra_por_mucho_que_lo_diga()
    {
        // No hay forma de «decirlo»: la sesión es lo único que se mira, y la
        // sesión viene firmada. Esta prueba fija que tener el rol de músico no
        // acerca en nada a administrar.
        Assert.False(Autorizacion.Permite(SesionCon(Roles.Musico), Operaciones.AdministrarUsuarios));
        Assert.False(Autorizacion.Permite(SesionCon(Roles.Musico), Operaciones.AdministrarDispositivos));
    }

    [Fact]
    public void Un_rol_que_no_existe_no_autoriza_nada()
    {
        var inventado = SesionCon("superadministrador");

        foreach (var operacion in Operaciones.Todas)
        {
            Assert.False(Autorizacion.Permite(inventado, operacion));
        }
    }

    [Fact]
    public void Sin_roles_no_se_autoriza_nada()
    {
        var sinRoles = SesionCon();

        foreach (var operacion in Operaciones.Todas)
        {
            Assert.False(Autorizacion.Permite(sinRoles, operacion));
        }
    }

    [Fact]
    public void Un_token_de_renovacion_no_autoriza_operaciones()
    {
        var todosLosRoles = SesionCon(Roles.Administrador, Roles.Operador, Roles.Musico);
        var renovacion = todosLosRoles with { Tipo = TipoDeToken.Renovacion };

        foreach (var operacion in Operaciones.Todas)
        {
            Assert.False(Autorizacion.Permite(renovacion, operacion));
        }
    }

    [Fact]
    public void Toda_operacion_del_catalogo_nombra_roles_conocidos()
    {
        // Un rol mal escrito en el catálogo no rompe nada visible: la operación
        // simplemente deja de autorizarse para siempre, y eso se descubre el
        // día del culto.
        foreach (var operacion in Operaciones.Todas)
        {
            Assert.NotEmpty(operacion.RolesQueLaPermiten);
            Assert.All(operacion.RolesQueLaPermiten, rol => Assert.Contains(rol, Roles.Todos));
        }
    }

    private static Sesion SesionCon(params string[] roles) => new()
    {
        UsuarioId = Guid.CreateVersion7(),
        IglesiaId = _iglesia,
        Roles = roles,
        DispositivoId = Guid.CreateVersion7(),
        Tipo = TipoDeToken.Acceso,
        Emisor = Emisor.Nube,
        IdDeClave = "00000000",
        EmitidaEn = DateTimeOffset.UnixEpoch,
        ExpiraEn = DateTimeOffset.UnixEpoch.AddHours(1),
    };
}
