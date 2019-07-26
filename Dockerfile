FROM openjdk:8-jre-alpine

LABEL maintainer="Gluu Inc. <support@gluu.org>"

# ===============
# Alpine packages
# ===============

RUN apk update && apk add --no-cache \
    wget \
    gettext \
	zip

# ==========
# OXD server
# ==========

ENV OX_VERSION=4.0.b1
ENV OX_BUILD_DATE=2019-03-15

RUN mkdir -p /app/scripts/
RUN wget -q https://ox.gluu.org/maven/org/gluu/oxd-server/${OX_VERSION}/oxd-server-${OX_VERSION}-distribution.zip -O /oxd.zip
cat https://ox.gluu.org/maven/org/gluu/oxd-server/${OX_VERSION}/oxd-server-${OX_VERSION}-distribution.zip
RUN unzip ./oxd.zip -d /opt/oxd-server

# ==
# jq
# ==

RUN wget -q https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64 -O /usr/bin/jq \
    && chmod +x /usr/bin/jq

# ====
# misc
# ====

RUN mkdir -p /etc/certs
COPY scripts /app/scripts
RUN chmod +x /app/scripts/entrypoint.sh
EXPOSE 8443 8444

# =====================
#################
# oxd-server ENV
#################
# =====================
# ==========
# server configuration ENV
# ==========
ENV USE_CLIENT_AUTHENTICATION_FOR_PAT true
ENV TRUST_ALL_CERTS false
ENV TRUST_STORE_PATH ''
ENV TRUST_STORE_PASSWORD ''
ENV CRYPT_PROVIDER_KEY_STORE_PATH ''
ENV CRYPT_PROVIDER_KEY_STORE_PASSWORD ''
ENV CRYPT_PROVIDER_DN_NAME ''
ENV SUPPORT_GOOGLE_LOGOUT true
ENV STATE_EXPIRATION_IN_MINUTES 5
ENV NONCE_EXPIRATION_IN_MINUTES 5
ENV PUBLIC_OP_KEY_CACHE_EXPIRATION_IN_MINUTES 60
ENV PROTECT_COMMANDS_WITH_ACCESS_TOKEN true
ENV UMA2_AUTO_REGISTER_CLAIMS_GATHERING_ENDPOINT_AS_REDIRECT_URI_OF_CLIENT false
ENV ADD_CLIENT_CREDENTIALS_GRANT_TYPE_AUTOMATICALLY_DURING_CLIENT_REGISTRATION true
ENV MIGRATION_SOURCE_FOLDER_PATH ''
ENV STORAGE h2
ENV DB_FILE_LOCATION /opt/oxd-server/data/oxd_db

# ==========
# Connectors ENV
# ==========

ENV APPLICATION_CONNECTOR_HTTPS_PORT 8443
ENV APPLICATION_KEYSTORE_PATH /opt/oxd-server/conf/oxd-server.keystore
ENV APPLICATION_KEYSTORE_PASSWORD example
ENV APPLICATION_KEYSTORE_VALIDATE_CERTS false
ENV ADMIN_CONNECTOR_HTTPS_PORT 8444
ENV ADMIN_KEYSTORE_PATH /opt/oxd-server/conf/oxd-server.keystore
ENV ADMIN_KEYSTORE_PASSWORD example
ENV ADMIN_KEYSTORE_VALIDATE_CERTS false

# ==========
# Logging ENV
# ==========

ENV GLUU_LOG_LEVEL TRACE
ENV XDI_LOG_LEVEL TRACE
ENV THRESHOLD TRACE
ENV CURRENT_LOG_FILENAME /var/log/oxd-server/oxd-server.log
ENV ARCHIVED_FILE_COUNT 7
ENV TIME_ZONE UTC
ENV MAX_FILE_SIZE 10MB

# ==========    
# DefaultSiteConfig ENV
# ==========

ENV DEFAULT_SITE_CONFIG_OP_HOST ''
ENV DEFAULT_SITE_CONFIG_OP_DISCOVERY_PATH ''
ENV DEFAULT_SITE_CONFIG_RESPONSE_TYPES ['code']
ENV DEFAULT_SITE_CONFIG_GRANT_TYPES ['authorization_code']
ENV DEFAULT_SITE_CONFIG_ACR_VALUES ['']
ENV DEFAULT_SITE_CONFIG_SCOPE ['openid', 'profile', 'email']
ENV DEFAULT_SITE_CONFIG_UI_LOCALES ['en']
ENV DEFAULT_SITE_CONFIG_CLAIMS_LOCALES ['en']
ENV DEFAULT_SITE_CONFIG_CONTACTS []


CMD ["sh", "/app/scripts/entrypoint.sh"]

