#!/bin/sh

set -e

BASEDIR=/opt/oxd-server
CONF=$BASEDIR/conf
LIB=$BASEDIR/lib
BIN=$BASEDIR/bin
envsubst < $CONF/oxd-server-template.yml > $CONF/oxd-server.yml

# ==========
# entrypoint
# ==========

# application keystore
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
        -passout pass:$APPLICATION_KEYSTORE_PASSWORD
fi

# admin keystore
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
        -passout pass:$ADMIN_KEYSTORE_PASSWORD
fi

# import Gluu Server cert to truststore (if any)
if [ ! -f /etc/certs/gluu_https.crt ]; then
    if [ ! -z $GLUU_SERVER_HOST ]; then
        openssl s_client -showcerts \
            -connect $GLUU_SERVER_HOST:443 </dev/null 2>/dev/null \
            | openssl x509 -outform PEM > /etc/certs/gluu_https.crt

        keytool -import -trustcacerts \
            -file /etc/certs/gluu_https.crt \
            -alias $GLUU_SERVER_HOST \
            -storepass changeit \
            -keystore /usr/lib/jvm/default-jvm/jre/lib/security/cacerts \
            -noprompt
    fi
fi

# run the server
sh $BIN/oxd-start.sh
