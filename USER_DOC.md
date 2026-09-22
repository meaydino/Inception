# USER_DOC — End-User and Administrator Guide

Welcome to the **Inception** infrastructure user documentation. This guide provides step-by-step instructions for end users, administrators, and evaluators on how to operate, monitor, manage, and verify the services running in this containerized environment.

---

## Table of Contents
1. [Services Overview](#1-services-overview)
2. [Getting Started & Project Lifecycle](#2-getting-started--project-lifecycle)
3. [Accessing the Website and Admin Panel](#3-accessing-the-website-and-admin-panel)
4. [Managing Credentials and Secrets](#4-managing-credentials-and-secrets)
5. [Monitoring & Health Verification](#5-monitoring--health-verification)
6. [WordPress Administration Walkthrough](#6-wordpress-administration-walkthrough)
7. [Troubleshooting & Common Questions](#7-troubleshooting--common-questions)

---

## 1. Services Overview

This infrastructure consists of three interconnected micro-services orchestrated with Docker Compose:

| Service | Technology | Role | Network Scope | Host Port |
|---|---|---|---|---|
| **`nginx`** | NGINX 1.22+ (Debian Bookworm) | Reverse proxy, TLS/SSL termination, and static file server | Public (Host network) | `443` (HTTPS) |
| **`wordpress`** | PHP-FPM 8.2 + WordPress Core | FastCGI application processor for dynamic content | Internal private network only (`inception_net`) | None (Internal: `9000`) |
| **`mariadb`** | MariaDB 10.11+ Server | Relational database management system storing all application data | Internal private network only (`inception_net`) | None (Internal: `3306`) |

### Key Security & Isolation Features:
* **Strict HTTPS Only:** The only entry point exposed to the host machine or public network is NGINX on port `443`. Plain HTTP (port `80`) is disabled.
* **No Direct DB or PHP Exposure:** MariaDB and WordPress cannot be accessed directly from outside the Docker network.
* **Encrypted Secrets:** All passwords and sensitive administrative accounts are stored outside the images and mounted securely inside `/run/secrets/`.

---

## 2. Getting Started & Project Lifecycle

All common administrative operations are managed using `make` commands executed from the project root directory.

### Quick Start
To build and start the entire stack:
```bash
# 1. Ensure domain resolution is configured in /etc/hosts (one-time setup)
echo "127.0.0.1 meaydino.42.fr" | sudo tee -a /etc/hosts

# 2. Build images and start all services in detached mode
make all
```

### Lifecycle Command Reference

| Command | Action | Data State |
|---|---|---|
| `make all` / `make` | Creates storage directories on host, builds images if not built, and starts all containers. | Preserved / Initialized |
| `make build` | Builds or rebuilds all Docker images without starting them. | Unchanged |
| `make down` | Gracefully stops and removes running containers and network. | **Preserved** |
| `make clean` | Alias for `make down`. Containers and network are removed. | **Preserved** |
| `make fclean` | Stops containers, deletes all images, deletes networks, destroys Docker volumes, and purges `/home/meaydino/data/*`. | **DESTROYED** |
| `make re` | Performs `make fclean` followed immediately by `make all` for a fresh installation. | **DESTROYED & Rebuilt** |

---

## 3. Accessing the Website and Admin Panel

### Host Setup (/etc/hosts)
Because the NGINX configuration listens for the domain name `meaydino.42.fr`, your browser must resolve this domain to your machine's local IP address (`127.0.0.1`).

Check if the domain is configured:
```bash
ping -c 1 meaydino.42.fr
```
If it does not resolve to `127.0.0.1`, run:
```bash
echo "127.0.0.1 meaydino.42.fr" | sudo tee -a /etc/hosts
```

### URLs

* **Public WordPress Website:** [https://meaydino.42.fr](https://meaydino.42.fr)
* **WordPress Administration Dashboard:** [https://meaydino.42.fr/wp-admin](https://meaydino.42.fr/wp-admin)

### Handling the SSL/TLS Certificate Warning
Since this project uses a self-signed TLS certificate generated via OpenSSL during the NGINX startup process, web browsers (Chrome, Firefox, Safari) will display a security warning (e.g., `NET::ERR_CERT_AUTHORITY_INVALID` or `Potential Security Risk Ahead`).
1. Click **Advanced** (or **More Information**).
2. Click **Proceed to meaydino.42.fr (unsafe)** or **Accept the Risk and Continue**.
3. You will immediately see the fully configured WordPress home page.

---

## 4. Managing Credentials and Secrets

All passwords and usernames are stored inside the `secrets/` directory. Each secret file contains sensitive credentials that are injected directly into containers at runtime via Docker Secrets.

### Secret Files Location and Format

| File Path | Description | Default Content Format |
|---|---|---|
| `secrets/credentials.txt` | WordPress Administrator credentials | Line 1: Username (`meaydino`)<br>Line 2: Password |
| `secrets/wp_user_credentials.txt` | WordPress Editor credentials | Line 1: Username (`wp_editor`)<br>Line 2: Password |
| `secrets/db_password.txt` | MariaDB WordPress User Password | Single Line: DB User password |
| `secrets/db_root_password.txt` | MariaDB Root Password | Single Line: DB Root password |

> [!IMPORTANT]
> - Per 42 evaluation rules, the Administrator username **MUST NOT** contain `admin`, `Admin`, or `administrator`.
> - Never commit plaintext secret files into a public Git repository.

### How to Change a Password
1. Modify the relevant text file in `secrets/`.
2. To apply new database credentials to an existing installation, a full reset is needed:
   ```bash
   make re
   ```

---

## 5. Monitoring & Health Verification

Use these standard commands to verify that the infrastructure is running properly:

### 1. Check Container Status
```bash
docker compose -f srcs/docker-compose.yml ps
```
**Expected Output:**
All three containers (`nginx`, `wordpress`, `mariadb`) should have a status of `Up` or `running`.

### 2. View Service Logs
```bash
# Follow live logs for all services:
docker compose -f srcs/docker-compose.yml logs -f

# Check individual container logs:
docker logs nginx
docker logs wordpress
docker logs mariadb
```

### 3. Verify Open Ports on Host
```bash
sudo netstat -tlpn | grep -E '443|80|9000|3306'
# or
ss -tulpn | grep -E '443|80|9000|3306'
```
**Expected Output:**
Only port `443` (docker-proxy / nginx) should be listening on the host. Ports `80`, `9000`, and `3306` must **NOT** be visible or open to the host.

### 4. Verify Volume Inspection
```bash
docker volume ls
docker volume inspect inception_wordpress_volume
docker volume inspect inception_mariadb_volume
```
The output will confirm that volumes point to `/home/meaydino/data/wordpress` and `/home/meaydino/data/mariadb`.

---

## 6. WordPress Administration Walkthrough

### 1. Logging into the Admin Panel
1. Open [https://meaydino.42.fr/wp-admin](https://meaydino.42.fr/wp-admin) in your browser.
2. Enter the administrator credentials:
   - **Username:** `meaydino` (or read line 1 of `secrets/credentials.txt`)
   - **Password:** (read line 2 of `secrets/credentials.txt`)
3. Click **Log In**.

### 2. Editing or Creating a Page / Post
1. From the WordPress left sidebar, navigate to **Posts** -> **Add New** (or **Pages** -> **All Pages** -> Edit "Sample Page").
2. Update the title and content (e.g., add "42 Inception Evaluation Test").
3. Click **Publish** or **Update**.
4. Open [https://meaydino.42.fr](https://meaydino.42.fr) in a separate tab to verify that the changes are live.

### 3. Submitting and Moderating Comments
1. Open [https://meaydino.42.fr](https://meaydino.42.fr) in an incognito window.
2. Navigate to the default post ("Hello world!").
3. Fill in the comment field with test text and submit.
4. Go back to the Admin Dashboard under **Comments** to see, approve, or reply to the comment.

---

## 7. Troubleshooting & Common Questions

#### Q: The browser shows "Unable to connect" or "Site can't be reached".
* **Solution:**
  1. Check if containers are running: `docker compose -f srcs/docker-compose.yml ps`.
  2. Verify that `/etc/hosts` contains `127.0.0.1 meaydino.42.fr`.
  3. Ensure you are using `https://` and **NOT** `http://`.

#### Q: The browser displays "502 Bad Gateway".
* **Cause:** NGINX cannot communicate with the WordPress PHP-FPM daemon on port 9000.
* **Solution:**
  1. Check WordPress container logs: `docker logs wordpress`.
  2. Ensure PHP-FPM is actively running inside the WordPress container.
  3. Restart the stack: `make down && make all`.

#### Q: The browser displays "Error establishing a database connection".
* **Cause:** WordPress cannot connect to MariaDB on port 3306 or authentication failed.
* **Solution:**
  1. Check MariaDB container logs: `docker logs mariadb`.
  2. Verify that `MYSQL_DATABASE` and `MYSQL_USER` in `srcs/.env` match the passwords in `secrets/`.
  3. Recreate the environment: `make re`.
