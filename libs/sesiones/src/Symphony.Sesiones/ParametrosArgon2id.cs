namespace Symphony.Sesiones;

/// <summary>
/// El costo que se le impone a quien intente adivinar una contraseña. Va
/// guardado <b>junto a cada hash</b>, no en el código: así se pueden subir los
/// parámetros más adelante sin invalidar a nadie, porque cada contraseña
/// recuerda con qué costo se calculó la suya ([ADR 0016]).
/// </summary>
/// <param name="MemoriaEnKib">Memoria de trabajo, en KiB. Es el parámetro que
/// más encarece el ataque con hardware dedicado.</param>
/// <param name="Iteraciones">Pasadas sobre esa memoria.</param>
/// <param name="Paralelismo">Hilos.</param>
public sealed record ParametrosArgon2id(int MemoriaEnKib, int Iteraciones, int Paralelismo)
{
    /// <summary>
    /// Calibrado contra el hardware más débil de las iglesias (002 T4.2), que
    /// es la PC que además proyecta el culto. El criterio es ese, no el
    /// servidor de la nube: el nodo autentica sin internet (constitución,
    /// punto 2), así que la misma contraseña tiene que poder verificarse ahí.
    ///
    /// 64 MiB y 3 pasadas es el perfil de "segunda opción" que recomienda el
    /// RFC 9106 para entornos con memoria limitada. El criterio de aceptación
    /// es que verificar una contraseña tarde entre 0,25 y 1 segundo en esa PC:
    /// por debajo sale barato atacarla, por encima el músico nota la espera
    /// mientras empieza el servicio.
    ///
    /// Subirlos después no invalida ninguna contraseña existente: los hash
    /// viejos siguen verificándose con los suyos, y se recalculan cuando su
    /// dueño vuelve a entrar.
    /// </summary>
    public static readonly ParametrosArgon2id PorDefecto = new(MemoriaEnKib: 65536, Iteraciones: 3, Paralelismo: 1);
}
