# 000-seguridad — Seguridad

**Estado:** 📝 reglas fijadas · **Depende de:** nada

## Objetivo

Fijar las reglas de seguridad que el sistema nuevo debe cumplir desde su
primera línea de código: secretos fuera del repositorio, base de datos nueva
en vez de la comprometida ([ADR 0008](../../docs/adr/0008-no-tocar-bd-existente.md)),
motores de base de datos inalcanzables desde internet, nada de ejecutar
comandos con datos de red, SQL siempre parametrizado, nodo con autenticación
desde el principio, contraseñas con hash lento y con sal, y una app que
funciona sin internet sin por ello autorizarse a sí misma.

## Este módulo no tiene código propio

No hay `plan.md` ni `tasks.md`. Como `legacy/` no se parchea
([ADR 0009](../../docs/adr/0009-no-se-parchea-el-legado.md)) y el sistema
nuevo todavía no existe, no queda nada que implementar aquí: los ocho
requisitos de [`spec.md`](spec.md) son **restricciones sobre otros módulos**,
no trabajo propio.

Cada uno se implementa y se prueba en el módulo que le corresponde:

| Requisito | Se implementa en |
|---|---|
| R1 secretos fuera del repo, configuración que falla ruidosamente | 001-andamiaje-y-tests |
| R2 base de datos nueva | 001-andamiaje-y-tests |
| R3 motores inalcanzables desde internet | 009-nodo-empaquetado |
| R4 nada de comandos con datos de red | 005-tiempo-real |
| R5 SQL parametrizado | todos los que toquen base de datos |
| R6 nodo con autenticación | 002-identidad-de-iglesia |
| R7 contraseñas con hash lento y con sal | 002-identidad-de-iglesia |
| R8 sesión sin internet, revocación, bloqueo | 002 y 008-sincronizacion-y-licencias |

**Se cierra** cuando esos módulos estén cerrados y sus pruebas cubran cada
requisito (constitución, punto 4). No antes, aunque aquí no haya código.

Antes de empezar cualquiera de ellos, leer la
[constitución](../constitution.md) y el
[estado actual](../../docs/arquitectura/estado-actual.md).
