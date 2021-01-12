#!/bin/bash
# From adafruit
if [ $(id -u) -ne 0 ]; then
	echo "Installer must be run as root."
	echo "Try 'sudo bash $0'"
	exit 1
fi

clear

echo "This script configures a Raspberry Pi"
echo "SD card to boot into read-only mode,"
echo "obviating need for clean shutdown."
echo "NO FILES ON THE CARD CAN BE CHANGED"
echo "WHEN PI IS BOOTED IN THIS STATE. Either"
echo "the filesystems must be remounted in"
echo "read/write mode, card must be mounted"
echo "R/W on another system"
echo
echo "Run time ~5 minutes. Reboot required."
echo
echo -n "CONTINUE? [y/N] "
read
if [[ ! "$REPLY" =~ ^(yes|y|Y)$ ]]; then
	echo "Canceled."
	exit 0
fi

# START INSTALL ------------------------------------------------------------
# All selections have been validated at this point...

# Given a filename, a regex pattern to match and a replacement string:
# Replace string if found, else no change.
# (# $1 = filename, $2 = pattern to match, $3 = replacement)
replace() {
	grep $2 $1 >/dev/null
	if [ $? -eq 0 ]; then
		# Pattern found; replace in file
		sed -i "s/$2/$3/g" $1 >/dev/null
	fi
}

# Given a filename, a regex pattern to match and a replacement string:
# If found, perform replacement, else append file w/replacement on new line.
replaceAppend() {
	grep $2 $1 >/dev/null
	if [ $? -eq 0 ]; then
		# Pattern found; replace in file
		sed -i "s/$2/$3/g" $1 >/dev/null
	else
		# Not found; append on new line (silently)
		echo $3 | sudo tee -a $1 >/dev/null
	fi
}

# Given a filename, a regex pattern to match and a string:
# If found, no change, else append file with string on new line.
append1() {
	grep $2 $1 >/dev/null
	if [ $? -ne 0 ]; then
		# Not found; append on new line (silently)
		echo $3 | sudo tee -a $1 >/dev/null
	fi
}

# Given a filename, a regex pattern to match and a string:
# If found, no change, else append space + string to last line --
# this is used for the single-line /boot/cmdline.txt file.
append2() {
	grep $2 $1 >/dev/null
	if [ $? -ne 0 ]; then
		# Not found; insert in file before EOF
		sed -i "s/\'/ $3/g" $1 >/dev/null
	fi
}

echo
echo "Starting installation..."
echo "Updating package index files..."
apt-get update

echo "Removing unwanted packages..."
#apt-get remove -y --force-yes --purge triggerhappy logrotate dbus \
# dphys-swapfile xserver-common lightdm fake-hwclock
# Let's keep dbus...that includes avahi-daemon, a la 'raspberrypi.local',
# also keeping xserver & lightdm for GUI login (WIP, not working yet)
apt-get remove -y --force-yes --purge triggerhappy logrotate \
 dphys-swapfile fake-hwclock
apt-get -y --force-yes autoremove --purge
rm -fr /var/swap

# Replace log management with busybox (use logread if needed)
echo "Installing ntp and busybox-syslogd..."
apt-get -y --force-yes install ntp busybox-syslogd; dpkg --purge rsyslog

echo "Configuring system..."

# Add fastboot, noswap and/or ro to end of /boot/cmdline.txt
append2 /boot/cmdline.txt fastboot fastboot
append2 /boot/cmdline.txt noswap noswap
append2 /boot/cmdline.txt ro^o^t ro

# Move /var/spool to /tmp
rm -rf /var/spool
ln -s /tmp /var/spool

# Move /var/lib/lightdm and /var/cache/lightdm to /tmp
rm -rf /var/lib/lightdm
rm -rf /var/cache/lightdm
ln -s /tmp /var/lib/lightdm
ln -s /tmp /var/cache/lightdm

# Make SSH work
replaceAppend /etc/ssh/sshd_config "^.*UsePrivilegeSeparation.*$" "UsePrivilegeSeparation no"
# bbro method (not working in Jessie?):
#rmdir /var/run/sshd
#ln -s /tmp /var/run/sshd

# Change spool permissions in var.conf (rondie/Margaret fix)
replace /usr/lib/tmpfiles.d/var.conf "spool\s*0755" "spool 1777"

# Move dhcpd.resolv.conf to tmpfs
touch /tmp/dhcpcd.resolv.conf
rm /etc/resolv.conf
ln -s /tmp/dhcpcd.resolv.conf /etc/resolv.conf

# Make edits to fstab
# make / ro
# tmpfs /var/log tmpfs nodev,nosuid 0 0
# tmpfs /var/tmp tmpfs nodev,nosuid 0 0
# tmpfs /tmp     tmpfs nodev,nosuid 0 0
replace /etc/fstab "vfat\s*defaults\s" "vfat    defaults,ro "
replace /etc/fstab "ext4\s*defaults,noatime\s" "ext4    defaults,noatime,ro "
append1 /etc/fstab "/var/log" "tmpfs /var/log tmpfs nodev,nosuid 0 0"
append1 /etc/fstab "/var/tmp" "tmpfs /var/tmp tmpfs nodev,nosuid 0 0"
append1 /etc/fstab "\s/tmp"   "tmpfs /tmp    tmpfs nodev,nosuid 0 0"

# Switch between RO and RW modes
cat >> /etc/bash.bashrc << EOF
set_bash_prompt() {
fs_mode=$(mount | sed -n -e "s/^\/dev\/.* on \/ .*(\(r[w|o]\).*/\1/p")
PS1='\[\033[01;32m\]\u@\h${fs_mode:+($fs_mode)}\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
}
alias ro='sudo mount -o remount,ro / ; sudo mount -o remount,ro /boot'
alias rw='sudo mount -o remount,rw / ; sudo mount -o remount,rw /boot'
PROMPT_COMMAND=set_bash_prompt
EOF

cat >> /etc/bash.bash_logout  << EOF
mount -o remount,ro /
mount -o remount,ro /boot
EOF

cat > /etc/cron.d/ntp << EOF
@reboot root ntpd -q -g
EOF

# PROMPT FOR REBOOT --------------------------------------------------------

echo "Done."
echo
echo "Settings take effect on next boot."
echo
echo -n "REBOOT NOW? [y/N] "
read
if [[ ! "$REPLY" =~ ^(yes|y|Y)$ ]]; then
	echo "Exiting without reboot."
	exit 0
fi
echo "Reboot started..."
reboot
exit 0