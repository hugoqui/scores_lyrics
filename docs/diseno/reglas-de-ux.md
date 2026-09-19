# Reglas de UX

Se deciden **una vez** y valen para toda interfaz del proyecto: el panel del
SaaS de [003](../../specs/003-panel-saas/), la app móvil de
[007](../../specs/007-app-movil/) y la app de escritorio de
[010](../../specs/010-app-de-escritorio/). No se redecide pantalla por pantalla
(spec 003 R6).

Nacieron en 003, que estrena la interfaz del proyecto, pero no son suyas.

## 1. Qué se confirma

Confirmar es caro: entrena a la gente a pulsar «sí» sin leer. Se pide
confirmación **solo** cuando el efecto alcanza a alguien más o no se puede
deshacer desde la misma pantalla.

| Se confirma | No se confirma |
|---|---|
| Revocar una licencia (deja a una iglesia sin ella) | Renombrar una iglesia |
| Suspender o reactivar una iglesia | Asignar o quitar un instrumento |
| Dar de baja a un usuario | Emitir una invitación |
| Revocar una invitación viva | Cambiar el rol de un usuario |
| Revocar un dispositivo | Cualquier filtro, orden o búsqueda |

La confirmación **dice qué va a pasar y a quién**, con el nombre delante:
«Revocar la licencia de Iglesia Central» no «¿Está seguro?». El botón que
confirma repite el verbo —«Revocar»—, nunca «Aceptar».

Cuando la acción pide un dato para poder hacerse —el motivo de una revocación—,
ese dato **es** la confirmación: no se pide dos veces.

## 2. Qué se puede deshacer

**Nada se borra, así que casi todo se deshace.** Es la forma de la constitución
en la interfaz (punto 5): dar de baja a un usuario cambia su estado, suspender
una iglesia cierra el acceso, revocar un dispositivo no toca la contraseña.

- Lo reversible se dice reversible **en el momento**: «Queda dado de baja.
  Puedes readmitirlo cuando quiera.»
- Lo irreversible se nombra irreversible **antes**: revocar una licencia o una
  invitación no se deshace; se emite otra.
- **No hay «deshacer» flotante ni ventana de gracia.** La reversión es una
  acción normal en la pantalla donde vive el objeto, no un mensaje que se va
  solo. Un aviso que desaparece no es una garantía.
- Nada se borra de verdad desde ninguna pantalla. Si una pantalla necesitara
  borrar, lo que está mal es la pantalla.

## 3. Cómo se enuncia un error

Un error dice **qué pasó**, **qué se puede hacer** y nada más. Ni códigos, ni
nombres de tabla, ni la excepción.

- **En el idioma de la persona**, desde el archivo de traducciones. Un mensaje
  de error es texto visible como cualquier otro (constitución, punto 9).
- **Sin culpar a quien lo lee.** «Esa invitación ya no es válida», no «Código
  inválido».
- **Junto al campo** cuando es de un campo; arriba de la pantalla cuando es de
  la operación entera. Nunca los dos a la vez.
- **Lo que no se sabe no se inventa.** Si el servidor no responde, se dice que
  no se pudo y se deja reintentar; no se afirma que algo falló cuando no consta.
- **Un error nunca revela lo que la persona no debía ver.** Pedir algo de otra
  iglesia responde *no existe*, no *no tienes permiso*: distinguirlos confirma
  que existe (spec 002 R2). Lo mismo con las invitaciones: caducada, canjeada y
  revocada dan **el mismo mensaje**.
- **Un error de licencia dice que es de licencia, y a quién avisar.** El
  administrador no puede renovarla; sí puede saber por qué no le deja y a quién
  llamar.

## 4. Qué se ve mientras algo carga

- **Nada parpadea.** Si la respuesta llega pronto no se muestra ningún
  indicador; el destello es peor que la espera.
- **El sitio no salta.** Lo que carga ocupa el espacio que va a ocupar: la
  lista no empuja la página al llegar.
- **El botón que disparó la acción se deshabilita mientras dura**, y lo dice.
  Es lo que impide emitir dos invitaciones por pulsar dos veces.
- **Una espera larga se nombra.** Si algo tarda de verdad, se dice qué se está
  haciendo, no se deja un círculo girando sin sujeto.
- El panel es Blazor Server y vive de una conexión permanente (ADR 0019):
  **perder la conexión se anuncia** y se recupera sola. No se deja una pantalla
  que parece viva y no responde.

## 5. Cómo se muestra una advertencia que no bloquea

Es la regla más delicada del proyecto, porque es donde un aviso razonable acaba
apagando algo (ADR 0020, constitución punto 1).

- **Una advertencia informa; no pide permiso ni interrumpe.** Nunca es un
  diálogo modal, nunca hay que descartarla para seguir trabajando.
- **Vive donde está lo que describe** y se queda mientras la condición siga
  siendo cierta: pasarse del tope de dispositivos se ve en el resumen de la
  iglesia y en la lista de dispositivos, no en un cartel global.
- **Dice el hecho y qué se puede hacer, sin alarma.** «Hay 14 dispositivos
  activos; la licencia declara 10. Puedes revisar la lista o ampliar el tope.»
  No es un error y no se pinta como uno.
- **Ninguna advertencia deshabilita ningún botón.** Si algo está bloqueado, es
  un bloqueo y se enuncia como tal (regla 3), con su motivo. Pasarse del tope
  **no** bloquea nada.
- **Ninguna advertencia del panel llega a la pantalla del templo.** Ni de
  licencia, ni de tope, ni de conexión. El panel no se abre ahí durante un
  servicio (constitución, punto 1).

## 6. Texto

- **Todo texto visible sale del archivo de traducciones**, español e inglés,
  desde el primer día. Ninguno se escribe en el código, ni siquiera
  «temporalmente» (constitución, punto 9). Una prueba lo verifica.
- **Se escribe en la lengua de la iglesia, no en la del sistema.** «Músico»,
  «instrumento», «lista de alabanza». No «entidad», «registro» ni «tenant».
- **Los botones llevan el verbo de lo que hacen**: «Emitir invitación»,
  «Revocar dispositivo». Nunca «Enviar», «Guardar cambios» ni «Aceptar».
- **La regla anterior es para el botón que hace algo. Salir no es hacer algo.**
  Un formulario que todavía no ha guardado nada no necesita un botón para
  abandonarlo: se sale por donde se entró —la migaja, la vuelta a la lista— y
  ya está. Poner un segundo botón junto al principal le hace competencia y
  obliga a leer los dos para decidir. Si hace falta una salida explícita, es un
  **enlace discreto** que nombra el destino —«Volver a iglesias»—, nunca un
  botón del mismo peso que el que crea la iglesia.
  Y no se llama «descartar» a lo que no existe: antes de pulsar «Crear
  iglesia» no hay ninguna iglesia a medias que tirar.
- **Una frase por mensaje.** Si hacen falta dos, la segunda es la salida.
- El contenido que carga la iglesia —letras, anotaciones, nombres de cantos—
  **no se traduce**: va en el idioma en que lo escribieron (constitución,
  punto 9).

## 7. Identidad y zona

- **Siempre se ve en qué zona se está y con qué identidad.** Las dos zonas del
  panel no se parecen por accidente: se distinguen a simple vista (ADR 0019).
- **Ninguna pantalla de iglesia muestra ni pide un identificador de iglesia.**
  Sale del token, siempre. No existe selector de iglesia.
- **Que un botón no esté no es autorización.** La interfaz esconde lo que no
  corresponde, y el servidor lo comprueba igual. Nada de lo de arriba sustituye
  a `ExigirOperacion`.

## 8. Dónde aparece algo: página, panel lateral o diálogo

Tres contenedores y tres usos. No se elige por tamaño del contenido, sino por
lo que hay que conservar detrás.

**Página completa** — cuando el resultado importa fuera del momento: hay que
poder recargarlo, guardarlo, imprimirlo o mandárselo a alguien. También cuando
no hay nada detrás que conservar.

> El alta de iglesia y lo que entrega al terminar —la invitación del primer
> administrador y la configuración del nodo— son página. El canje de
> invitación también: es público, no hay lista detrás.

**Panel lateral** (*drawer*) — ver o editar un registro **sin perder la lista**.
Es el contenedor por defecto del panel: casi siempre se quiere seguir viendo la
tabla para pasar a la fila siguiente o comparar.

> Ficha de usuario, instrumentos de un músico, dispositivos, emitir invitación
> y mostrar su QR, ficha de iglesia.

**Diálogo** (*modal*) — confirmar algo destructivo, y nada más. Poca
información, una decisión de dos salidas. Aquí interrumpir es el objetivo.

> Revocar una licencia, revocar un dispositivo, dar de baja a un usuario.

Reglas que hacen que esto funcione:

- **El panel lateral tiene su propia URL.** Si no, recargar devuelve a la lista
  pelada y no se le puede pasar a nadie el enlace de una ficha. Se decide al
  construir el primero, no en la pantalla doce.
- **No se anidan.** Nunca un diálogo sobre un panel lateral: si dentro de una
  ficha hay que confirmar algo destructivo, se cierra el panel y se confirma
  sobre la lista. Dos capas encima de otra y ya nadie sabe qué cierra qué.
- **Un diálogo que necesita desplazamiento está mal elegido.** Si el contenido
  no cabe, era un panel lateral o una página.
- **Nada importante vive solo dentro de un panel lateral.** Lo que hay que
  conservar —un código de invitación, la configuración de un nodo— se entrega
  en una página.

## 9. Accesibilidad, que sí se verifica

No es una lista de buenas intenciones: cada punto se puede comprobar, y por eso
está aquí.

- **Contraste mínimo 4.5:1** para texto normal y 3:1 para texto grande y para
  los bordes de los controles. Vale en los **dos temas**, claro y oscuro. El
  dorado de la marca no pasa sobre fondo claro: ahí se oscurece o se usa en
  fondos y bordes, nunca en texto pequeño.
- **Nada se entiende solo por el color.** «Vigente», «por vencer» y «vencida»
  llevan texto o icono además del verde, el ámbar y el rojo. Quien no
  distingue esos colores es más común que quien usa un lector de pantalla.
- **Todo se alcanza con el teclado**, en un orden que sigue a la lectura. Nada
  que se pueda pulsar con el ratón queda fuera.
- **El foco se ve siempre**, con un contorno propio y no solo un cambio de
  color de fondo. No se desactiva nunca «porque afea».
- **`Esc` cierra el panel lateral y el diálogo**, y al cerrarse **el foco
  vuelve a donde estaba** —a la fila que se abrió—, no al principio de la
  página.
- **Mientras un diálogo está abierto, el foco no se escapa detrás de él.**
- **Cada campo tiene su etiqueta visible**, asociada de verdad al campo. Un
  texto de ejemplo dentro del campo no es una etiqueta: desaparece al escribir.
- **El error se anuncia, no solo se pinta**: queda asociado a su campo para que
  un lector de pantalla lo lea al llegar.
- **Nada depende de pasar el ratón por encima.** En una tabla densa es
  tentador esconder las acciones de una fila hasta el *hover*; con teclado y en
  táctil eso no existe.
- **Ningún texto se sustituye por una imagen**, y todo icono que actúa solo
  lleva nombre accesible. Sale del archivo de traducciones como cualquier otro
  texto (regla 6).
