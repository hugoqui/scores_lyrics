# Especificaciones

Convención de [Spec Kit](https://github.com/github/spec-kit), adoptada sin
instalar la herramienta. Cada módulo se trabaja en cuatro fases:

| Fase | Archivo | Contenido | Modelo |
|---|---|---|---|
| specify | `spec.md` | El **qué** y el **porqué**: requisitos y comportamiento. Sin implementación. | Opus |
| plan | `plan.md` | El **cómo**: arquitectura, contratos, estrategia de verificación. | Opus |
| tasks | `tasks.md` | Tareas atómicas, en casillas. | Opus |
| implement | — | El código, más la actualización de `docs/`. | según la fase |

**Escribir specs, planes y ADR es trabajo de Opus**: ahí se decide el modelo de
datos, el aislamiento entre iglesias y lo que después nadie vuelve a revisar.
Implementar tareas ya especificadas suele ser trabajo de Sonnet; cada fase de
`tasks.md` dice cuál conviene, y las excepciones están marcadas ahí.

Reglas:

- No se escribe código de un módulo sin su `spec.md` aprobado.
- Antes de empezar, comparar el modelo en uso con el sugerido. Si no coincide,
  avisar y esperar; el cambio de modelo lo hace el propietario.
- Un módulo no se cierra sin pruebas unitarias (constitución, punto 4).
- Al cerrar un módulo se actualiza `docs/arquitectura/`, que es lo que queda
  vigente cuando el spec ya caducó.

Antes de empezar cualquier módulo, leer [`constitution.md`](constitution.md).

## Estado

Leyenda: ⬜ sin especificar · 📝 especificado · 🔨 en implementación · ✅ cerrado

| # | Módulo | Estado | Objetivo en una línea | Modelo |
|---|---|---|---|---|
| 000 | [seguridad](000-seguridad/) | 📝 | Fijar las reglas de seguridad que cumple el sistema nuevo. Sin código propio: se implementan en los módulos que le siguen. | Opus |
| 001 | [andamiaje-y-tests](001-andamiaje-y-tests/) | 📝 | Migraciones versionadas, armazón de pruebas e integración continua, para que lo demás sea reversible. | mixto |
| 002 | [identidad-de-iglesia](002-identidad-de-iglesia/) | ⬜ | Crear la entidad iglesia y propagarla a datos, usuarios y permisos. | **Opus** |
| 003 | [panel-saas](003-panel-saas/) | ⬜ | Alta de iglesias, licencias, administrador por iglesia e invitaciones por QR. | mixto |
| 004 | [estado-en-vivo](004-estado-en-vivo/) | ⬜ | Persistir lista de alabanza y canto actual por iglesia; matar `songid.txt` y el array en memoria. | mixto |
| 005 | [tiempo-real](005-tiempo-real/) | ⬜ | Protocolo nuevo con salas por iglesia y autorización por rol en los eventos de control. | **Opus** |
| 006 | [catalogo-y-partituras](006-catalogo-y-partituras/) | ⬜ | Modelo melodía/arreglo, deduplicación por hash y acceso autenticado a los archivos. | **Opus** |
| 007 | [app-movil](007-app-movil/) | ⬜ | Reescribir la capa de datos de Symphony conservando funcionalidades, descargas y anotaciones, y añadir el rol de operador. | mixto |
| 008 | [sincronizacion-y-licencias](008-sincronizacion-y-licencias/) | ⬜ | Sincronización nube↔nodo y licencia firmada verificable sin internet. | **Opus** |
| 009 | [nodo-empaquetado](009-nodo-empaquetado/) | ⬜ | Instalador único del nodo, actualizaciones con reversión automática y respaldo. | mixto |
| 010 | [app-de-escritorio](010-app-de-escritorio/) | ⬜ | **Symphony Master**: proyección en pantalla extendida y control desde el equipo del templo; reemplaza al panel Vue y a la cáscara WPF. | mixto |

**Siguiente:** `001-andamiaje-y-tests` — fase 1 (esqueleto de la solución)
terminada. Toca la **fase 2** de su `tasks.md`. El módulo 000 ya fijó sus reglas y no tiene código propio; 001 es
el primero que construye.

**Opus** en 002, 005, 006 y 008: identidad y aislamiento entre iglesias,
autorización en tiempo real, deduplicación de partituras por hash y validación
de sesión sin internet. Son las cuatro donde un error se paga caro y tarde.
**Mixto** quiere decir Opus para `spec.md`, `plan.md` y los ADR, Sonnet para
implementar.

## Orden y dependencias

```
000 seguridad ──┐
                ├──> 002 identidad ──> 003 panel SaaS
001 andamiaje ──┘         │
                          ├──> 004 estado en vivo ──> 005 tiempo real
                          │
                          └──> 006 catalogo ──> 007 app movil
                                    │
                                    └──> 008 sincronizacion ──> 009 nodo empaquetado

005 tiempo real ──> 010 app de escritorio
```

010 reemplaza al panel Vue y a la cáscara WPF
([ADR 0013](../docs/adr/0013-app-de-escritorio-en-vez-de-panel-web.md)); va al
final porque necesita el estado en vivo y el protocolo nuevo debajo.

000 y 001 no dependen de nada y pueden ir en paralelo. 003 es el primer
entregable visible del negocio y por eso va pronto, pero necesita 002 antes:
un panel que administra iglesias requiere que la iglesia exista.
