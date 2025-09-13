#!/bin/bash

# Определение переменных
SOURCE_DIRS=(
    "/home/stpdcybersec/docker-app-system/data"
    "/home/stpdcybersec/docker-app-system/logs"
)  # Каталоги для бэкапа
BACKUP_DIR="/home/stpdcybersec/docker-app-system/backups"  # Каталог для хранения архива
ARCHIVE_NAME="backup_$(date +%Y%m%d_%H%M%S).tar.gz"  # Имя архива с timestamp
LOG_FILE="/home/stpdcybersec/docker-app-system/logs/backup.log"  # Файл лога
ARCHIVE_PATH="$BACKUP_DIR/$ARCHIVE_NAME"  # Путь к архиву

# Функция для логирования
log_message() 
{
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

# Обработчик ошибок
set -e  # Выход при любой ошибке
trap 'log_message "ERROR: Script failed at line $LINENO"; exit 1' ERR INT TERM

# Проверка наличия исходных каталогов
for dir in "${SOURCE_DIRS[@]}"; do
    if [ ! -d "$dir" ]; then
        log_message "ERROR: Source directory '$dir' does not exist."
        exit 1
    fi
done

# Проверка наличия каталога бэкапа и его создание, если он не существует
if [ ! -d "$BACKUP_DIR" ]; then
    mkdir -p "$BACKUP_DIR"
    if [ $? -ne 0 ]; then
        log_message "ERROR: Failed to create backup directory '$BACKUP_DIR'."
        exit 1
    fi
    log_message "INFO: Created backup directory '$BACKUP_DIR'."
fi

# Создание архива
log_message "INFO: Starting backup of directories ${SOURCE_DIRS[*]} to '$ARCHIVE_PATH'."
tar -czf "$ARCHIVE_PATH" -C /home/stpdcybersec/docker-app-system data logs 2>> "$LOG_FILE"
if [ $? -ne 0 ]; then
    log_message "ERROR: Failed to create archive '$ARCHIVE_PATH'."
    exit 1
else
    log_message "SUCCESS: Archive '$ARCHIVE_PATH' created successfully."
fi

# Проверка целостности архива
log_message "INFO: Verifying archive integrity."
if tar -tzf "$ARCHIVE_PATH" >/dev/null 2>> "$LOG_FILE"; then
    log_message "SUCCESS: Archive '$ARCHIVE_PATH' verified successfully."
else
    log_message "ERROR: Archive '$ARCHIVE_PATH' integrity check failed."
    rm -f "$ARCHIVE_PATH"  # Удаление архива, если он повреждён
    exit 1
fi

log_message "SUCCESS: Backup process completed successfully."
exit 0
