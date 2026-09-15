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

| Si quieres… | Lee |
|---|---|
| Entender el proyecto y sus reglas | [`specs/constitution.md`](specs/constitution.md) |
| Saber cómo está el sistema hoy | [`docs/arquitectura/estado-actual.md`](docs/arquitectura/estado-actual.md) |
| Saber por dónde vamos | [`specs/README.md`](specs/README.md) |
| Entender por qué algo se decidió así | [`docs/adr/`](docs/adr/) |

## Estructura

Las carpetas se organizan por **ciclo de vida**, no por tecnología:

| Carpeta | Qué contiene |
|---|---|
| `specs/` | Especificaciones por módulo: el qué, el cómo y las tareas |
| `docs/` | Documentación transversal siempre vigente |
| `apps/` | Lo que se mantiene y evoluciona |
| `services/` | La nube |
| `legacy/` | Lo que corre hoy en las iglesias y será reemplazado. Referencia viva |
| `frozen/` | Congelado, se retoma a futuro |
| `_graveyard/` | Muerto, se elimina más adelante |

### Componentes

| Ruta | Qué es | Tecnología |
|---|---|---|
| [`apps/node-server`](apps/node-server/) | Servidor del templo | C# · por construir |
| [`apps/web-panel`](apps/web-panel/) | Panel, proyección, Biblia y teleprompter | Vue 2 |
| [`apps/mobile`](apps/mobile/) | App Symphony de los músicos | Flutter |
| [`apps/desktop-node`](apps/desktop-node/) | Ventana de proyección en el segundo monitor | C# WPF |
| [`apps/stream-agent`](apps/stream-agent/) | Atajos para OBS/vMix | Node |
| [`services/cloud-api`](services/cloud-api/) | Identidad, licencias y catálogo maestro | C# · por construir |

## Estado

En migración a una plataforma multi-iglesia. El trabajo va por módulos, uno a la
vez; el avance se lee en [`specs/README.md`](specs/README.md).
