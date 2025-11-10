#!/bin/bash

DB_ROOT_PASSWORD=$(cat /run/secrets/db_root_password)
DB_PASSWORD=$(cat /run/secrets/db_password)
DB_USER=${MYSQL_USER}
DB_NAME=${MYSQL_DATABASE}

INITIALIZED_FLAG="/var/lib/mysql/.initialized"

if [ ! -f "$INITIALIZED_FLAG" ]; then
    echo "[INIT] Starting database initialization..." >&2
    
    if [ ! -d "/var/lib/mysql/mysql" ]; then
        echo "[INIT] Initializing MariaDB data directory..." >&2
        mysqld --initialize --user=mysql 2>&1 | tee -a /tmp/init.log
    fi

    echo "[INIT] Starting MariaDB daemon..." >&2
    mysqld_safe --skip-networking --user=mysql >> /tmp/mysqld_safe.log 2>&1 &
    BOOT_PID=$!

    echo "[INIT] Waiting for MariaDB to respond..." >&2
    for i in {1..30}; do
        if mysqladmin ping --silent 2>/dev/null; then
            echo "[INIT] MariaDB is ready" >&2
            break
        fi
        echo "[INIT] Waiting... ($i/30)" >&2
        sleep 1
    done

    echo "[INIT] Setting up databases and users..." >&2
    mysql -uroot <<EOF 2>&1 | tee -a /tmp/init.log
SET PASSWORD FOR 'root'@'localhost' = PASSWORD('${DB_ROOT_PASSWORD}');
UPDATE mysql.user SET plugin='mysql_native_password' WHERE user='root' AND host='localhost';
CREATE USER IF NOT EXISTS 'root'@'%' IDENTIFIED BY '${DB_ROOT_PASSWORD}';
GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' WITH GRANT OPTION;
CREATE DATABASE IF NOT EXISTS \`${DB_NAME}\`;
CREATE USER IF NOT EXISTS '${DB_USER}'@'%' IDENTIFIED BY '${DB_PASSWORD}';
GRANT ALL PRIVILEGES ON \`${DB_NAME}\`.* TO '${DB_USER}'@'%';
FLUSH PRIVILEGES;
EOF

    echo "[INIT] Shutting down MariaDB for restart..." >&2
    mysqladmin -uroot shutdown 2>&1 | tee -a /tmp/init.log || true
    sleep 2
    wait "$BOOT_PID" 2>/dev/null || true
    
    echo "[INIT] Creating initialized flag..." >&2
    touch "$INITIALIZED_FLAG" 2>/dev/null || echo "[WARN] Could not create flag file" >&2
    echo "[INIT] Database initialization complete" >&2
else
    echo "[INIT] Database already initialized, skipping setup..." >&2
fi

echo "[BOOT] Starting MariaDB server..." >&2
exec mysqld_safe --user=mysql



