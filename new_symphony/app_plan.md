# Plan de Migración: Symphony App (NativeScript -> Flutter)

## 1. Configuración Inicial y Arquitectura
- [x] Inicializar proyecto Flutter (Arquitectura por funcionalidad/core).
- [x] Configurar manejo de estados (Riverpod configurado en `main.dart`).
- [x] Configurar temas (Dark/Light centralizados en `AppTheme`).
- [x] Configurar inyección de dependencias (GetIt configurado en `service_locator.dart`).

## 1.1. Migración de Datos Legados (NativeScript -> Flutter)
- [x] **Análisis de Rutas:** Verificado uso de `path_provider`.
- [x] **Migración de SharedPreferences/UserDefaults:** Implementado en `MigrationService`.
- [x] **Script de Primer Inicio:** Lógica de migración integrada en el constructor de `ScoreRepository`.

## 2. Capa de Datos y Servicios Core
- [x] **Cliente HTTP (Dio):** Configurado con interceptores para host dinámico y JWT.
- [x] **Local Storage:** Implementado con `shared_preferences` y registrado en el locator.
- [x] **Servicio de Instrumentos:** Migrado a `InstrumentsService`.
- [x] **Capa de Abstracción de Partituras (ScoreRepository):** Estructura base y persistencia local creadas.
    - [ ] **Implementación actual:** Replicar la lógica de `ScoresDownloaderService` para obtener la lista de cantos (actualmente desde un JSON) y URLs de descarga (actualmente parseando HTML).
    - [ ] Lógica de descarga de binarios (PNG/MP3).
    - [ ] Gestión de carpetas por instrumento.
    - [ ] Mapeo de tonalidades (Chords) desde la API.
    - [ ] **Nota:** Esta implementación será reemplazada cuando el backend mejore, pero la interfaz del `ScoreRepository` debe permanecer estable.

## 3. Autenticación y Seguridad
- [x] Migrar flujo de Login (Email/User, Password en texto plano, DeviceID).
- [x] Persistencia de Token JWT.
- [x] Persistencia de credenciales (email/password) para "recordarme".
- [x] Implementar Pantalla de Login y manejo de estado (Riverpod).

## 3.1. Pantalla de Inicio (Menu Principal)
- [x] Crear `HomeScreen` con acceso a las 4 áreas principales:
    - [ ] **Sincronización en Vivo:** (Conexión al Socket).
    - [ ] **Explorar/Descargar:** (Navegar por instrumentos y bajar partituras).
    - [ ] **Mis Listas:** (Práctica personal y carpetas locales).
    - [ ] **Ajustes:** (Cambiar host, cerrar sesión).
- [x] **Diseño Responsivo:** Ajustar `GridView` para adaptarse a diferentes orientaciones y tamaños de pantalla.

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
