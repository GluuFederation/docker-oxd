FROM openjdk:8-jre-alpine

LABEL maintainer="Gluu Inc. <support@gluu.org>"

# ===============
# Alpine packages
# ===============

RUN apk update && apk add --no-cache \
    wget \
    gettext \
    openssl \
    unzip

# ==========
# OXD server
# ==========

ENV OX_VERSION=4.0.b1 \
    OX_BUILD_DATE=2019-08-30

RUN wget -q https://ox.gluu.org/maven/org/gluu/oxd-server/${OX_VERSION}/oxd-server-${OX_VERSION}-distribution.zip -O /oxd.zip \
    && mkdir -p /opt/oxd-server \
    && unzip /oxd.zip -d /opt/oxd-server \
    && rm /oxd.zip

EXPOSE 8443 8444

# =======
# License
# =======

RUN mkdir -p /licenses
COPY LICENSE /licenses/

# =====================
# oxd-server ENV
# =====================

# ==========
# server configuration ENV
# ==========
ENV USE_CLIENT_AUTHENTICATION_FOR_PAT=true \
    TRUST_ALL_CERTS=false \
    TRUST_STORE_PATH='' \
    TRUST_STORE_PASSWORD='' \
    CRYPT_PROVIDER_KEY_STORE_PATH='' \
    CRYPT_PROVIDER_KEY_STORE_PASSWORD='' \
    CRYPT_PROVIDER_DN_NAME='' \
    SUPPORT_GOOGLE_LOGOUT=true \
    STATE_EXPIRATION_IN_MINUTES=5 \
    NONCE_EXPIRATION_IN_MINUTES=5 \
    PUBLIC_OP_KEY_CACHE_EXPIRATION_IN_MINUTES=60 \
    PROTECT_COMMANDS_WITH_ACCESS_TOKEN=true \
    UMA2_AUTO_REGISTER_CLAIMS_GATHERING_ENDPOINT_AS_REDIRECT_URI_OF_CLIENT=false \
    ADD_CLIENT_CREDENTIALS_GRANT_TYPE_AUTOMATICALLY_DURING_CLIENT_REGISTRATION=true \
    MIGRATION_SOURCE_FOLDER_PATH='' \
    STORAGE=h2 \
    DB_FILE_LOCATION=/opt/oxd-server/data/oxd_db

# ==========
# Connectors ENV
# ==========

ENV APPLICATION_CONNECTOR_HTTPS_PORT=8443 \
    APPLICATION_KEYSTORE_PATH=/opt/oxd-server/conf/oxd-server.keystore \
    APPLICATION_KEYSTORE_PASSWORD=example \
    APPLICATION_KEYSTORE_VALIDATE_CERTS=false \
    ADMIN_CONNECTOR_HTTPS_PORT=8444 \
    ADMIN_KEYSTORE_PATH=/opt/oxd-server/conf/oxd-server.keystore \
    ADMIN_KEYSTORE_PASSWORD=example \
    ADMIN_KEYSTORE_VALIDATE_CERTS=false

# ==========
# Logging ENV
# ==========

ENV GLUU_LOG_LEVEL=TRACE \
    XDI_LOG_LEVEL=TRACE \
    THRESHOLD=TRACE \
    CURRENT_LOG_FILENAME=/var/log/oxd-server/oxd-server.log \
    ARCHIVED_FILE_COUNT=7 \
    TIME_ZONE=UTC \
    MAX_FILE_SIZE=10MB

# ==========
# DefaultSiteConfig ENV
# ==========

ENV DEFAULT_SITE_CONFIG_OP_HOST="" \
    DEFAULT_SITE_CONFIG_OP_DISCOVERY_PATH=""
ENV DEFAULT_SITE_CONFIG_RESPONSE_TYPES ['code']
ENV DEFAULT_SITE_CONFIG_GRANT_TYPES ['authorization_code']
ENV DEFAULT_SITE_CONFIG_ACR_VALUES ['']
ENV DEFAULT_SITE_CONFIG_SCOPE ['openid', 'profile', 'email']
ENV DEFAULT_SITE_CONFIG_UI_LOCALES ['en']
ENV DEFAULT_SITE_CONFIG_CLAIMS_LOCALES ['en']
ENV DEFAULT_SITE_CONFIG_CONTACTS []

# ====
# misc
# ====

RUN mkdir -p /etc/certs /app
COPY scripts /app/scripts
RUN chmod +x /app/scripts/entrypoint.sh

COPY oxd-server-template.yml /opt/oxd-server/conf/
RUN chmod +x /app/scripts/entrypoint.sh
CMD ["sh", "/app/scripts/entrypoint.sh"]
