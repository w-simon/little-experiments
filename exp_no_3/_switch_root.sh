#!/bin/sh

set -x

/bin/mkdir /proc /sys /dev /mnt
/bin/mount -t proc none /proc
/bin/mount -t sysfs none /sys

/sbin/mdev -s
/bin/mount /dev/mmcblk0 /mnt

ls -l /mnt/
ls -l /mnt/bin/

exec switch_root /mnt /sbin/init


