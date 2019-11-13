#!/bin/sh

set -e

cat << LICENSE_ACK

# ================================================================================= #
# Gluu License Agreement: https://www.gluu.org/support-license/                     #
# The use of Gluu Server Enterprise Edition is subject to the Gluu Support License. #
# ================================================================================= #

LICENSE_ACK

BASEDIR=/opt/oxd-server
CONF=$BASEDIR/conf
LIB=$BASEDIR/lib
BIN=$BASEDIR/bin
envsubst < $CONF/oxd-server-template.yml > $CONF/oxd-server.yml

# ==========
# entrypoint
# ==========

sh $BIN/oxd-start.sh
