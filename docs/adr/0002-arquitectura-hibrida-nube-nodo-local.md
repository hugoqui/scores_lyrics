# ADR 0002 — Nube de control con nodo local por iglesia

**Estado:** aceptada · **Fecha:** 2026-09-14

## Contexto

El servicio dominical no puede depender de internet: una caída de conexión no
puede tumbar la transmisión ni dejar a los músicos sin partituras. Hoy ya existe
un servidor dentro de cada templo, pero sin identidad propia y, en varias
instalaciones, leyendo la base de datos por internet.

## Decisión

Arquitectura híbrida con autoridad repartida por dominio:

- **La nube manda** en identidad, licencias, catálogo maestro y biblioteca
  compartida. El nodo los trata como solo lectura.
- **El nodo local manda** en todo lo que ocurre durante el servicio: lista de
  alabanza y canto actual. Ese estado nunca baja de la nube.

Un nodo sirve a una sola iglesia. El aislamiento entre iglesias es físico
además de lógico.

## Razones

La asimetría es lo que hace que la sincronización sea simple: casi nada es
bidireccional, y lo que lo es (los cantos propios de la iglesia) tiene un único
editor en la práctica.

Si la nube tuviera opinión sobre qué se está proyectando, un hipo de red
cambiaría la pantalla en medio del culto.

## Costo aceptado

Hay que construir y mantener replicación, y cada templo necesita un equipo
encendido. A cambio, el culto no depende de la conexión.
