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

sh $BIN/oxd-start.sh
