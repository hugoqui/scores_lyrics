# Documentación

Dos carpetas, separadas por **ciclo de vida**:

- **[`../specs/`](../specs/)** — el trabajo por módulo. Un spec caduca cuando su
  módulo se termina.
- **`docs/`** — lo transversal, que debe estar **siempre vigente**. El modelo de
  datos no caduca.

## Por dónde empezar

1. **[`../specs/constitution.md`](../specs/constitution.md)** — los principios
   que no se negocian. Léelo antes de proponer nada.
2. **[`arquitectura/estado-actual.md`](arquitectura/estado-actual.md)** — cómo
   está el sistema hoy, verificado en el código. Todo hallazgo apunta al módulo
   que lo resuelve.
3. **[`../specs/README.md`](../specs/README.md)** — qué módulos hay y por cuál
   vamos.

## Contenido

| Carpeta | Qué hay | Cuándo se actualiza |
|---|---|---|
| `arquitectura/` | Cómo funciona el sistema | Al cerrar cada módulo |
| `adr/` | Decisiones tomadas, con su porqué y su costo | Una vez, al tomarlas |
| `operacion/` | Instalación, inventario y soporte | Continuamente |

## Sobre los ADR

Un ADR **no se reescribe**. Si una decisión cambia, se escribe uno nuevo que
sustituye al anterior y se marca el viejo como sustituido. El valor está en
poder reconstruir por qué se decidió algo con la información de entonces.
