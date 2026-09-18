using Symphony.Cloud.BaseDeDatos;

namespace Symphony.Cloud.Iglesias;

/// <summary>
/// <c>dotnet run -- crear-iglesia "&lt;nombre&gt;" &lt;correo-administrador&gt; "&lt;nombre-administrador&gt;"</c>
/// (spec R9, T7.1–T7.3): crea la primera iglesia y su administrador sin panel,
/// al estilo del <c>-- migrar</c> que ya existe en el nodo.
///
/// <para>
/// La contraseña se lee de la entrada estándar, nunca de un argumento: un
/// argumento queda en el historial de la terminal y en la lista de procesos,
/// justo lo que T7.2 prohíbe para la credencial inicial. Leerla de la entrada
/// estándar sirve igual a mano (se escribe y se pulsa enter) que en un script
/// (<c>echo "..." | dotnet run -- crear-iglesia ...</c>), que es lo que R9 pide
/// para levantar un entorno de pruebas desde cero.
/// </para>
/// </summary>
public static class ComandoCrearIglesia
{
    public const string Nombre = "crear-iglesia";

    public static async Task<int> Ejecutar(
        IReadOnlyList<string> args, AccesoComoPropietario propietario, TextReader entrada, TextWriter salida)
    {
        var posicionales = args.SkipWhile(a => a != Nombre).Skip(1).ToList();
        if (posicionales.Count != 3)
        {
            salida.WriteLine(
                $"Uso: {Nombre} <nombre-de-la-iglesia> <correo-del-administrador> <nombre-del-administrador>");
            salida.WriteLine("La contraseña del administrador se lee de la entrada estándar.");
            return 1;
        }

        var (nombreIglesia, correoAdministrador, nombreAdministrador) =
            (posicionales[0], posicionales[1], posicionales[2]);

        var contrasena = await entrada.ReadLineAsync();
        if (string.IsNullOrWhiteSpace(contrasena))
        {
            salida.WriteLine("La contraseña del primer administrador es obligatoria.");
            return 1;
        }

        var alta = await propietario.CrearIglesiaConAdministrador(
            nombreIglesia, correoAdministrador, nombreAdministrador, contrasena);

        salida.WriteLine();
        salida.WriteLine($"Iglesia creada: {alta.IglesiaId} ({nombreIglesia})");
        salida.WriteLine($"Administrador: {correoAdministrador}");
        salida.WriteLine();
        salida.WriteLine("Variable para el .env del nodo de esta iglesia:");
        salida.WriteLine($"SYMPHONY_NODE_IGLESIA_ID={alta.IglesiaId}");
        salida.WriteLine();

        return 0;
    }
}
