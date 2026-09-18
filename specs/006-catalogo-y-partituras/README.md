# 006-catalogo-y-partituras — Catálogo y partituras

**Estado:** ⬜ sin especificar · **Depende de:** 002

## Objetivo

Modelo de base y arreglo con una base por afinación, deduplicación por contenido, catálogo real en vez de parsear HTML, y acceso autenticado a los archivos. Empieza con una auditoría que verifica si los archivos duplicados son idénticos byte a byte.

## Lo que dejó decidido 002

El módulo [002](../002-identidad-de-iglesia/) definió los instrumentos y su
afinación, y por el camino apareció esto, que es de aquí y conviene no
redescubrirlo:

- **Un canto no tiene *una* partitura base: tiene una por afinación.** Los
  instrumentos en Do —piano, violines, flautas, guitarra, cello— leen la base en
  Do; la trompeta y los clarinetes leen la de Si♭. La afinación de cada
  instrumento ya está en el catálogo, en datos.
- **La regla de entrega es una sola:** si hay arreglo para este canto y este
  instrumento, se entrega; si no, la base de su afinación.
- **Se llama *base*, no *melodía*.** La de Si♭ también es la melodía.
- **El archivo que hoy está copiado en `/piano/`, `/violin1/`, `/violin2/`,
  `/flute1/` y `/flute2/` no son cinco archivos: es una base en Do duplicada
  cinco veces.** Es lo primero que tiene que confirmar la auditoría.
- **Nada de un campo tipo `tiene_arreglo`.** No es una propiedad del
  instrumento —el mismo instrumento tiene arreglo en un canto y no en otro— y se
  responde mirando si el archivo existe. Un campo que repite lo que ya dicen los
  datos acaba mintiendo.
- **La clave (sol/fa) no se guarda.** No cambia qué partitura le toca a nadie:
  el piano usa dos a la vez y el cello lee la misma base en Do. Una versión
  específica para un instrumento es un arreglo, no un campo.

## Siguiente paso

Escribir `spec.md`: el **qué** y el **porqué**, sin entrar en implementación.
Después `plan.md` y `tasks.md`.

Antes de empezar, leer la [constitución](../constitution.md) y el
[estado actual](../../docs/arquitectura/estado-actual.md).
