#!/bin/bash -x
# A script to run all relevant compilation-only tests for Rust.
# Log of results (compilation-*.log) and standard output (compilation-*.stdout) are
# saved in the <path to toolchain>/test-output directory.

# Variables used in this script
TOPDIR="$(realpath $(dirname $0)/../../)"
CHERIDIR="${HOME}/cheri/output/"

# Ensure we have the Morello tools on our PATH before testing Rust.
PATH=${CHERIDIR}/morello-sdk/bin:${PATH}

mkdir -p ${TOPDIR}/toolchain/test-output

(
  set -e
  cd ${TOPDIR}/rust
  ./x.py test assembly --target=morello-unknown-freebsd-purecap \
      --test-args="--logfile=${TOPDIR}/toolchain/test-output/compilation-assembly.log" \
      --force-rerun > ${TOPDIR}/toolchain/test-output/compilation-assembly.stdout 2>&1
)

(
  set -e
  cd ${TOPDIR}/rust
  ./x.py test codegen --target=morello-unknown-freebsd-purecap \
      --test-args="--logfile=${TOPDIR}/toolchain/test-output/compilation-codegen.log" \
      --force-rerun > ${TOPDIR}/toolchain/test-output/compilation-codegen.stdout 2>&1
)

(
  set -e
  cd ${TOPDIR}/rust
  ./x.py test codegen-units --target=morello-unknown-freebsd-purecap \
      --test-args="--logfile=${TOPDIR}/toolchain/test-output/compilation-codegen-units.log" \
      --force-rerun > ${TOPDIR}/toolchain/test-output/compilation-codegen-units.stdout 2>&1
)

(
  set -e
  cd ${TOPDIR}/rust
  ./x.py test incremental --target=morello-unknown-freebsd-purecap \
      --test-args="--logfile=${TOPDIR}/toolchain/test-output/compilation-incremental.log" \
      --force-rerun > ${TOPDIR}/toolchain/test-output/compilation-incremental.stdout 2>&1
)

(
  set -e
  cd ${TOPDIR}/rust
  ./x.py test mir-opt --target=morello-unknown-freebsd-purecap \
      --test-args="--logfile=${TOPDIR}/toolchain/test-output/compilation-mir-opt.log" \
      --force-rerun > ${TOPDIR}/toolchain/test-output/compilation-mir-opt.stdout 2>&1
)

(
  set -e
  cd ${TOPDIR}/rust
  ./x.py test pretty --target=morello-unknown-freebsd-purecap \
      --test-args="--logfile=${TOPDIR}/toolchain/test-output/compilation-pretty.log" \
      --force-rerun > ${TOPDIR}/toolchain/test-output/compilation-pretty.stdout 2>&1
)

(
  set -e
  cd ${TOPDIR}/rust
  ./x.py test ui --target=morello-unknown-freebsd-purecap \
      --test-args="--logfile=${TOPDIR}/toolchain/test-output/compilation-ui.log" \
      --force-rerun --pass build > ${TOPDIR}/toolchain/test-output/compilation-ui.stdout 2>&1
)
