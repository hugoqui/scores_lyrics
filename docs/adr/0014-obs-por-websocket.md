# ADR 0014 — El nodo habla con OBS por su protocolo oficial; `stream-agent` se retira

**Estado:** aceptada · **Fecha:** 2026-09-15

## Contexto

`apps/stream-agent` (Node) traduce eventos de socket en **pulsaciones de teclado**
para controlar OBS/vMix: cambiar de escena, encender fuentes. Recibe un valor por
socket sin autenticar y lo concatena en una cadena de PowerShell, lo que permite
a cualquiera en la red del templo ejecutar comandos en la PC de transmisión
(`docs/arquitectura/estado-actual.md`; es el hallazgo R4 de
[000-seguridad](../../specs/000-seguridad/spec.md)).

Hasta ahora se daba por hecho que ese agente se conservaba y se arreglaba al
conectarlo al protocolo nuevo.

## Decisión

El nodo controla OBS **directamente por obs-websocket**, el protocolo oficial de
OBS. `apps/stream-agent` se retira entero; no se arregla.

## Razones

- **Elimina la vulnerabilidad en vez de contenerla.** Sin simulación de teclado
  no hay cadena que construir ni comando que inyectar: el requisito R4 de
  000-seguridad deja de necesitar vigilancia.
- **Las pulsaciones de teclado son frágiles.** Dependen de que OBS tenga el
  foco, de los atajos configurados y de que nadie los cambie. Un domingo con la
  ventana equivocada en primer plano manda las teclas a otra parte.
- **El protocolo devuelve estado.** Se puede saber qué escena está activa, no
  solo pedir un cambio a ciegas.
- **Una pieza menos.** El nodo ya está en el mismo equipo y ya mantiene el
  estado del servicio.

## Costo aceptado

- **vMix no habla obs-websocket.** Si alguna iglesia usa vMix, necesitará su
  propia integración —vMix tiene API HTTP— o quedará fuera. No hay constancia de
  que se use hoy; hay que confirmarlo antes de retirar el agente.
- Depende de que obs-websocket esté habilitado en cada instalación de OBS. Es
  parte de OBS desde la versión 28, pero exige activarlo y configurar su
  contraseña: entra en el procedimiento de instalación
  ([009-nodo-empaquetado](../../specs/009-nodo-empaquetado/)).
- **Mientras tanto, la ejecución remota sigue abierta** en las iglesias, como el
  resto de lo que será reemplazado ([ADR 0009](0009-no-se-parchea-el-legado.md)).

## Notas de implementación

- Sustituye a la nota de ADR 0009 que excluía a `apps/stream-agent` de la
  retirada del legado. Ya no se conserva: se retira.
- La contraseña de obs-websocket es un secreto de configuración
  (000-seguridad R1): del entorno, nunca del repositorio.
