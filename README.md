![Cat with shield](https://raw.githubusercontent.com/lateralblast/guige/master/guige.jpg)

GUIGE
-----

Generic Ubuntu ISO Generation Engine

A guige (/ɡiːʒ/, /ɡiːd͡ʒ/) is a long strap, typically made of leather, 
used to hang a shield on the shoulder or neck when not in use. 

Version
-------

Current version: 0.4.6

Introduction
------------

This script provides a wrapper for the Ubuntu ISO creation process.
I wrote this as I didn't want to have to fire up Cubic or a similar GUI tool to create an ISO.
I wanted to be able to automate the process.

This method doesn't support the older preseed method (i.e. Ubuntu 18.04 or earlier).
Preseed method could be added reasonably easily I expect, but I've only need for Ubuntu 20.04 or later.

Currently this is WIP and it works for ZFS root only. 
It is being converted from a set of shell commands.
See the Todo section for some future plans/ideas.

In particular this script provides support for creating autoinstall ISO with:

- ZFS root 
- Adding packages to installation

So that the additional packages added to the install do not require network access,
the squashfs filesystem is mounted and the packages are installed into it with the download option,
then the packages are copied to the ISO image that is created.
Doing it this way also ensures packages dependencies are also handled.

Rather than being directly run, the commands are wrappered and run through
an execute function so that the script can be used to produce another script.

By default the script will create an autoinstall ISO that uses DHCP,
and installs packages from the ISO rather than fetching them over the network.

The current default install options in the grub menu are:
- ZFS on /dev/sda
- ZFS on /dev/vda (e.g. KVM)
- LVM on /dev/sda
- LVM on /dev/vda (e.g. KVM)

These can be modified via command line arguments.

An example of the grub menu when booting from the ISO:

![Boot menu example](https://raw.githubusercontent.com/lateralblast/guige/master/grubmenu.jpg)

The current disk layouts are default one root partition configs, i.e. no separate
var or home partitions. This could be changed, but in my experience testing recent
cloud-init autoinstall versions/configs on Ubuntu it takes quite a bit of testing
to get more complex layouts working without issue.

Usage
-----

You can get help using the -h switch:

```
  Usage: guige.sh [OPTIONS...]
    -A|--codename         Linux release codename (default: jammy)
    -a|--arch             Architecture (default: amd64)
    -B|--layout           Layout (default: us)
    -b|--getiso           Get base ISO
    -C|--runchrootscript  Run chroot script
    -c|--createiso        Create ISO (perform all steps - e.g. grub, packages, etc)
    -D|--defaults         Use defaults (default: false)
    -d|--bootdisk         Boot Disk devices (default: sda vda)
    -E|--locale           LANGUAGE (default: en_US.UTF-8)
    -e|--lcall            LC_ALL (default: en_US)
    -f|--delete           Remove previously created files (default: false)
    -H|--hostname:        Hostname (default: ubuntu)
    -h|--help             Help/Usage Information
    -I|--interactive      Interactive mode (will ask for input rather than using command line options or defaults)
    -i|--inputiso:        Input/base ISO file (default: /home/sysadmin/ubuntu-iso/ubuntu-22.04.1-live-server-amd64.iso)
    -k|--kernelargs:      Kernel arguments (default: net.ifnames=0 biosdevname=0)
    -K|--kernel:          Kernel package (default: linux-generic)
    -L|--release:         LSB release (default: 22.04.1)
    -l|--justiso          Create ISO (perform last step only - just run xoriso)
    -m|--volumemanager:   Volume Managers (defauls: zfs lvm)
    -N|--nic:             Network device (default: eth0)
    -m|--grubmenu:        Set default grub menu (default: 0)
    -n|--nounmount        Do not unmount loopback filesystems (useful for troubleshooting)
    -o|--outputiso:       Output ISO file (default: /home/sysadmin/ubuntu-iso/ubuntu-22.04.1-live-server-amd64-autoinstall.iso)
    -P|--password:        Password (default: ubuntu)
    -p|--chrootpackages:  Packages to add to ISO (default: zfsutils-linux grub-efi zfs-initramfs net-tools curl wget)
    -R|--realname:        Realname (default Ubuntu)
    -r|--installrequired  Install required packages on host (p7zip-full wget xorriso whois)
    -S|--swapsize:        Swap size (default 2G)
    -s|--staticip         Static IP configuration (default DHCP)
    -T|--timezone:        Timezone (default: Australia/Melbourne)
    -t|--testmode         Test mode (display commands but don't run them)
    -U|--username:        Username (default: ubuntu)
    -u|--unmount          Unmount loopback filesystems
    -V|--version          Display Script Version
    -v|--verbose          Verbose output (default: false)
    -W|--workdir:         Work directory (default: /home/sysadmin/ubuntu-iso)
    -w|--checkdirs        Check work directories exist
    -Y|--installpackages: Packages to install after OS installation
    -y|--installupdatex   Install updates after install (requires network)
    -x|--grubtimeout:     Grub timeout (default: 10)
    -Z|--distupgrade      Perform dist-upgrade after OS installation
```

Todo
----

Things I plan to do:

- While this release is focused on ZFS root, I plan to add a non ZFS option
- Support for nightly build images etc
- Script cleanup and more flexibility
- Support architechtures other than x86_64

Thanks
------

Thanks to Mark Lane for testing, suggestions, etc.

Examples
--------

Get usage/help information:

```
./guige.sh --help
```

Install required packages:

```
./guide.sh --install required
```

Download base ISO (jammy)

```
./guide.sh --getiso 
```

Create ISO (performs all steps):

```
./guide.sh --createiso
```

Run the previous command but in test mode (don't execute commands) to produce output suitable for creating a script:


```
./guide.sh --createiso --testmode
```

Just do autoinstall config and create ISO (assumes an ISO has been previously create and we are just updating the autoinstall config), enabling updates and installing additional packages (requires networkduring OS install)

```
./guige.sh --justiso --verbose --installupdates --installpackages --distupgrade
```

Process
-------

This is a basic breakdown of the process involed:

- Install required packages
- Make work directories
- Get ISO
- Mount base ISO as loopback device so contents can be copied
- Copy contents of ISO to a RW location so we can work with them
- Mount squashfs and copy giles into it
- Create a chroot script and execute it
- Uncompress ISO into directory and create autoinstall shell
- Create ISO autoinstall files
- Create ISO grub file menu that calls autoinstall file(s)
- Create ISO file

Install Required Packages
=========================

```
sudo apt install -y p7zip-full wget xorriso
```

Make Work Directories
=====================

```
mkdir -p ./isomount ./isonew/squashfs ./isonew/cd ./isonew/custom
```

Get ISO
=======

```
wget https://releases.ubuntu.com/22.04.1/ubuntu-22.04.1-live-server-amd64.iso -O ./ubuntu-iso/ubuntu-22.04.1-live-server-amd64.iso
```

Mount ISO
=========

```
sudo mount -o loop ./ubuntu-22.04.1-live-server-amd64.iso ./isomount
```

Copy ISO
========

```
rsync --exclude=/casper/ubuntu-server-minimal.squashfs -av ./isomount/ ./isonew/cd
rsync -av ./isomount/ ./isonew/cd
```

Mount Squashfs
==============

```
sudo mount -t squashfs -o loop ./isomount/casper/ubuntu-server-minimal.squashfs ./isonew/squashfs/
sudo rsync -av ./isonew/squashfs/ ./isonew/custom
sudo cp /etc/resolv.conf /etc/hosts ./isonew/custom/etc/
sudo cp /etc/apt/sources.list ./isonew/custom/etc/apt/
```

Create chroot
=============

Create chroot script:

```
cat <<EOF > ./ubuntu-iso/isonew/custom/tmp/modify_chroot.sh
#!/usr/bin/bash
mount -t proc none /proc/
mount -t sysfs none /sys/
mount -t devpts none /dev/pts
export HOME=/root
sudo apt update
sudo apt install -y --download-only zfsutils-linux grub-efi zfs-initramfs net-tools curl wget
sudo apt install -y zfsutils-linux grub-efi zfs-initramfs net-tools curl wget
umount /proc/
umount /sys/
umount /dev/pts/
exit
EOF
```

This script install the required ZFS and other packages into the squashfs filewsystem.
It also also downloads a copy of the packages so we can copy this into ISO we create,
so they can be installed as part of the installation method without requiring network.

Execute chroot script:

```
sudo chmod +x ./ubuntu-iso/isonew/custom/tmp/modify_chroot.sh
sudo chroot ./ubuntu-iso/isonew/custom /tmp/modify_chroot.sh
```

Uncompress ISO
==============

Uncompress ISO and move BOOT files to where they will be used by ISO creation process:

```
7z -y x ./ubuntu-iso/ubuntu-22.04.1-live-server-amd64.iso -o./ubuntu-iso/source-files
mv ./source-files/\[BOOT\] ./BOOT
```

Creat directories for autoinstall configs:

```
mkdir -p ./source-files/autoinstall/configs/sda
mkdir -p ./source-files/autoinstall/packages
touch ./source-files/autoinstall/configs/sda/meta-data
```

Copy packages we downloaded as part of chroot process so they can be included on the ISO:

```
cp ./isonew/custom/var/cache/apt/archives/*.deb source-files/autoinstall/packages/
```

Create autoinstall Files
========================

This example uses /dev/sda as a ZFS root device. 
The documentation for this process is hard to find, so the example is a simple unmirrored device, as this works.
A mirror could be done as a post script or after install.

An example of getting a password crypt:

```
export PASSWORD_CRYPT=$(echo P455w0rD |mkpasswd --method=SHA-512 --stdin)
```

Create a user-data file:

```
cat <<EOF > ./source-files/autoinstall/configs/sda/user-data
#cloud-config
autoinstall:
 apt:
   preferences:
     - package: "*"
       pin: "release a=jammy-security"
       pin-priority: 200
   disable_components: []
   geoip: true
   preserve_sources_list: false
   primary:
   - arches:
     - amd64
     - i386
     uri: http://archive.ubuntu.com/ubuntu
   - arches:
     - default
     uri: http://ports.ubuntu.com/ubuntu-ports
 package_update: false
 package_upgrade: false
 drivers:
   install: false
 user-data:
   timezone: Australia/Melbourne
 identity:
   hostname: ubuntu
   password: "$PASSWORD_CRYPT"
   realname: Ubuntu
   username: ubuntu
 kernel:
   package: linux-generic
 keyboard:
   layout: us
 locale: en_US.UTF-8
 network:
   ethernets:
     ens33:
       critical: true
       dhcp-identifier: mac
       dhcp4: true
   version: 2
 ssh:
   allow-pw: true
   authorized-keys: []
   install-server: true
 storage:
   config:
   - ptable: gpt
     path: /dev/sda
     wipe: superblock-recursive
     preserve: false
     name: ''
     grub_device: true
     type: disk
     id: disk1
   - device: disk1
     size: 1127219200
     wipe: superblock-recursive
     flag: boot
     number: 1
     preserve: false
     grub_device: true
     type: partition
     ptable: gpt
     id: disk1p1
   - fstype: fat32
     volume: disk1p1
     preserve: false
     type: format
     id: disk1p1fs1
   - path: /boot/efi
     device: disk1p1fs1
     type: mount
     id: mount-2
   - device: disk1
     size: -1
     wipe: superblock-recursive
     flag: root
     number: 2
     preserve: false
     grub_device: false
     type: partition
     id: disk1p2
   - id: disk1p2fs1
     type: format
     fstype: zfsroot
     volume: disk1p2
     preserve: false
   - id: disk1p2f1_rootpool
     mountpoint: /
     pool: rpool
     type: zpool
     device: disk1p2fs1
     preserve: false
     vdevs:
       - disk1p2fs1
   - id: disk1_rootpool_container
     pool: disk1p2f1_rootpool
     preserve: false
     properties:
       canmount: "off"
       mountpoint: "none"
     type: zfs
     volume: /ROOT
   - id: disk1_rootpool_rootfs
     pool: disk1p2f1_rootpool
     preserve: false
     properties:
       canmount: noauto
       mountpoint: /
     type: zfs
     volume: /ROOT/zfsroot
   - path: /
     device: disk1p2fs1
     type: mount
     id: mount-disk1p2
   swap:
     swap: 0
 early-commands:
   - "sudo dpkg --auto-deconfigure --force-depends -i /cdrom/autoinstall/packages/*.deb"
 version: 1
EOF
```

Create ISO grub File
====================

Greate grub file:

```
cat <<EOF > ./source-files/boot/grub/grub.cfg
set timeout=10
loadfont unicode
set menu_color_normal=white/black
set menu_color_highlight=black/light-gray
menuentry "Autoinstall Ubuntu Server - Physical" {
   set gfxpayload=keep
   linux   /casper/vmlinuz quiet autoinstall ds=nocloud\;s=/cdrom/autoinstall/configs/sda/  ---
   initrd  /casper/initrd
}
menuentry "Try or Install Ubuntu Server" {
 set gfxpayload=keep
 linux /casper/vmlinuz quiet ---
 initrd  /casper/initrd
}
menuentry 'Boot from next volume' {
 exit 1
}
menuentry 'UEFI Firmware Settings' {
 fwsetup
}
EOF
```

Create ISO File
===============

Get required partition information from existing ISO:

```
export APPEND_PARTITION=$(xorriso -indev ubuntu-22.04.1-live-server-amd64.iso -report_el_torito as_mkisofs |grep append_partition |tail -1 |awk '{print $3}' 2>&1)
export ISO_MBR_PART_TYPE=$(xorriso -indev ubuntu-22.04.1-live-server-amd64.iso -report_el_torito as_mkisofs |grep iso_mbr_part_type |tail -1 |awk '{print $2}' 2>&1)
```

Create ISO:

```
xorriso -as mkisofs -r -V 'Ubuntu-Server 22.04.1 LTS arm64' -o ../ubuntu-22.04-autoinstall-arm64.iso --grub2-mbr \
../BOOT/Boot-NoEmul.img -partition_offset 16 --mbr-force-bootable -append_partition 2 $APPEND_PARTITION ../BOOT/Boot-NoEmul.img \
-appended_part_as_gpt -iso_mbr_part_type $ISO_MBR_PART_TYPE -c '/boot/boot.cat' -e '--interval:appended_partition_2:::' -no-emul-boot
```

