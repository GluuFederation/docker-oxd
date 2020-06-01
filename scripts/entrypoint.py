import os

from ruamel.yaml import safe_load
from ruamel.yaml import safe_dump

from pygluu.containerlib import get_manager
from pygluu.containerlib.persistence import render_couchbase_properties
from pygluu.containerlib.persistence import render_gluu_properties
from pygluu.containerlib.persistence import render_hybrid_properties
from pygluu.containerlib.persistence import render_ldap_properties
from pygluu.containerlib.persistence import render_salt
from pygluu.containerlib.persistence import sync_couchbase_truststore
from pygluu.containerlib.persistence import sync_ldap_truststore
# from pygluu.containerlib.utils import cert_to_truststore
# from pygluu.containerlib.utils import get_server_certificate

manager = get_manager()


# def get_gluu_cert():
#     if not os.environ.get("GLUU_SERVER_HOST", ""):
#         return

#     if not os.path.isfile("/etc/certs/gluu_https.crt"):
#         get_server_certificate(manager.config.get("hostname"), 443, "/etc/certs/gluu_https.crt")

#     cert_to_truststore(
#         "gluu_https",
#         "/etc/certs/gluu_https.crt",
#         "/usr/lib/jvm/default-jvm/jre/lib/security/cacerts",
#         "changeit",
#     )


def render_oxd_config():
    persistence_type = os.environ.get("GLUU_PERSISTENCE_TYPE", "ldap")

    app_keystore_file = os.environ.get("APPLICATION_KEYSTORE_PATH", "/opt/oxd-server/conf/oxd-server.keystore")
    admin_keystore_file = os.environ.get("ADMIN_KEYSTORE_PATH", "/opt/oxd-server/conf/oxd-server.keystore")

    app_keystore_password = "example"
    app_keystore_password_file = os.environ.get(
        "APPLICATION_KEYSTORE_PASSWORD_FILE",
        "/etc/gluu/conf/app_keystore_password",
    )
    with open(app_keystore_password_file) as f:
        app_keystore_password = f.read().strip()

    admin_keystore_password = "example"
    admin_keystore_password_file = os.environ.get(
        "ADMIN_KEYSTORE_PASSWORD_FILE",
        "/etc/gluu/conf/admin_keystore_password",
    )
    with open(admin_keystore_password_file) as f:
        admin_keystore_password = f.read().strip()

    with open("/app/templates/oxd-server.yml.tmpl") as f:
        data = safe_load(f.read())

    if persistence_type == "ldap":
        conn = "gluu-ldap.properties"
    elif persistence_type == "couchbase":
        conn = "gluu-couchbase.properties"
    else:
        conn = "gluu-hybrid.properties"

    data["storage_configuration"]["connection"] = f"/etc/gluu/conf/{conn}"
    data["server"]["applicationConnectors"][0]["keyStorePassword"] = app_keystore_password
    data["server"]["applicationConnectors"][0]["keyStorePath"] = app_keystore_file
    data["server"]["adminConnectors"][0]["keyStorePassword"] = admin_keystore_password
    data["server"]["adminConnectors"][0]["keyStorePath"] = admin_keystore_file

    with open("/opt/oxd-server/conf/oxd-server.yml", "w") as f:
        f.write(safe_dump(data))


def main():
    persistence_type = os.environ.get("GLUU_PERSISTENCE_TYPE", "ldap")

    render_salt(manager, "/app/templates/salt.tmpl", "/etc/gluu/conf/salt")
    render_gluu_properties("/app/templates/gluu.properties.tmpl", "/etc/gluu/conf/gluu.properties")

    if persistence_type in ("ldap", "hybrid"):
        render_ldap_properties(
            manager,
            "/app/templates/gluu-ldap.properties.tmpl",
            "/etc/gluu/conf/gluu-ldap.properties",
        )
        sync_ldap_truststore(manager)

    if persistence_type in ("couchbase", "hybrid"):
        render_couchbase_properties(
            manager,
            "/app/templates/gluu-couchbase.properties.tmpl",
            "/etc/gluu/conf/gluu-couchbase.properties",
        )
        sync_couchbase_truststore(manager)

    if persistence_type == "hybrid":
        render_hybrid_properties("/etc/gluu/conf/gluu-hybrid.properties")

    # @TODO: oxd-server config YAML
    # if not os.path.isfile("/opt/oxd-server/conf/oxd-server.yml"):
    render_oxd_config()


if __name__ == "__main__":
    main()
