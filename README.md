*This project has been created as part of the 42 curriculum by meaydino.*

# Inception

![Docker](https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white)
![Docker Compose](https://img.shields.io/badge/Docker_Compose-2496ED?style=for-the-badge&logo=docker&logoColor=white)
![NGINX](https://img.shields.io/badge/NGINX-009639?style=for-the-badge&logo=nginx&logoColor=white)
![WordPress](https://img.shields.io/badge/WordPress-21759B?style=for-the-badge&logo=wordpress&logoColor=white)
![MariaDB](https://img.shields.io/badge/MariaDB-003545?style=for-the-badge&logo=mariadb&logoColor=white)
![Debian](https://img.shields.io/badge/Debian-A81D33?style=for-the-badge&logo=debian&logoColor=white)

---

## Table of Contents
- [Description](#description)
  - [Architecture Overview](#architecture-overview)
  - [Services Breakdown](#services-breakdown)
  - [Design Choices & Comparative Analysis](#design-choices--comparative-analysis)
- [Instructions](#instructions)
  - [Prerequisites](#prerequisites)
  - [Environment Setup](#environment-setup)
  - [Compilation & Execution](#compilation--execution)
  - [Service Access](#service-access)
  - [Cleaning & Resetting](#cleaning--resetting)
- [Resources](#resources)
  - [Official Documentation](#official-documentation)
  - [Tools & References](#tools--references)
  - [AI Usage Disclosure](#ai-usage-disclosure)

---

## Description

**Inception** is a system administration project in the 42 curriculum designed to deepen understanding of infrastructure virtualization, containerization, and service orchestration.

The goal is to build a complete, resilient web infrastructure using **Docker** and **Docker Compose**, running multiple micro-services inside isolated containers adhering to strict security and design rules:
- Every image is custom-built from a dedicated `Dockerfile` using the penultimate/stable version of **Debian/Alpine** (no pre-built DockerHub application images).
- **NGINX** acts as the sole entry point to the infrastructure via HTTPS (TLSv1.2/TLSv1.3 only, port 443).
- **WordPress** runs exclusively with **PHP-FPM** without any bundled web server.
- **MariaDB** provides database services to WordPress without exposing ports to the host machine.
- All containers communicate exclusively over an isolated custom Docker bridge network (`inception_net`).
- Data persists across container restarts and VM reboots using Docker volumes mapped to `/home/meaydino/data/`.
- Sensitive information (passwords, credentials) is managed via **Docker Secrets**.

---

### Architecture Overview

```
                                  HOST MACHINE
                                       │
                               HTTPS Requests (Port 443)
                                       │
                                       ▼
                     ┌───────────────────────────────────┐
                     │           NGINX Container         │
                     │  - Port 443 (Exposed to Host)     │
                     │  - TLSv1.2 / TLSv1.3 SSL Offload  │
                     │  - Static Content Serving         │
                     └─────────────────┬─────────────────┘
                                       │
                               FastCGI (Port 9000)
                     ┌─────────────────┴─────────────────┐
                     │     INCEPTION_NET (Bridge)        │
                     └─────────────────┬─────────────────┘
                                       │
                                       ▼
                     ┌───────────────────────────────────┐
                     │        WordPress Container        │
                     │  - PHP-FPM 8.2 (Port 9000)        │
                     │  - WP-CLI Automation              │
                     │  - Volume: /var/www/html          │
                     └─────────────────┬─────────────────┘
                                       │
                               MySQL (Port 3306)
                                       │
                                       ▼
                     ┌───────────────────────────────────┐
                     │         MariaDB Container         │
                     │  - MariaDB Server (Port 3306)     │
                     │  - Internal Network Only          │
                     │  - Volume: /var/lib/mysql         │
                     └───────────────────────────────────┘
                                       │
                     ┌─────────────────┴─────────────────┐
                     │          PERSISTENT DATA          │
                     │  - /home/meaydino/data/wordpress  │
                     │  - /home/meaydino/data/mariadb    │
                     └───────────────────────────────────┘
```

---

### Services Breakdown

| Service | Base OS | Exposing Ports | Internal Ports | Volumes | Description |
|---|---|---|---|---|---|
| **`nginx`** | Debian Bookworm | `443/tcp` | None | `wordpress_volume:/var/www/html:ro` | Reverse proxy and TLS termination point. Configured to handle HTTPS traffic only and forward `.php` scripts to WordPress. |
| **`wordpress`** | Debian Bookworm | None | `9000/tcp` | `wordpress_volume:/var/www/html` | Core CMS running PHP-FPM. Bootstrapped with WP-CLI to install core files, configure `wp-config.php`, and create users automatically. |
| **`mariadb`** | Debian Bookworm | None | `3306/tcp` | `mariadb_volume:/var/lib/mysql` | Relational database management system storing all WordPress data, tables, users, posts, and settings. |

---

### Design Choices & Comparative Analysis

#### 1. Docker Containers vs Virtual Machines (VM)
* **Virtual Machines (Hardware Virtualization):**
  - Run a complete Guest OS on top of a Hypervisor (Type 1 or Type 2).
  - Emulate full virtual hardware (CPU, RAM, Network Interfaces, Storage controllers).
  - High resource overhead, slow boot times (minutes), and large image sizes (gigabytes).
* **Docker Containers (OS-level Virtualization):**
  - Share the host Linux kernel while running in isolated user spaces.
  - Utilize Linux kernel features:
    - **Namespaces:** Provide process isolation (PID, NET, IPC, MNT, UTS, USER).
    - **Control Groups (cgroups):** Enforce resource constraints (CPU, RAM, I/O limits).
  - Near-zero resource overhead, instantaneous startup (milliseconds), and minimal storage footprint.

#### 2. Docker Compose vs Raw Docker Commands
* Raw `docker run` commands require manual management of dependencies, port mappings, volume bindings, environment variables, network attachments, and startup order across multiple long command lines.
* **Docker Compose** defines entire multi-container application topologies declaratively in a reproducible `docker-compose.yml` file, ensuring identical environments across deployments.

#### 3. Docker Bridge Network vs Host Network (`network: host`)
* `network: host` attaches containers directly to the host's networking namespace, bypassing isolation and exposing all internal container ports to the outside world.
* A custom **Docker Bridge Network** (`inception_net`) provides strict network boundary isolation. Containers communicate with each other securely using internal DNS service discovery names (`nginx`, `wordpress`, `mariadb`), while only necessary ports (`443`) are mapped to the host.

#### 4. Persistent Docker Named Volumes vs Ephemeral Storage
* Container file systems are ephemeral by default; any data written inside a container is permanently destroyed when the container is removed (`docker rm`).
* We configure **Docker Named Volumes** with a bind-mount driver mapped to `/home/meaydino/data/wordpress` and `/home/meaydino/data/mariadb` on the host machine. This guarantees persistent retention of database records and uploaded files across restarts and container recreation.

#### 5. Docker Secrets vs Environment Variables
* Environment variables can be inspected easily via `docker inspect <container>`, process table listings (`/proc/<pid>/environ`), or container logs.
* **Docker Secrets** mount sensitive credentials (database passwords, administrator authentication) as temporary, in-memory files at `/run/secrets/<secret_name>` inside authorized containers, ensuring passwords are never stored in image layers or exposed via environment variables.

---

## Instructions

### Prerequisites

Ensure the following packages are installed on your Linux host:
- **Docker Engine** (v24.0.0+)
- **Docker Compose** (v2.20.0+)
- **GNU Make**
- **Sudo privileges** (for volume folder initialization under `/home/meaydino/data/`)

Verify installation:
```bash
docker --version
docker compose version
make --version
```

---

### Environment Setup

1. **Configure Host DNS Resolution:**
   Add the local domain mapping to your host's `/etc/hosts` file:
   ```bash
   echo "127.0.0.1 meaydino.42.fr" | sudo tee -a /etc/hosts
   ```

2. **Verify Environment Variables and Secrets:**
   Ensure the following files are present in the repository:
   - `srcs/.env` (Domain, database name/user, WordPress title, administrator & user details)
   - `secrets/wp_admin_password.txt` (WordPress Admin password)
   - `secrets/wp_user_password.txt` (WordPress Editor user password)
   - `secrets/db_password.txt` (Database user password)
   - `secrets/db_root_password.txt` (Database root password)

---

### Compilation & Execution

Use the root **Makefile** to control the full lifecycle of the infrastructure:

```bash
# Build all Docker images and start all services in the background
make all

# Alternatively, just run make
make
```

The Makefile will automatically:
1. Create the persistent host directories (`/home/meaydino/data/wordpress` and `/home/meaydino/data/mariadb`).
2. Build custom Docker images for NGINX, WordPress, and MariaDB according to their respective `Dockerfile`s.
3. Establish the `inception_net` network and attach the persistent volumes.
4. Launch the containers in detached mode (`-d`).

---

### Service Access

Once containers are up and running:

* **Public WordPress Website:** [https://meaydino.42.fr](https://meaydino.42.fr)
* **WordPress Administration Panel:** [https://meaydino.42.fr/wp-admin](https://meaydino.42.fr/wp-admin)

> [!NOTE]
> When accessing the website, your browser will display a security warning regarding a self-signed SSL/TLS certificate. This is expected behavior for custom certificates generated during container initialization. Accept the risk to proceed.

---

### Cleaning & Resetting

```bash
# Stop running containers without deleting persistent data
make down

# Clean containers and temporary files (preserves volumes and images)
make clean

# Full clean: Stop containers, remove images, delete network, remove Docker volumes,
# and delete all data from /home/meaydino/data (Requires sudo)
make fclean

# Complete reset: fclean followed by a clean rebuild and startup
make re
```

---

## Resources

### Official Documentation
- [Docker Documentation](https://docs.docker.com/)
- [Docker Compose Specification](https://docs.docker.com/compose/compose-file/)
- [NGINX Core Documentation](https://nginx.org/en/docs/)
- [MariaDB Knowledge Base](https://mariadb.com/kb/en/)
- [WordPress Developer Resources](https://developer.wordpress.org/)
- [WP-CLI Command Reference](https://developer.wordpress.org/cli/commands/)
- [PHP-FPM Configuration Guide](https://www.php.net/manual/en/install.fpm.configuration.php)
- [OpenSSL Cryptography Toolkit](https://www.openssl.org/docs/)

### Tools & References
- [Debian Official Release Information](https://www.debian.org/releases/)
- [Linux Namespaces and Cgroups Manual](https://man7.org/linux/man-pages/man7/namespaces.7.html)
- [Mozilla SSL Configuration Generator](https://ssl-config.mozilla.org/)

---

### AI Usage Disclosure

In compliance with 42 evaluation guidelines, AI tooling (Google DeepMind Antigravity / Claude) was utilized in this project under the following conditions:

1. **Conceptual Understanding & Architecture Review:**
   - Reviewing the security boundaries between Docker Secrets vs. environment variables.
   - Clarifying PID 1 process management, signal handling (`SIGTERM`/`SIGQUIT`), and why foreground execution (`exec ...`) is required in entrypoint scripts instead of background daemons (`daemon off;` vs `&`).
2. **Script Validation & Debugging:**
   - Structuring `WP-CLI` headless installation scripts to handle non-interactive configuration safely without hanging.
   - Designing idempotent MariaDB bootstrap initialization routines to allow seamless container restarts.
3. **Documentation Authoring & Refinement:**
   - Generating structured markdown layouts and technical summaries for `README.md`, `USER_DOC.md`, and `DEV_DOC.md`.
4. **Independent Verification:**
   - All generated configurations, Dockerfiles, and shell commands were personally reviewed, tested, debugged, and verified on the target Linux virtual machine environment to guarantee full compliance with the 42 subject rules.
