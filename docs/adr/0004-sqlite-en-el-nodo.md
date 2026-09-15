# ADR 0004 — SQLite en el nodo, motor completo en la nube

**Estado:** aceptada · **Fecha:** 2026-09-14

## Contexto

El nodo local corre en hardware heterogéneo: en una iglesia hay un servidor
dedicado, en otra es la misma PC que proyecta. En ninguna hay personal técnico.

## Decisión

- **Nodo local: SQLite embebido** en el proceso.
- **Nube: motor completo** (PostgreSQL).

## Razones

- Cero instalación, cero servicio que arrancar, cero contraseña, cero puerto
  abierto. Cada instalación de un servidor de base de datos en una PC de iglesia
  es una llamada de soporte futura garantizada.
- **Respaldar es copiar un archivo, y restaurar es copiarlo de vuelta.** Eso se
  le puede explicar a cualquiera por teléfono.
- La carga real es un operador y unas veinte personas con el teléfono,
  dominada por lecturas. SQLite sobra.
- La búsqueda bíblica con índice de texto completo es mejor que el `LIKE '%…%'`
  actual.

## Costo aceptado

Sin acceso remoto a la base por red —irrelevante, porque todo pasa por el
proceso del servidor— y herramientas gráficas menos familiares.

## Notas de implementación

- La Biblia va en un archivo aparte, en solo lectura: así se actualiza sin tocar
  los datos de la iglesia y el respaldo no la arrastra.
- **La base no puede quedar dentro de una carpeta sincronizada** (OneDrive,
  Drive): es corrupción garantizada. Se instala en almacenamiento local y se
  verifica la ruta al arrancar.
