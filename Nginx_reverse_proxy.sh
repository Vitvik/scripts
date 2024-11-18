#!/bin/bash

# 1. Встановлення Apache
yum install -y httpd

# Налаштування Apache порту
cat > /etc/httpd/conf.d/port.conf << EOF
Listen 6200
EOF

# 2. Встановлення Nginx
yum install -y nginx

# Налаштування Nginx
cat > /etc/nginx/conf.d/proxy.conf << EOF
server {
    listen 8095;
    server_name _;

    location / {
        proxy_pass http://127.0.0.1:6200;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

# 3. Копіювання index файлу
cp /home/thor/index.html /var/www/html/

# 4. Встановлення правильних прав
chown apache:apache /var/www/html/index.html
chmod 644 /var/www/html/index.html

# 5. Запуск сервісів
systemctl start httpd
systemctl enable httpd
systemctl start nginx
systemctl enable nginx

# 6. Перевірка статусу
systemctl status httpd
systemctl status nginx

# 7. Перевірка портів
netstat -tulpn | grep -E '6200|8095'
