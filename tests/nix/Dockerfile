ARG BASE=ubuntu:24.04
FROM ${BASE}
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y \
    ca-certificates curl xz-utils git python3 sudo locales \
    && rm -rf /var/lib/apt/lists/* \
    && useradd -m -s /bin/bash tester \
    && mkdir /nix && chown tester /nix \
    && sed -i 's/^# en_US.UTF-8/en_US.UTF-8/' /etc/locale.gen && locale-gen
COPY --chown=tester . /work
USER tester
WORKDIR /work
RUN curl -fsSL https://releases.nixos.org/nix/nix-2.28.5/install -o /tmp/install-nix \
    && python3 -c 'import hashlib,json; assert hashlib.sha256(open("/tmp/install-nix","rb").read()).hexdigest() == json.load(open("nix/bootstrap.json"))["installerSha256"]' \
    && sh /tmp/install-nix --no-daemon --yes --no-channel-add \
    && mkdir -p /home/tester/.config/nix \
    && printf 'sandbox = false\n' > /home/tester/.config/nix/nix.conf
ENV PATH="/home/tester/.nix-profile/bin:${PATH}" \
    NIX_CONFIG="experimental-features = nix-command flakes" \
    DOTFILES_TEST_GUEST=1
CMD ["bash", "tests/nix/integration.sh"]
