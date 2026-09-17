using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.Data.Sqlite;
using Microsoft.Extensions.Logging.Abstractions;
using Symphony.Node.BaseDeDatos;
using Symphony.Node.Configuration;

namespace Symphony.Node.Tests.BaseDeDatos;

/// <summary>
/// El nodo sirve a una sola iglesia ([ADR 0002]) y tiene que demostrarlo: una
/// sola fila en <c>iglesia</c>, todo lo demás colgando de ella, y la negativa a
/// arrancar contra la base de otra congregación (spec R1, R3).
/// </summary>
[Collection(ConfiguracionDelProceso.Nombre)]
public class IdentidadDelNodoTests
{
    [Fact]
    public void La_segunda_iglesia_es_rechazada_por_la_base()
    {
        using var nodo = new NodoDePrueba();
        nodo.Migrar();
        nodo.SembrarIglesia(nodo.IglesiaId);

        using var conexion = nodo.Abrir();
        using var comando = conexion.CreateCommand();
        comando.CommandText =
            """
            INSERT INTO iglesia (fila, id, nombre, estado, creada_en)
            VALUES (2, $id, 'Iglesia intrusa', 'activa', '2026-01-01T00:00:00Z')
            """;
        comando.Parameters.AddWithValue("$id", Guid.CreateVersion7().ToString());

        // Da igual qué número de fila se intente: el 1 choca con la clave
        // primaria y cualquier otro incumple el CHECK. No hay forma de tener
        // dos iglesias en la misma base.
        Assert.Throws<SqliteException>(() => comando.ExecuteNonQuery());

        comando.CommandText = comando.CommandText.Replace("VALUES (2,", "VALUES (1,", StringComparison.Ordinal);
        Assert.Throws<SqliteException>(() => comando.ExecuteNonQuery());
    }

    [Theory]
    [InlineData("INSERT INTO usuario (id, iglesia_id, correo, nombre, hash_contrasena, estado, creado_en) " +
        "VALUES ($fila, $ajena, 'intruso@ejemplo.invalid', 'Intruso', 'no-es-un-hash', 'activo', '2026-01-01T00:00:00Z')")]
    [InlineData("INSERT INTO dispositivo (id, iglesia_id, usuario_id, tipo, nombre, creado_en) " +
        "VALUES ($fila, $ajena, NULL, 'pantalla', 'Pantalla intrusa', '2026-01-01T00:00:00Z')")]
    public void Insertar_una_fila_de_otra_iglesia_falla_en_el_motor(string insercion)
    {
        using var nodo = new NodoDePrueba();
        nodo.Migrar();
        nodo.SembrarIglesia(nodo.IglesiaId);

        using var conexion = nodo.Abrir();
        using var comando = conexion.CreateCommand();
        comando.CommandText = insercion;
        comando.Parameters.AddWithValue("$fila", Guid.CreateVersion7().ToString());
        comando.Parameters.AddWithValue("$ajena", Guid.CreateVersion7().ToString());

        var error = Assert.Throws<SqliteException>(() => comando.ExecuteNonQuery());
        Assert.Contains("FOREIGN KEY", error.Message, StringComparison.OrdinalIgnoreCase);
    }

    [Fact]
    public void El_nodo_se_niega_a_arrancar_con_la_base_de_otra_iglesia()
    {
        using var nodo = new NodoDePrueba();
        nodo.Migrar();

        var ajena = Guid.CreateVersion7();
        nodo.SembrarIglesia(ajena, "Iglesia de la otra ciudad");

        var excepcion = Assert.Throws<InvalidOperationException>(
            () => IdentidadDelNodo.Verificar(NodeOptions.FromEnvironment("Development"), NullLogger.Instance));

        // El mensaje tiene que servirle a quien restauró el respaldo
        // equivocado un domingo: qué iglesia esperaba y cuál encontró.
        Assert.Contains(nodo.IglesiaId.ToString(), excepcion.Message, StringComparison.Ordinal);
        Assert.Contains(ajena.ToString(), excepcion.Message, StringComparison.Ordinal);
        Assert.Contains("Iglesia de la otra ciudad", excepcion.Message, StringComparison.Ordinal);
    }

    [Fact]
    public async Task El_arranque_completo_se_cae_con_la_base_de_otra_iglesia()
    {
        // La prueba de arriba comprueba la comprobación; esta comprueba que
        // está enchufada al arranque de verdad, que es lo que protege el
        // domingo.
        using var nodo = new NodoDePrueba();
        nodo.Migrar();
        nodo.SembrarIglesia(Guid.CreateVersion7());

        await using var factory = new WebApplicationFactory<Program>();

        Assert.Throws<InvalidOperationException>(() => factory.CreateClient());
    }

    [Fact]
    public void Con_su_propia_iglesia_el_nodo_arranca()
    {
        // La contraparte: si "siempre se cae" fuera el comportamiento, las
        // pruebas de arriba pasarían sin probar nada.
        using var nodo = new NodoDePrueba();
        nodo.Migrar();
        nodo.SembrarIglesia(nodo.IglesiaId);

        IdentidadDelNodo.Verificar(NodeOptions.FromEnvironment("Development"), NullLogger.Instance);
    }

    [Fact]
    public void Una_base_recien_creada_todavia_no_contradice_a_nadie()
    {
        // Sin fila de iglesia no hay datos que servir —todo cuelga de ella— y
        // la iglesia llega con la configuración inicial o con la primera
        // sincronización (módulo 008).
        using var nodo = new NodoDePrueba();
        nodo.Migrar();

        IdentidadDelNodo.Verificar(NodeOptions.FromEnvironment("Development"), NullLogger.Instance);
    }
}
