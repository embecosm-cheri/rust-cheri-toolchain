#!/bin/bash
# Script for checking out sources of branches

# Variables used in this script
TOPDIR="$(realpath $(dirname $0)/../../)"
CHERIDIR="${HOME}/cheri/output/"

# Build the Morello CheriBSD SDK.

(
  set -e
  cd ${TOPDIR}/cheribuild
  ./cheribuild.py cheribsd-sdk-morello-purecap --qemu/no-use-smbd --skip-update
)


# Ensure we have the Morello tools on our PATH before building Rust.
PATH=${CHERIDIR}/morello-sdk/bin:${PATH}

# Build Rust for Morello.

(
  set -e
  cd ${TOPDIR}/rust
  cp config.toml.morello config.toml
  ./x.py build --target=morello-unknown-freebsd-purecap library/std
)

# Can we copy from the build directory to an install directory?

# Optionally, build the remote-test-server binary for Morello.
(
  set -e
  cd ${TOPDIR}/rust
  ./x.py build --target=morello-unknown-freebsd-purecap src/tools/remote-test-server
)


