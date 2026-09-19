# 003-panel-saas — herramientas de diseño (T0.3)

Comprobado antes de empezar la fase 0, para no descargar nada a mitad de la
fase 4.

## Qué hay

| Para | Herramienta | Estado |
|---|---|---|
| Wireframes (T0.5) y prototipos (T0.6) | Artifact **Design** — canvas con artboards | disponible |
| Reglas de UX y tokens (T0.7, `docs/diseno/`) | Artifact **Design System** | disponible; **ninguno creado todavía** |
| Apoyo al escribir prototipos | skills `artifact-design`, `artifact-diagramming`, `artifact-capabilities`, `dataviz` | disponibles |
| Blazor Server (fase 3) | — | **no hay skill ni plantilla.** Se escribe a mano |

El panel estrena el sistema de diseño del proyecto, igual que estrena la
interfaz y las traducciones. Lo que salga de aquí lo heredan
[007](../007-app-movil/) y [010](../010-app-de-escritorio/).

## Cómo se trabaja el diseño

Claude Design no se ejecuta desde esta sesión. El reparto es:

1. Claude entrega el **prompt** para Claude Design, pantalla por pantalla o
   flujo por flujo, y avisa al llegar a ese punto.
2. El propietario lo ejecuta en Claude Design y **aprueba** el resultado
   (spec R6: ninguna pantalla se implementa sin prototipo aprobado).
3. El propietario deposita el prototipo aprobado en el repositorio.
4. Solo entonces se implementa esa pantalla.

Los prototipos aprobados se depositan en
[`docs/diseno/prototipos/`](../../docs/diseno/prototipos/), junto a las reglas
de UX: son documentación vigente que heredan 007 y 010, no material de este
módulo que caduca con el spec.
