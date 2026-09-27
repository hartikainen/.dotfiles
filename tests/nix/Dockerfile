ARG BASE=ubuntu:26.04
FROM ${BASE}
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y \
    ca-certificates curl xz-utils git python3 sudo locales dbus dconf-service libarchive-tools \
    && rm -rf /var/lib/apt/lists/* \
    && useradd -m -s /bin/bash tester \
    && mkdir /nix && chown tester /nix \
    && sed -i 's/^# en_US.UTF-8/en_US.UTF-8/' /etc/locale.gen && locale-gen
COPY --chown=tester . /work
USER tester
WORKDIR /work
# Use `bsdtar` for bootstrap until Rosetta implements `openat2`.
# https://github.com/orbstack/orbstack/issues/2588
RUN curl -fsSL https://releases.nixos.org/nix/nix-2.34.4/install -o /tmp/install-nix \
    && python3 -c 'import hashlib,json; assert hashlib.sha256(open("/tmp/install-nix","rb").read()).hexdigest() == json.load(open("nix/bootstrap.json"))["installerSha256"]' \
    && mkdir /tmp/nix-bootstrap-tools \
    && ln -s /usr/bin/bsdtar /tmp/nix-bootstrap-tools/tar \
    && NIX_CONFIG='filter-syscalls = false' PATH="/tmp/nix-bootstrap-tools:${PATH}" sh /tmp/install-nix --no-daemon --yes --no-channel-add \
    && rm -rf /tmp/nix-bootstrap-tools \
    && mkdir -p /home/tester/.config/nix \
    && printf 'sandbox = false\nfilter-syscalls = false\n' > /home/tester/.config/nix/nix.conf
ENV PATH="/home/tester/.nix-profile/bin:${PATH}" \
    NIX_CONFIG="experimental-features = nix-command flakes" \
    DOTFILES_TEST_GUEST=1
CMD ["bash", "tests/nix/integration.sh"]
