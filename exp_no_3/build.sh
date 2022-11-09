#!/bin/bash

BASE=`pwd`
BUILD_KERNEL=${BASE}/build_kernel
BUILD_BUSYBOX=${BASE}/build_busybox
DEPLOY=${BASE}/deploy

CROSS_PREFIX=arm-linux-gnueabi- 
NR=$(grep processor /proc/cpuinfo | tail -n 1 | awk '{print $3}')

prepare() {
	mkdir -p  ${BUILD_KERNEL}
	mkdir -p  ${BUILD_BUSYBOX}
	mkdir -p  ${DEPLOY}
}

build_kernel() {
	cd ${BASE}/../linux && \
	make ARCH=arm vexpress_defconfig O=${BUILD_KERNEL} && \
	cd ${BUILD_KERNEL} && \
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

deploy_img() {
	dd if=/dev/zero of=${DEPLOY}/disk.img bs=1024k count=32
	mkfs.ext2 -F -m0 ${DEPLOY}/disk.img
	sudo mount -t ext2 -o loop ${DEPLOY}/disk.img /mnt

	pushd ${BUILD_BUSYBOX}/_install/
	ln -s bin/busybox init
	sudo cp -r * /mnt/
	popd

	sudo umount /mnt
}

deploy_rootfs() {
	pushd ${BUILD_BUSYBOX}/_install/
	cp -f ${BASE}/_switch_root.sh ${BUILD_BUSYBOX}/_install/bin/
	chmod +x ${BUILD_BUSYBOX}/_install/bin/_switch_root.sh
	find . | cpio -o -H newc | gzip -9 > ${DEPLOY}/rootfs.gz
	popd
}

prepare
build_kernel
build_busybox
deploy_kernel
deploy_rootfs
deploy_img

