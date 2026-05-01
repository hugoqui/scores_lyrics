# Plan de Implementación: Compartir Listas vía QR

## Formato del QR
```json
{"v":1,"n":"Lista Domingo","s":["Canto A","Canto B","Canto C"]}
```
- `v` → versión del schema
- `n` → nombre de la lista
- `s` → array de títulos (el instrumento lo elige el receptor al importar)

---

## Tarea 1 — Instalar dependencia de generación de QR ✅
- [x] Agregar `qr_flutter` al `pubspec.yaml`
- [x] Correr `flutter pub get`
- [x] Verificar que la app compila y corre sin errores

## Tarea 2 — Botón "Compartir" y visualización del QR (emisor) ✅
- [x] Agregar ícono de compartir en el AppBar de `MyListDetailScreen`
- [x] Serializar la lista al formato JSON compacto `{"v":1,"n":...,"s":[...]}`
- [x] Mostrar un dialog/bottom sheet con el QR generado y el nombre de la lista

## Tarea 3 — Instalar dependencia de escaneo de QR ✅
- [x] Agregar `mobile_scanner` al `pubspec.yaml`
- [x] Configurar permisos de cámara en Android (`AndroidManifest.xml`) e iOS (`Info.plist`)
- [x] Correr `flutter pub get`
- [x] Verificar que la app compila y corre sin errores

## Tarea 4 — Escaneo e importación (receptor)
- [x] Agregar botón "Escanear QR" en `MyListsScreen`
- [x] Crear pantalla de cámara con `mobile_scanner`
- [x] Al detectar QR válido: mostrar dialog con nombre, cantidad de cantos y selector de instrumento
- [x] Permitir editar el título de la lista en el modal antes de confirmar
- [x] Al confirmar: crear la lista llamando a `createList` + `addSongsToList`

## Tarea 5 — Manejo de errores y casos borde
- [x] QR inválido o formato desconocido → snackbar de error
- [x] Nombre de lista duplicado → agregar sufijo " (importada)" automáticamente
- [x] Cantos no descargados → se omiten con aviso; si ninguno existe, no se importa la lista
