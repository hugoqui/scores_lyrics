# Inventario de instalaciones

> **Sin completar.** Es la primera tarea del módulo
> [`000-seguridad`](../../specs/000-seguridad/).

## Por qué hace falta

Cada iglesia se instaló a mano y **no sabemos en qué estado está ninguna**. La
configuración versionada apunta a un MySQL remoto por IP y las variantes locales
están comentadas, así que hay instalaciones que probablemente leen la base de
datos por internet — es decir, que un corte de conexión les tumba la Biblia y el
catálogo en pleno culto.

Sin este inventario no se puede planificar la rotación de credenciales: **app y
nodos comparten la misma base de datos**, así que rotar la contraseña tumba a
todas las iglesias y a todos los músicos a la vez. Eso necesita coordinación
humana, no solo técnica.

## Qué recoger de cada iglesia

| Campo | Notas |
|---|---|
| Iglesia | Nombre y ciudad |
| Contacto técnico | Quién tiene acceso al equipo, y su teléfono |
| Dónde corre el nodo | Servidor dedicado o la misma PC de proyección |
| Sistema operativo y versión | |
| Base de datos a la que apunta | **Local o remota.** El dato clave |
| Versión del código desplegada | Commit o fecha aproximada |
| IP del nodo en la red local | |
| Instrumentos en uso | Sirve para el módulo 006 |
| Nº de músicos con la app | |
| Ventana de mantenimiento aceptable | Nunca fin de semana |

## Tabla

| Iglesia | Contacto | Nodo | SO | BD | Versión | IP | Ventana |
|---|---|---|---|---|---|---|---|
| Belén | | | | | | | |
