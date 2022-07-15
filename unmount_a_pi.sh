#!/bin/bash
# Only works with images made with Win32Imager. Does not work with ImageUSB

losetup -d /dev/loop100
umount /dev/loop100p1
umount /dev/loop100p2
