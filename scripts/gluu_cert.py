import os
import shlex
import socket
import ssl
import subprocess
import time

ALIAS = "gluu_https"
TRUSTSTORE = "/usr/lib/jvm/default-jvm/jre/lib/security/cacerts"
STOREPASS = "changeit"
GLUU_CERT = "/etc/certs/gluu_https.crt"
GLUU_SERVER_HOST = os.environ.get("GLUU_SERVER_HOST", "")


def exec_cmd(cmd):
    args = shlex.split(cmd)
    popen = subprocess.Popen(args,
                             stdin=subprocess.PIPE,
                             stdout=subprocess.PIPE,
                             stderr=subprocess.PIPE)
    stdout, stderr = popen.communicate()
    retcode = popen.returncode
    return stdout, stderr, retcode


def alias_exists(alias):
    cmd = " ".join([
        "keytool",
        "-list",
        "-alias", alias,
        "-keystore", TRUSTSTORE,
        "-storepass", STOREPASS,
    ])
    _, _, code = exec_cmd(cmd)

    if code != 0:
        return False
    return True


def cert_to_truststore(alias, file_):
    cmd = " ".join([
        "keytool",
        "-import",
        "-trustcacerts",
        "-alias", alias,
        "-file", file_,
        "-keystore", TRUSTSTORE,
        "-storepass", STOREPASS,
        "-noprompt",
    ])
    _, _, code = exec_cmd(cmd)

    if code != 0:
        return False
    return True


def get_server_certificate(host, port, filepath, server_hostname=""):
    server_hostname = server_hostname or host

    conn = ssl.create_connection((host, port))
    context = ssl.SSLContext(ssl.PROTOCOL_SSLv23)
    sock = context.wrap_socket(conn, server_hostname=server_hostname)
    cert = ssl.DER_cert_to_PEM_cert(sock.getpeercert(True))

    with open(filepath, "w") as f:
        f.write(cert.decode())


def main():
    if not GLUU_SERVER_HOST:
        return

    while True:
        if alias_exists(ALIAS):
            return

        try:
            get_server_certificate(GLUU_SERVER_HOST, 443, GLUU_CERT)
            if cert_to_truststore(ALIAS, GLUU_CERT):
                return
        except socket.error as exc:
            print("Unable to download Gluu Server cert; reason={}".format(exc))

        time.sleep(10)


if __name__ == "__main__":
    main()
