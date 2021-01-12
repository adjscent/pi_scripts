#!/bin/bash
# Only works with images made with Win32Imager. Does not work with ImageUSB
 
IMG="$1"
echo $IMG 
if [[ -e $IMG ]]; then
	mkdir /mnt/boot
	mkdir /mnt/rootfs
	losetup -P /dev/loop0 "$IMG"
	mount /dev/loop0p2 /mnt/rootfs
	mount /dev/loop0p1 /mnt/boot
else
  echo "Usage: $0 filename"
fi
