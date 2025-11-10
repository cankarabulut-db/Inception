#!/bin/bash

log_info() {
    echo "[INFO] $(date "+%Y-%m-%d %H:%M:%S") - $1"
}

log_error() {
    echo "[ERROR] $(date "+%Y-%m-%d %H:%M:%S") - $1" >&2
}

if [ -z "$DOMAIN_NAME" ]; then
    log_error "DOMAIN_NAME variable is not set! Please make sure it's defined in your .env file."
    exit 1
fi

log_info "Creating SSL directory: /etc/nginx/ssl"
mkdir -p /etc/nginx/ssl || { log_error "Failed to create directory."; exit 1; }

if [ ! -f ${SSL_KEYPATH} ]; then
    log_info "Generating SSL certificate... (valid for 1 year)"

    openssl req -x509 -nodes -days 365 -newkey rsa:4096 \
        -keyout ${SSL_KEYPATH} -out ${SSL_CERTPATH} \
        -subj "/C=TR/ST=ISTANBUL/L=SARIYER/O=42Istanbul/CN=${DOMAIN_NAME}" \
        || { log_error "Failed to generate SSL certificate."; exit 1; }

    chmod 600 ${SSL_KEYPATH}
    chmod 644 ${SSL_CERTPATH}

    log_info "SSL certificate successfully generated."
else
    log_info "SSL certificate already exists. Skipping generation."
fi

NPATH="/etc/nginx/sites-available/default"
cat > $NPATH << EOF
server {
    listen ${SSLPORT} ssl;
    listen [::]:${SSLPORT} ssl;
    server_name ${DOMAIN_NAME};

    ssl_certificate ${SSL_CERTPATH};
    ssl_certificate_key ${SSL_KEYPATH};
    ssl_protocols TLSv1.2 TLSv1.3;

    root /var/www/html;
    index index.php index.html index.htm;

    location / {
        try_files \$uri \$uri/ /index.php?\$args;
    }

    location ~ \\.php\$ {
        include fastcgi_params;
        fastcgi_pass wordpress:9000;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        fastcgi_index index.php;
    }
}
EOF

log_info "Starting NGINX service..."
exec "$@" || { log_error "Failed to start NGINX service."; exit 1; }
log_info "NGINX service started successfully."