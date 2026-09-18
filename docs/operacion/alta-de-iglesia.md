# Alta de una iglesia

Cómo crear una iglesia y su primer administrador sin panel (spec R9 de
[002-identidad-de-iglesia](../../specs/002-identidad-de-iglesia/spec.md)). El
panel llega en [003-panel-saas](../../specs/003-panel-saas/); esto es lo que
existe mientras tanto, y sigue sirviendo después para levantar un entorno de
pruebas desde cero. **Ningún paso de aquí crea una contraseña por defecto ni
una cuenta de fábrica**: la credencial inicial se da en el momento del alta.

## Requisitos

- Las migraciones de la nube ya aplicadas (`dotnet run -- migrar`, o el
  arranque normal del servicio, que las aplica solo).
- La variable `SYMPHONY_CLOUD_POSTGRES_PROPIETARIO_CONNECTION_STRING` fijada:
  el comando usa el rol `symphony_propietario`
  ([por qué](roles-de-base-de-datos.md#qué-caminos-pueden-usar-el-rol-del-propietario)).

## Comando

Desde `services/cloud-api/src/Symphony.Cloud`:

```bash
echo "la-contraseña-del-administrador" | dotnet run -- crear-iglesia \
    "Nombre de la iglesia" correo@de-la-iglesia.example "Nombre del administrador"
```

La contraseña se lee de la entrada estándar, nunca de un argumento: un
argumento queda en el historial de la terminal y en la lista de procesos del
sistema. Escrita a mano en vez de con `echo`, funciona igual: se escribe y se
pulsa enter.

## Qué queda hecho

- Una fila en `iglesia`, activa, con identificador propio (UUIDv7).
- Un usuario en esa iglesia con el rol `administrador`, con la contraseña que
  se le dio, guardada con Argon2id y sal propia
  ([ADR 0016](../adr/0016-sesion-firmada-verificable-sin-internet.md)).

El comando termina imprimiendo el identificador de la iglesia y la variable
lista para pegar en el `.env` del nodo de esa iglesia:

```
SYMPHONY_NODE_IGLESIA_ID=<el identificador impreso>
```

## Lo que falta para que el nodo arranque

Este comando solo resuelve la identidad de la iglesia. El nodo además necesita
su par de claves de firma y la clave pública de la nube — eso se genera aparte,
con `dotnet run -- generar-claves` en cada lado
([claves-de-firma.md](claves-de-firma.md)) — y las variables de conexión y ruta
de `NodeOptions` que documentará
[009-nodo-empaquetado](../../specs/009-nodo-empaquetado/).
