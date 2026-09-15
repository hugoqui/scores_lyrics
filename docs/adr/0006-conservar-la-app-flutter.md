# ADR 0006 — Conservar la app Flutter y reescribir su capa de datos

**Estado:** aceptada · **Fecha:** 2026-09-14

## Contexto

La app debe conservar sus funcionalidades actuales: descargar partituras, crear
listas, compartirlas por QR, escuchar audios alternando melodía y arreglo, y
conectarse a la transmisión en vivo. La pregunta era si conservarla o
reescribirla.

## Decisión

Se conserva el proyecto. Se reescribe **solo su capa de datos**.

## Razones

43 archivos, 5.791 líneas. El desglose decide:

| Área | Líneas | Destino |
|---|---|---|
| `core` + `data` (red, caché, autenticación, instrumentos fijos) | ~900 | **Se reescribe** |
| Visor de partituras con zoom y lienzo de anotaciones | 1.517 | Se conserva |
| Listas | 814 | Se conserva |
| Modo práctica | 632 | Se conserva |
| Inicio y transmisión en vivo | 1.023 | Se conserva |
| Descargas | 549 | Se conserva |

Las ~900 líneas a reescribir son exactamente la capa que había que cambiar de
todos modos. Las ~4.800 restantes son las funcionalidades a conservar, y son la
parte cara.

Además, **la app ya es una reescritura reciente** desde NativeScript. Rehacerla
sería la segunda en año y medio, y el dolor no está en la interfaz.

## Consecuencias

- El identificador `org.nativescript.symphony` y las llaves de firma **no se
  tocan**: la publicación es transparente y los músicos conservan sus descargas
  y anotaciones.
- El nombre del paquete Dart sigue siendo `new_symphony` aunque la carpeta ahora
  sea `apps/mobile`. Renombrarlo tocaría 43 archivos sin beneficio; queda como
  deuda menor.
- La interfaz se puede pulir sobre esta base.
- Compartir listas por WhatsApp es un añadido pequeño: el esquema JSON del QR ya
  existe, falta la hoja de compartir del sistema.
