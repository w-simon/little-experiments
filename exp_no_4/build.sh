#!/bin/bash

BASE=`pwd`
BUILD_KERNEL=${BASE}/build_kernel
BUILD_BUSYBOX=${BASE}/build_busybox
BUILD_UBOOT=${BASE}/build_uboot
DEPLOY=${BASE}/deploy

IMG=zImage
DTS=vexpress-v2p-ca9.dtb

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

build_uboot() {
	cd ${BASE}/../u-boot && \
	make ARCH=arm vexpress_ca9x4_defconfig O=${BUILD_UBOOT} && \
	cd ${BUILD_UBOOT} && \
	make ARCH=arm CROSS_COMPILE=${CROSS_PREFIX} -j ${NR}
}

deploy_kernel() {
	pushd ${BUILD_KERNEL}
	cp arch/arm/boot/${IMG} ${DEPLOY}/
	cp arch/arm/boot/dts/vexpress-v2p-ca9.dtb ${DEPLOY}/
	popd
}

deploy_rootfs() {
	pushd ${BUILD_BUSYBOX}/_install/
	cp -f ${BASE}/_switch_root.sh ${BUILD_BUSYBOX}/_install/bin/
	chmod +x ${BUILD_BUSYBOX}/_install/bin/_switch_root.sh
	find . | cpio -o -H newc | gzip -9 > ${DEPLOY}/rootfs.gz
	popd
}

deploy_uboot() {
	pushd ${BUILD_UBOOT}
	cp u-boot ${DEPLOY}/
	popd
}

make_sd_img() {
	pushd ${DEPLOY}
	mkimage -A arm -O linux -T script -C none -a 0 -e 0 -n "boot script" -d ../cmd.txt boot.scr

	rmm -f sd.img
	dd if=/dev/zero of=sd.img bs=1024k count=32
	sudo sfdisk sd.img << EOF
1,20480,L,*
,,,,
EOF
	DEV=$(sudo losetup -f)
	sudo losetup -d ${DEV}
	sudo losetup -P ${DEV} sd.img
	sudo mkfs.fat -F 16 -n BOOT ${DEV}p1
	sudo mkfs.ext4 -L ROOTFS ${DEV}p2

	sudo mount ${DEV}p1 /mnt
	sudo cp boot.scr zImage vexpress-v2p-ca9.dtb /mnt
	sudo umount /mnt

	sudo mount ${DEV}p2 /mnt
	pushd ${BUILD_BUSYBOX}/_install/
	ln -s bin/busybox init
	sudo cp -r * /mnt/
	sudo cp ${DEPLOY}/${IMG} /mnt/
	sudo cp ${DEPLOY}/${DTS} /mnt/
	popd
	sudo umount /mnt

	sudo losetup -d ${DEV}
	popd
}

prepare
build_kernel
build_busybox
build_uboot
deploy_kernel
deploy_rootfs
deploy_uboot
make_sd_img

