*This project has been created as part of the 42 curriculum by meaydino.*

# Inception

## Description

Inception is a system administration project that introduces Docker containerization. The goal is to set up a small infrastructure composed of multiple services, each running in its own Docker container, orchestrated with Docker Compose.

### Services Included

| Service | Description |
|---|---|
| **NGINX** | Reverse proxy, sole entry point via port 443 (TLSv1.2/TLSv1.3 only) |
| **WordPress + php-fpm** | CMS application with PHP-FPM, no built-in web server |
| **MariaDB** | Relational database storing WordPress data |

### Design Choices

#### Virtual Machines vs Docker
Virtual Machines emulate full hardware and run a complete OS, consuming significant resources. Docker containers share the host kernel, are lightweight, start in milliseconds, and are ideal for running isolated services without the overhead of a full OS.

#### Secrets vs Environment Variables
Environment variables are visible in `docker inspect` and process listings — a security risk for passwords. Docker Secrets store sensitive data in `/run/secrets/` inside the container and are never exposed as environment variables, making them significantly safer for credentials.

#### Docker Network vs Host Network
`network: host` removes network isolation and exposes all container ports directly on the host, creating security risks. A Docker bridge network (`inception_net`) isolates containers from the host and each other, allowing controlled inter-service communication by service name (DNS).

#### Docker Volumes vs Bind Mounts
Bind mounts depend on a specific host path and are not portable. Docker named volumes are managed by Docker, survive container removal, and are the recommended way to persist data. This project uses named volumes stored under `/home/meaydino/data/` on the host.

---

## Instructions

### Prerequisites

- Docker and Docker Compose installed
- Domain `meaydino.42.fr` pointing to `127.0.0.1` in `/etc/hosts`
- Secrets files present in `Inception/secrets/`

### Setup

```bash
# 1. Add domain to /etc/hosts
echo "127.0.0.1 meaydino.42.fr" | sudo tee -a /etc/hosts

# 2. Build and start all services
cd Inception
make all
```

### Stop / Restart

```bash
make down    # Stop containers
make clean   # Stop containers (preserves data and images)
make fclean  # Full clean (removes images, volumes, and data)
make re      # Full reset (fclean + all)
```

### Access

- **Website**: https://meaydino.42.fr
- **Admin panel**: https://meaydino.42.fr/wp-admin

---

## Resources

### Documentation
- [Docker Official Documentation](https://docs.docker.com/)
- [Docker Compose Reference](https://docs.docker.com/compose/)
- [NGINX Documentation](https://nginx.org/en/docs/)
- [MariaDB Documentation](https://mariadb.com/kb/en/)
- [WordPress WP-CLI](https://wp-cli.org/)
- [PHP-FPM Configuration](https://www.php.net/manual/en/install.fpm.configuration.php)
- [OpenSSL Self-Signed Certificates](https://www.openssl.org/docs/)

### AI Usage
AI tools (Antigravity / Claude) were used in this project for:
- **Understanding concepts**: Explaining Docker networking, PID 1 behavior, and daemon best practices
- **Debugging**: Identifying issues in entrypoint scripts (e.g., USER directive conflicts, heredoc quoting)
- **Documentation**: Generating initial drafts of README, USER_DOC, and DEV_DOC which were then reviewed and corrected
- **Code review**: Checking Dockerfiles and docker-compose.yml against the project subject requirements

All AI-generated content was reviewed, tested, and validated before inclusion in the project.
