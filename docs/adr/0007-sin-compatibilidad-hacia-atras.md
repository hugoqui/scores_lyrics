# ADR 0007 — Sin compatibilidad con la versión actual

**Estado:** aceptada · **Fecha:** 2026-09-14

## Contexto

Hay apps Symphony instaladas en los teléfonos de los músicos hablando el
protocolo actual. La pregunta era si el sistema nuevo debía seguir
entendiéndolas durante una transición.

## Decisión

No. La versión nueva exige el sistema nuevo. Se coordina la actualización con
las iglesias en vez de mantener dos protocolos vivos.

## Qué trabajo elimina

Registrado para que la decisión sea rastreable si algún día se cuestiona:

- Un traductor bidireccional entre el protocolo viejo y el nuevo.
- Congelar la forma de respuesta de cada endpoint actual y sostenerla.
- Instrumentación para contar clientes antiguos conectados y decidir cuándo
  apagar el puente.
- Una ventana de convivencia realista de 9 a 12 meses antes de poder retirar
  nada.
- Una etapa final dedicada a retirar lo viejo.

## Qué NO cambia

El identificador de la aplicación (`org.nativescript.symphony`) y las llaves de
firma **se conservan**. La app se actualiza en sitio: los músicos no reinstalan
y conservan sus partituras descargadas y sus anotaciones.

Romper el protocolo es barato; romper la continuidad de la publicación en las
tiendas y los datos locales de los músicos, no.

## Costo aceptado

La actualización deja de ser opcional para el músico: hasta que actualice, la
app no funcionará. Requiere avisar con antelación y acompañar a cada iglesia.
