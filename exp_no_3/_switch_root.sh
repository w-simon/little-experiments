#!/bin/sh

set -x

/bin/mkdir /proc /sys /dev /mnt

/bin/mount -t proc none /proc
/bin/mount -t sysfs none /sys

/sbin/mdev -s

/bin/sleep 2
/bin/mount /dev/mmcblk0 /mnt

/bin/sleep 1
exec switch_root /mnt /bin/sh
