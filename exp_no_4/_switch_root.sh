#!/bin/sh

set -x

/bin/mount -a
/sbin/mdev -s

/bin/mount /dev/mmcblk0p2 /mnt

exec switch_root /mnt /sbin/init

