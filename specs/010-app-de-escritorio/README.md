# 010-app-de-escritorio — Symphony Master

**Estado:** ⬜ sin especificar · **Depende de:** 004-estado-en-vivo, 005-tiempo-real

## Objetivo

**Symphony Master** es la app que se usa el domingo: control del servicio y
proyección en la pantalla extendida, en una sola pieza multiplataforma
construida con Tauri. El nombre dice lo que hace: dirige a todas las Symphony
conectadas
([ADR 0013](../../docs/adr/0013-app-de-escritorio-en-vez-de-panel-web.md)).

Reemplaza a dos componentes a la vez:

- [`apps/web-panel`](../../apps/web-panel/) — el panel Vue, al que ya nadie se
  conecta desde la red.
- [`apps/desktop-node`](../../apps/desktop-node/) — la cáscara WPF que solo
  existía para abrir ese panel en el segundo monitor.

## No es el único control

El control del servicio también se puede hacer desde un teléfono o tablet, con
el **rol de operador de la app Symphony** → [007-app-movil](../007-app-movil/).
Esta app maneja la proyección en la pantalla extendida, que es lo que solo puede
hacer el equipo conectado al monitor.

## Qué tiene que recoger antes de que se retiren

El panel Vue es la referencia funcional. Al menos: control de la lista de
alabanza, proyección de letras, Biblia, teleprompter y control de OBS.
Inventariarlo es parte del `spec.md`.

## Siguiente paso

Escribir `spec.md`. No empieza hasta que 004 y 005 estén cerrados: sin estado en
vivo persistido ni protocolo nuevo, no hay con qué hablar.

Antes de empezar, leer la [constitución](../constitution.md) y el
[estado actual](../../docs/arquitectura/estado-actual.md).
