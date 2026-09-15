# ADR 0001 — Un solo repositorio

**Estado:** aceptada · **Fecha:** 2026-09-14

## Contexto

El producto vivía en `scores_lyrics` (servidor del templo, panel, proyección) y
`symphony` (app de los músicos, backend de nube). La app habla con ambos a la
vez, y el contrato que los une —los eventos de socket— estaba partido entre los
dos repositorios y sin documentar en ninguno.

## Decisión

Un solo repositorio, `scores_lyrics`, con `symphony` importado mediante
`git subtree` para preservar el historial completo de ambos.

Las carpetas se organizan por **ciclo de vida**, no por tecnología:

- `apps/` — lo que se mantiene y evoluciona.
- `services/` — la nube, por construir.
- `legacy/` — lo que corre hoy en las iglesias y será reemplazado. Referencia viva.
- `frozen/` — congelado, se retoma a futuro.
- `_graveyard/` — muerto, se elimina más adelante.

## Razones

Un cambio en el protocolo en vivo toca el servidor, el panel y la app. En dos
repositorios eso son dos cambios coordinados que se desincronizan; en uno, es un
solo cambio revisable de una vez.

## Costo aceptado

El repositorio es más grande y mezcla cuatro tecnologías. A cambio, deja de
existir la clase de fallo "el servidor y la app no se pusieron de acuerdo".

## Alternativas descartadas

- **Repositorio nuevo desde cero:** el historial nuevo nacería sin las
  credenciales filtradas, pero se perderían años de historia de ambos proyectos
  y las credenciales hay que rotarlas igual. Ver ADR 0007 y el módulo 000.
- **Dejarlos separados con un contrato versionado aparte:** menos disrupción
  ahora, pero no resuelve la causa del problema.
