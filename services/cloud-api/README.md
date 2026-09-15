# cloud-api — la nube

> **Por construir.** C# / ASP.NET Core. Ver [ADR 0003](../../docs/adr/0003-backend-en-csharp.md).

Absorberá a [`legacy/belen-backend`](../../legacy/belen-backend/), que hoy solo
resuelve login y catálogo de cantos.

## Qué será

La autoridad de todo lo que **no** ocurre durante el culto:

- identidad de personas e iglesias,
- licencias del SaaS,
- catálogo maestro y biblioteca compartida,
- almacenamiento de partituras,
- registro de nodos y sus actualizaciones.

## Lo que NO hace

**No tiene opinión sobre qué se está proyectando.** El estado del servicio en
vivo pertenece al nodo local y nunca baja de la nube: si la nube pudiera
cambiarlo, un hipo de red cambiaría la pantalla en mitad del culto
([ADR 0002](../../docs/adr/0002-arquitectura-hibrida-nube-nodo-local.md)).
