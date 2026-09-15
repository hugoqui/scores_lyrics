# ADR 0009 — El legado no se parchea; se retira

**Estado:** aceptada · **Fecha:** 2026-09-14

## Contexto

`legacy/back-scores` y `legacy/belen-backend` corren hoy en las dos iglesias y
cargan con fallas verificadas: SQL por concatenación, contraseñas en SHA1 sin
sal, credenciales en el repositorio y un nodo sin autenticación alguna
(`docs/arquitectura/estado-actual.md`).

La pregunta era si arreglarlas mientras se construye el sistema nuevo, o
dejarlas correr y concentrar el esfuerzo en el reemplazo.

## Decisión

No se toca `legacy/`. Ni arreglos de seguridad, ni rotación de secretos, ni
refactores. Ese código se retira entero cuando el sistema nuevo lo reemplace.

Sus fallas quedan registradas en `estado-actual.md` como **restricciones sobre
el sistema nuevo** —lo que no puede repetirse—, no como tareas pendientes.

## Razones

- Lleva un año funcionando así. El riesgo es real pero conocido y acotado: dos
  iglesias, red local, y un solo responsable que administra ambas.
- El arreglo se tira. Todo lo que se invierta en endurecer Node + MySQL
  desaparece cuando entre el nodo en C# con SQLite (ADR 0003, ADR 0004).
- Tocar producción para arreglarla puede tumbar un domingo (constitución,
  punto 1). El código que nadie toca no falla de formas nuevas.
- Sin compatibilidad hacia atrás (ADR 0007), no hay periodo en que los dos
  sistemas convivan: se desinstala uno y se instala el otro.

## Costo aceptado

Las vulnerabilidades siguen abiertas durante los meses que tarde la
construcción del sistema nuevo. En concreto: la ejecución remota de comandos
en la PC de transmisión y el acceso sin autenticar al nodo siguen siendo
explotables por cualquiera dentro de la red del templo.

Se acepta explícitamente por decisión del propietario, que es quien opera y da
soporte a las dos instalaciones.

## Notas de implementación

- `apps/stream-agent` **no** entra en esta decisión: no es legado, se conserva
  (`estado-actual.md`). Su ejecución remota de comandos sí se arregla, cuando
  se conecte al protocolo nuevo (`005-tiempo-real`).
- Si en algún momento entra una tercera iglesia, o alguien más administra una
  instalación, el costo aceptado aquí deja de serlo y esta decisión se
  revisa con un ADR nuevo.
