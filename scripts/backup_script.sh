#!/bin/bash

# Конфигурация
BACKUP_DIR="./backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_NAME="backup_$TIMESTAMP"
BACKUP_PATH="$BACKUP_DIR/$BACKUP_NAME"

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Функция логирования
log() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"
}

# Функция для проверки ошибок
check_error() {
    if [ $? -ne 0 ]; then
        echo -e "${RED}❌ Error: $1${NC}"
        exit 1
    fi
}

# Создаем директорию для бэкапов
mkdir -p "$BACKUP_PATH"
mkdir -p "$BACKUP_PATH/postgres_data"
mkdir -p "$BACKUP_PATH/logs"
mkdir -p "$BACKUP_PATH/configs"

echo -e "${GREEN}=== Starting System Backup ===${NC}"
log "Backup started at: $(date)"
log "Backup directory: $BACKUP_PATH"

# 1. Резервное копирование данных PostgreSQL
echo -e "${YELLOW}1. Backing up PostgreSQL data...${NC}"
log "Copying PostgreSQL data files..."

# Копируем данные PostgreSQL с хоста
cp -r ./data/postgres/* "$BACKUP_PATH/postgres_data/" 2>/dev/null || log "No PostgreSQL data files found"

# 2. Резервное копирование логов
echo -e "${YELLOW}2. Backing up logs...${NC}"
log "Copying log files..."

# Копируем логи Nginx
if [ -d "./logs/nginx" ]; then
    cp -r ./logs/nginx/* "$BACKUP_PATH/logs/" 2>/dev/null
    log "Nginx logs copied"
else
    log "No Nginx logs found"
fi

# Копируем логи из контейнеров
log "Exporting container logs..."
docker logs postgres_db > "$BACKUP_PATH/logs/postgres_log.log" 2>/dev/null || log "Failed to get PostgreSQL logs"
docker logs pgadmin > "$BACKUP_PATH/logs/pgadmin_log.log" 2>/dev/null || log "Failed to get PgAdmin logs"
docker logs nginx_proxy > "$BACKUP_PATH/logs/nginx_log.log" 2>/dev/null || log "Failed to get Nginx logs"

# 3. Резервное копирование конфигураций
echo -e "${YELLOW}3. Backing up configurations...${NC}"
log "Copying configuration files..."

# Копируем конфиги Nginx
cp ./nginx/nginx.conf "$BACKUP_PATH/configs/nginx.conf" 2>/dev/null || log "Nginx config not found"

# Копируем Docker Compose файл
cp ./docker-compose.yml "$BACKUP_PATH/configs/docker-compose.yml" 2>/dev/null || log "Docker compose file not found"

# Копируем скрипты
if [ -d "./scripts" ]; then
    cp -r ./scripts/* "$BACKUP_PATH/configs/scripts/" 2>/dev/null
    log "Scripts copied"
fi

# 4. Резервное копирование баз данных PostgreSQL
echo -e "${YELLOW}4. Backing up PostgreSQL databases...${NC}"
log "Creating database dumps..."

# Создаем дампы всех баз данных
DATABASES=$(docker exec -i postgres_db psql -U admin -d postgres -t -c "SELECT datname FROM pg_database WHERE datistemplate = false AND datname NOT IN ('postgres');")

for DB in $DATABASES; do
    log "Backing up database: $DB"
    docker exec -i postgres_db pg_dump -U admin -d "$DB" -F c > "$BACKUP_PATH/${DB}_backup.dump" 2>/dev/null
    if [ $? -eq 0 ]; then
        log "✅ Database $DB backed up successfully"
    else
        log "❌ Failed to backup database $DB"
    fi
done

# 5. Информация о системе
echo -e "${YELLOW}5. Saving system information...${NC}"
log "Collecting system info..."

# Сохраняем информацию о Docker
docker ps -a > "$BACKUP_PATH/system_info/docker_containers.txt"
docker images > "$BACKUP_PATH/system_info/docker_images.txt"
docker network ls > "$BACKUP_PATH/system_info/docker_networks.txt"

# Сохраняем информацию о портах
netstat -tlnp > "$BACKUP_PATH/system_info/network_ports.txt" 2>/dev/null || ss -tlnp > "$BACKUP_PATH/system_info/network_ports.txt"

# 6. Создаем архив бэкапа
echo -e "${YELLOW}6. Creating backup archive...${NC}"
log "Compressing backup..."

cd "$BACKUP_DIR" && tar -czf "${BACKUP_NAME}.tar.gz" "$BACKUP_NAME" && cd - > /dev/null
check_error "Failed to create backup archive"

# Удаляем временную директорию
rm -rf "$BACKUP_PATH"

# 7. Очистка старых бэкапов (сохраняем последние 7)
echo -e "${YELLOW}7. Cleaning up old backups...${NC}"
BACKUP_COUNT=$(ls -1 "$BACKUP_DIR"/*.tar.gz 2>/dev/null | wc -l)
if [ $BACKUP_COUNT -gt 7 ]; then
    ls -t "$BACKUP_DIR"/*.tar.gz | tail -n +8 | xargs rm -f
    log "Removed $(($BACKUP_COUNT - 7)) old backup(s)"
fi

# 8. Финальный отчет
echo -e "${GREEN}=== Backup Completed Successfully! ===${NC}"
log "Backup completed at: $(date)"

# Информация о созданном бэкапе
BACKUP_FILE="${BACKUP_NAME}.tar.gz"
BACKUP_SIZE=$(du -h "$BACKUP_DIR/$BACKUP_FILE" | cut -f1)

echo -e "${GREEN}📦 Backup file: ${BACKUP_DIR}/${BACKUP_FILE}${NC}"
echo -e "${GREEN}💾 Backup size: $BACKUP_SIZE${NC}"
echo -e "${GREEN}📊 Databases backed up: $(echo $DATABASES | wc -w)${NC}"

# Добавляем запись в лог
echo "$(date): Backup created - ${BACKUP_FILE} (size: $BACKUP_SIZE)" >> "$BACKUP_DIR/backup.log"

echo -e "${GREEN}✅ Backup process completed!${NC}"
