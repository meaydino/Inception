# DEV_DOC — Developer Documentation

## Setting Up the Environment from Scratch

### Prerequisites

- OS: Linux (project requires a virtual machine per subject rules)
- Docker Engine installed (`docker --version`)
- Docker Compose v2+ installed (`docker compose version`)
- `make` installed
- `openssl` installed (for TLS certificate generation)

### Configuration Files

| File | Purpose |
|---|---|
| `Inception/srcs/.env` | Environment variables (domain, DB name, DB user) |
| `Inception/secrets/credentials.txt` | WordPress admin credentials |
| `Inception/secrets/wp_user_credentials.txt` | WordPress editor credentials |
| `Inception/secrets/db_password.txt` | DB user password |
| `Inception/secrets/db_root_password.txt` | DB root password |

### Setting Up Secrets

Create the `secrets/` files with your own values:

```bash
# Admin user (must NOT contain "admin" or "administrator")
echo "meaydino_wp" > Inception/secrets/credentials.txt
echo "MyAdminPass42!" >> Inception/secrets/credentials.txt

# Editor user
echo "wp_editor" > Inception/secrets/wp_user_credentials.txt
echo "Editor@Inception42!" >> Inception/secrets/wp_user_credentials.txt

# Database passwords
echo "DbUserPass42!" > Inception/secrets/db_password.txt
echo "DbRootPass42!" > Inception/secrets/db_root_password.txt
```

### .env Setup

The `Inception/srcs/.env` file should look like:

```env
DOMAIN_NAME=meaydino.42.fr
MYSQL_DATABASE=wordpress
MYSQL_USER=wp_user
```

### Add Domain to /etc/hosts

```bash
echo "127.0.0.1 meaydino.42.fr" | sudo tee -a /etc/hosts
```

---

## Building and Launching with Makefile and Docker Compose

```bash
cd Inception

# Build all images and start containers (foreground build, detached run)
make all

# Build images only (without starting)
make build

# Stop containers (preserve volumes)
make down

# Full reset: stop, remove volumes, recreate
make re

# Remove images and volumes
make clean
```

The Makefile calls:
```
docker compose -f ./srcs/docker-compose.yml up -d --build
```

---

## Useful Container Management Commands

```bash
# View running containers
docker ps

# Follow logs for a specific container
docker logs -f nginx
docker logs -f wordpress
docker logs -f mariadb

# Execute a shell inside a container (debug)
docker exec -it nginx sh
docker exec -it wordpress sh
docker exec -it mariadb sh

# Connect to MariaDB directly
docker exec -it mariadb mariadb -u root -p

# List Docker volumes
docker volume ls

# Inspect a volume
docker volume inspect inception_wordpress_volume
docker volume inspect inception_mariadb_volume

# List Docker networks
docker network ls
docker network inspect inception_inception_net
```

---

## Where Data Is Stored and How It Persists

### Host Machine Paths

| Volume | Host Path | Container Path |
|---|---|---|
| `wordpress_volume` | `/home/meaydino/data/wordpress` | `/var/www/html` |
| `mariadb_volume` | `/home/meaydino/data/mariadb` | `/var/lib/mysql` |

These are **Docker named volumes** using `driver: local` with `type: none` and `o: bind`, effectively mounting the host directories into the containers.

### Data Persistence

- Data persists across `make down` / `make all` cycles.
- `make re` and `make clean` **delete** `/home/meaydino/data/` and remove volumes — **all WordPress content and the database are lost**.
- The MariaDB initialization script runs only when `/var/lib/mysql/mysql` does not exist (i.e., on first boot or after a full reset).

### TLS Certificate

The SSL certificate is generated automatically by the NGINX entrypoint using `openssl` and stored inside the container at `/etc/nginx/ssl/`. It is regenerated on each container start if not present.

---

## Directory Structure

```
inception/                        ← Git repository root
├── .gitignore
├── README.md
├── USER_DOC.md
├── DEV_DOC.md
└── Inception/
    ├── Makefile
    ├── secrets/                  ← NOT committed to git
    │   ├── credentials.txt
    │   ├── wp_user_credentials.txt
    │   ├── db_password.txt
    │   └── db_root_password.txt
    └── srcs/
        ├── .env                  ← NOT committed to git
        ├── docker-compose.yml
        └── requirements/
            ├── nginx/
            │   ├── Dockerfile
            │   ├── conf/nginx.conf
            │   └── tools/entrypoint.sh
            ├── mariadb/
            │   ├── Dockerfile
            │   ├── conf/mariadb.cnf
            │   └── tools/entrypoint.sh
            └── wordpress/
                ├── Dockerfile
                └── tools/entrypoint.sh
```
