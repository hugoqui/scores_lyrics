# Especificaciones

Convención de [Spec Kit](https://github.com/github/spec-kit), adoptada sin
instalar la herramienta. Cada módulo se trabaja en cuatro fases:

| Fase | Archivo | Contenido |
|---|---|---|
| specify | `spec.md` | El **qué** y el **porqué**: requisitos y comportamiento. Sin implementación. |
| plan | `plan.md` | El **cómo**: arquitectura, contratos, estrategia de verificación. |
| tasks | `tasks.md` | Tareas atómicas, en casillas. |
| implement | — | El código, más la actualización de `docs/`. |

Reglas:

- No se escribe código de un módulo sin su `spec.md` aprobado.
- Un módulo no se cierra sin pruebas unitarias (constitución, punto 4).
- Al cerrar un módulo se actualiza `docs/arquitectura/`, que es lo que queda
  vigente cuando el spec ya caducó.

Antes de empezar cualquier módulo, leer [`constitution.md`](constitution.md).

## Estado

Leyenda: ⬜ sin especificar · 📝 especificado · 🔨 en implementación · ✅ cerrado

| # | Módulo | Estado | Objetivo en una línea |
|---|---|---|---|
| 000 | [seguridad](000-seguridad/) | 📝 | Fijar las reglas de seguridad que cumple el sistema nuevo. Sin código propio: se implementan en los módulos que le siguen. |
| 001 | [andamiaje-y-tests](001-andamiaje-y-tests/) | 📝 | Migraciones versionadas, armazón de pruebas e integración continua, para que lo demás sea reversible. |
| 002 | [identidad-de-iglesia](002-identidad-de-iglesia/) | ⬜ | Crear la entidad iglesia y propagarla a datos, usuarios y permisos. |
| 003 | [panel-saas](003-panel-saas/) | ⬜ | Alta de iglesias, licencias, administrador por iglesia e invitaciones por QR. |
| 004 | [estado-en-vivo](004-estado-en-vivo/) | ⬜ | Persistir lista de alabanza y canto actual por iglesia; matar `songid.txt` y el array en memoria. |
| 005 | [tiempo-real](005-tiempo-real/) | ⬜ | Protocolo nuevo con salas por iglesia y autorización por rol en los eventos de control. |
| 006 | [catalogo-y-partituras](006-catalogo-y-partituras/) | ⬜ | Modelo melodía/arreglo, deduplicación por hash y acceso autenticado a los archivos. |
| 007 | [app-movil](007-app-movil/) | ⬜ | Reescribir la capa de datos de Symphony conservando funcionalidades, descargas y anotaciones. |
| 008 | [sincronizacion-y-licencias](008-sincronizacion-y-licencias/) | ⬜ | Sincronización nube↔nodo y licencia firmada verificable sin internet. |
| 009 | [nodo-empaquetado](009-nodo-empaquetado/) | ⬜ | Instalador único del nodo, actualizaciones con reversión automática y respaldo. |

**Siguiente:** `001-andamiaje-y-tests` — `spec.md`, `plan.md` y `tasks.md`
escritos y aprobados. Toca **implementar**, empezando por la fase 1 de su
`tasks.md`. El módulo 000 ya fijó sus reglas y no tiene código propio; 001 es
el primero que construye.

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
```

000 y 001 no dependen de nada y pueden ir en paralelo. 003 es el primer
entregable visible del negocio y por eso va pronto, pero necesita 002 antes:
un panel que administra iglesias requiere que la iglesia exista.
