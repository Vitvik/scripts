#!/bin/bash

# Створення zip-архіву
zip -r /backup_folder/backup.zip /tmp/data

# Копіювання архіву на сервер резервного копіювання
scp /backup_folder/backup.zip backup_user@backup_server:/backup_folder/

# Перевірка успішності копіювання
if [ $? -eq 0 ]; then
    echo "Backup успішно створено та скопійовано на сервер резервного копіювання."
else
    echo "Помилка при копіюванні backup на сервер резервного копіювання."
fi

# sudo chmod +x /scripts/backup.sh
# потрібен  SSH-ключі для безпарольного доступу
# crontab -e
# 0 1 * * * /scripts/media_backup.sh
