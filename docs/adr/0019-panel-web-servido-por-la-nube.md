# ADR 0019 — El panel del SaaS es web, servido por la nube, con dos zonas por rol

**Estado:** aceptada · **Fecha:** 2026-09-18

## Contexto

El módulo [003-panel-saas](../../specs/003-panel-saas/spec.md) construye la
**primera interfaz de usuario del sistema nuevo**. Hoy no existe ninguna: el
proceso de la nube es una minimal API con OpenAPI, y una iglesia se da de alta
con un comando en una terminal
([alta-de-iglesia.md](../operacion/alta-de-iglesia.md)).

Hay que decidir dos cosas a la vez, porque una condiciona a la otra: con qué se
construye el panel, y cómo conviven en él dos públicos muy distintos.

- **El propietario del SaaS**, que ve **todas** las iglesias: las crea y emite
  o revoca sus licencias. Una persona.
- **El administrador de cada iglesia**, que ve **solo la suya**: sus usuarios,
  instrumentos, dispositivos e invitaciones. Una persona por congregación.

[ADR 0013](0013-app-de-escritorio-en-vez-de-panel-web.md) retiró un panel web,
pero no este: retiró el panel **del templo**, el que se usaba para proyectar y
controlar el culto. Ese se fue a una app de escritorio porque el domingo tiene
que funcionar sin internet (constitución, punto 2) y porque la pantalla
extendida se maneja mejor nativamente. Ninguna de esas dos razones aplica aquí:
el panel del SaaS **no va al templo** y la constitución lo nombra
explícitamente entre las excepciones que sí pueden exigir conexión.

## Decisión

**Una sola aplicación web Blazor Server, servida por el propio proceso de
`Symphony.Cloud`, con dos zonas separadas por rol.**

La separación no es cosmética: **cada zona tiene su propio acceso a datos**.

```
/saas/*      →  propietario del SaaS  →  AccesoComoPropietario  →  ve todas las iglesias
/iglesia/*   →  administrador         →  AccesoALaNube          →  RLS, solo su iglesia
```

Reglas que acompañan a la decisión:

- **Ningún componente de `/iglesia/*` puede obtener `AccesoComoPropietario`.**
  Se impone en el código y se comprueba con una prueba; no se confía a la
  disciplina de quien escriba la siguiente pantalla.
- La iglesia sale **siempre del token**, nunca de la ruta ni del formulario
  ([ADR 0015](0015-aislamiento-por-rls-y-nodo-atado-a-su-iglesia.md)). No
  existe ninguna pantalla con selector de iglesia en la zona de iglesia.
- Cada operación se comprueba en el servidor con la misma `ExigirOperacion` que
  usan los endpoints. **Esconder un botón no autoriza nada.**
- Compartir componentes de presentación entre zonas es correcto. Compartir
  acceso a datos, no.
- Ningún texto visible se escribe en el código: sale del archivo de
  traducciones, español e inglés (constitución, punto 9, que nombra al panel
  del SaaS).
- **El panel nunca se abre en el equipo del templo durante un servicio.** Ni un
  aviso de licencia ni un error suyo puede aparecer en la pantalla de la
  iglesia (constitución, punto 1).

## Razones

- **Un despliegue, un lenguaje, una tubería.** No hay proyecto de frontend, ni
  empaquetado de JavaScript, ni una segunda superficie de autenticación que
  mantener en sincronía con la primera. El propietario es el único que mantiene
  esto.
- **La sesión firmada de 002 ya sirve tal cual**
  ([ADR 0016](0016-sesion-firmada-verificable-sin-internet.md)). Con un cliente
  en el navegador habría que decidir cómo viaja el token hasta allí, dónde se
  guarda y cómo se renueva — tres decisiones nuevas, cada una con su forma de
  salir mal, para dos tipos de usuario.
- **El panel puede exigir internet**, así que la razón que hizo inviable un
  panel web para el culto no aplica. Si el panel está caído, el domingo
  funciona igual: el nodo no depende de él.
- **La separación por zonas es la pieza que sostiene el aislamiento.** Mezclar
  los dos públicos en las mismas pantallas obligaría a que cada vista decidiera
  en cada consulta si filtra por iglesia o no, y ese es exactamente el defecto
  que 002 se construyó para hacer imposible (constitución, punto 3). Con dos
  accesos a datos distintos, el límite está en la puerta y no en cada pantalla.
- **Coherencia con [ADR 0017](0017-acceso-a-datos-con-sql-explicito.md).** La
  RLS necesita que la iglesia se fije sobre la conexión de cada unidad de
  trabajo. Que el panel use la misma puerta que el resto del código es lo que
  hace que esa garantía valga también para las pantallas.

## Alternativas descartadas

- **Un SPA (Vue, React) contra la API.** Añade un segundo despliegue, un
  segundo pipeline y una segunda forma de guardar la sesión, para dos usuarios
  y un puñado de pantallas de administración. El costo es permanente; el
  beneficio, cero en esta escala.
- **Dos aplicaciones separadas, una por zona.** Duplica plantillas,
  traducciones y autenticación para separar algo que se separa mejor por rol
  dentro de una sola aplicación.
- **Extender la app de escritorio de [010](../../specs/010-app-de-escritorio/)
  con pantallas de administración.** Obligaría al administrador de una iglesia
  a instalar un programa para invitar a un músico, y llevaría avisos de
  licencia al equipo que proyecta — justo lo que prohíbe el punto 1 de la
  constitución.

## Costo aceptado

- **Blazor Server exige conexión permanente con el servidor**, y una conexión
  inestable se nota en la interfaz. Se acepta: es la única parte del sistema a
  la que se le permite depender de internet, y quien la usa está en una oficina
  o en su casa, no en el templo a mitad de un culto.
- **Entran dos tecnologías de interfaz al proyecto**: Blazor aquí, y lo que
  elija [010](../../specs/010-app-de-escritorio/) para la app de escritorio
  sobre Tauri (ADR 0013). No se comparten componentes entre ambas. Se acepta
  porque no comparten ni público ni pantallas: una administra, la otra proyecta.
  Lo que sí se comparte es el archivo de traducciones y las reglas de UX de
  `docs/diseno/`.
- **El panel vive en el mismo proceso que la API.** Una pantalla que consuma
  recursos afecta al servicio que atiende a los nodos. Es asumible con dos
  iglesias y un puñado de usuarios administrativos; si algún día deja de serlo,
  separarlo es mover un proyecto, no rediseñar.
- **La regla de "ningún componente de iglesia alcanza el acceso del
  propietario" hay que sostenerla con una prueba**, porque nada en el lenguaje
  la impone sola.

## Notas de implementación

- Las minimal API existentes no se tocan ni se reemplazan: el panel se suma al
  mismo proceso, y la app móvil sigue consumiendo la API.
- `AccesoComoPropietario` ya está acotado y documentado en
  [roles-de-base-de-datos.md](../operacion/roles-de-base-de-datos.md); la zona
  `/saas/*` se añade a esa lista de caminos permitidos.
- El propietario del SaaS entra por su propio camino de autenticación: desde
  002 es una tabla aparte, no un usuario de iglesia con más permisos.
- El archivo de traducciones nace en este módulo y lo heredan
  [007](../../specs/007-app-movil/) y [010](../../specs/010-app-de-escritorio/).
