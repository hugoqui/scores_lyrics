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
    - [x] **Implementación actual:** Replicar la lógica de `ScoresDownloaderService` para obtener la lista de cantos.
    - [x] Lógica de descarga de binarios (PNG/MP3).
    - [x] Gestión de carpetas por instrumento.
    - [x] Mapeo de tonalidades (Chords) desde la API.
    - [x] **Lógica de agrupación local (PracticeProvider):** Implementar escaneo de archivos para identificar pares Melodía/Arreglo basado en el sufijo del instrumento.
    - [x] **Nota:** Esta implementación será reemplazada cuando el backend mejore, pero la interfaz del `ScoreRepository` debe permanecer estable.

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
    - [x] **Ajustes:** (Cambiar host, cerrar sesión).
- [x] **Diseño Responsivo:** Ajustar `GridView` para adaptarse a diferentes orientaciones y tamaños de pantalla.

## 4. Funcionalidades de Partituras (Módulo Reutilizable)
- [x] **4.1 Visor de Partituras (ScoreScreen):**
    - [x] Implementar `ScoreImageView` usando `photo_view` para zoom fluido.
    - [x] Lógica de Swapping Melodía/Arreglo: Detectar presencia de archivo `_instrumento.png`.
    - [x] Ocultar toggle de arreglo para instrumentos que no lo requieren (Piano, Trompeta).
    - [x] Soporte para Swipe horizontal entre una lista de partituras (PageController).
    - [x] Modo Inmersivo: Ocultar AppBar y controles al hacer tap en la partitura.
    - [x] **Floating Player Card:** Diseño minimalista con desenfoque y controles unificados.
    - [x] **Ajuste de Responsividad:** Implementar `maxWidth` para el reproductor en modo horizontal/tablets.
    - [x] **Lógica de Interfaz de Audio:** 
        *   Si Score == Melodía: Bloquear switch de audio (Solo Melodía).
        *   Si Score == Arreglo: Permitir switch entre audio Melodía y Arreglo.

## 5. Práctica y Biblioteca Local
- [x] **5.1 Flujo de Selección:**
    - [x] Reutilizar `InstrumentGrid` para filtrar por instrumento.
    - [x] `PracticeLibraryScreen`: Listar solo archivos base (melodía) descargados.
    - [x] Buscador local para filtrar canciones en el teléfono.
    - [x] **Filtrado por Tonalidad:** Chips de selección (C, Eb, F, G, Bb) y Avatars visuales.
    - [x] Al seleccionar, navegar a `ScoreScreen` pasando la lista filtrada.

## 6. Audio y Reproducción (Práctica)
- [x] **6.1 Motor de Audio (`just_audio`):**
    - [x] Streaming desde URL y lógica de Hot-Swap sincronizada.
    - [x] **Control de Velocidad:** Implementado cambio de speed (0.5x a 1.5x).
    - [x] **Modo Loop:** Repetición de track infinito.
    - [x] **Barra de Progreso (Seek):** Slider interactivo con visualización de tiempo.
    - [x] Manejo de estados de carga (Buffering/Loading).
- [ ] **6.2 Grabadora de Práctica (`record`):**
    - [ ] **Postergado:** Funcionalidad de grabación no requerida para esta fase.

## 6. Sincronización en Vivo (Live) - COMPLETADO
- [x] **Socket.io Client:** Implementado en `SocketService`.
- [x] **Eventos:**
    - [x] Escuchar `text_change` para navegación automática.
    - [x] Escuchar `listChange` para actualizar lista de sesión.
    - [x] **Carga Inicial:** Peticiones HTTP a `lastSong` y `songList` al conectar.
- [x] **Interfaz LiveScreen:**
    - [x] PageView para navegación entre cantos.
    - [x] Buscador avanzado con filtrado por tonalidad (Chord Avatars).
    - [x] Persistencia de Host e Instrumento sugerido.
- [x] **Manejo de Estado de Conexión:** Indicador visual (punto de color) y auto-desconexión al salir.

## 7. Gestión de Listas (My Lists)
- [x] **CRUD de listas locales:** Con acciones de swipe (Editar/Eliminar) estilo WhatsApp.
- [x] **Persistencia:** Guardado local mediante SharedPreferences.
- [x] **Filtrado por tonalidad:** Buscador integrado con selección de nota y Avatars.

## 8. UI/UX Mejorado
- [x] Rediseñar la navegación (GoRouter).
- [x] Modal de búsqueda global (Opcional).
- [ ] Feedback visual (Snackbars, Activity Indicators).

## 10. Sistema de Anotaciones (Notas)
- [x] **Capa de Dibujo:** Implementar un `CustomPainter` sobre el visor de partituras.
- [x] **Persistencia:** Guardar trazos por canción e instrumento en `SharedPreferences`.
- [x] **Herramientas:** Menú flotante con selección de colores, borrador y toggle de visibilidad.
- [ ] **Sincronización de Zoom:** Asegurar que las notas se escalen y desplacen junto con la partitura.

## 11. Reproductor y Herramientas Camaleónicas (Orientación)
- [x] **Paso 1: Refactorización de FloatingPlayerCard**
    - [x] Implementar detección de orientación.
    - [x] Crear Layout Vertical (Column) para modo Landscape.
    - [x] Implementar Barra de Progreso Vertical (`RotatedBox`).
    - [x] Adaptar etiquetas de texto a versiones cortas (ej: "Mel.", "Arr.").
 - [x] **Paso 2: Reposicionamiento Dinámico en ScoreImageView**
    - [x] Mover `AnnotationToolbar` (Lápiz) a la izquierda en Landscape.
    - [x] Integrar `FloatingPlayerCard` en el Stack lateral derecho en Landscape.
- [ ] **Paso 3: Sincronización y Pruebas**
    - [ ] Verificar que el audio no se interrumpa al girar el dispositivo.

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
