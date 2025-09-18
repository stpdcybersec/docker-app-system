# Docker App System - PostgreSQL, PgAdmin, Nginx, cAdvisor & Postgres Exporter
## Установка и запуск
`````
# Клонирование репозитория
git clone <https url/ssh url>
cd docker-app-system

# Создание необходимых директорий
mkdir -p nginx data logs scripts backups

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
      POSTGRES_USER: ${POSTGRES_USER}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
    volumes:
      - ./data/postgres:/var/lib/postgresql/data
    ports:
      - "5433:5432"
    restart: unless-stopped
    networks:
      - app_network

  pgadmin:
    image: dpage/pgadmin4:7
    container_name: pgadmin
    environment:
      PGADMIN_DEFAULT_EMAIL: ${PGADMIN_DEFAULT_EMAIL}
      PGADMIN_DEFAULT_PASSWORD: ${PGADMIN_DEFAULT_PASSWORD}
    restart: unless-stopped
    networks:
      - app_network
    depends_on:
      - postgres

  nginx:
    image: nginx:alpine
    container_name: nginx_proxy
    ports:
      - "8080:80"
    volumes:
      - ./nginx/nginx.conf:/etc/nginx/nginx.conf:ro
      - ./logs/nginx:/var/log/nginx
    restart: unless-stopped
    networks:
      - app_network
    depends_on:
      - pgadmin
      - cadvisor

  cadvisor:
    image: gcr.io/cadvisor/cadvisor:v0.49.1
    container_name: cadvisor
    volumes:
      - /:/rootfs:ro
      - /var/run:/var/run:ro
      - /sys:/sys:ro
      - /var/lib/docker/:/var/lib/docker:ro
      - /dev/disk/:/dev/disk:ro
    restart: unless-stopped
    networks:
      - app_network
    depends_on:
      - postgres

  postgres_exporter:
    image: prometheuscommunity/postgres-exporter:v0.15.0
    container_name: postgres_exporter
    environment:
      DATA_SOURCE_NAME: "postgresql://${POSTGRES_USER}:${POSTGRES_PASSWORD}@postgres:5432/mydatabase?sslmode=disable"
    ports:
      - "9188:9187"
    restart: unless-stopped
    networks:
      - app_network
    depends_on:
      - postgres

networks:
  app_network:
    driver: bridge
```
2. Список прослушиваемых портов на хостовой машине
```
tcp   LISTEN 0      4096                                     0.0.0.0:5433       0.0.0.0:*   
tcp   LISTEN 0      4096                                     0.0.0.0:8080       0.0.0.0:*   
tcp   LISTEN 0      4096                                     0.0.0.0:9188       0.0.0.0:*   
tcp   LISTEN 0      4096                                        [::]:5433          [::]:*   
tcp   LISTEN 0      4096                                        [::]:8080          [::]:*   
tcp   LISTEN 0      4096                                        [::]:9188          [::]:*
```
3. Список запущенных контейнеров
```
CONTAINER ID   IMAGE                                           COMMAND                  CREATED          STATUS                    PORTS                                         NAMES
8673caba52ad   nginx:alpine                                    "/docker-entrypoint.…"   32 minutes ago   Up 32 minutes             0.0.0.0:8080->80/tcp, [::]:8080->80/tcp       nginx_proxy
d3fea4acc824   dpage/pgadmin4:7                                "/entrypoint.sh"         32 minutes ago   Up 32 minutes             80/tcp, 443/tcp                               pgadmin
b66b75bd3933   prometheuscommunity/postgres-exporter:v0.15.0   "/bin/postgres_expor…"   32 minutes ago   Up 32 minutes             0.0.0.0:9188->9187/tcp, [::]:9188->9187/tcp   postgres_exporter
2aa0d99fdf52   gcr.io/cadvisor/cadvisor:v0.49.1                "/usr/bin/cadvisor -…"   32 minutes ago   Up 32 minutes (healthy)   8080/tcp                                      cadvisor
7e9613075c35   postgres:15                                     "docker-entrypoint.s…"   32 minutes ago   Up 32 minutes             0.0.0.0:5433->5432/tcp, [::]:5433->5432/tcp   postgres_db  
```
4. Содержимое volume каталога с данными
```
итого 136
drwx------ 19 dnsmasq      root             4096 сен 18 13:23 .
drwxrwxr-x  3 stpdcybersec stpdcybersec     4096 сен 13 17:20 ..
drwxrwxrwx  7 dnsmasq      systemd-journal  4096 сен 13 18:00 base
drwxrwxrwx  2 dnsmasq      systemd-journal  4096 сен 18 13:30 global
drwxrwxrwx  2 dnsmasq      systemd-journal  4096 сен 13 17:20 pg_commit_ts
drwxrwxrwx  2 dnsmasq      systemd-journal  4096 сен 13 17:20 pg_dynshmem
-rwxrwxrwx  1 dnsmasq      systemd-journal  4917 сен 13 17:20 pg_hba.conf
-rwxrwxrwx  1 dnsmasq      systemd-journal  1636 сен 13 17:20 pg_ident.conf
drwxrwxrwx  4 dnsmasq      systemd-journal  4096 сен 18 13:23 pg_logical
drwxrwxrwx  4 dnsmasq      systemd-journal  4096 сен 13 17:20 pg_multixact
drwxrwxrwx  2 dnsmasq      systemd-journal  4096 сен 13 17:20 pg_notify
drwxrwxrwx  2 dnsmasq      systemd-journal  4096 сен 13 17:20 pg_replslot
drwxrwxrwx  2 dnsmasq      systemd-journal  4096 сен 13 17:20 pg_serial
drwxrwxrwx  2 dnsmasq      systemd-journal  4096 сен 13 17:20 pg_snapshots
drwxrwxrwx  2 dnsmasq      systemd-journal  4096 сен 18 12:55 pg_stat
drwxrwxrwx  2 dnsmasq      systemd-journal  4096 сен 13 17:20 pg_stat_tmp
drwxrwxrwx  2 dnsmasq      systemd-journal  4096 сен 13 17:20 pg_subtrans
drwxrwxrwx  2 dnsmasq      systemd-journal  4096 сен 13 17:20 pg_tblspc
drwxrwxrwx  2 dnsmasq      systemd-journal  4096 сен 13 17:20 pg_twophase
-rwxrwxrwx  1 dnsmasq      systemd-journal     3 сен 13 17:20 PG_VERSION
drwxrwxrwx  3 dnsmasq      systemd-journal  4096 сен 13 17:59 pg_wal
drwxrwxrwx  2 dnsmasq      systemd-journal  4096 сен 13 17:20 pg_xact
-rwxrwxrwx  1 dnsmasq      systemd-journal    88 сен 13 17:20 postgresql.auto.conf
-rwxrwxrwx  1 dnsmasq      systemd-journal 29517 сен 13 17:20 postgresql.conf
-rwxrwxrwx  1 dnsmasq      systemd-journal    36 сен 18 13:23 postmaster.opts
-rw-------  1 dnsmasq      systemd-journal    94 сен 18 13:23 postmaster.pid
```
5. Результат выполнения работы скрипта (список файлов)
```
итого 16
drwxrwxr-x 4 stpdcybersec stpdcybersec 4096 сен 18 14:02 .
drwxrwxr-x 3 stpdcybersec stpdcybersec 4096 сен 18 14:02 ..
drwxrwxrwx 3 stpdcybersec stpdcybersec 4096 сен 13 17:20 data
drwxrwxr-x 3 stpdcybersec stpdcybersec 4096 сен 18 14:01 logs
```
6. Результат выполнения работы скрипта (cat логов)
```
2025-09-18 14:01:55 - INFO: Starting backup of directories /home/stpdcybersec/docker-app-system/data /home/stpdcybersec/docker-app-system/logs to '/home/stpdcybersec/docker-app-system/backups/backup_20250918_140155.tar.gz'.
2025-09-18 14:02:10 - SUCCESS: Archive '/home/stpdcybersec/docker-app-system/backups/backup_20250918_140155.tar.gz' created successfully.
2025-09-18 14:02:10 - INFO: Verifying archive integrity.
2025-09-18 14:02:12 - SUCCESS: Archive '/home/stpdcybersec/docker-app-system/backups/backup_20250918_140155.tar.gz' verified successfully.
2025-09-18 14:02:12 - SUCCESS: Backup process completed successfully.
```
7. Скриншоты веб интерфейса, чтобы было видно адресную строку и имя базы данных, списка таблиц
[https://raw.githubusercontent.com/stpdcbersec/docker-app-system/screenshots/1.png](https://github.com/stpdcybersec/docker-app-system/blob/main/screenshots/1.png)
[https://raw.githubusercontent.com/stpdcbersec/docker-app-system/screenshots/2.png](https://github.com/stpdcybersec/docker-app-system/blob/main/screenshots/2.png)
[https://raw.githubusercontent.com/stpdcbersec/docker-app-system/screenshots/3.png](https://github.com/stpdcybersec/docker-app-system/blob/main/screenshots/3.png)
[https://raw.githubusercontent.com/stpdcbersec/docker-app-system/screenshots/4.png](https://github.com/stpdcybersec/docker-app-system/blob/main/screenshots/4.png)
[https://raw.githubusercontent.com/stpdcbersec/docker-app-system/screenshots/5.png](https://github.com/stpdcybersec/docker-app-system/blob/main/screenshots/5.png)
[https://raw.githubusercontent.com/stpdcbersec/docker-app-system/screenshots/6.png](https://github.com/stpdcybersec/docker-app-system/blob/main/screenshots/6.png)

