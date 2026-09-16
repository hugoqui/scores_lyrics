# Base de datos de la nube (PostgreSQL en el VPS)

Procedimiento para crear la base de `Symphony.Cloud` en el VPS y aplicar las
migraciones por primera vez (spec R2, [ADR 0010](../adr/0010-migraciones-sql-planas.md)).
**Ningún paso aquí incluye contraseñas reales.**

## 1. Instalar PostgreSQL

El VPS es Ubuntu. Si `psql --version` no existe:

```bash
sudo apt update && sudo apt install -y postgresql
```

## 2. Crear el usuario y la base

Genera una contraseña fuerte y guárdala en un `.env` propio del servidor
(por ejemplo `/etc/symphony/.env`, con `chmod 600`), **nunca en el repositorio**:

```bash
openssl rand -base64 24
```

Entra a la consola de Postgres y crea el rol y la base con esa contraseña:

```bash
sudo -u postgres psql
```

```sql
CREATE USER symphony_cloud WITH PASSWORD '...';
CREATE DATABASE symphony_cloud OWNER symphony_cloud;
```

## 3. Verificar que no es alcanzable desde internet (000-seguridad R3)

Postgres debe escuchar solo en loopback:

```bash
sudo ss -ltnp | grep 5432
```

Debe mostrar `127.0.0.1:5432` y `[::1]:5432`, nunca `0.0.0.0` ni la IP pública.
Además, el firewall no debe tener el puerto abierto:

```bash
sudo ufw status
```

`5432` no debe aparecer en la lista.

## 4. Aplicar las migraciones

El VPS puede no tener el SDK de .NET, solo el runtime. En vez de instalar el
SDK en un servidor con otras aplicaciones corriendo, se compila
`Symphony.Cloud` en otra máquina y se copia ya compilado:

```bash
# En la máquina de desarrollo
dotnet publish services/cloud-api/src/Symphony.Cloud/Symphony.Cloud.csproj \
  -c Release -o ./publish-cloud --self-contained false

# Copiar al VPS
rsync -avz --delete ./publish-cloud/ root@<vps>:/opt/symphony/cloud/
```

En el VPS, con la contraseña ya en `/etc/symphony/.env`:

```bash
set -a; source /etc/symphony/.env; set +a
export SYMPHONY_CLOUD_POSTGRES_CONNECTION_STRING="Host=127.0.0.1;Port=5432;Database=symphony_cloud;Username=symphony_cloud;Password=${SYMPHONY_CLOUD_POSTGRES_PASSWORD}"
export ASPNETCORE_ENVIRONMENT=Production
cd /opt/symphony/cloud && dotnet Symphony.Cloud.dll migrar
```

Verificar lo aplicado:

```bash
sudo -u postgres psql -d symphony_cloud -c \
  "SELECT numero, nombre, aplicada_en FROM migraciones_aplicadas;"
```

## Notas

- La base MySQL del sistema legacy no tiene relación con esta base y no debe
  aparecer en ninguna cadena de conexión de `Symphony.Cloud` ni `Symphony.Node`.
- Cada migración nueva (`0002_...sql`, etc.) se aplica repitiendo el paso 4:
  compilar, copiar, correr `migrar`. El ejecutor es idempotente — no rompe
  nada si se corre de más.
