# Plan de Migración: Symphony App (NativeScript -> Flutter)

## 1. Configuración Inicial y Arquitectura
- [x] Inicializar proyecto Flutter.
- [x] **Estructura de Carpetas:** Crear `lib/core` para constantes y temas, y mover archivos.
- [x] **Constantes de Diseño:**
    - [x] Crear `lib/core/constants/app_colors.dart` para colores y mover `app_colors.dart`.
    - [x] Crear `lib/core/constants/app_dimensions.dart` para espaciados y tamaños y mover `app_dimensions.dart`.
    - [x] Crear `lib/core/constants/app_styles.dart` para estilos de texto y mover `app_styles.dart`.
- [x] **Temas:** Crear `lib/core/theme/app_theme.dart` para definir `ThemeData` (Light/Dark) y mover `app_theme.dart`.
- [x] **Manejo de estados:** Configurar `Riverpod` en `main.dart`.
- [x] **Inyección de dependencias:** Configurar `GetIt` en `lib/core/di/service_locator.dart`.
- [ ] **Soporte de UI:** Configurar `SystemChrome` para pantalla completa (se abordará en el punto 4).

## 1.1. Migración de Datos Legados (NativeScript -> Flutter)
- [x] **Análisis de Rutas:** Confirmado que `path_provider` accede al mismo sandbox.
- [x] **Migración de SharedPreferences/UserDefaults:** Implementado en `MigrationService`.
- [ ] **Script de Primer Inicio:** Crear un servicio que verifique si existen archivos antiguos y los indexe en la nueva base de datos local si es necesario.

## 2. Capa de Datos y Servicios Core
- [ ] **Cliente HTTP (Dio):** Implementar interceptores para JWT y manejo de errores.
- [ ] **Local Storage:** Implementar `shared_preferences` (para settings) y `path_provider` (para archivos de partituras).
- [ ] **Servicio de Instrumentos:** Migrar lógica de `InstrumentsService`.
- [ ] **Capa de Abstracción de Partituras (ScoreRepository):** Crear una interfaz para la obtención y descarga de partituras.
    - [ ] **Implementación actual:** Replicar la lógica de `ScoresDownloaderService` para obtener la lista de cantos (actualmente desde un JSON) y URLs de descarga (actualmente parseando HTML).
    - [ ] Lógica de descarga de binarios (PNG/MP3).
    - [ ] Gestión de carpetas por instrumento.
    - [ ] Mapeo de tonalidades (Chords) desde la API.
    - [ ] **Nota:** Esta implementación será reemplazada cuando el backend mejore, pero la interfaz del `ScoreRepository` debe permanecer estable.

## 3. Autenticación y Seguridad
- [ ] Migrar flujo de Login (Email/User, Password en texto plano, DeviceID).
- [ ] Persistencia de Token JWT.
- [ ] Lógica de validación de dispositivo único.

## 4. Funcionalidades de Partituras (Score)
- [ ] **Visor de Imágenes:** Implementar visor con zoom (PhotoView).
- [ ] **Lógica de Archivos:**
    - [ ] Swapping entre Melodía (`song.png`) y Arreglo (`song_instrument.png`).
    - [ ] Fallbacks de archivos no encontrados.
- [ ] **Lógica por instrumento:** Ocultar switch de partitura para Piano y Trompeta (heredado de `shouldShowScoreSwitch`).
- [ ] **Gestos:** Implementar Swipe horizontal para navegar entre canciones de la lista.
- [ ] **Modo Inmersivo:** Implementar "Immersive Sticky" (Android) y Fade (iOS) al tocar la pantalla.

## 5. Audio y Reproducción
- [ ] **Reproductor de Audio (just_audio):**
    - [ ] Streaming desde URL y manejo de caché.
    - [ ] Toggle entre audio de "Arreglo" y "Melodía" (Canto base).
    - [ ] Indicadores de carga (Loading states).
- [ ] **Grabadora (record):**
    - [ ] Grabación en formato M4A.
    - [ ] Funciones de Pausa, Reanudación y Detención.
    - [ ] Integración con `share_plus` para compartir el archivo grabado.

## 6. Sincronización en Vivo (Live)
- [ ] **Socket.io Client:** Implementar conexión persistente.
- [ ] **Eventos:**
    - [ ] Escuchar `listChange` para actualizar lista de adoración.
    - [ ] **Navegación automática:** Actualizar `currentSong` y `scorePath` mediante `effect` reactivo al recibir cambio del socket.
- [ ] **Manejo de Estado de Conexión:** Offline, Online, Reconnecting.

## 7. Gestión de Listas (My Lists)
- [ ] CRUD de listas locales.
- [ ] Persistencia de canciones seleccionadas por lista.
- [ ] Filtrado por tonalidad (C, Eb, F, G, Bb, etc.).

## 8. UI/UX Mejorado
- [ ] Rediseñar la navegación (GoRouter).
- [ ] Modal de búsqueda global (SearchModal).
- [ ] Feedback visual (Snackbars, Activity Indicators).

## 9. Pruebas y Despliegue
- [ ] Pruebas unitarias de servicios de lógica de nombres de archivos.
- [ ] Configuración de permisos (Micrófono, Almacenamiento, Internet).
- [ ] Build para Android (App Bundle).
- [ ] Build para iOS.

## Notas Críticas de Lógica
*   **Nomenclatura:** Mantener la lógica de `_instrument.png` para no romper la compatibilidad con el servidor actual.
*   **Performance:** El visor de imágenes debe manejar archivos grandes sin lag.
*   **Offline First:** Asegurar que si el archivo está descargado, no intente usar red.
*   **Continuidad:** Es obligatorio mantener el mismo Bundle ID / Package Name para que el SO no borre los archivos antiguos al actualizar.
*   **Seguridad:** El backend aplica `SHA1` al password recibido; Flutter debe enviar el password en texto plano.
