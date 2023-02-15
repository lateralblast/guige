![Cat with shield](https://raw.githubusercontent.com/lateralblast/guige/master/guige.jpg)

GUIGE
-----

Generic Ubuntu ISO Generation Engine

A guige (/ɡiːʒ/, /ɡiːd͡ʒ/) is a long strap, typically made of leather, 
used to hang a shield on the shoulder or neck when not in use. 

Version
-------

Current version: 0.8.7

Introduction
------------

This script provides a wrapper for the Ubuntu ISO creation process.
I wrote this as I didn't want to have to fire up Cubic or a similar GUI tool to create an ISO.
I wanted to be able to automate the process.

This script also supports creating ISOs via docker for non Linux platforms.
On Apple Silicon support for creating arm64 and amd64 is available by using the platform flag of docker.

This method doesn't support the older preseed method (i.e. Ubuntu 18.04 or earlier).
Preseed method could be added reasonably easily I expect, but I've only need for Ubuntu 20.04 or later.

Currently this is WIP and it works for ZFS (and LVM encapsulated EXT4) root only. 
It is being converted from a set of shell commands.
See the Todo section for some future plans/ideas.

In particular this script provides support for creating autoinstall ISO with:

- ZFS (or LVM encapsulated ETX4) root 
- Adding packages to installation

So that the additional packages added to the install do not require network access,
the squashfs filesystem is mounted and the packages are installed into it with the download option,
then the packages are copied to the ISO image that is created.
Doing it this way also ensures packages dependencies are also handled.

By default the script will create an autoinstall ISO that uses DHCP,
and installs packages from the ISO rather than fetching them over the network.

The current default install options in the grub menu are:
- ZFS on first available disk
- LVM on first available disk

These can be modified via command line arguments.

An example of the grub menu when booting from the ISO:

![Boot menu example](https://raw.githubusercontent.com/lateralblast/guige/master/grubmenu.jpg)

The current disk layouts are default one root partition configs, i.e. no separate
var or home partitions. This could be changed, but in my experience testing recent
cloud-init autoinstall versions/configs on Ubuntu it takes quite a bit of testing
to get more complex layouts working without issue.

Usage
-----

You can get help using the -h or --help switch:

```
  Usage: guige.sh [OPTIONS...]
    -1|--bootserverfile   Boot sever file (default: ubuntu-22.04.1-live-server-arm64-autoinstall.iso)
    -2|--squashfsfile     Squashfs file (default: ubuntu-server-minimal.squashfs)
    -3|--grubfile         GRUB file (default: grub.cfg)
    -A|--codename         Linux release codename (default: jammy)
    -a|--action:          Action to perform (e.g. createiso, justiso, runchrootscript, checkdocker, installrequired)
    -B|--layout           Layout (default: us)
    -b|--bootserverip:    NFS/Bootserver IP (default: 192.168.1.18)
    -C|--cidr:            CIDR (default: 24)
    -c|--sshkeyfile:      SSH key file to use as SSH key (default: /Users/spindler/.ssh/id_rsa.pub)
    -D|--installdrivers   Install additional drivers (default: false)
    -d|--bootdisk:        Boot Disk devices (default: ROOT_DEV)
    -E|--locale:          LANGUAGE (default: en_US.UTF-8)
    -e|--lcall:           LC_ALL (default: en_US)
    -F|--bmcusername:     BMC/iDRAC User (default: root)
    -f|--delete:          Remove previously created files (default: false)
    -G|--gateway:         Gateway (default 192.168.1.254)
    -g|--grubmenu:        Set default grub menu (default: 0)
    -H|--hostname:        Hostname (default: ubuntu)
    -h|--help             Help/Usage Information
    -I|--ip:              IP Address (default: 192.168.1.2)
    -i|--inputiso:        Input/base ISO file (default: ubuntu-22.04.1-live-server-arm64.iso)
    -J|--hwe              Use HWE kernel (defaults: false)
    -j|--autoinstalldir   Directory where autoinstall config files are stored on ISO (default: autoinstall)
    -K|--kernel:          Kernel package (default: linux-generic)
    -k|--kernelargs:      Kernel arguments (default: net.ifnames=0 biosdevname=0)
    -L|--release:         LSB release (default: 22.04.1)
    -l|--bmcip:           BMC/iDRAC IP (default: 192.168.1.3)
    -M|--installtarget:   Where the install mounts the target filesystem (default: )
    -m|--installmount:    Where the install mounts the CD during install (default: /cdrom)
    -N|--dns:             DNS Server (ddefault: )
    -n|--nic:             Network device (default: eth0)
    -O|--isopackages:     List of packages to install (default: zfsutils-linux grub-efi zfs-initramfs net-tools curl wget sudo file rsync)
    -o|--outputiso:       Output ISO file (default: ubuntu-22.04.1-live-server-arm64-autoinstall.iso)
    -P|--password:        Password (default: ubuntu)
    -p|--chrootpackages:  List of packages to add to ISO (default: )
    -Q|--build:           Type of ISO to build (default: live-server)
    -q|--arch:            Architecture (default: arm64)
    -R|--realname:        Realname (default Ubuntu)
    -r|--mode:            Mode (default: defaults)
    -S|--swapsize:        Swap size (default 2G)
    -s|--staticip         Static IP configuration (default DHCP)
    -T|--timezone:        Timezone (default: Australia/Melbourne)
    -t|--testmode         Test mode (display commands but don't run them)
    -U|--username:        Username (default: ubuntu)
    -u|--postinstall:     Postinstall action (e.g. installpackages, upgrade, distupgrade)
    -V|--version          Display Script Version
    -v|--verbose          Verbose output (default: false)
    -W|--workdir:         Work directory (default: /Users/spindler/ubuntu-iso/22.04.1)
    -w|--checkdirs        Check work directories exist
    -X|--isovolid:        ISO Volume ID (default:  22.04.1 Server)
    -x|--grubtimeout:     Grub timeout (default: 10)
    -Y|--allowpassword    Allow password access via SSH (default: false)
    -y|--bmcpassword:     BMC/iDRAC password (default: calvin)
    -Z|--nounmount        Do not unmount loopback filesystems (useful for troubleshooting)
    -z|--volumemanager:   Volume Managers (defauls: zfs lvm)
```

Todo
----

Things I plan to do:

- Full support for 20.04 (at the moment LVM based installs are working ZFS is not)

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
./guige.sh --action installrequired
```

Download base ISO (jammy)

```
./guige.sh --action getiso 
```

Create ISO (performs all steps):

```
./guige.sh --action createiso
```

Run the previous command but in test mode (don't execute commands) to produce output suitable for creating a script:


```
./guige.sh --action createiso --testmode
```

Use docker to create amd64 ISOs on Apple Silicon:

```
./guige.sh --action createdockeriso --arch amd64
```

Just do autoinstall config and create ISO (assumes an ISO has been previously create and we are just updating the autoinstall config), enabling updates and installing additional packages (requires networkduring OS install)

```
./guige.sh --action justiso --verbose --postinstall distupgrade
```

Build ISO using daily build (this is useful for ARM where daily builds tend to have more hardware support, e.g. being virtualised on Apple Silicon)

```
./guige.sh --action createiso --build daily-live
```

Create an ISO with a static IP configuration:

```
./guige.sh --action createiso --verbose --staticip --ip 192.168.1.211 --cidr 24 --dns 8.8.8.8 --gateway 192.168.1.254
```

Create NFS export for ISO for server install via iDRAC:

```
./guige.sh --action createexport --bmcip 192.168.11.238
```

Create Ansible code to deploy ISO to Dell Server (but don't deploy):

```
./guige.sh --action createansible --bmcip 192.168.11.238 --bmcusername root --bmcpassword XXXXXXXX --arch amd64
```

Deploy ISO to Dell Server using Ansible:

```
./guige.sh --action runansible --bmcip 192.168.11.238 --bmcusername root --bmcpassword XXXXXXXX --arch amd64 --bootserverip 192.168.11.5
```

Deploy ISO to Dell Server using racadm:

```
./guige.sh --action runracadm --bmcip 192.168.11.238 --bmcusername root --bmcpassword XXXXXXXX --arch amd64 --bootserverip 192.168.11.5
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

