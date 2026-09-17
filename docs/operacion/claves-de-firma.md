# Claves de firma de sesiones

Cómo se generan y dónde va cada una ([ADR 0016](../adr/0016-sesion-firmada-verificable-sin-internet.md),
[ADR 0018](../adr/0018-criptografia-con-bouncycastle.md)).
**Ninguna clave privada entra al repositorio** (constitución, punto 7).

Hay **dos pares**, uno por emisor. Cada lado firma con el suyo y verifica al
otro con su mitad pública. Comprometer el equipo de un templo compromete esa
iglesia, no las demás: esa es la razón de que sean dos pares y no un secreto
compartido.

| Par | Lo genera | Privada vive en | Pública viaja a |
|---|---|---|---|
| De la nube | El VPS | `.env` del VPS | Todos los nodos |
| Del nodo | Cada nodo, en su instalación | `.env` de ese nodo | La nube |

## Generarlas

En el VPS:

```bash
cd services/cloud-api/src/Symphony.Cloud
dotnet run -- generar-claves
```

En el equipo del templo:

```bash
cd apps/node-server/src/Symphony.Node
dotnet run -- generar-claves
```

El comando **imprime** las dos líneas y no escribe ningún archivo: quien la
genera decide dónde va, y nada automatizado deja una clave privada en disco
dentro del repositorio.

## Dónde va cada línea

De la salida del comando de la nube:

- `SYMPHONY_CLOUD_CLAVE_PRIVADA=…` → al `.env` del VPS (`chmod 600`).
- `SYMPHONY_NODE_CLAVE_PUBLICA_NUBE=…` → al `.env` de **cada** nodo.

De la salida del comando de un nodo:

- `SYMPHONY_NODE_CLAVE_PRIVADA=…` → al `.env` de ese nodo.
- La pública → a la nube, junto al registro de ese nodo.

> El transporte automático de estas claves es del módulo
> [008](../../specs/008-sincronizacion-y-licencias/). Hoy se copian a mano, que
> es lo que corresponde con dos iglesias.

## Qué pasa si falta o está mal copiada

El proceso **no arranca** y dice cuál variable es. Se comprueba al arrancar y no
al usarla, para que el problema aparezca cuando se instala y no un domingo por
la mañana, cuando alguien intenta entrar.

## Si una clave se compromete

Se genera un par nuevo y se reemplaza. Las sesiones firmadas con la vieja dejan
de verificarse, así que todo el mundo vuelve a entrar; con una iglesia por nodo
eso es un inconveniente de una mañana, no una salida de servicio. La rotación
ordenada —con las dos claves válidas a la vez durante un tiempo— es del módulo
008, y por eso cada token lleva escrito el identificador de la clave que lo
firmó.
