#!/bin/bash
# A script to run all relevant execution tests for Rust.
# Log of results (execution-*.log) and standard output (execution-*.stdout) are
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
  cargo update -p colored@2.1.0 --precise 2.0.4
)

# First we need to build a test server to go on the QEMU CheriBSD instance so
# we can attach to it.
(
  set -e
  cd ${TOPDIR}/rust
  ./x.py build --target=morello-unknown-freebsd-purecap src/tools/remote-test-server
)

# Make sure we have the test server available on the QEMU instance and that we
# start it from /etc/rc.local. Note, we can't preserve the previous state of the
# image because we have to rebuild it when adding extra files.
rm ${CHERIDIR}/cheribsd-morello-purecap.img
mkdir -p ${CHERIDIR}/../extra-files/etc
echo "./remote-test-server --bind 0.0.0.0:12345" > ${CHERIDIR}/../extra-files/etc/rc.local
cp ${TOPDIR}/rust/build/*/stage1-tools/morello-unknown-freebsd-purecap/*/remote-test-server ${CHERIDIR}/../extra-files/remote-test-server

# Now lets start the QEMU instance, making sure to have the ports available.
(
  set -e
  cd ${TOPDIR}/cheribuild
  ./cheribuild.py disk-image-morello-purecap --skip-update
  ${CHERIDIR}/sdk/bin/qemu-system-morello -M virt,gic-version=3 -cpu morello -bios edk2-aarch64-code.fd -m 2048 -nographic -drive if=none,file=${CHERIDIR}/cheribsd-morello-purecap.img,id=drv,format=raw -device virtio-blk-pci,drive=drv -device virtio-net-pci,netdev=net0 -netdev user,id=net0,hostfwd=tcp::10005-:22,hostfwd=tcp::12345-:12345 -device virtio-rng-pci -vga none -display none < /dev/null > ${TOPDIR}/toolchain/test-output/qemu.log 2>&1 &
) || exit -1

while [ -e $(echo ping | netcat -N localhost 12345 | grep pong) ]; do sleep 1; done

# We can now start the tests!
(
  set -e
  cd ${TOPDIR}/rust
  export TEST_DEVICE_ADDR="0.0.0.0:12345"
  ./x.py test ui --target=morello-unknown-freebsd-purecap \
      --test-args="--logfile=${TOPDIR}/toolchain/test-output/execution-ui.log" \
      --force-rerun --pass run > ${TOPDIR}/toolchain/test-output/execution-ui.stdout 2>&1
)


# TODO: Something nicer here
killall qemu-system-morello
