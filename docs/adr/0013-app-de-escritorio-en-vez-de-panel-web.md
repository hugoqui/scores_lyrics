# ADR 0013 — El panel web se retira; el control vive en una app de escritorio

**Estado:** aceptada · **Fecha:** 2026-09-15

## Contexto

`apps/web-panel` (Vue 2.6) nació como panel de control porque en ese momento los
músicos se conectaban a él desde el navegador. Eso ya no ocurre: la app móvil
Symphony los atiende.

Verificado con el propietario: **hoy nadie se conecta al panel web**. El control
se opera siempre desde la misma PC que proyecta.

Además, Vue 2.6 está fuera de soporte, y `apps/desktop-node` (C# WPF) solo existe
para abrir ese panel en un WebView2 y colocar una ventana en el segundo monitor.
WPF no corre en macOS, y no hay certeza de que todos los clientes futuros usen
Windows.

## Decisión

El control y la proyección pasan a **Symphony Master**, una sola app de
escritorio multiplataforma construida con Tauri. El nombre la enlaza con la app
móvil que ya usan los músicos: dirige a todas las Symphony conectadas.

**El control remoto no desaparece: se muda a la app móvil.** Symphony gana un
**rol de operador** que permite manejar el servicio desde un teléfono o tablet.
La app de escritorio no es el único control posible.

Se retiran, cuando esa app la reemplace:

- `apps/web-panel` — el panel Vue completo.
- `apps/desktop-node` — la cáscara WPF.

**Lo que sí sigue siendo web:** la página de texto que OBS consume como *browser
source*. La sirve el nodo como una página estática suelta, no como una
aplicación Vue.

## Razones

- **El panel web ya no tiene usuarios.** Su única razón de ser —que los músicos
  se conectaran— desapareció con la app móvil.
- **Menos piezas.** Dos proyectos (Vue + WPF) se vuelven uno.
- **macOS.** WPF ata la proyección a Windows. Tauri corre en los dos.
- **Tauri usa el motor del sistema**: WebView2 en Windows, que es exactamente lo
  que ya se usa hoy; WKWebView en macOS. No es un salto tecnológico, es la misma
  idea sin la cáscara WPF.
- **La pantalla extendida se maneja nativamente**, en vez de depender de que el
  navegador coopere.

## Costo aceptado

- **El control desde otro dispositivo exige instalar Symphony.** Antes bastaba
  con abrir una URL en el navegador; ahora el operador necesita la app. Se
  acepta porque el operador es una persona conocida de la iglesia, no una
  visita, y porque a cambio ese control queda autenticado y con rol, en vez de
  abierto a cualquiera en la red.
- **Hay que probar en dos motores de render**: WebView2 y WKWebView no pintan
  idéntico.
- **Entra una tecnología más al proyecto** (Rust, por debajo de Tauri), aunque el
  desarrollo del día a día sea web.
- El trabajo hecho en el panel Vue se tira. Su comportamiento —Biblia,
  teleprompter, proyección— es la referencia funcional de lo que la app nueva
  debe hacer, y hay que recogerlo antes de retirarlo.

## Notas de implementación

- `apps/web-panel` y `apps/desktop-node` siguen corriendo en las iglesias hasta
  que exista el reemplazo. No se parchean mientras tanto, igual que el resto de
  lo que será reemplazado ([ADR 0009](0009-no-se-parchea-el-legado.md)).
- [ADR 0003](0003-backend-en-csharp.md) decía que el nodo serviría el panel Vue
  como archivos estáticos. Eso queda sustituido: el nodo sigue sirviendo
  archivos estáticos, pero solo la página para OBS.
- La app de escritorio se especifica en
  [010-app-de-escritorio](../../specs/010-app-de-escritorio/).
- El rol de operador en Symphony se especifica en
  [007-app-movil](../../specs/007-app-movil/), sobre el modelo de roles de
  [002-identidad-de-iglesia](../../specs/002-identidad-de-iglesia/).
