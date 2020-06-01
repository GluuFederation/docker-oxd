FROM adoptopenjdk/openjdk11:alpine-jre

# symlink JVM
RUN mkdir -p /usr/lib/jvm/default-jvm /usr/java/latest \
    && ln -sf /opt/java/openjdk /usr/lib/jvm/default-jvm/jre \
    && ln -sf /usr/lib/jvm/default-jvm/jre /usr/java/latest/jre

# ===============
# Alpine packages
# ===============

RUN apk update \
    && apk add --no-cache openssl py3-pip tini \
    && apk add --no-cache --virtual build-deps unzip wget git

# ==========
# OXD server
# ==========

ARG GLUU_VERSION=4.2.0-SNAPSHOT
ARG GLUU_BUILD_DATE="2020-05-30 08:22"

RUN wget -q https://ox.gluu.org/maven/org/gluu/oxd-server/${GLUU_VERSION}/oxd-server-${GLUU_VERSION}-distribution.zip -O /oxd.zip \
    && mkdir -p /opt/oxd-server \
    && unzip /oxd.zip -d /opt/oxd-server \
    && rm /oxd.zip \
    && rm -rf /opt/oxd-server/conf/oxd-server.keystore

EXPOSE 8443 8444

# ======
# Python
# ======

RUN apk add --no-cache py3-cryptography
COPY requirements.txt /tmp/requirements.txt
RUN pip3 install -U pip \
    && pip3 install --no-cache-dir -r /tmp/requirements.txt

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

# ===
# ENV
# ===

ENV APPLICATION_KEYSTORE_PATH=/opt/oxd-server/conf/oxd-server.keystore \
    APPLICATION_KEYSTORE_CN="localhost" \
    APPLICATION_KEYSTORE_PASSWORD_FILE=/etc/gluu/conf/app_keystore_password \
    ADMIN_KEYSTORE_PATH=/opt/oxd-server/conf/oxd-server.keystore \
    ADMIN_KEYSTORE_CN="localhost" \
    ADMIN_KEYSTORE_PASSWORD_FILE=/etc/gluu/conf/admin_keystore_password \
    GLUU_SERVER_HOST=""

# ====
# misc
# ====

LABEL name="oxd" \
    maintainer="Gluu Inc. <support@gluu.org>" \
    vendor="Gluu Federation" \
    version="4.2.0" \
    release="dev" \
    summary="Gluu oxd" \
    description="Client software to secure apps with OAuth 2.0, OpenID Connect, and UMA"

RUN mkdir -p /etc/certs /app/templates/ /deploy /etc/gluu/conf
COPY scripts /app/scripts
COPY templates/*.tmpl /app/templates/
RUN chmod +x /app/scripts/entrypoint.sh

ENTRYPOINT ["tini", "-e", "143", "-g", "--"]
CMD ["sh", "/app/scripts/entrypoint.sh"]
