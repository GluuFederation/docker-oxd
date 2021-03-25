FROM alpine:3.13

# ===============
# Alpine packages
# ===============

RUN apk update \
    && apk add --no-cache openssl py3-pip tini curl openjdk11-jre-headless py3-cryptography \
    && apk add --no-cache --virtual build-deps unzip wget git \
    && mkdir -p /usr/java/latest \
    && ln -sf /usr/lib/jvm/default-jvm/jre /usr/java/latest/jre

# ==========
# OXD server
# ==========

ENV GLUU_VERSION=4.3.0-SNAPSHOT
ENV GLUU_BUILD_DATE="2021-02-05 14:32"

RUN wget -q https://ox.gluu.org/maven/org/gluu/oxd-server/${GLUU_VERSION}/oxd-server-${GLUU_VERSION}-distribution.zip -O /oxd.zip \
    && mkdir -p /opt/oxd-server \
    && unzip -qq /oxd.zip -d /opt/oxd-server \
    && rm /oxd.zip \
    && rm -rf /opt/oxd-server/conf/oxd-server.keystore /opt/oxd-server/conf/oxd-server.yml

EXPOSE 8443 8444

# ======
# Python
# ======

COPY requirements.txt /app/requirements.txt
RUN pip3 install -U pip \
    && pip3 install --no-cache-dir -r /app/requirements.txt \
    && rm -rf /src/pygluu-containerlib/.git

# =======
# Cleanup
# =======

RUN apk del build-deps \
    && rm -rf /var/cache/apk/*

# =======
# License
# =======

RUN mkdir -p /licenses
COPY LICENSE /licenses/

# ==========
# Config ENV
# ==========

ENV GLUU_CONFIG_ADAPTER=consul \
    GLUU_CONFIG_CONSUL_HOST=localhost \
    GLUU_CONFIG_CONSUL_PORT=8500 \
    GLUU_CONFIG_CONSUL_CONSISTENCY=stale \
    GLUU_CONFIG_CONSUL_SCHEME=http \
    GLUU_CONFIG_CONSUL_VERIFY=false \
    GLUU_CONFIG_CONSUL_CACERT_FILE=/etc/certs/consul_ca.crt \
    GLUU_CONFIG_CONSUL_CERT_FILE=/etc/certs/consul_client.crt \
    GLUU_CONFIG_CONSUL_KEY_FILE=/etc/certs/consul_client.key \
    GLUU_CONFIG_CONSUL_TOKEN_FILE=/etc/certs/consul_token \
    GLUU_CONFIG_KUBERNETES_NAMESPACE=default \
    GLUU_CONFIG_KUBERNETES_CONFIGMAP=gluu \
    GLUU_CONFIG_KUBERNETES_USE_KUBE_CONFIG=false

# ==========
# Secret ENV
# ==========

ENV GLUU_SECRET_ADAPTER=vault \
    GLUU_SECRET_VAULT_SCHEME=http \
    GLUU_SECRET_VAULT_HOST=localhost \
    GLUU_SECRET_VAULT_PORT=8200 \
    GLUU_SECRET_VAULT_VERIFY=false \
    GLUU_SECRET_VAULT_ROLE_ID_FILE=/etc/certs/vault_role_id \
    GLUU_SECRET_VAULT_SECRET_ID_FILE=/etc/certs/vault_secret_id \
    GLUU_SECRET_VAULT_CERT_FILE=/etc/certs/vault_client.crt \
    GLUU_SECRET_VAULT_KEY_FILE=/etc/certs/vault_client.key \
    GLUU_SECRET_VAULT_CACERT_FILE=/etc/certs/vault_ca.crt \
    GLUU_SECRET_KUBERNETES_NAMESPACE=default \
    GLUU_SECRET_KUBERNETES_SECRET=gluu \
    GLUU_SECRET_KUBERNETES_USE_KUBE_CONFIG=false

# ===============
# Persistence ENV
# ===============

ENV GLUU_PERSISTENCE_TYPE=ldap \
    GLUU_PERSISTENCE_LDAP_MAPPING=default \
    GLUU_LDAP_URL=localhost:1636 \
    GLUU_LDAP_USE_SSL=true \
    GLUU_COUCHBASE_URL=localhost \
    GLUU_COUCHBASE_USER=admin \
    GLUU_COUCHBASE_CERT_FILE=/etc/certs/couchbase.crt \
    GLUU_COUCHBASE_PASSWORD_FILE=/etc/gluu/conf/couchbase_password \
    GLUU_COUCHBASE_CONN_TIMEOUT=10000 \
    GLUU_COUCHBASE_CONN_MAX_WAIT=20000 \
    GLUU_COUCHBASE_SCAN_CONSISTENCY=not_bounded \
    GLUU_COUCHBASE_BUCKET_PREFIX=gluu \
    GLUU_COUCHBASE_TRUSTSTORE_ENABLE=true \
    GLUU_COUCHBASE_KEEPALIVE_INTERVAL=30000 \
    GLUU_COUCHBASE_KEEPALIVE_TIMEOUT=2500

# =======
# oxD ENV
# =======

ENV GLUU_OXD_APPLICATION_CERT_CN="localhost" \
    GLUU_OXD_ADMIN_CERT_CN="localhost" \
    GLUU_OXD_BIND_IP_ADDRESSES="*"

# ===========
# Generic ENV
# ===========

ENV GLUU_MAX_RAM_PERCENTAGE=75.0 \
    GLUU_WAIT_MAX_TIME=300 \
    GLUU_WAIT_SLEEP_DURATION=10 \
    GLUU_JAVA_OPTIONS="" \
    GLUU_SSL_CERT_FROM_SECRETS=false

# ====
# misc
# ====

LABEL name="oxd" \
    maintainer="Gluu Inc. <support@gluu.org>" \
    vendor="Gluu Federation" \
    version="4.3.0" \
    release="dev" \
    summary="Gluu oxd" \
    description="Client software to secure apps with OAuth 2.0, OpenID Connect, and UMA"

RUN mkdir -p /etc/certs /app/templates/ /deploy /etc/gluu/conf
COPY scripts /app/scripts
COPY templates/*.tmpl /app/templates/
RUN chmod +x /app/scripts/entrypoint.sh

ENTRYPOINT ["tini", "-e", "143", "-g", "--"]
CMD ["sh", "/app/scripts/entrypoint.sh"]
