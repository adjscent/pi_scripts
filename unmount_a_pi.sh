#!/bin/bash
# Only works with images made with Win32Imager. Does not work with ImageUSB
 
losetup -d /dev/loop0
umount /dev/loop0p1
umount /dev/loop0p2
