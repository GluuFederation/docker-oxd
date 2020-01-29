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

keytool -genkey -noprompt \
  -alias oxd-server \
  -dname "CN=oxd-server, OU=ID, O=Gluu, L=Gluu, S=TX, C=US" \
  -keystore oxd-server.keystore \
  -storepass $APPLICATION_KEYSTORE_PASSWORD \
  -keypass $ADMIN_KEYSTORE_PASSWORD \
  -deststoretype pkcs12 \
  -keysize 2048 && mv oxd-server.keystore $CONF

sh $BIN/oxd-start.sh
