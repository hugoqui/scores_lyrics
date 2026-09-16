# ADR 0016 — Sesión firmada, verificable sin internet, con dos emisores

**Estado:** aceptada · **Fecha:** 2026-09-15

## Contexto

El módulo [002-identidad-de-iglesia](../../specs/002-identidad-de-iglesia/spec.md)
(R7, R8) necesita que el servidor —no el cliente— decida quién es alguien, a
qué iglesia pertenece y qué puede hacer.

Las restricciones vienen de la constitución y de 000-seguridad:

- **El domingo el login no puede depender de internet** (constitución, punto 2).
  El nodo tiene que poder autenticar a un músico con la conexión caída.
- **La sesión no se valida contra el reloj del teléfono** (000-seguridad R8):
  hoy la ventana de 30 días se comprueba contra la fecha local, falseable
  atrasando el reloj.
- **A un músico expulsado hay que poder cortarle el acceso**, y la vía normal de
  revocación es el nodo del templo, no la nube.
- Hoy la contraseña se guarda en SHA1 sin sal en el servidor y **en claro en el
  teléfono** (`apps/mobile/lib/data/repositories/auth_repository.dart`), y el
  rol sale de `localStorage` del navegador.

La alternativa era una sesión opaca guardada en la base de la nube, consultada
en cada petición. Es más fácil de revocar, y es exactamente lo que no funciona
sin internet.

## Decisión

### Formato: un token firmado, con clave asimétrica

Una sesión es un **token firmado con criptografía de clave pública** (curva
Edwards de 25519 bits). Lleva quién es el usuario, su iglesia, sus roles, el
dispositivo, cuándo se emitió, cuándo caduca, quién lo emitió y con qué clave.

**Quien verifica solo necesita la clave pública.** Ese es el punto entero: el
nodo valida sin llamar a nadie.

### Dos emisores, un solo formato

- **La nube** emite sesiones para el panel y para el acceso por internet.
- **El nodo** emite sesiones para lo que pasa dentro del templo, y lo hace con
  su propia clave, **sin consultar a la nube**.

Cada uno tiene su par de claves. El nodo conoce la clave pública de la nube; la
nube conoce la del nodo. El transporte de esas claves pertenece a
[008-sincronizacion-y-licencias](../../specs/008-sincronizacion-y-licencias/);
aquí se fija que el nodo deba poder verificar y emitir sin conexión.

### Dos duraciones, con propósitos distintos

- **Token de acceso: corto** (del orden de una hora). Es el que viaja en cada
  petición. No se consulta en la base: se verifica su firma y ya.
- **Token de renovación: largo, atado a un dispositivo y revocable.** Vive
  guardado —solo su huella, nunca el token— del lado del servidor. Revocar un
  dispositivo es borrar esa fila, y el acceso se corta en cuanto caduca el token
  de acceso en curso.

La ventana de ~30 días de 000-seguridad R8 es la caducidad del token de
renovación: **el techo del peor caso**, no la duración normal de una sesión.

### El reloj

La caducidad la comprueba **quien verifica** —nodo o nube—, no el teléfono. La
app no concede acceso por su cuenta mirando su propia fecha, y recuerda la
última hora vista de un servidor para desconfiar de cualquier fecha local
anterior (000-seguridad R8).

### Contraseñas

Se guardan con **Argon2id**, con sal por usuario y parámetros versionados junto
al hash, para poder subirlos sin invalidar a nadie. Nunca SHA1, nunca en claro.
La app **no guarda la contraseña**: guarda el token de renovación, que es
revocable.

## Razones

- **La firma asimétrica es lo que permite verificar sin internet.** Con un
  secreto compartido, cada nodo tendría la llave con la que se firman las
  sesiones de todo el SaaS: comprometer un equipo dentro de un templo —al que
  tiene acceso físico cualquiera que esté en el edificio— permitiría
  falsificar sesiones de cualquier otra iglesia.
- **Que el nodo emita sus propias sesiones es la única forma de cumplir el punto
  2 de la constitución.** Si el login del domingo tuviera que pasar por la nube,
  un corte de internet deja a los músicos fuera en pleno culto.
- **Dos duraciones resuelven la tensión entre "sin internet" y "revocable".** El
  token corto hace barata la verificación; el largo es el que se revoca. Un solo
  token de 30 días sería irrevocable en la práctica.
- **Argon2id** es la recomendación vigente para contraseñas nuevas: resiste
  ataque con hardware dedicado, que es exactamente el escenario de una tabla de
  usuarios ya filtrada (ADR 0008).
- **El rol viaja firmado**, así que no hay nada que el cliente pueda declarar
  sobre sí mismo. Eso mata de raíz el `localStorage` que hoy permite
  autoproclamarse operador.

## Costo aceptado

- **Un token de acceso robado sigue siendo válido hasta que caduca**, porque no
  se consulta en la base. Es el precio de verificar sin internet. Se acota
  manteniéndolo corto; la revocación real actúa sobre la renovación.
- **Hay claves privadas que custodiar en cada nodo**, en equipos sin personal
  técnico. Si un nodo se compromete, se compromete esa iglesia —no las demás—, y
  su clave se puede revocar desde la nube.
- **Argon2id añade una dependencia** al proyecto, y consume memoria a propósito:
  hay que calibrar sus parámetros para el hardware más débil de las iglesias,
  que en una de ellas es la misma PC que proyecta.
- **Dos emisores es más maquinaria** que uno: dos pares de claves, dos caminos
  de emisión y la rotación de claves que habrá que resolver en 008.
