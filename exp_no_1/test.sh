#!/bin/bash

BASE=`pwd`
BUILD_KERNEL=${BASE}/build_kernel
BUILD_BUSYBOX=${BASE}/build_busybox
DEPLOY=${BASE}/deploy

CROSS_PREFIX=arm-linux-gnueabi- 
NR=$(grep processor /proc/cpuinfo | tail -n 1 | awk '{print $3}')

cd ${BASE}/../linux
make ARCH=arm versatile_defconfig O=${BUILD_KERNEL}
cd ${BUILD_KERNEL}
make ARCH=arm CROSS_COMPILE=${CROSS_PREFIX} -j ${NR}
cp arch/arm/boot/zImage ${DEPLOY}/

cd $(BASE)/../busybox
make ARCH=arm defconfig O=$(BUILD_BUSYBOX)
cd ${BUILD_BUSYBOX}
make ARCH=arm CROSS_COMPILE=${CROSS_COMPILE} -j ${NR} install
cd _install/
find . | cpio -o -H newc | gzip -9 > ${DEPLOY}/rootfs.gz

