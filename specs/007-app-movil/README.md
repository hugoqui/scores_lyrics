# 007-app-movil — App móvil

**Estado:** ⬜ sin especificar · **Depende de:** 006 · el rol de operador además de 005-tiempo-real

## Objetivo

Reescribir la capa de datos de Symphony conservando todas sus funcionalidades, y migrar el caché local sin que ningún músico vuelva a descargar lo que ya tiene ni pierda sus anotaciones.

Además, Symphony gana un **rol de operador**: controlar el servicio desde un
teléfono o tablet, que es lo que hoy se hace desde el panel web y que este
reemplaza ([ADR 0013](../../docs/adr/0013-app-de-escritorio-en-vez-de-panel-web.md)).
El rol lo decide el servidor, nunca el cliente (000-seguridad, R6).

## Siguiente paso

Escribir `spec.md`: el **qué** y el **porqué**, sin entrar en implementación.
Después `plan.md` y `tasks.md`.

Antes de empezar, leer la [constitución](../constitution.md) y el
[estado actual](../../docs/arquitectura/estado-actual.md).
