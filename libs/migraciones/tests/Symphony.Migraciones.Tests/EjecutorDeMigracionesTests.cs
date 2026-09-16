namespace Symphony.Migraciones.Tests;

/// <summary>
/// Las dos propiedades que hacen confiable al ejecutor: el esquema converge
/// (T3.3, T3.4) y aplicar de más no hace nada (T3.5). Más la red de seguridad:
/// una migración aplicada que cambia en disco no deja arrancar (T3.6).
/// </summary>
public class EjecutorDeMigracionesTests
{
    [Fact]
    public void Base_vacia_mas_todas_las_migraciones_da_el_esquema_esperado()
    {
        using var carpeta = new CarpetaDePrueba();
        SqlDePrueba.EscribirTodas(carpeta);

        using (var conexion = carpeta.Abrir())
        {
            var resultado = carpeta.Ejecutor().Aplicar(conexion);

            Assert.Equal(["0001_inicial", "0002_cantos", "0003_musicos"], resultado.Aplicadas);
        }

        var esquema = carpeta.Esquema();
        Assert.Contains("table cantos", esquema);
        Assert.Contains("table musicos", esquema);
        Assert.Contains("index ix_musicos_correo", esquema);
        Assert.Contains("table migraciones_aplicadas", esquema);
        Assert.Equal(3, carpeta.MigracionesAnotadas().Count);
    }

    [Fact]
    public void Base_a_medio_migrar_converge_al_mismo_esquema_que_una_vacia()
    {
        // Referencia: base vacía con las tres migraciones de una vez.
        using var completa = new CarpetaDePrueba();
        SqlDePrueba.EscribirTodas(completa);
        using (var conexion = completa.Abrir())
        {
            completa.Ejecutor().Aplicar(conexion);
        }

        // La otra queda a medio migrar y recibe la que falta después.
        using var aMedias = new CarpetaDePrueba();
        aMedias.EscribirMigracion("0001_inicial.sql", SqlDePrueba.Inicial);
        aMedias.EscribirMigracion("0002_cantos.sql", SqlDePrueba.Cantos);
        using (var conexion = aMedias.Abrir())
        {
            aMedias.Ejecutor().Aplicar(conexion);
        }

        aMedias.EscribirMigracion("0003_musicos.sql", SqlDePrueba.Musicos);
        using (var conexion = aMedias.Abrir())
        {
            var resultado = aMedias.Ejecutor().Aplicar(conexion);

            Assert.Equal(["0003_musicos"], resultado.Aplicadas);
        }

        Assert.Equal(completa.Esquema(), aMedias.Esquema());
        Assert.Equal(completa.MigracionesAnotadas(), aMedias.MigracionesAnotadas());
    }

    [Fact]
    public void Aplicar_dos_veces_no_cambia_nada_ni_falla()
    {
        using var carpeta = new CarpetaDePrueba();
        SqlDePrueba.EscribirTodas(carpeta);

        using (var conexion = carpeta.Abrir())
        {
            carpeta.Ejecutor().Aplicar(conexion);
        }

        var esquemaTrasLaPrimera = carpeta.Esquema();
        var anotadasTrasLaPrimera = carpeta.MigracionesAnotadas();

        using (var conexion = carpeta.Abrir())
        {
            var segunda = carpeta.Ejecutor().Aplicar(conexion);

            Assert.False(segunda.HuboCambios);
            Assert.Empty(segunda.Aplicadas);
            Assert.Equal(3, segunda.YaEstaban.Count);
        }

        Assert.Equal(esquemaTrasLaPrimera, carpeta.Esquema());
        Assert.Equal(anotadasTrasLaPrimera, carpeta.MigracionesAnotadas());
    }

    [Fact]
    public void Alterar_en_disco_una_migracion_ya_aplicada_hace_fallar_el_arranque()
    {
        using var carpeta = new CarpetaDePrueba();
        SqlDePrueba.EscribirTodas(carpeta);
        using (var conexion = carpeta.Abrir())
        {
            carpeta.Ejecutor().Aplicar(conexion);
        }

        carpeta.EscribirMigracion("0002_cantos.sql", SqlDePrueba.Cantos + "\nALTER TABLE cantos ADD COLUMN tono TEXT;");

        using var otra = carpeta.Abrir();
        var error = Assert.Throws<ErrorDeMigracion>(() => carpeta.Ejecutor().Aplicar(otra));

        Assert.Contains("0002_cantos.sql", error.Message);
        Assert.Contains("cambió en disco", error.Message);
    }

    [Fact]
    public void Cambiar_solo_los_finales_de_linea_no_invalida_una_migracion_aplicada()
    {
        using var carpeta = new CarpetaDePrueba();
        SqlDePrueba.EscribirTodas(carpeta);
        using (var conexion = carpeta.Abrir())
        {
            carpeta.Ejecutor().Aplicar(conexion);
        }

        // Lo que haría un clon del repositorio en Windows.
        carpeta.EscribirMigracion("0002_cantos.sql", SqlDePrueba.Cantos.Replace("\n", "\r\n"));

        using var otra = carpeta.Abrir();
        var resultado = carpeta.Ejecutor().Aplicar(otra);

        Assert.False(resultado.HuboCambios);
    }

    [Fact]
    public void Borrar_una_migracion_ya_aplicada_hace_fallar_el_arranque()
    {
        using var carpeta = new CarpetaDePrueba();
        SqlDePrueba.EscribirTodas(carpeta);
        using (var conexion = carpeta.Abrir())
        {
            carpeta.Ejecutor().Aplicar(conexion);
        }

        carpeta.BorrarMigracion("0002_cantos.sql");

        using var otra = carpeta.Abrir();
        var error = Assert.Throws<ErrorDeMigracion>(() => carpeta.Ejecutor().Aplicar(otra));

        Assert.Contains("0002_cantos", error.Message);
    }

    [Fact]
    public void Una_migracion_nueva_con_numero_anterior_al_ultimo_aplicado_se_rechaza()
    {
        // Si se aceptara, una base nueva la aplicaría y una base ya migrada
        // nunca: los dos esquemas dejarían de converger.
        using var carpeta = new CarpetaDePrueba();
        carpeta.EscribirMigracion("0001_inicial.sql", SqlDePrueba.Inicial);
        carpeta.EscribirMigracion("0003_musicos.sql", SqlDePrueba.Musicos);
        using (var conexion = carpeta.Abrir())
        {
            carpeta.Ejecutor().Aplicar(conexion);
        }

        carpeta.EscribirMigracion("0002_cantos.sql", SqlDePrueba.Cantos);

        using var otra = carpeta.Abrir();
        var error = Assert.Throws<ErrorDeMigracion>(() => carpeta.Ejecutor().Aplicar(otra));

        Assert.Contains("0002_cantos.sql", error.Message);
        Assert.Contains("anteriores a la última aplicada", error.Message);
    }

    [Fact]
    public void Un_archivo_con_nombre_fuera_de_formato_hace_fallar_el_arranque()
    {
        using var carpeta = new CarpetaDePrueba();
        SqlDePrueba.EscribirTodas(carpeta);
        carpeta.EscribirMigracion("notas.sql", "-- esto no es una migración");

        var error = Assert.Throws<ErrorDeMigracion>(() => carpeta.Ejecutor().LeerDeDisco());

        Assert.Contains("notas.sql", error.Message);
    }

    [Fact]
    public void Si_una_migracion_falla_no_queda_aplicada_ninguna_de_la_tanda()
    {
        using var carpeta = new CarpetaDePrueba();
        carpeta.EscribirMigracion("0001_inicial.sql", SqlDePrueba.Inicial);
        carpeta.EscribirMigracion("0002_cantos.sql", SqlDePrueba.Cantos);
        carpeta.EscribirMigracion("0003_rota.sql", "ESTO NO ES SQL;");

        using (var conexion = carpeta.Abrir())
        {
            Assert.ThrowsAny<Exception>(() => carpeta.Ejecutor().Aplicar(conexion));
        }

        Assert.DoesNotContain("table cantos", carpeta.Esquema());
        Assert.Empty(carpeta.MigracionesAnotadas());
    }

    [Fact]
    public void Una_carpeta_que_no_existe_hace_fallar_el_arranque()
    {
        var ejecutor = new EjecutorDeMigraciones(
            Path.Combine(Path.GetTempPath(), "symphony-no-existe-" + Guid.NewGuid().ToString("N")),
            DialectoSql.Sqlite);

        var error = Assert.Throws<ErrorDeMigracion>(ejecutor.LeerDeDisco);

        Assert.Contains("No existe la carpeta", error.Message);
    }
}
