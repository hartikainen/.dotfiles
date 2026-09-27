FROM ubuntu:26.04
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    ca-certificates curl python3 openssh-client cloud-image-utils qemu-system-arm \
    qemu-system-x86 qemu-utils qemu-efi-aarch64 seabios \
    && rm -rf /var/lib/apt/lists/*
COPY . /work
WORKDIR /work
ENV DOTFILES_TEST_GUEST=1
ENTRYPOINT ["python3", "tests/nix/vm.py"]
