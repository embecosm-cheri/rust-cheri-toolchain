#!/bin/bash -x
# A script to run all relevant compilation-only tests for Rust.
# Log of results (compilation-*.log) and standard output (compilation-*.stdout) are
# saved in the <path to toolchain>/test-output directory.

# Variables used in this script
TOPDIR="$(realpath $(dirname $0)/../../)"
LINUX_TARGET=yes
FREEBSD_TARGET=yes

for opt in ${@}; do
  valid_arg=1
  case ${opt} in
  "--linux")
    LINUX_TARGET=yes
    ;;
  "--no-linux")
    LINUX_TARGET=no
    ;;
  "--freebsd")
    FREEBSD_TARGET=yes
    ;;
  "--no-freebsd")
    FREEBSD_TARGET=no
    ;;
  "--help")
    valid_arg=0
    ;;&
  *)
    echo "Usage for $0:"
    echo "  --linux                      Assume we're building a toolchain for Morello Linux [Default]"
    echo "  --no-linux                   Assume we're not building a toolchain for Morello Linux"
    echo "  --freebsd                    Assume we're building a toolchain for Morello FreeBSD [Default]"
    echo "  --no-freebsd                 Assume we're not building a toolchain for Morello FreeBSD"
    echo "  --help                       Present this message."
    exit $valid_arg
    ;;
  esac
done

# Ensure we have the Morello tools on our PATH before testing Rust.
if [ "${FREEBSD_TARGET}" == "yes" ]; then
  PATH=${HOME}/cheri/output/morello-sdk/bin:${PATH}
fi

if [ "${LINUX_TARGET}" == "yes" ]; then
  PATH=${HOME}/morello/llvm/bin:${PATH}
fi

(
  set -e
  cd ${TOPDIR}/rust
  cargo update -p colored@2.1.0 --precise 2.0.4
)

mkdir -p ${TOPDIR}/toolchain/test-output

TARGETS=()
if [ "${FREEBSD_TARGET}" == "yes" ]; then
  TARGETS+=("morello-unknown-freebsd-purecap")
fi
if [ "${LINUX_TARGET}" == "yes" ]; then
  TARGETS+=("morello-unknown-linux-purecap")
fi

for target in ${TARGETS}; do
  mkdir -p ${TOPDIR}/toolchain/test-output/${target}
  (
    set -e
    cd ${TOPDIR}/rust
    ./x.py test assembly --target=${target} \
        --test-args="--logfile=${TOPDIR}/toolchain/test-output/${target}/compilation-assembly.log" \
        --force-rerun > ${TOPDIR}/toolchain/test-output/${target}/compilation-assembly.stdout 2>&1
  )

  (
    set -e
    cd ${TOPDIR}/rust
    ./x.py test codegen --target=${target} \
        --test-args="--logfile=${TOPDIR}/toolchain/test-output/${target}/compilation-codegen.log" \
        --force-rerun > ${TOPDIR}/toolchain/test-output/${target}/compilation-codegen.stdout 2>&1
  )

  (
    set -e
    cd ${TOPDIR}/rust
    ./x.py test codegen-units --target=${target} \
        --test-args="--logfile=${TOPDIR}/toolchain/test-output/${target}/compilation-codegen-units.log" \
        --force-rerun > ${TOPDIR}/toolchain/test-output/${target}/compilation-codegen-units.stdout 2>&1
  )

  (
    set -e
    cd ${TOPDIR}/rust
    ./x.py test incremental --target=${target} \
        --test-args="--logfile=${TOPDIR}/toolchain/test-output/${target}/compilation-incremental.log --skip rustc-rust-log" \
        --force-rerun > ${TOPDIR}/toolchain/test-output/${target}/compilation-incremental.stdout 2>&1
  )

  (
    set -e
    cd ${TOPDIR}/rust
    ./x.py test mir-opt --target=${target} \
        --test-args="--logfile=${TOPDIR}/toolchain/test-output/${target}/compilation-mir-opt.log" \
        --force-rerun > ${TOPDIR}/toolchain/test-output/${target}/compilation-mir-opt.stdout 2>&1
  )

  (
    set -e
    cd ${TOPDIR}/rust
    ./x.py test pretty --target=${target} \
        --test-args="--logfile=${TOPDIR}/toolchain/test-output/${target}/compilation-pretty.log" \
        --force-rerun > ${TOPDIR}/toolchain/test-output/${target}/compilation-pretty.stdout 2>&1
  )

  (
    set -e
    cd ${TOPDIR}/rust
    ./x.py test ui --target=${target} \
        --test-args="--logfile=${TOPDIR}/toolchain/test-output/${target}/compilation-ui.log" \
        --force-rerun --pass build > ${TOPDIR}/toolchain/test-output/${target}/compilation-ui.stdout 2>&1
  )
done
