#!/bin/bash
# Only works with images made with Win32Imager. Does not work with ImageUSB
 
losetup -d /dev/loop20
umount /dev/loop20p1
umount /dev/loop20p2
