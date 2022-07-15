#!/bin/bash
# Only works with images made with Win32Imager. Does not work with ImageUSB

IMG="$1"
echo $IMG
if [[ -e $IMG ]]; then
	mkdir /mnt/boot
	mkdir /mnt/rootfs
	losetup -P /dev/loop100 "$IMG"
	mount /dev/loop100p2 /mnt/rootfs
	mount /dev/loop100p1 /mnt/boot
	echo "Mounted on /mnt/rootfs and /mnt/boot"
else
	echo "Usage: $0 filename"
fi
