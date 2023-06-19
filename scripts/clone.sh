#!/bin/bash
# Script for checking out sources of branches

# Variables used in this script
TOPDIR="$(realpath $(dirname $0)/../../)"

if [ ! -d ${TOPDIR}/toolchain ]; then
  git clone https://github.com/lewis-revill/rust-cheri-toolchain.git ${TOPDIR}/toolchain
fi
if [ ! -d ${TOPDIR}/cheribuild ]; then
  git clone https://github.com/CTSRD-CHERI/cheribuild.git ${TOPDIR}/cheribuild
fi
if [ ! -d ${TOPDIR}/rust ]; then
  git clone https://github.com/CyberHive/rust-cheri.git ${TOPDIR}/rust
fi
