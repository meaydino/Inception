# USER_DOC — User Documentation

## What Services Are Provided?

This stack runs three services:

| Service | Role | Port |
|---|---|---|
| **NGINX** | Web server / reverse proxy (HTTPS only) | 443 (external) |
| **WordPress** | Website & admin panel (php-fpm) | Internal only |
| **MariaDB** | Database | Internal only |

Only NGINX is accessible from the outside. WordPress and MariaDB communicate internally over the private Docker network.

---

## Starting and Stopping the Project

### Start
```bash
cd Inception
make all
```
This will:
1. Create data directories on the host (`/home/meaydino/data/`)
2. Build Docker images
3. Start all containers in the background

### Stop / Clean (keep data)
```bash
make down    # or make clean
```

### Full reset / Full clean (deletes all data, volumes, and images)
```bash
make fclean  # Remove containers, images, volumes, and data
make re      # Full rebuild from scratch (fclean + all)
```

---

## Accessing the Website and Admin Panel

> **Important:** Make sure `meaydino.42.fr` points to your machine in `/etc/hosts`:
> ```bash
> echo "127.0.0.1 meaydino.42.fr" | sudo tee -a /etc/hosts
> ```

| Page | URL |
|---|---|
| Public website | https://meaydino.42.fr |
| Admin panel | https://meaydino.42.fr/wp-admin |

> Your browser will warn about the self-signed certificate — this is expected. Accept the exception to proceed.

---

## Locating and Managing Credentials

All credentials are stored as plain text files in the `secrets/` directory at the project root. **These files must never be committed to Git.**

| File | Contents |
|---|---|
| `secrets/credentials.txt` | Line 1: admin username, Line 2: admin password |
| `secrets/wp_user_credentials.txt` | Line 1: editor username, Line 2: editor password |
| `secrets/db_password.txt` | WordPress database user password |
| `secrets/db_root_password.txt` | MariaDB root password |

To change a password: edit the relevant file, then run `make re` to recreate the stack.

---

## Checking That Services Are Running

```bash
# List running containers
docker ps

# Check logs for each service
docker logs nginx
docker logs wordpress
docker logs mariadb

# Check container health
docker compose -f Inception/srcs/docker-compose.yml ps
```

Expected output of `docker ps` should show three containers (`nginx`, `wordpress`, `mariadb`) all with status `Up`.
