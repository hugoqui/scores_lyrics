namespace Symphony.Sesiones;

/// <summary>
/// Genera un par de claves y lo imprime como las dos líneas que hay que pegar
/// en el archivo de entorno del servidor.
///
/// Se imprime y no se guarda en ningún archivo a propósito: nada automatizado
/// escribe una clave privada en disco dentro del repositorio (constitución,
/// punto 7). Quien la genera decide dónde va.
/// </summary>
public static class GeneracionDeClaves
{
    public static void Imprimir(string variablePrivada, string variablePublica, TextWriter salida)
    {
        var claves = ParDeClaves.Generar();

        salida.WriteLine();
        salida.WriteLine($"# Par de claves Ed25519 nuevo. Identificador: {claves.Id}");
        salida.WriteLine("# La privada va al .env del servidor (chmod 600) y NUNCA al repositorio.");
        salida.WriteLine($"{variablePrivada}={claves.PrivadaEnBase64}");
        salida.WriteLine();
        salida.WriteLine("# La pública es la que se le entrega a quien tenga que verificar.");
        salida.WriteLine($"{variablePublica}={claves.PublicaEnBase64}");
        salida.WriteLine();
    }
}
