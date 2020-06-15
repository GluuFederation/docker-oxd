#!/bin/sh

set -e

gen_certs() {
    # application keystore
    if [ ! -f $APPLICATION_KEYSTORE_PASSWORD_FILE ]; then
        echo "example" > $APPLICATION_KEYSTORE_PASSWORD_FILE
    fi

    if [ ! -f $APPLICATION_KEYSTORE_PATH ]; then
        # generate cert and key if needed
        if [ ! -f /etc/certs/application.crt ]; then
            openssl req -x509 \
                -newkey rsa:2048 \
                -keyout /etc/certs/application.key \
                -out /etc/certs/application.crt \
                -days 365 \
                -subj "/CN=$APPLICATION_KEYSTORE_CN" \
                -nodes
        fi

        # create pkcs12 keystore
        openssl pkcs12 -export \
            -name oxd-server \
            -out $APPLICATION_KEYSTORE_PATH \
            -inkey /etc/certs/application.key \
            -in /etc/certs/application.crt \
            -passout pass:$(cat $APPLICATION_KEYSTORE_PASSWORD_FILE)
    fi

    # admin keystore
    if [ ! -f $ADMIN_KEYSTORE_PASSWORD_FILE ]; then
        echo "example" > $ADMIN_KEYSTORE_PASSWORD_FILE
    fi

    if [ ! -f $ADMIN_KEYSTORE_PATH ]; then
        # generate cert and key if needed
        if [ ! -f /etc/certs/admin.crt ]; then
            openssl req -x509 \
                -newkey rsa:2048 \
                -keyout /etc/certs/admin.key \
                -out /etc/certs/admin.crt \
                -days 365 \
                -subj "/CN=$ADMIN_KEYSTORE_CN" \
                -nodes
        fi

        # create pkcs12 keystore
        openssl pkcs12 -export \
            -name oxd-server \
            -out $ADMIN_KEYSTORE_PATH \
            -inkey /etc/certs/admin.key \
            -in /etc/certs/admin.crt \
            -passout pass:$(cat $ADMIN_KEYSTORE_PASSWORD_FILE)
    fi
}

# ==========
# entrypoint
# ==========

gen_certs

python3 /app/scripts/wait.py

if [ ! -f /deploy/touched ]; then
    python3 /app/scripts/entrypoint.py
    touch /deploy/touched
fi

# python3 /app/scripts/gluu_cert.py &


# run the server
exec sh /opt/oxd-server/bin/oxd-start.sh
