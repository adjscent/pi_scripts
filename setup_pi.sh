#!/bin/bash
cat > /boot/config.txt << EOF
# For more options and information see
# http://rpf.io/configtxt
# Some settings may impact device functionality. See link above for details

# uncomment to force a console size. By default it will be display's size minus
# overscan.
framebuffer_width=1280
framebuffer_height=720

# uncomment if hdmi display is not detected and composite is being output
hdmi_force_hotplug=1

# uncomment to force a HDMI mode rather than DVI. This can make audio work in
# DMT (computer monitor) modes
hdmi_drive=2

# Enable audio (loads snd_bcm2835)
#dtparam=audio=on

[pi4]
# Enable DRM VC4 V3D driver on top of the dispmanx display stack
dtoverlay=vc4-fkms-v3d
max_framebuffers=2

[all]
enable_uart=1
gpu_mem=16
EOF

cat > /etc/sysctl.conf << EOF
kernel.panic = 5
vm.swappiness = 1
EOF

cat > /etc/systemd/journald.conf << EOF
[Journal]
SystemMaxUse=10M
EOF