# node-server — el servidor del templo

> **Por construir.** C# / ASP.NET Core. Ver [ADR 0003](../../docs/adr/0003-backend-en-csharp.md).

Reemplazará a [`legacy/back-scores`](../../legacy/back-scores/), que es la
referencia viva mientras tanto: sigue corriendo hoy en las iglesias.

## Qué será

Un **ejecutable único autocontenido**, instalado como servicio de Windows, que
en el mismo proceso:

- expone la API del templo,
- mantiene la conexión en tiempo real con el panel y con los teléfonos,
- guarda su estado en SQLite embebido ([ADR 0004](../../docs/adr/0004-sqlite-en-el-nodo.md)),
- y **sirve el panel Vue compilado como archivos estáticos**, de modo que
  [`apps/desktop-node`](../desktop-node/) solo tiene que apuntar su WebView2 a
  `localhost`.

Sin runtime que instalar, sin servicio de base de datos aparte, sin puerto de
base de datos abierto.

## Principio rector

Funciona sin internet durante todo el servicio dominical
([constitución, punto 2](../../specs/constitution.md)).
