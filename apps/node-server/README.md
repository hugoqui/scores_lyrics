# node-server — el servidor del templo

> **Por construir.** C# / ASP.NET Core. Ver [ADR 0003](../../docs/adr/0003-backend-en-csharp.md).

Reemplazará a [`legacy/back-scores`](../../legacy/back-scores/), que es la
referencia viva mientras tanto: sigue corriendo hoy en las iglesias.

## Qué será

Un **ejecutable único autocontenido**, instalado como servicio del sistema, que
en el mismo proceso:

- expone la API del templo,
- mantiene la conexión en tiempo real con Symphony Master y con los teléfonos,
- guarda su estado en SQLite embebido ([ADR 0004](../../docs/adr/0004-sqlite-en-el-nodo.md)),
- **controla OBS por su protocolo oficial**, sin simular teclado
  ([ADR 0014](../../docs/adr/0014-obs-por-websocket.md)),
- y **sirve como archivo estático la página de texto que OBS consume** como
  *browser source*. Ya no sirve el panel Vue: ese se retira
  ([ADR 0013](../../docs/adr/0013-app-de-escritorio-en-vez-de-panel-web.md)).

Sin runtime que instalar, sin servicio de base de datos aparte, sin puerto de
base de datos abierto.

> **Abierto:** si alguna iglesia proyecta desde un Mac, el nodo corre ahí
> también. C# no tiene problema, pero "servicio de Windows" sí: la forma de
> instalarlo en cada sistema se decide en
> [009-nodo-empaquetado](../../specs/009-nodo-empaquetado/).

## Principio rector

Funciona sin internet durante todo el servicio dominical
([constitución, punto 2](../../specs/constitution.md)).
