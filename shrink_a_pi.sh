#!/bin/bash
# Only works with images made with Win32Imager. Does not work with ImageUSB
 
IMG="$1"
echo $IMG 
if [[ -e $IMG ]]; then
  P_START=$( fdisk -lu $IMG | grep Linux | awk '{print $2}' ) # Start of 2nd partition in 512 byte sectors
  P_SIZE=$(( $( fdisk -lu $IMG | grep Linux | awk '{print $3}' ) * 1024 )) # Partition size in bytes
  losetup /dev/loop20 $IMG -o $(($P_START * 512)) --sizelimit $P_SIZE
  fsck -f /dev/loop20
  resize2fs -M /dev/loop20 # Make the filesystem as small as possible
  fsck -f /dev/loop20
  P_NEWSIZE=$( dumpe2fs /dev/loop20 2>/dev/null | grep '^Block count:' | awk '{print $3}' ) # In 4k blocks
  P_NEWEND=$(( $P_START + ($P_NEWSIZE * 8) + 1 )) # in 512 byte sectors
  losetup -d /dev/loop20
  echo -e "p\nd\n2\nn\np\n2\n$P_START\n$P_NEWEND\np\nw\n" | fdisk $IMG
  I_SIZE=$((($P_NEWEND + 1) * 512)) # New image size in bytes
  truncate -s $I_SIZE $IMG
else
  echo "Usage: $0 filename"
fi
