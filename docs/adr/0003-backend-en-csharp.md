# ADR 0003 — Backend en C# / ASP.NET Core

**Estado:** aceptada · **Fecha:** 2026-09-14

## Contexto

El servidor actual es Node + Express (15 archivos). Había que decidir si
evolucionarlo, reescribirlo en TypeScript o cambiar de plataforma.

El riesgo número uno del proyecto es operativo, no técnico: **un nodo que no
arranca un domingo por la mañana en una iglesia sin personal técnico.**

## Decisión

C# / ASP.NET Core para el servidor del templo (`apps/node-server`) y la API de
nube (`services/cloud-api`).

## Razones

- **Un ejecutable único autocontenido**, instalable como servicio de Windows,
  sin instalar runtime ni un servicio de base de datos aparte. Es lo mejor que
  le puede pasar a una PC de iglesia sin nadie técnico.
- Ese mismo ejecutable **sirve el panel Vue como archivos estáticos**, así que
  el WPF existente sigue funcionando apuntando su WebView2 a `localhost`. Se
  descarta la migración a Electron que se había considerado: menos trabajo y una
  pieza menos que mantener.
- **EF Core aporta migraciones de esquema versionadas**, que hoy no existen en
  ninguna forma.
- El backend actual son 15 archivos: no hay casi nada que perder al reescribir.
- Ya hay experiencia de C# en el proyecto (el WPF de `apps/desktop-node`).

## La reserva que se investigó y no se sostuvo

El argumento en contra era el cliente de tiempo real en Flutter. Los clientes de
SignalR para Dart están flojos: el más popular (`signalr_netcore`, 232 likes)
lleva un año sin actualizarse, y el único que se mantiene al día no tiene rodaje
real.

**Pero SignalR no hace falta.** El protocolo son alrededor de doce eventos
pequeños; con WebSockets planos y `web_socket_channel` —publicado por el propio
equipo de Dart, ~10 millones de descargas semanales— funciona igual contra
cualquier backend. La reserva desaparece.

## Costo aceptado

El panel sigue en Vue/JS, así que el proyecto lleva Dart, JavaScript, C# y SQL
en vez de Dart, TypeScript y SQL. Se acepta a cambio de la fiabilidad del nodo.

## Alternativa descartada

**TypeScript / Node.** Daba continuidad con el código actual y un solo lenguaje
entre servidor, panel y un envoltorio Electron. Pero el nodo local cargaría con
un runtime de Node y un empaquetado más frágil justo en el punto donde el
proyecto menos puede permitirse fallar.
