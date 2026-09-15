# Plataforma de proyección y partituras para iglesias

Sistema para el servicio dominical de una iglesia:

- **Proyecta** la letra de los cantos en una pantalla extendida o un televisor.
- **Muestra versículos** bíblicos.
- **Entrega partituras en vivo** a los músicos: la app Symphony se conecta a la
  transmisión y cada quien recibe la partitura del canto que se está entonando
  en ese momento, en su instrumento.

Todo el servicio funciona **sin internet**: el templo corre su propio nodo en la
red local.

## Por dónde empezar

**Si acabas de llegar —persona o asistente— lee en este orden:**

1. [`specs/constitution.md`](specs/constitution.md) — los 9 principios que no se
   negocian. Nada se propone sin haberlo leído.
2. [`docs/arquitectura/estado-actual.md`](docs/arquitectura/estado-actual.md) —
   cómo está el sistema hoy, verificado en el código.
3. [`specs/README.md`](specs/README.md) — la tabla de módulos y **cuál toca
   ahora**. La línea **Siguiente:** dice exactamente dónde vamos.
4. La carpeta de ese módulo: su `tasks.md` es la lista de trabajo pendiente.

| Si quieres… | Lee |
|---|---|
| Entender el proyecto y sus reglas | [`specs/constitution.md`](specs/constitution.md) |
| Saber cómo está el sistema hoy | [`docs/arquitectura/estado-actual.md`](docs/arquitectura/estado-actual.md) |
| **Saber qué toca hacer ahora** | [`specs/README.md`](specs/README.md) → módulo activo → `tasks.md` |
| Entender por qué algo se decidió así | [`docs/adr/`](docs/adr/) |

## Dónde está la documentación

Dos carpetas, separadas por **ciclo de vida**: `specs/` caduca cuando su módulo
termina; `docs/` está siempre vigente.

### `specs/` — el trabajo, módulo por módulo

| Ruta | Qué contiene |
|---|---|
| [`specs/constitution.md`](specs/constitution.md) | Los 9 principios innegociables. Se lee antes que nada |
| [`specs/README.md`](specs/README.md) | Tabla de los 10 módulos, su estado y **cuál sigue** |
| `specs/NNN-modulo/` | Una carpeta por módulo, con cuatro archivos |

Dentro de cada módulo, siempre los mismos cuatro archivos y siempre en este
orden ([convención de Spec Kit](https://github.com/github/spec-kit)):

| Archivo | Contiene | Regla |
|---|---|---|
| `README.md` | Resumen del módulo y en qué punto va | |
| `spec.md` | El **qué** y el **porqué**: requisitos numerados `R1`, `R2`… Sin implementación | No se escribe código sin este archivo aprobado |
| `plan.md` | El **cómo**: forma del código, decisiones, estrategia de verificación | Sus decisiones de arquitectura van a un ADR antes de implementarse |
| `tasks.md` | **La lista de trabajo**: tareas atómicas en casillas `T1.1`, `T1.2`… | Se hace una tarea a la vez; una tarea no se cierra sin su prueba |

> **¿Qué toca hacer?** Abre el `tasks.md` del módulo activo y busca la primera
> casilla sin marcar. Eso es lo que sigue. No hay otra lista en ningún lado.

### `docs/` — lo transversal, siempre vigente

| Ruta | Qué contiene | Cuándo se actualiza |
|---|---|---|
| [`docs/adr/`](docs/adr/) | Una decisión de arquitectura por archivo, numeradas, con su porqué y su **costo aceptado** | Una vez, al tomarla. **Un ADR no se reescribe**: si la decisión cambia, se escribe uno nuevo |
| [`docs/arquitectura/`](docs/arquitectura/) | Cómo funciona el sistema. Hoy, `estado-actual.md` | Al cerrar cada módulo |
| [`docs/operacion/`](docs/operacion/) | Instalación, inventario de iglesias y soporte | Continuamente |

## Cómo se trabaja

- **Un módulo a la vez**, en el orden de `specs/README.md`.
- Dentro del módulo: `spec.md` → `plan.md` → `tasks.md` → implementar.
- **Una tarea a la vez.** Se hace, se marca su casilla, se confirma en git, y se
  espera revisión antes de seguir.
- Ninguna tarea que añade comportamiento se cierra sin su prueba (constitución,
  punto 4).
- Toda decisión de arquitectura se registra en un ADR **antes** de
  implementarse (constitución, punto 6).
- Al cerrar un módulo se actualiza `docs/arquitectura/`, que es lo que queda
  vigente cuando el spec ya caducó.

## Estructura del código

Las carpetas se organizan por **ciclo de vida**, no por tecnología:

| Carpeta | Qué contiene |
|---|---|
| `apps/` | Lo que se mantiene y evoluciona |
| `services/` | La nube |
| `legacy/` | Lo que corre hoy en las iglesias y será reemplazado. Referencia viva |
| `frozen/` | Congelado, se retoma a futuro |
| `_graveyard/` | Muerto, se elimina más adelante |

### Componentes

| Ruta | Qué es | Tecnología |
|---|---|---|
| [`apps/node-server`](apps/node-server/) | Servidor del templo | C# · por construir |
| [`apps/web-panel`](apps/web-panel/) | Panel, proyección, Biblia y teleprompter | Vue 2 · **será retirado** ([ADR 0013](docs/adr/0013-app-de-escritorio-en-vez-de-panel-web.md)) |
| [`apps/mobile`](apps/mobile/) | App Symphony de los músicos | Flutter |
| [`apps/desktop-node`](apps/desktop-node/) | Ventana de proyección en el segundo monitor | C# WPF · **será retirado**, se funde con el panel en **Symphony Master** ([ADR 0013](docs/adr/0013-app-de-escritorio-en-vez-de-panel-web.md)) |
| [`apps/stream-agent`](apps/stream-agent/) | Atajos para OBS/vMix | Node · **será retirado**: el nodo habla con OBS por su protocolo ([ADR 0014](docs/adr/0014-obs-por-websocket.md)) |
| [`services/cloud-api`](services/cloud-api/) | Identidad, licencias y catálogo maestro | C# · por construir |

## Estado

En migración a una plataforma multi-iglesia. El trabajo va por módulos, uno a la
vez; el avance se lee en [`specs/README.md`](specs/README.md).

**Nada de lo que será reemplazado se parchea**: se retira entero cuando el
sistema nuevo lo sustituya. Aplica a `legacy/`
([ADR 0009](docs/adr/0009-no-se-parchea-el-legado.md)), a `web-panel` y
`desktop-node` ([ADR 0013](docs/adr/0013-app-de-escritorio-en-vez-de-panel-web.md))
y a `stream-agent` ([ADR 0014](docs/adr/0014-obs-por-websocket.md)). Sus fallas
están registradas como restricciones sobre lo nuevo, no como tareas pendientes.
