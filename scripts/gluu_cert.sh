#!/bin/sh

set -e

ALIAS=gluu_https
TRUSTSTORE=/usr/lib/jvm/default-jvm/jre/lib/security/cacerts
STOREPASS=changeit
GLUU_CERT=/etc/certs/gluu_https.crt
GLUU_SERVER_HOST=${GLUU_SERVER_HOST:-""}

# likely not using Gluu Server; bail the process
if [ $GLUU_SERVER_HOST = "" ]; then
    exit 0
fi

while :
do
    # check if Gluu Server cert already stored in truststore
    alias_err=$(keytool -list -alias $ALIAS -keystore $TRUSTSTORE -storepass $STOREPASS | grep "error" || :)

    # if cert already imported, bail the process
    if [ -z "$alias_err" ]; then
        exit 0
    fi

    # download Gluu Server cert
    openssl s_client -showcerts \
        -connect $GLUU_SERVER_HOST:443 </dev/null 2>/dev/null \
        | openssl x509 -outform PEM > $GLUU_CERT || :

    # import cert to truststore
    if [ -f $GLUU_CERT ]; then
        keytool -import -trustcacerts \
            -file $GLUU_CERT \
            -alias $ALIAS \
            -storepass $STOREPASS \
            -keystore $TRUSTSTORE \
            -noprompt || :
    fi

    sleep 10
done
