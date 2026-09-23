# DEV_DOC — Developer & Architecture Documentation

This document serves as the complete technical specification and developer manual for the **Inception** infrastructure project. It details the architecture, component lifecycles, configuration schemas, entrypoint routines, storage subsystems, and operational playbooks required to maintain, debug, or modify the system.

---

## Table of Contents
1. [Development Environment Setup](#1-development-environment-setup)
2. [Repository Directory Structure](#2-repository-directory-structure)
3. [Configuration Files & Secrets Specification](#3-configuration-files--secrets-specification)
4. [Docker Compose & Container Architecture](#4-docker-compose--container-architecture)
5. [Dockerfiles & Build Mechanisms](#5-dockerfiles--build-mechanisms)
6. [Entrypoint Scripts & Process Lifecycle (PID 1)](#6-entrypoint-scripts--process-lifecycle-pid-1)
7. [Networking & Internal DNS Resolution](#7-networking--internal-dns-resolution)
8. [Storage Architecture & Data Persistence](#8-storage-architecture--data-persistence)
9. [SSL/TLS Cryptographic Implementation](#9-ssltls-cryptographic-implementation)
10. [Developer Maintenance Playbooks & Evaluation Guides](#10-developer-maintenance-playbooks--evaluation-guides)
11. [Troubleshooting & Diagnostic Guide](#11-troubleshooting--diagnostic-guide)

---

## 1. Development Environment Setup

### Prerequisites
The project must run in an isolated Linux environment (e.g. Debian, Ubuntu, or Alpine VM).
- **Linux Kernel:** 5.10+
- **Docker Engine:** Version 24.0.0 or higher
- **Docker Compose:** Version 2.20.0 or higher (V2 plugin: `docker compose`)
- **GNU Make:** 4.3+
- **OpenSSL:** 3.0+
- **Host User Account:** Sudoer privileges for managing `/home/meaydino/data/` volume directories.

### Setup Commands
```bash
# 1. Update package list and install prerequisites
sudo apt-get update
sudo apt-get install -y make curl openssl ca-certificates gnupg

# 2. Add local domain to host /etc/hosts
echo "127.0.0.1 meaydino.42.fr" | sudo tee -a /etc/hosts

# 3. Verify Docker Engine & Compose installation
docker --version
docker compose version
```

---

## 2. Repository Directory Structure

```
.
├── Makefile                                # Top-level build orchestration Makefile
├── README.md                               # Project overview, requirements, resources, AI usage
├── USER_DOC.md                             # End-user and administrator manual
├── DEV_DOC.md                              # Technical specifications and developer documentation
├── secrets/                                # Sensitive authentication data (Docker Secrets)
│   ├── wp_admin_password.txt               # WordPress Administrator password
│   ├── wp_user_password.txt                # WordPress Editor user password
│   ├── db_password.txt                     # WordPress MySQL user password
│   └── db_root_password.txt                # MariaDB root database password
└── srcs/
    ├── .env                                # Non-sensitive environment variables
    ├── docker-compose.yml                  # Multi-container service definition & topology
    └── requirements/
        ├── nginx/                          # NGINX reverse proxy service
        │   ├── Dockerfile                  # Custom Debian-based image build file
        │   ├── conf/
        │   │   └── nginx.conf              # TLSv1.2/v1.3 reverse proxy configuration
        │   └── tools/
        │       └── entrypoint.sh           # Certificate generator & NGINX starter
        ├── mariadb/                        # MariaDB SQL database service
        │   ├── Dockerfile                  # Custom Debian-based image build file
        │   ├── conf/
        │   │   └── mariadb.cnf             # MySQL server socket & network bindings
        │   └── tools/
        │       └── entrypoint.sh           # MariaDB bootstrap & user initialization script
        └── wordpress/                      # WordPress application service
            ├── Dockerfile                  # Custom Debian-based image build file (PHP-FPM)
            └── tools/
                └── entrypoint.sh           # WP-CLI download, auto-install, and PHP-FPM launcher
```

---

## 3. Configuration Files & Secrets Specification

### 3.1 Non-Sensitive Variables (`srcs/.env`)
The `.env` file contains non-sensitive deployment parameters injected into `docker-compose.yml`:
```env
DOMAIN_NAME=meaydino.42.fr
MYSQL_DATABASE=wordpress
MYSQL_USER=wp_user
WP_TITLE=Inception
WP_ADMIN_USER=meaydino
WP_ADMIN_EMAIL=meaydino@student.42.fr
WP_USER=wp_editor
WP_USER_EMAIL=wp_editor@student.42.fr
```

### 3.2 Secrets Management (`secrets/`)
Docker Secrets decouple sensitive credentials from environment variables. They are mounted as read-only files in an in-memory `tmpfs` volume at `/run/secrets/<name>` inside authorized containers.

| Secret Name | Source File | Consuming Services | Expected File Structure |
|---|---|---|---|
| `wp_admin_password` | `secrets/wp_admin_password.txt` | `wordpress` | Single Line: WordPress Admin password |
| `wp_user_password` | `secrets/wp_user_password.txt` | `wordpress` | Single Line: WordPress Editor password |
| `db_password` | `secrets/db_password.txt` | `wordpress`, `mariadb` | Single Line: `<database_user_password>` |
| `db_root_password` | `secrets/db_root_password.txt` | `wordpress`, `mariadb` | Single Line: `<database_root_password>` |

---

## 4. Docker Compose & Container Architecture

The `srcs/docker-compose.yml` orchestrates three services adhering to the following rules:
- **No `network: host` or `links:`** directives are used.
- **Dedicated Bridge Network (`inception_net`):** Enforces network namespace isolation.
- **Named Volumes with Host Bindings:** Maps container directories to `/home/meaydino/data/`.
- **Port Mapping:** Exclusively exposes port `443` on `nginx`.

```yaml
services:
  nginx:
    build: ./requirements/nginx
    image: nginx
    container_name: nginx
    restart: always
    ports:
      - "443:443"
    volumes:
      - wordpress_volume:/var/www/html
    depends_on:
      - wordpress
    networks:
      - inception_net

  wordpress:
    build: ./requirements/wordpress
    image: wordpress
    container_name: wordpress
    restart: always
    volumes:
      - wordpress_volume:/var/www/html
    environment:
      - DOMAIN_NAME=${DOMAIN_NAME}
      - MYSQL_DATABASE=${MYSQL_DATABASE}
      - MYSQL_USER=${MYSQL_USER}
      - WP_TITLE=${WP_TITLE}
      - WP_ADMIN_USER=${WP_ADMIN_USER}
      - WP_ADMIN_EMAIL=${WP_ADMIN_EMAIL}
      - WP_USER=${WP_USER}
      - WP_USER_EMAIL=${WP_USER_EMAIL}
    secrets:
      - db_password
      - db_root_password
      - wp_admin_password
      - wp_user_password
    depends_on:
      - mariadb
    networks:
      - inception_net

  mariadb:
    build: ./requirements/mariadb
    image: mariadb
    container_name: mariadb
    restart: always
    volumes:
      - mariadb_volume:/var/lib/mysql
    environment:
      - MYSQL_DATABASE=${MYSQL_DATABASE}
      - MYSQL_USER=${MYSQL_USER}
    secrets:
      - db_password
      - db_root_password
    networks:
      - inception_net

networks:
  inception_net:
    driver: bridge

volumes:
  wordpress_volume:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /home/meaydino/data/wordpress

  mariadb_volume:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /home/meaydino/data/mariadb

secrets:
  db_password:
    file: ../secrets/db_password.txt
  db_root_password:
    file: ../secrets/db_root_password.txt
  wp_admin_password:
    file: ../secrets/wp_admin_password.txt
  wp_user_password:
    file: ../secrets/wp_user_password.txt
```

---

## 5. Dockerfiles & Build Mechanisms

All Dockerfiles follow strict 42 rules:
1. Built from **Debian Bookworm** (`FROM debian:bookworm`).
2. Do not use generic pre-built application images from DockerHub.
3. Keep container sizes minimal using `--no-install-recommends` and cleaning `/var/lib/apt/lists/*`.
4. Run without infinite sleeping loops (`tail -f`, `sleep infinity`).

### 5.1 NGINX Dockerfile
- Installs `nginx` and `openssl`.
- Creates `/etc/nginx/ssl` directory for certificates.
- Copies custom reverse proxy configuration to `/etc/nginx/conf.d/default.conf`.
- Exposes port `443`.
- Entrypoint triggers TLS generation and executes NGINX in foreground mode.

### 5.2 MariaDB Dockerfile
- Installs `mariadb-server` and `mariadb-client`.
- Prepares runtime directory `/run/mysqld` with correct `mysql:mysql` ownership.
- Copies custom server configuration `conf/mariadb.cnf` binding to `0.0.0.0:3306`.
- Exposes port `3306`.

### 5.3 WordPress Dockerfile
- Installs `php-fpm`, `php-mysql`, `php-cli`, `php-gd`, `php-curl`, `php-xml`, `php-mbstring`, `mariadb-client`, `wget`.
- Updates `listen` directive in `/etc/php/8.2/fpm/pool.d/www.conf` to `0.0.0.0:9000`.
- Downloads and installs the `wp-cli` binary to `/usr/local/bin/wp`.
- Exposes port `9000`.

---

## 6. Entrypoint Scripts & Process Lifecycle (PID 1)

In containerized environments, the main process inside the container runs as **PID 1**. If PID 1 terminates, the container exits. All entrypoint scripts utilize `exec` to replace the shell process with the target daemon.

### 6.1 NGINX Entrypoint (`nginx/tools/entrypoint.sh`)
```sh
#!/bin/sh
if [ ! -f /etc/nginx/ssl/inception.crt ]; then
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout /etc/nginx/ssl/inception.key \
        -out /etc/nginx/ssl/inception.crt \
        -subj "/C=TR/ST=Kocaeli/L=Gebze/O=42/OU=42Kocaeli/CN=meaydino.42.fr"
fi
exec nginx -g "daemon off;"
```
* Generates an X.509 RSA 2048-bit self-signed certificate if one does not already exist.
* Launches NGINX in foreground mode (`daemon off;`) replacing the shell as PID 1.

### 6.2 MariaDB Entrypoint (`mariadb/tools/entrypoint.sh`)
1. Reads passwords securely from `/run/secrets/db_root_password` and `/run/secrets/db_password`.
2. If `/var/lib/mysql/mysql` system table does not exist:
   - Runs `mariadb-install-db` to initialize the data directory.
   - Executes `mysqld --bootstrap` to apply initial SQL setup non-interactively (creating databases, users, grants).
3. Re-applies grants idempotently to guarantee compatibility across volume restarts.
4. Executes `exec mysqld --user=mysql` as PID 1.

### 6.3 WordPress Entrypoint (`wordpress/tools/entrypoint.sh`)
1. Checks if `/var/www/html/wp-config.php` exists.
2. If first boot:
   - Downloads WordPress core files via `wp core download --allow-root`.
   - Polls MariaDB readiness using `mariadb-admin ping` in a non-blocking loop.
   - Generates `wp-config.php` with database credentials via `wp config create`.
   - Runs `wp core install` to initialize database tables, setting the admin user to `meaydino`.
   - Configures comment moderation options (`comment_moderation 1`, `comment_previously_approved 0`).
   - Creates a second user with the `editor` role (`wp_editor`).
3. Executes `exec php-fpm8.2 -F` in foreground mode.

---

## 7. Networking & Internal DNS Resolution

Docker Compose automatically creates the user-defined bridge network `inception_net` (Subnet: `172.x.x.x/16` or similar).

```
 ┌────────────────────────────────────────────────────────┐
 │               INCEPTION_NET (Docker Bridge)            │
 │                                                        │
 │   ┌───────────┐         ┌───────────┐   ┌───────────┐  │
 │   │   nginx   ├────────►│ wordpress ├──►│  mariadb  │  │
 │   │ (443:443) │  :9000  │  (:9000)  │   │  (:3306)  │  │
 │   └───────────┘ FastCGI └───────────┘SQL└───────────┘  │
 └────────────────────────────────────────────────────────┘
```

* **Embedded Docker DNS Server (`127.0.0.11`):** Resolves container hostnames (`mariadb`, `wordpress`, `nginx`) to their respective container IP addresses within the network.
* **FastCGI Communication:** NGINX forwards all PHP requests via `fastcgi_pass wordpress:9000;`.
* **Database Communication:** WordPress connects to `mariadb:3306`.

---

## 8. Storage Architecture & Data Persistence

### Host Mapping Specification
Persistent storage is implemented via Docker Named Volumes configured with `driver: local`, `type: none`, and `o: bind`.

| Named Volume | Host Directory Path | Container Mount Point | Stored Assets |
|---|---|---|---|
| `wordpress_volume` | `/home/meaydino/data/wordpress` | `/var/www/html` | WordPress core, plugins, themes, uploads |
| `mariadb_volume` | `/home/meaydino/data/mariadb` | `/var/lib/mysql` | InnoDB tablespaces, system databases, logs |

### Persistence Lifecycle Behavior
* **`make down` / `make all`:** Data remains intact in `/home/meaydino/data/`. When containers start, entrypoints detect existing configuration files and skip re-initialization.
* **VM Reboot:** Once Docker daemon restarts and `make all` is run, existing tables and media are loaded immediately.
* **`make fclean`:** Explicitly removes containers, images, volume definitions, and executes `sudo rm -rf /home/meaydino/data/*`.

---

## 9. SSL/TLS Cryptographic Implementation

The NGINX configuration strictly enforces modern cryptographic protocols:

```nginx
ssl_protocols TLSv1.2 TLSv1.3;
ssl_certificate /etc/nginx/ssl/inception.crt;
ssl_certificate_key /etc/nginx/ssl/inception.key;
```

### Verification via OpenSSL CLI:
```bash
# Verify TLSv1.2 handshake:
openssl s_client -connect meaydino.42.fr:443 -tls1_2

# Verify TLSv1.3 handshake:
openssl s_client -connect meaydino.42.fr:443 -tls1_3

# Verify SSLv3 / TLSv1.0 / TLSv1.1 are REJECTED:
openssl s_client -connect meaydino.42.fr:443 -tls1_1
# (Expected: Handshake failure / connection closed)
```

---

## 10. Developer Maintenance Playbooks & Evaluation Guides

### Playbook A: Live Port Change (Evaluation Requirement)
If the evaluator requests changing NGINX's port from `443` to another port (e.g. `8443`):

1. **Edit `srcs/requirements/nginx/conf/nginx.conf`:**
   ```nginx
   server {
       listen 8443 ssl;
       listen [::]:8443 ssl;
       ...
   ```
2. **Edit `srcs/docker-compose.yml`:**
   ```yaml
   nginx:
     ports:
       - "8443:8443"
   ```
3. **Rebuild & Restart:**
   ```bash
   make all
   ```
4. **Test:** Open `https://meaydino.42.fr:8443` in the browser.

---

### Playbook B: Direct MariaDB Database Access & Inspection
During defense, you may be asked to demonstrate that the database contains tables and is not empty:

```bash
# Connect as root user:
docker exec -it mariadb mariadb -u root -p$(cat secrets/db_root_password.txt)

# Or connect as application user:
docker exec -it mariadb mariadb -u wp_user -p$(cat secrets/db_password.txt) wordpress
```

**Common SQL Commands to Run:**
```sql
SHOW DATABASES;
USE wordpress;
SHOW TABLES;
SELECT ID, user_login, user_email FROM wp_users;
SELECT comment_author, comment_content FROM wp_comments;
```

---

### Playbook C: Inspecting Volumes and Networks
```bash
# Inspect Named Volume mappings:
docker volume inspect inception_wordpress_volume
docker volume inspect inception_mariadb_volume

# Inspect Network configuration:
docker network inspect inception_inception_net
```

---

## 11. Troubleshooting & Diagnostic Guide

| Symptom | Probable Cause | Diagnostic Command | Remediation |
|---|---|---|---|
| `502 Bad Gateway` | PHP-FPM is down or port 9000 is not listening | `docker logs wordpress` | Check if PHP-FPM failed to bind to `0.0.0.0:9000` in `/etc/php/8.2/fpm/pool.d/www.conf`. |
| `Error establishing DB connection` | MariaDB initialization incomplete or bad credentials | `docker logs mariadb` | Check `secrets/db_password.txt` against `srcs/.env`. Re-run `make re`. |
| Permission Denied on `/var/www/html` | Host directory owned by root without write permissions | `ls -ld /home/meaydino/data/wordpress` | Run `sudo chown -R 33:33 /home/meaydino/data/wordpress` (33 = `www-data`). |
| Host cannot resolve `meaydino.42.fr` | Missing entry in `/etc/hosts` | `ping -c 1 meaydino.42.fr` | Add `127.0.0.1 meaydino.42.fr` to `/etc/hosts`. |
