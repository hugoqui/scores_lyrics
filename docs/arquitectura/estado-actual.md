# Estado actual del sistema

Radiografía del código **tal como está hoy**, verificada leyéndolo. Es la base
desde la que parten todos los módulos. Se actualiza a medida que cada módulo
resuelve lo que aquí se registra.

> Todo lo de este documento está comprobado en el código. Donde hay una
> suposición sin verificar, se dice explícitamente.

## Componentes

| Ruta | Qué es | Estado |
|---|---|---|
| `legacy/back-scores/` | Node + Express + socket.io + MySQL, puerto 3014. Corre en un servidor dentro de cada iglesia. Biblia, cantos, lista de alabanza y proyección. | En producción. Será reemplazado. |
| `legacy/belen-backend/` | Node + Express + MySQL en la nube. Solo `/api/login` y `/api/cantos`. | En producción. Será reemplazado. |
| `apps/web-panel/` | Vue 2.6 + vue-cli 4. Panel de control, pantalla de proyección (`#/screen`), Biblia, teleprompter, control de OBS. | **Será reemplazado** por la app de escritorio ([ADR 0013](../adr/0013-app-de-escritorio-en-vez-de-panel-web.md)). Nadie se conecta a él desde la red. |
| `apps/mobile/` | Flutter 3.6.0. App Symphony de los músicos. 43 archivos, 5.791 líneas. | Se conserva; se reescribe su capa de datos. |
| `apps/desktop-node/` | C# WPF + WebView2. Abre el panel y una ventana a pantalla completa en el segundo monitor. | **Será reemplazado**: se funde con el panel en una app de escritorio multiplataforma ([ADR 0013](../adr/0013-app-de-escritorio-en-vez-de-panel-web.md)). |
| `apps/stream-agent/` | Node. Traduce eventos de socket en pulsaciones de teclado para OBS/vMix. | **Será retirado**: el nodo hablará con OBS por su protocolo oficial ([ADR 0014](../adr/0014-obs-por-websocket.md)). |
| `apps/node-server/` | El servidor del templo en C#. | Por construir. |
| `services/cloud-api/` | Identidad, licencias y catálogo maestro en C#. | Por construir. |
| `frozen/audio-console-manager/` | Flutter. Control OSC de una consola Behringer X32. No habla con el resto. | Congelado. |

## Cómo encajan hoy

La app Flutter habla con **dos backends a la vez**:

- Nube (`api.iglesiacristianabelen.com`): `POST /login`, `GET /cantos`.
- Nodo del templo (por omisión `192.168.5.1:3014`): `GET /api/lastSong`,
  `GET /api/songList`, y el socket con los eventos `text_change` y `list_change`.

Las partituras salen de un tercer sitio, `partituras.iglesiacristianabelen.com`,
que es un **autoindex de Apache sin código en ningún repositorio**. La app
descubre qué archivos existen **parseando el HTML del listado con una expresión
regular**.

Los dos backends usan el mismo puerto 3014, uno en la nube y otro en la red local.

## Hallazgos

Cada uno apunta al módulo que lo resuelve. Ninguno queda sin dueño.

> **Resolver no significa parchear lo que será reemplazado.** Nada de
> `back-scores` ni `belen-backend` se arregla: ese código se retira entero
> cuando el sistema nuevo lo reemplace
> ([ADR 0009](../adr/0009-no-se-parchea-el-legado.md)). Lo mismo vale ahora para
> `web-panel`, `desktop-node` ([ADR 0013](../adr/0013-app-de-escritorio-en-vez-de-panel-web.md))
> y `stream-agent` ([ADR 0014](../adr/0014-obs-por-websocket.md)). Un hallazgo
> sobre cualquiera de ellos queda aquí como lo que el sistema nuevo no puede
> repetir, no como una tarea pendiente sobre ese código.

### Seguridad → [`000-seguridad`](../../specs/000-seguridad/)

- **Credenciales de producción en el repositorio.** `legacy/back-scores/src/config/config.js`
  y `legacy/belen-backend/src/config/config.js` contienen usuario y contraseña de
  MySQL en claro, más un `jwtSecret`. Están en el historial de git de repos que
  han sido públicos. **Hay que planificar asumiendo que la tabla de usuarios ya
  fue copiada.**
- **El nodo del templo no tiene autenticación alguna.** Cualquiera con acceso a
  la red del templo puede leer, crear, editar y borrar cantos, y proyectar texto
  arbitrario en la pantalla.
- **Ejecución remota de comandos.** `apps/stream-agent/app.js` recibe un valor por
  socket sin autenticar y lo concatena en una cadena de PowerShell. Cualquiera en
  la red —incluida una visita en el wifi de invitados— ejecuta comandos en la PC
  de transmisión. **No se arregla: el agente se retira entero**
  ([ADR 0014](../adr/0014-obs-por-websocket.md)), y el control de OBS pasa al
  nodo por obs-websocket, sin simular teclado.
- **SQL construido por concatenación** en `legacy/back-scores/src/controllers/mysqlController.js`
  y en `legacy/belen-backend/src/controllers/usuarios.js`. Hoy es una
  vulnerabilidad; en multi-iglesia sería fuga de datos entre congregaciones.
- **Contraseñas con SHA1 sin sal**, y la contraseña del usuario guardada **en
  claro** en el dispositivo (`apps/mobile/lib/data/repositories/auth_repository.dart`,
  clave `saved_password` en SharedPreferences).
- **Sesión de 30 días validada contra la fecha local del teléfono**, falseable
  cambiando la hora del dispositivo. El JWT real dura 7 días y no se comprueba.

### Ausencia de red de seguridad → [`001-andamiaje-y-tests`](../../specs/001-andamiaje-y-tests/) ✅ resuelto

Resuelto por el módulo 001: `Symphony.Node` y `Symphony.Cloud` tienen
migraciones versionadas y verificadas por hash
([ADR 0010](../adr/0010-migraciones-sql-planas.md)), pruebas contra bases
reales y efímeras ([ADR 0011](../adr/0011-pruebas-con-base-real-efimera.md)),
integración continua en GitHub Actions que bloquea la fusión sin tubería verde
([ADR 0012](../adr/0012-integracion-continua-en-github-actions.md)), y logs
estructurados con filtrado de secretos en ambos procesos (spec R7). Ya se sabe
qué esquema tiene cada base y hay forma de auditar qué pasó un domingo.

### No existe el concepto de iglesia → [`002-identidad-de-iglesia`](../../specs/002-identidad-de-iglesia/) ✅ resuelto

Resuelto por el módulo 002 en el sistema nuevo: la iglesia es una fila con
identidad propia (UUIDv7, [ADR 0005](../adr/0005-identificadores.md)) y **el
aislamiento lo impone el motor, no la consulta**
([ADR 0015](../adr/0015-aislamiento-por-rls-y-nodo-atado-a-su-iglesia.md)). En
la nube, row-level security activada y forzada contra la iglesia de la sesión,
con un rol de aplicación `NOBYPASSRLS` que no es dueño de las tablas: olvidar
un filtro da cero filas, no filas de otra congregación. En el nodo el
aislamiento es físico: una sola fila en `iglesia` impuesta por el esquema, todo
lo demás colgando de ella por clave foránea, y un proceso que se niega a
arrancar contra la base de otra iglesia. La iglesia de cada petición sale del
token firmado y de ningún otro sitio
([ADR 0016](../adr/0016-sesion-firmada-verificable-sin-internet.md)): ninguna
API la acepta por parámetro.

Sobre eso: un usuario pertenece a una iglesia y su correo es único dentro de
ella; darlo de baja cambia su estado y no borra su trabajo; los instrumentos
son datos con su afinación y un músico puede tener varios; los dispositivos son
varios por persona y revocables por separado; y los roles son una lista cerrada
que decide el servidor, en la que ninguno incluye a otro. La primera iglesia se
crea por comando, sin panel. Las pruebas están escritas para **intentar**
cruzarse de iglesia con identificadores válidos de la otra, y dos guardias
impiden añadir una tabla de dominio sin su política o un endpoint que atienda
sin sesión firmada.

Lo que sigue así en el legado hasta que se retire
([ADR 0009](../adr/0009-no-se-parchea-el-legado.md)):

La base de datos se llama `belen`, el socket emite en difusión global sin salas,
y el único rastro de la iglesia es el título de una ventana. Cada iglesia es una
instalación manual del mismo código.

Los músicos tampoco pertenecen a ninguna iglesia: un usuario es un email con un
`deviceId` atado, en una base compartida por todos. Si cambia de teléfono,
recibe 403 y no hay forma de liberarlo.

Los instrumentos están escritos a fuego en la app
(`apps/mobile/lib/core/services/instruments_service.dart`, diez fijos) y **un
músico solo puede tener uno**, cuando en la práctica alguien toca piano,
clarinete y flauta.

### Estado que no sobrevive a un reinicio → [`004-estado-en-vivo`](../../specs/004-estado-en-vivo/)

- La lista de alabanza es un **array en memoria del proceso**
  (`legacy/back-scores/src/data/songModel.js`). Si el servidor se reinicia a
  mitad del servicio, la lista desaparece.
- El último canto proyectado es un **archivo plano**, `songid.txt`.
- Un cliente que conecta a mitad del culto **no recibe el estado actual**: se
  queda en blanco hasta el siguiente cambio.

Bugs que tumban el proceso:

- `getLast` (`legacy/back-scores/src/controllers/songs.js`) lee una ruta relativa
  y hace `throw` dentro de un callback asíncrono: excepción no capturada desde un
  endpoint público.
- `removeFromList` (`songModel.js`) no valida el índice; con `-1` lanza excepción.
- `mysqlController` resuelve la promesa **después** de rechazarla (falta un
  `return` tras el `reject`).

### Difusión global sin permisos → [`005-tiempo-real`](../../specs/005-tiempo-real/)

socket.io sin salas ni espacios de nombres: todo es `io.emit` global y cada
cliente filtra por su cuenta. El rol (pantalla, servidor, control) se decide en
`localStorage` del navegador (`apps/web-panel/src/views/Settings.vue`), así que
cualquiera que abra la URL se autoproclama operador.

El payload distingue canto de versículo por una convención implícita: si
`reference` viene vacío, es un canto.

### Partituras duplicadas y públicas → [`006-catalogo-y-partituras`](../../specs/006-catalogo-y-partituras/)

- El archivo de melodía de un canto está **duplicado físicamente** en la carpeta
  de cada instrumento: `abre_mis_ojos.png` existe como copia en `/piano/`,
  `/violin1/`, `/violin2/`, `/flute1/`, `/flute2/`.
- El rol del archivo se **adivina por su nombre**: `canto.png` es melodía y
  `canto_{instrumento}.png` es arreglo
  (`apps/mobile/lib/features/practice/providers/practice_provider.dart`). Falla
  con cualquier título que lleve guion bajo.
- El catálogo se obtiene **parseando el HTML** del autoindex de Apache con una
  expresión regular.
- El servidor de partituras es **público**: cualquiera con la URL se lleva el
  repertorio completo de la iglesia.

> **Sin verificar:** que los archivos de melodía duplicados sean idénticos byte
> a byte. Si se exportaron por separado desde el editor de partituras, no lo
> serán y la deduplicación automática no los agrupará. **Auditar antes de
> comprometer fechas** para este módulo.

### App móvil → [`007-app-movil`](../../specs/007-app-movil/)

- **El ajuste de servidor no funciona**: `settings_screen.dart` escribe la clave
  `api_host`, pero `dio_client.dart` lee `host`. Cambiar el host desde Ajustes no
  tiene ningún efecto.
- Un solo `baseUrl` para todo, cuando hacen falta dos conceptos distintos: el
  host de la nube y el del nodo del templo.
- El índice de descargas es un **blob JSON en SharedPreferences**
  (`downloaded_files_v2`) que se reescribe entero en cada descarga.
- Las anotaciones se guardan bajo una clave derivada del **nombre del archivo**,
  lo que obliga a re-enlazarlas con cuidado en cualquier migración.

### Empaquetado y despliegue → [`009-nodo-empaquetado`](../../specs/009-nodo-empaquetado/)

- **La promesa de funcionar sin internet no se cumple hoy de forma confiable.**
  La configuración versionada de `back-scores` apunta a un host MySQL **remoto
  por IP**; las variantes locales están comentadas. Cada iglesia se instaló a
  mano, así que el estado real varía por instalación.
  → **Pendiente: inventario de instalaciones** (`docs/operacion/inventario-iglesias.md`).
- Sin Dockerfile, sin CI, sin gestor de procesos, sin actualizaciones
  automáticas. El escritorio se publica por ClickOnce sin firmar, último
  publicado en octubre de 2024.
- `apps/desktop-node` posiciona mal la ventana en el segundo monitor: usa
  `Bounds.Width` como coordenada `Left` en vez de `Bounds.X`. Funciona por
  casualidad con dos monitores idénticos lado a lado. No se arregla: la app de
  escritorio nueva ([ADR 0013](../adr/0013-app-de-escritorio-en-vez-de-panel-web.md))
  maneja la pantalla extendida de forma nativa, y esto queda como lo que no
  debe repetir.
- Rutas inconsistentes: `.htaccess` declara `RewriteBase /lyricspanel`, mientras
  `vue.config.js` y el WPF usan `/panel`.
- `npm run build` del panel usa sintaxis de Windows; en Mac hay que usar
  `npm run build-ios`.
