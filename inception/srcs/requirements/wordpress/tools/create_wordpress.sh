#!/bin/sh

log_info() {
    echo "[INFO] $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_error() {
    echo "[ERROR] $(date '+%Y-%m-%d %H:%M:%S') - $1" >&2
}

export WP_ADMIN_PASSWORD=$(cat /run/secrets/wp_admin_password)
export WP_USER_PASSWORD=$(cat /run/secrets/wp_user_password)
export MYSQL_PASSWORD=$(cat /run/secrets/db_password)


if [ -f ./wp-config.php ]; then
    log_info "WordPress already exists. Skipping download."
else
    log_info "Downloading WordPress..."
    wget http://wordpress.org/latest.tar.gz || { log_error "Failed to download WordPress."; exit 1; }

    log_info "Extracting WordPress..."
    tar xfz latest.tar.gz && mv wordpress/* . && rm -rf latest.tar.gz wordpress

    log_info "Configuring wp-config.php..."
    sed -i "s/username_here/$MYSQL_USER/g" wp-config-sample.php
    sed -i "s/password_here/$MYSQL_PASSWORD/g" wp-config-sample.php
    sed -i "s/localhost/$MYSQL_HOSTNAME/g" wp-config-sample.php
    sed -i "s/database_name_here/$MYSQL_DATABASE/g" wp-config-sample.php
    cp wp-config-sample.php wp-config.php
    log_info "Generated wp-config.php:"
    head -n 100 wp-config.php
fi

if ! wp core is-installed --allow-root; then
    log_info "Installing WordPress core..."
    timeout=60  # maksimum süre (saniye cinsinden)
    counter=0

    until mysqladmin ping -h ${MYSQL_HOSTNAME} --silent; do
        if [ $counter -ge $timeout ]; then
            echo "TIMEOUT: MariaDB ${MYSQL_HOSTNAME}"
            exit 1
        fi
        echo "MariaDB Starting... (${counter}s)"
        sleep 1
        counter=$((counter+1))
    done

    wp core install \
        --url="https://$DOMAIN_NAME" \
        --title="$WP_TITLE" \
        --admin_user="$WP_ADMIN_USER" \
        --admin_password="$WP_ADMIN_PASSWORD" \
        --admin_email="$WP_ADMIN_EMAIL" \
        --skip-email \
        --allow-root || { log_error "WordPress installation failed."; exit 1; }

    wp user create "${WP_USER_NAME}" "${WP_USER_EMAIL}" \
        --role=author \
        --user_pass="${WP_USER_PASSWORD}" \
        --allow-root || { log_error "Failed to create WordPress user."; exit 1; }

fi

log_info "Startup script completed successfully."
exec "$@"
