import os
import socket
import time

from pygluu.containerlib import get_manager
# from pygluu.containerlib.utils import exec_cmd
from pygluu.containerlib.utils import cert_to_truststore
from pygluu.containerlib.utils import get_server_certificate

# ALIAS = "gluu_https"
# TRUSTSTORE = "/usr/lib/jvm/default-jvm/jre/lib/security/cacerts"
# STOREPASS = "changeit"
# GLUU_CERT = "/etc/certs/gluu_https.crt"
GLUU_SERVER_HOST = os.environ.get("GLUU_SERVER_HOST", "")

manager = get_manager()


# def alias_exists(alias):
#     cmd = " ".join([
#         "keytool",
#         "-list",
#         "-alias", alias,
#         "-keystore", TRUSTSTORE,
#         "-storepass", STOREPASS,
#     ])
#     _, _, code = exec_cmd(cmd)

#     if code != 0:
#         return False
#     return True


def main():
    if not GLUU_SERVER_HOST:
        return

    while True:
        # if alias_exists(ALIAS):
        #     return

        try:
            if not os.path.isfile("/etc/certs/gluu_https.crt"):
                get_server_certificate(manager.config.get("hostname"), 443, "/etc/certs/gluu_https.crt")

            _, _, retcode = cert_to_truststore(
                "gluu_https",
                "/etc/certs/gluu_https.crt",
                "/usr/lib/jvm/default-jvm/jre/lib/security/cacerts",
                "changeit",
            )
            if retcode == 0:
                return
        except socket.error as exc:
            print(f"Unable to download Gluu Server cert; reason={exc}")

        time.sleep(10)


if __name__ == "__main__":
    main()
