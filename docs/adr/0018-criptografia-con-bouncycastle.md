# ADR 0018 — La criptografía la pone BouncyCastle, en código administrado

**Estado:** aceptada · **Fecha:** 2026-09-17

## Contexto

[ADR 0016](0016-sesion-firmada-verificable-sin-internet.md) decidió **qué**
criptografía usa el sistema: firma Ed25519 para las sesiones y Argon2id para las
contraseñas. Faltaba decidir **con qué** se implementa, que es lo que la fase 4
de [002](../../specs/002-identidad-de-iglesia/tasks.md) necesita para existir.

.NET 10 no trae ninguna de las dos. Se comprobó en el propio SDK del proyecto,
no se supuso: `System.Security.Cryptography` no expone Ed25519 —solo ECDSA sobre
curvas NIST— y tampoco Argon2. Así que hay que traer una biblioteca.

Las opciones reales eran dos:

- **BouncyCastle**, que cubre Ed25519 y Argon2id, en código 100% administrado.
- **NSec** (una envoltura de libsodium) para la firma, más **Konscious** o
  **Isopoh** para Argon2id.

## Decisión

**BouncyCastle.Cryptography**, una sola dependencia para las dos cosas.

## Razones

- **Dónde corre esto decide más que el rendimiento.** El nodo se instala a mano
  en la PC de un templo, sin personal técnico, y en una de las dos iglesias es la
  misma PC que proyecta. Una biblioteca administrada viaja con el ejecutable y no
  depende de que cargue el binario nativo correcto para ese sistema operativo.
  Un fallo así no aparece al compilar: aparece al arrancar, y el peor momento
  posible para que aparezca es un domingo por la mañana.
- **Una dependencia en lugar de dos**, y una menos que vigilar por avisos de
  seguridad. El propietario es el único que mantiene esto.
- **El rendimiento no es la restricción aquí.** Se firma un token por inicio de
  sesión, no miles por segundo. Argon2id es lento *a propósito* —ese es su
  trabajo— y sus parámetros se calibran contra el hardware más débil de las
  iglesias (002 T4.2), que es lo que fija el costo real, no la biblioteca.
- **Es la implementación de referencia que más tiempo lleva auditada** en el
  mundo .NET, y ya la usan por debajo varias bibliotecas del ecosistema.

## Costo aceptado

- **Es más lenta que libsodium**, que está escrito en C y usa instrucciones del
  procesador. En este sistema esa diferencia no se nota, pero si algún día se
  notara, cambiarla obliga a tocar el código de firma. Se contiene dejando la
  firma detrás de una interfaz propia, no esparciendo llamadas a BouncyCastle
  por el dominio.
- **Su API es más áspera** que la de .NET: trabaja con tipos propios y con más
  pasos. Se paga una vez, dentro de la biblioteca de sesiones.
- **Es una dependencia grande** para lo poco que se le usa: trae mucho más de lo
  que este sistema necesita.

## Consecuencia importante

**La firma vive detrás de una interfaz del proyecto**, y el resto del código no
sabe qué biblioteca hay debajo. Es lo que hace que este ADR se pueda reemplazar
por otro sin reescribir el dominio, tal como pide la regla de que un ADR no se
reescribe: si la decisión cambia, se escribe uno nuevo.
