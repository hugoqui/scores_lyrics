using Npgsql;

namespace Symphony.Cloud.Tests.BaseDeDatos;

/// <summary>Cuál de los identificadores de la iglesia ajena usa cada caso.</summary>
public enum Ajeno
{
    Usuario,
    Dispositivo,
    Sesion,
}

/// <summary>
/// Las pruebas están escritas para <b>intentar</b> romper el aislamiento, no
/// para confirmar que funciona: tienen a mano todos los identificadores de la
/// segunda iglesia y los usan (spec R10). Una prueba complaciente aquí es peor
/// que ninguna, porque da por verificado lo que nadie verificó.
/// </summary>
public sealed class AislamientoEntreIglesiasTests : IClassFixture<NubeDePrueba>
{
    private readonly NubeDePrueba _nube;

    public AislamientoEntreIglesiasTests(NubeDePrueba nube) => _nube = nube;

    [Theory]
    [InlineData("SELECT count(*) FROM iglesia WHERE id = @id")]
    [InlineData("SELECT count(*) FROM usuario WHERE iglesia_id = @id")]
    [InlineData("SELECT count(*) FROM dispositivo WHERE iglesia_id = @id")]
    [InlineData("SELECT count(*) FROM sesion WHERE iglesia_id = @id")]
    public async Task La_sesion_de_una_iglesia_no_alcanza_ninguna_fila_de_la_otra(string consulta)
    {
        var ajena = _nube.Segunda;
        await using var conexion = await _nube.AbrirComoAplicacion(_nube.Primera.Id);

        Assert.Equal(0L, await Escalar(conexion, consulta, ajena.Id));
    }

    [Theory]
    [InlineData("SELECT count(*) FROM usuario WHERE id = @id", Ajeno.Usuario)]
    [InlineData("SELECT count(*) FROM usuario_rol WHERE usuario_id = @id", Ajeno.Usuario)]
    [InlineData("SELECT count(*) FROM usuario_instrumento WHERE usuario_id = @id", Ajeno.Usuario)]
    [InlineData("SELECT count(*) FROM dispositivo WHERE id = @id", Ajeno.Dispositivo)]
    [InlineData("SELECT count(*) FROM sesion WHERE id = @id", Ajeno.Sesion)]
    public async Task Conocer_el_identificador_ajeno_no_da_acceso_a_la_fila(string consulta, Ajeno cual)
    {
        // Conocer un identificador no concede acceso (spec R2): la fila
        // responde como si no existiera, no como prohibida.
        await using var conexion = await _nube.AbrirComoAplicacion(_nube.Primera.Id);

        var identificador = cual switch
        {
            Ajeno.Usuario => _nube.Segunda.UsuarioId,
            Ajeno.Dispositivo => _nube.Segunda.DispositivoId,
            _ => _nube.Segunda.SesionId,
        };

        Assert.Equal(0L, await Escalar(conexion, consulta, identificador));
    }

    [Fact]
    public async Task Escribir_en_la_iglesia_ajena_falla_aunque_se_tenga_su_identificador()
    {
        await using var conexion = await _nube.AbrirComoAplicacion(_nube.Primera.Id);

        await using var comando = new NpgsqlCommand(
            """
            INSERT INTO usuario (id, iglesia_id, correo, nombre, hash_contrasena, estado, creado_en)
            VALUES (@nuevo, @ajena, 'intruso@ejemplo.invalid', 'Intruso', 'no-es-un-hash', 'activo', now())
            """,
            conexion);
        comando.Parameters.AddWithValue("nuevo", Guid.CreateVersion7());
        comando.Parameters.AddWithValue("ajena", _nube.Segunda.Id);

        var error = await Assert.ThrowsAsync<PostgresException>(() => comando.ExecuteNonQueryAsync());
        Assert.Equal(PostgresErrorCodes.InsufficientPrivilege, error.SqlState);
    }

    [Theory]
    [InlineData("SELECT count(*) FROM iglesia")]
    [InlineData("SELECT count(*) FROM usuario")]
    [InlineData("SELECT count(*) FROM usuario_rol")]
    [InlineData("SELECT count(*) FROM usuario_instrumento")]
    [InlineData("SELECT count(*) FROM dispositivo")]
    [InlineData("SELECT count(*) FROM sesion")]
    public async Task La_consulta_sin_filtro_de_iglesia_devuelve_cero_filas(string consultaSinFiltro)
    {
        // El modo de fallo que se busca: quien olvida el filtro no ve nada, en
        // vez de ver las filas de la otra congregación ([ADR 0015]).
        await using var conexion = await _nube.AbrirComoAplicacion(iglesiaId: null);

        Assert.Equal(0L, await Escalar(conexion, consultaSinFiltro));
    }

    [Fact]
    public async Task Con_la_iglesia_fijada_la_consulta_sin_filtro_solo_trae_lo_propio()
    {
        // La contraparte de la prueba anterior: si "cero filas" fuera el
        // resultado siempre, las de arriba pasarían sin probar nada.
        await using var conexion = await _nube.AbrirComoAplicacion(_nube.Primera.Id);

        // El músico y el administrador que siembra cada iglesia de prueba.
        Assert.Equal(1L, await Escalar(conexion, "SELECT count(*) FROM iglesia"));
        Assert.Equal(2L, await Escalar(conexion, "SELECT count(*) FROM usuario"));
        Assert.Equal(2L, await Escalar(conexion, "SELECT count(*) FROM usuario_rol"));
        Assert.Equal(1L, await Escalar(conexion, "SELECT count(*) FROM dispositivo"));
    }

    [Theory]
    [InlineData("ALTER TABLE usuario DISABLE ROW LEVEL SECURITY")]
    [InlineData("ALTER TABLE usuario NO FORCE ROW LEVEL SECURITY")]
    [InlineData("DROP POLICY usuario_de_la_sesion ON usuario")]
    public async Task El_rol_de_la_aplicacion_no_puede_desactivar_la_politica(string intento)
    {
        await using var conexion = await _nube.AbrirComoAplicacion(_nube.Primera.Id);

        await using var comando = new NpgsqlCommand(intento, conexion);
        var error = await Assert.ThrowsAsync<PostgresException>(() => comando.ExecuteNonQueryAsync());
        Assert.Equal(PostgresErrorCodes.InsufficientPrivilege, error.SqlState);
    }

    [Fact]
    public async Task El_rol_de_la_aplicacion_no_puede_saltarse_la_politica()
    {
        // NOBYPASSRLS no es un detalle de configuración: es lo que impide que
        // la aplicación se conceda a sí misma el permiso de verlo todo.
        await using var conexion = await _nube.AbrirComoAplicacion(_nube.Primera.Id);

        await using var comando = new NpgsqlCommand("ALTER ROLE symphony_app BYPASSRLS", conexion);
        var error = await Assert.ThrowsAsync<PostgresException>(() => comando.ExecuteNonQueryAsync());
        Assert.Equal(PostgresErrorCodes.InsufficientPrivilege, error.SqlState);
    }

    [Fact]
    public async Task El_catalogo_de_instrumentos_se_ve_sin_iglesia_fijada()
    {
        // Es la excepción cerrada de spec R2: compartido y de solo lectura.
        await using var conexion = await _nube.AbrirComoAplicacion(iglesiaId: null);

        Assert.Equal(10L, await Escalar(conexion, "SELECT count(*) FROM instrumento"));
        Assert.Equal(3L, await Escalar(conexion, "SELECT count(*) FROM instrumento WHERE afinacion = 'bb'"));
    }

    private static async Task<long> Escalar(NpgsqlConnection conexion, string sql, Guid? id = null)
    {
        await using var comando = new NpgsqlCommand(sql, conexion);
        if (id is not null)
        {
            comando.Parameters.AddWithValue("id", id.Value);
        }

        return (long)(await comando.ExecuteScalarAsync())!;
    }
}
