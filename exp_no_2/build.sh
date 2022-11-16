#!/bin/bash

BASE=`pwd`
BUILD_KERNEL=${BASE}/build_kernel
BUILD_BUSYBOX=${BASE}/build_busybox
DEPLOY=${BASE}/deploy

IMG=zImage
DTB=vexpress-v2p-ca9.dtb
INITRD=initrd.img

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

deploy_initrd() {
	dd if=/dev/zero of=${DEPLOY}/${INITRD} bs=1024k count=4
	mkfs.ext2 -F -m0 ${DEPLOY}/${INITRD}
	sudo mount -t ext2 -o loop ${DEPLOY}/${INITRD} /mnt

	pushd ${BUILD_BUSYBOX}/_install/
	sudo cp -r * /mnt/
	popd

	sudo cat > fstab <<EOF
proc		/proc	proc	defaults    0	0
sys		/sys	sysfs	defaults    0	0
EOF

	sudo cat > rcS <<EOF
#!/bin/sh

/bin/mount -a
EOF
	sudo chmod +x rcS

	sudo cat > inittab <<EOF
::sysinit:/etc/init.d/rcS
::respawn:-/bin/sh
::ctrlaltdel:/bin/umount -a -r
EOF
	sudo mkdir /mnt/{proc,sys,dev,etc}
	sudo mkdir /mnt/etc/init.d/
	sudo mv fstab /mnt/etc/
	sudo mv inittab /mnt/etc/
	sudo mv rcS /mnt/etc/init.d/

	sudo umount /mnt
}

prepare
build_kernel
build_busybox
deploy_kernel
deploy_initrd

