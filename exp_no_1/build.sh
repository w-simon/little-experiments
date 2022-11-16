#!/bin/bash

BASE=`pwd`
BUILD_KERNEL=${BASE}/build_kernel
BUILD_BUSYBOX=${BASE}/build_busybox
DEPLOY=${BASE}/deploy

IMG=zImage
DTB=vexpress-v2p-ca9.dtb
INITRD=rootfs.gz

CROSS_PREFIX=arm-linux-gnueabi- 
NR=$(grep processor /proc/cpuinfo | tail -n 1 | awk '{print $3}')

prepare () {
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
	cp arch/arm/boot/${IMG} ${DEPLOY}/
	cp arch/arm/boot/dts/${DTB} ${DEPLOY}/
	popd
}

deploy_initrd() {
	pushd ${BUILD_BUSYBOX}/_install/

	mkdir proc sys dev etc
	cat >etc/fstab <<EOF
proc		/proc	proc	defaults    0	0
sys		/sys	sysfs	defaults    0	0
EOF

	mkdir etc/init.d/
	cat >etc/init.d/rcS <<EOF
#!/bin/sh

/bin/mount -a
EOF
	chmod +x etc/init.d/rcS

	cat >etc/inittab <<EOF
::sysinit:/etc/init.d/rcS
::respawn:-/bin/sh
::ctrlaltdel:/bin/umount -a -r
EOF
	find . | cpio -o -H newc | gzip -9 > ${DEPLOY}/${INITRD}
	popd
}

prepare
build_kernel
build_busybox
deploy_kernel
deploy_initrd
