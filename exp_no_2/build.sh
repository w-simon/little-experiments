#!/bin/bash

BASE=`pwd`
BUILD_KERNEL=${BASE}/build_kernel
BUILD_BUSYBOX=${BASE}/build_busybox
DEPLOY=${BASE}/deploy

CROSS_PREFIX=arm-linux-gnueabi- 
NR=$(grep processor /proc/cpuinfo | tail -n 1 | awk '{print $3}')

prepare () {
	mkdir -p  ${BUILD_KERNEL}
	mkdir -p  ${BUILD_BUSYBOX}
	mkdir -p  ${DEPLOY}
}


# support ramdisk 
#CONFIG_BLK_DEV_RAM=y
#CONFIG_BLK_DEV_RAM_COUNT=16
#CONFIG_BLK_DEV_RAM_SIZE=4096

build_kernel() {
	cd ${BASE}/../linux && \
	make ARCH=arm vexpress_defconfig O=${BUILD_KERNEL} && \
	cd ${BUILD_KERNEL} && \
	sed -i 's/# CONFIG_BLK_DEV_RAM is not set/CONFIG_BLK_DEV_RAM=y/' .config && \
	sed -i '/CONFIG_BLK_DEV_RAM=y/a\CONFIG_BLK_DEV_RAM_COUNT=16'  .config && \
	sed -i '/CONFIG_BLK_DEV_RAM=y/a\CONFIG_BLK_DEV_RAM_SIZE=4096' .config && \
	make ARCH=arm CROSS_COMPILE=${CROSS_PREFIX} zImage dtbs -j ${NR}
}

build_busybox() {
	cd ${BASE}/../busybox && \
	make ARCH=arm defconfig O=${BUILD_BUSYBOX} && \
	cd ${BUILD_BUSYBOX} && \
	sed -i 's/# CONFIG_STATIC is not set/CONFIG_STATIC=y/g' .config && \
	make ARCH=arm CROSS_COMPILE=${CROSS_PREFIX} -j ${NR} install
}

deploy_kernel() {
	pushd ${BUILD_KERNEL}
	cp arch/arm/boot/zImage ${DEPLOY}/
	cp arch/arm/boot/dts/vexpress-v2p-ca9.dtb ${DEPLOY}/
	popd
}

deploy_rootfs() {
	dd if=/dev/zero of=${DEPLOY}/initrd.img bs=1024k count=4
	mkfs.ext2 -F -m0 ${DEPLOY}/initrd.img
	sudo mount -t ext2 -o loop ${DEPLOY}/initrd.img /mnt

	pushd ${BUILD_BUSYBOX}/_install/
	sudo cp -r * /mnt/
	popd

	sudo umount /mnt
	#gzip -9 ${DEPLOY}/initrd.img
}

prepare
build_kernel
build_busybox
deploy_kernel
deploy_rootfs

