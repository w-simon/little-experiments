#!/bin/bash

BASE=`pwd`
QEMU=${BASE}/../tools/qemu
DEPLOY=${BASE}/deploy

# raw qemu
${QEMU}/qemu-system-arm \
	-m 128M \
	-M vexpress-a9 \
	-kernel ${DEPLOY}/u-boot \
	-drive format=raw,file=${DEPLOY}/disk.img,if=sd \
	-nographic
