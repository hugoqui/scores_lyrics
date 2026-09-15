# ADR 0012 — Integración continua en GitHub Actions

**Estado:** aceptada · **Fecha:** 2026-09-15

## Contexto

No existe integración continua: no hay `.github/`, ni tubería en ningún otro
servicio (verificado). El módulo
[001-andamiaje-y-tests](../../specs/001-andamiaje-y-tests/spec.md) (R6) exige
que cada push compile y corra todas las pruebas automáticamente, y que una
prueba rota bloquee la fusión.

El repositorio ya vive en GitHub (`hugoqui/scores_lyrics`, privado).

## Decisión

**GitHub Actions.** Un flujo que corre en cada push y en cada pull request:
compila la solución con advertencias como errores, corre todas las pruebas
—incluidas las de contenedor ([ADR 0011](0011-pruebas-con-base-real-efimera.md))—
y verifica el formato del código.

`main` y `dev` quedan protegidas: sin tubería verde no entra la fusión.

La tubería **no recibe ningún secreto de producción**. El PostgreSQL contra el
que prueba es el del contenedor efímero, con credenciales de juguete.

## Razones

- **No añade un servicio más.** El código ya está en GitHub; usar otra
  plataforma significaría otra cuenta, otro sitio donde guardar secretos y otro
  lugar que revisar cuando algo falla. Con un solo administrador
  ([ADR 0009](0009-no-se-parchea-el-legado.md)), eso importa.
- **Trae Docker de fábrica**, que es lo que necesitan las pruebas de
  integración.
- **La protección de ramas vive en el mismo sitio** que la tubería: la regla y
  su verificación no se pueden desincronizar.
- Gratis para el volumen de este proyecto en un repositorio privado.

## Costo aceptado

Queda atado a GitHub — el mismo sitio al que ya está atado el repositorio, así
que no añade dependencia nueva. Si algún día el código se muda, la tubería se
reescribe; es un archivo.
