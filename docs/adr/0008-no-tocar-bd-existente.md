# ADR 0008 — No se modifica la base de datos existente; se provisiona una nueva

**Estado:** aceptada · **Fecha:** 2026-09-14

## Contexto

Las credenciales de la base de datos MySQL actual (`belen` y equivalentes por
iglesia) están filtradas y se asume que la tabla de usuarios ya fue copiada
(`docs/arquitectura/estado-actual.md`). El módulo 000-seguridad necesita
cerrar ese hueco. La opción evidente era rotar la contraseña en sitio sobre la
misma base de datos.

## Decisión

No se toca la base de datos actual: ni se migra en sitio, ni se le rotan las
credenciales, ni se escribe sobre ella. Se provisiona una base de datos nueva,
con credenciales nuevas, y todo lo que se construya de aquí en adelante
apunta a esa base.

La base de datos actual queda **congelada**: solo se lee, y solo si hace
falta traer datos a la base nueva. Nunca vuelve a ser destino de escritura.

## Razones

- Es producción real, en uso cada domingo (constitución, punto 1). Modificarla
  en sitio arriesga tumbar un servicio si algo sale mal, y no hay forma de
  revertir un cambio a medio hacer sin arriesgar más.
- Ya se asume comprometida (posible copia de la tabla de usuarios). Rotar su
  contraseña no deshace esa copia; solo bloquea el acceso hacia adelante.
  Empezar limpio en una base nueva es más simple que sanear la vieja.
- Coincide con la arquitectura ya decidida (ADR 0002, ADR 0004): el sistema
  nuevo no reutiliza el motor ni el esquema del legado, así que la base nueva
  iba a existir de todas formas.

## Costo aceptado

- Migrar los datos que sí se necesitan (repertorio, historial) de la base
  vieja a la nueva es trabajo explícito, no un simple cambio de contraseña.
- Los músicos se dan de alta de nuevo, con contraseñas nuevas: la tabla de
  usuarios vieja se considera comprometida y no se importa.
- El corte lo hace el propietario a mano en las dos iglesias, desinstalando la
  versión vieja e instalando la nueva. Con dos instalaciones y un solo
  responsable, no hace falta coordinación remota.

## Notas de implementación

- La base vieja no se borra ni se apaga por este módulo; se congela como
  solo lectura hasta que cada iglesia haya cortado a la base nueva.
