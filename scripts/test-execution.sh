#!/bin/bash
# A script to run all relevant execution tests for Rust.
# Log of results (execution-*.log) and standard output (execution-*.stdout) are
# saved in the <path to toolchain>/test-output directory.

# Variables used in this script
TOPDIR="$(realpath $(dirname $0)/../../)"
CHERIDIR="${HOME}/cheri/output/"
LINUX_TARGET=yes
FREEBSD_TARGET=yes
MORELLO_LINUX_IP="192.168.0.122"

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

for target in $TARGETS; do
  mkdir -p ${TOPDIR}/toolchain/test-output/${target}

  # First we need to build a test server to go on the Morello instance so
  # we can attach to it.
  (
    set -e
    cd ${TOPDIR}/rust
    ./x.py build --target=${target} src/tools/remote-test-server
  )
done

if [ "${FREEBSD_TARGET}" == "yes" ]; then
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
fi

if [ "${LINUX_TARGET}" == "yes" ]; then
  # Make sure the remote test server is copied to the Morello box, and set it running.
  # Incredibly insecure if we actually care about protecting access to the Morello box, but we don't.
  sshpass -pmorello scp ${TOPDIR}/rust/build/*/stage1-tools/morello-unknown-linux-purecap/*/remote-test-server root@${MORELLO_LINUX_IP}:
  sshpass -pmorello ssh -o StrictHostKeyChecking=no -l root@${MORELLO_LINUX_IP} "./remote-test-server --bind 0.0.0.0:12345"

  # We can now start the tests!
  (
    set -e
    cd ${TOPDIR}/rust
    export TEST_DEVICE_ADDR="${MORELLO_LINUX_IP}:12345"
    ./x.py test ui --target=morello-unknown-linux-purecap \
        --test-args="--logfile=${TOPDIR}/toolchain/test-output/execution-ui.log" \
        --rustc-args="-C linker=aarch64-unknown-linux-musl_purecap-clang -C link-arg=-fuse-ld=lld -C link-arg=--sysroot=$HOME/morello/musl/ -C link-self-contained=no" \
        --force-rerun > ${TOPDIR}/toolchain/test-output/execution-ui.stdout 2>&1
  )

fi
