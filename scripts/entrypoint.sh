#!/bin/sh

set -e

cat << LICENSE_ACK

# ================================================================================================ #
# Gluu License Agreement: https://github.com/GluuFederation/enterprise-edition/blob/4.0.0/LICENSE. #
# The use of Gluu Server Enterprise Edition is subject to the Gluu Support License.                #
# ================================================================================================ #

LICENSE_ACK

BASEDIR=/opt/oxd-server
CONF=$BASEDIR/conf
LIB=$BASEDIR/lib
BIN=$BASEDIR/bin


# handle sensitive info/creds

if [ -f /etc/certs/license_id ]; then
    jq ".license_id = \"$(cat /etc/certs/license_id)\"" $CONF/oxd-server.yml > /tmp/oxd-server.yml \
        && mv /tmp/oxd-server.yml $CONF/oxd-server.yml
fi

if [ -f /etc/certs/public_password ]; then
    jq ".public_password = \"$(cat /etc/certs/public_password)\"" $CONF/oxd-server.yml > /tmp/oxd-server.yml \
        && mv /tmp/oxd-server.yml $CONF/oxd-server.yml
fi

if [ -f /etc/certs/public_key ]; then
    jq ".public_key = \"$(cat /etc/certs/public_key)\"" $CONF/oxd-server.yml > /tmp/oxd-server.yml \
        && mv /tmp/oxd-server.yml $CONF/oxd-server.yml
fi

if [ -f /etc/certs/license_password ]; then
    jq ".license_password = \"$(cat /etc/certs/license_password)\"" $CONF/oxd-server.yml > /tmp/oxd-server.yml \
        && mv /tmp/oxd-server.yml $CONF/oxd-server.yml
fi

if [ -f /etc/certs/trust_store_password ]; then
    jq ".trust_store_password = \"$(cat /etc/certs/trust_store_password)\"" $CONF/oxd-server.yml > /tmp/oxd-server.yml \
        && mv /tmp/oxd-server.yml $CONF/oxd-server.yml
fi

if [ -f /etc/certs/crypt_provider_key_store_password ]; then
    jq ".crypt_provider_key_store_password = \"$(cat /etc/certs/crypt_provider_key_store_password)\"" $CONF/oxd-server.yml > /tmp/oxd-server.yml \
        && mv /tmp/oxd-server.yml $CONF/oxd-server.yml
fi

# ==========
# entrypoint
# ==========

sh $BIN/oxd-start.sh
