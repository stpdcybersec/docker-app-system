# Docker App System - PostgreSQL, PgAdmin & Nginx
## Установка и запуск
`````
# Клонирование репозитория
git clone <your-repo-url>
cd docker-app-system

# Создание необходимых директорий
mkdir -p nginx data/postgres logs/nginx scripts backups

# Запуск системы
docker-compose up -d
``````
## Для защиты
1. Compose файл
```
version: '3.8'

services:
  postgres:
    image: postgres:15
    container_name: postgres_db
    environment:
      POSTGRES_DB: mydatabase
      POSTGRES_USER: admin
      POSTGRES_PASSWORD: secretpassword
      POSTGRES_HOST_AUTH_METHOD: trust
    volumes:
      - ./data/postgres:/var/lib/postgresql/data
      - ./backups:/backups
      - ./scripts:/scripts
    ports:
      - "5433:5432"
    restart: unless-stopped
    networks:
      - app_network

  pgadmin:
    image: dpage/pgadmin4:7
    container_name: pgadmin
    environment:
      PGADMIN_DEFAULT_EMAIL: admin@mail.ru
      PGADMIN_DEFAULT_PASSWORD: adminpassword
    restart: unless-stopped
    networks:
      - app_network
    depends_on:
      - postgres

  nginx:
    image: nginx:alpine
    container_name: nginx_proxy
    ports:
      - "8080:8080"
    volumes:
      - ./nginx/nginx.conf:/etc/nginx/nginx.conf:ro
      - ./logs/nginx:/var/log/nginx
    restart: unless-stopped
    networks:
      - app_network
    depends_on:
      - pgadmin

networks:
  app_network:
    driver: bridge
```
2. Список прослушиваемых портов на хостовой машине
```
tcp        0      0 0.0.0.0:8080            0.0.0.0:*               LISTEN      -                   
tcp        0      0 0.0.0.0:5433            0.0.0.0:*               LISTEN      -                   
tcp6       0      0 :::8080                 :::*                    LISTEN      -                   
tcp6       0      0 :::5433                 :::*                    LISTEN      - 
```
3. Список запущенных контейнеров
```
CONTAINER ID   IMAGE              COMMAND                  CREATED         STATUS         PORTS                                               NAMES
f87cbb2ee261   nginx:alpine       "/docker-entrypoint.…"   3 minutes ago   Up 3 minutes   80/tcp, 0.0.0.0:8080->8080/tcp, :::8080->8080/tcp   nginx_proxy
c3b4a9bc3a6b   dpage/pgadmin4:7   "/entrypoint.sh"         4 minutes ago   Up 3 minutes   80/tcp, 443/tcp                                     pgadmin
e51dcd014456   postgres:15        "docker-entrypoint.s…"   4 minutes ago   Up 4 minutes   0.0.0.0:5433->5432/tcp, [::]:5433->5432/tcp         postgres_db
```
4. Содержимое volume каталога с данными
```
итого 136
drwx------ 19 dnsmasq      root             4096 сен 13 19:44 .
drwxrwxr-x  3 stpdcybersec stpdcybersec     4096 сен 13 17:20 ..
drwxrwxrwx  7 dnsmasq      systemd-journal  4096 сен 13 18:00 base
drwxrwxrwx  2 dnsmasq      systemd-journal  4096 сен 13 19:45 global
drwxrwxrwx  2 dnsmasq      systemd-journal  4096 сен 13 17:20 pg_commit_ts
drwxrwxrwx  2 dnsmasq      systemd-journal  4096 сен 13 17:20 pg_dynshmem
-rwxrwxrwx  1 dnsmasq      systemd-journal  4917 сен 13 17:20 pg_hba.conf
-rwxrwxrwx  1 dnsmasq      systemd-journal  1636 сен 13 17:20 pg_ident.conf
drwxrwxrwx  4 dnsmasq      systemd-journal  4096 сен 13 19:49 pg_logical
drwxrwxrwx  4 dnsmasq      systemd-journal  4096 сен 13 17:20 pg_multixact
drwxrwxrwx  2 dnsmasq      systemd-journal  4096 сен 13 17:20 pg_notify
drwxrwxrwx  2 dnsmasq      systemd-journal  4096 сен 13 17:20 pg_replslot
drwxrwxrwx  2 dnsmasq      systemd-journal  4096 сен 13 17:20 pg_serial
drwxrwxrwx  2 dnsmasq      systemd-journal  4096 сен 13 17:20 pg_snapshots
drwxrwxrwx  2 dnsmasq      systemd-journal  4096 сен 13 19:44 pg_stat
drwxrwxrwx  2 dnsmasq      systemd-journal  4096 сен 13 17:20 pg_stat_tmp
drwxrwxrwx  2 dnsmasq      systemd-journal  4096 сен 13 17:20 pg_subtrans
drwxrwxrwx  2 dnsmasq      systemd-journal  4096 сен 13 17:20 pg_tblspc
drwxrwxrwx  2 dnsmasq      systemd-journal  4096 сен 13 17:20 pg_twophase
-rwxrwxrwx  1 dnsmasq      systemd-journal     3 сен 13 17:20 PG_VERSION
drwxrwxrwx  3 dnsmasq      systemd-journal  4096 сен 13 17:59 pg_wal
drwxrwxrwx  2 dnsmasq      systemd-journal  4096 сен 13 17:20 pg_xact
-rwxrwxrwx  1 dnsmasq      systemd-journal    88 сен 13 17:20 postgresql.auto.conf
-rwxrwxrwx  1 dnsmasq      systemd-journal 29517 сен 13 17:20 postgresql.conf
-rwxrwxrwx  1 dnsmasq      systemd-journal    36 сен 13 19:44 postmaster.opts
-rw-------  1 dnsmasq      systemd-journal    94 сен 13 19:44 postmaster.pid
```
5. Результат выполнения работы скрипта (список файлов, cat логов)
```
drwxrwxr-x 4 stpdcybersec stpdcybersec 4096 сен 13 18:57 .
drwxrwxr-x 3 stpdcybersec stpdcybersec 4096 сен 13 19:14 ..
drwxrwxr-x 3 stpdcybersec stpdcybersec 4096 сен 13 17:20 data
drwxrwxr-x 3 stpdcybersec stpdcybersec 4096 сен 13 18:43 logs
```

```
2025-09-13 19:14:06 - INFO: Starting backup of directories /home/stpdcybersec/docker-app-system/data /home/stpdcybersec/docker-app-system/logs to '/home/stpdcybersec/docker-app-system/backups/backup_20250913_191406.tar.gz'.
2025-09-13 19:14:17 - SUCCESS: Archive '/home/stpdcybersec/docker-app-system/backups/backup_20250913_191406.tar.gz' created successfully.
2025-09-13 19:14:17 - INFO: Verifying archive integrity.
2025-09-13 19:14:19 - SUCCESS: Archive '/home/stpdcybersec/docker-app-system/backups/backup_20250913_191406.tar.gz' verified successfully.
2025-09-13 19:14:19 - SUCCESS: Backup process completed successfully.
```
6. Скриншоты веб интерфейса, чтобы было видно адресную строку и имя базы данных, списка таблиц
https://raw.githubusercontent.com/stpdcbersec/docker-app-system/a369112c9ac7a2013db3a52f6a3ebed232a6ec6d/screenshots/1.png
https://raw.githubusercontent.com/stpdcbersec/docker-app-system/a369112c9ac7a2013db3a52f6a3ebed232a6ec6d/screenshots/2.png
