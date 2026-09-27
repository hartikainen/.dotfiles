import grp
import json
import os
from pathlib import Path
import pwd
import subprocess
import sys


def main():
    config = json.loads(Path(sys.argv[1]).read_text())
    missing = []
    for package in config["packages"]:
        result = subprocess.run(
            ["/usr/bin/dpkg-query", "-W", "-f=${db:Status-Status}", package],
            capture_output=True,
            text=True,
        )
        if result.returncode or result.stdout != "installed":
            missing.append(package)
    if missing:
        env = dict(os.environ, DEBIAN_FRONTEND="noninteractive")
        subprocess.run(["/usr/bin/apt-get", "update"], check=True, env=env)
        subprocess.run(
            [
                "/usr/bin/apt-get",
                "-o",
                "DPkg::Lock::Timeout=300",
                "install",
                "-y",
                "--no-install-recommends",
                *missing,
            ],
            check=True,
            env=env,
        )
    if "ubuntu-desktop-minimal" in config["packages"]:
        subprocess.run(
            ["/usr/bin/systemctl", "start", "display-manager.service"], check=True
        )
    username = config["dockerUser"]
    if username:
        pwd.getpwnam(username)
        try:
            group = grp.getgrnam("docker")
        except KeyError:
            subprocess.run(["/usr/sbin/groupadd", "--system", "docker"], check=True)
            group = grp.getgrnam("docker")
        if username not in group.gr_mem:
            subprocess.run(["/usr/sbin/usermod", "-aG", "docker", username], check=True)


if __name__ == "__main__":
    main()
