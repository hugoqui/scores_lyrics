# Prototipos aprobados

Ninguna pantalla se implementa sin su prototipo aprobado por el propietario
([`specs/README.md`](../../../specs/README.md)). Aquí queda lo aprobado.

Los archivos son **exportaciones congeladas**, no fuentes: no se editan desde el
repositorio. Si hay que cambiar algo se cambia en Claude Design y se vuelve a
exportar.

## 003 — Panel del SaaS

### `003-wireframes-flujos.png` — T0.5

Wireframes de baja fidelidad de los tres flujos con interacción nueva. Las
otras 17 pantallas del
[inventario](../../../specs/003-panel-saas/inventario-de-pantallas.md) son
listas y formularios, y pasan directo a prototipo (spec R6).

| Fila | Flujo | Qué resuelve |
|---|---|---|
| 1 | Alta de iglesia (`/saas/*`) | El alta no termina al crear: termina entregando la invitación del primer administrador y la configuración del nodo, en la misma pantalla. No se pide contraseña de nadie |
| 2 | Invitación, de emisión a canje | Emitir → mostrar QR y código una sola vez → listar → canjear sin sesión → un único mensaje para caducada, canjeada y revocada |
| 3 | Resumen de la iglesia, tres variantes | Cómo se distingue una **advertencia que no bloquea** (tope de dispositivos) de un **bloqueo** (licencia vencida) |

En todos los artboards: la zona marcada en la cabecera, selector ES|EN incluso
en las pantallas públicas, y notas de dónde caen la carga y los errores.

**Corrección aplicada tras la revisión:** el formulario de alta llevaba un botón
«Descartar el alta» junto al principal. Se retira: antes de pulsar «Crear
iglesia» no existe ninguna iglesia que descartar, y un segundo botón del mismo
peso le hace competencia al que sí hace algo. Se sale por la migaja. De ahí sale
el matiz de la regla del verbo en
[`reglas-de-ux.md`](../reglas-de-ux.md).

El texto visible del PNG es relleno de composición. El texto real sale del
archivo de traducciones, español e inglés (constitución, punto 9).
