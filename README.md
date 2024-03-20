![Cat with shield](https://raw.githubusercontent.com/lateralblast/guige/master/guige.jpg)

GUIGE
-----

Generic Ubuntu ISO Generation Engine

A guige (/ɡiːʒ/, /ɡiːd͡ʒ/) is a long strap, typically made of leather,
used to hang a shield on the shoulder or neck when not in use.

Version
-------

Current version: 2.2.5

Issues
------

Current issues:

- Currently does not work with Ubuntu 22.04.4 or later (have logged a bug with curtin installer team)
  - A workaround for this is to install 22.04.3 or 23.04 and upgrade to a later release
- BIOS ISO does not support ZFS
  - Default mode is UEFI with ZFS and LVM install options
  - BIOS ISO mode will build installer with only LVM install

Prerequisites
-------------

The Following packages are required on Linux (or in the Docker container when building ISO on non Linux platforms):

- p7zip-full (created to extract ISO contents)
- lftp (required to fetch files)
- wget (required to fetch files)
- xorriso (required to create ISO)
- whois (required for mkpasswd to create password hashes - MacOS will use openssl)
- squashfs-tools (required for copying/manipulating root filesystem on ISO)
- sudo (required for mounting loop back filesystems e.g. ISO and squashfs)
- file (required to check files have downloaded correctly)
- rsync (required for copying from base ISO and to to destination ISO image)
- dialog (required for installing packages in chroot environment)

The following packages are optional for additional features:

- docker (required to create ISO on non Linux platforms)
- nfs-kernel-server (required for racadm and redfish based ISO deployment)
- ansible (required for iDRAC redfish ISO deployment)
- kvm (required for building KVM test VM for testing ISO)
- Use ksvalidator to check kickstart files if available (pip install pykickstart)

For best results:

- When creating ZFS based installs UEFI should be used for the entirety of install process
- When using UEFI based installs with USB sticks, the ISO should be written to the USB stick in UEFI mode

Hints / Observations:

- I've found Rufus the most reliable for creating bootable USB sticks
- When using Rufus and using UEFI based installs, change the Target system to UEFI (non CSM)
- To get the Ubuntu ISO to boot on ARM reliably it's best to go with the very latest release (e.g. use --build daily-live)
- A lot of older/earlier BIOS/BMCs will still boot in legacy BIOS mode even when the system is configured to use UEFI
  - iDRAC version 7 and earlier appear to do this
  - Booting to a USB stick created with a GPT partition and UEFI (non CSM) with Rufus addresses this issue

Introduction
------------

This script provides a wrapper for the Ubuntu ISO creation process.
I wrote this as I didn't want to have to fire up Cubic or a similar GUI tool to create an ISO.
I wanted to be able to automate the process.

By default this script creates a DHCP based install ISO with four additonal install options:
- ZFS based install to the first non USB drive available using the first network device with link
- ZFS LVM based install to the first non USB drive available using the first network device with link (work in progress)
- LVM based install to the first non USB drive available using the first network device with link (EXT4 root filesystem)
- LVM based install to the first non USB drive available using the first network device with link (XFS root filesystem)
- LVM based install to the first non USB drive available using the first network device with link (BTRFS root filesystem)

A custom cloud-init user-data file can be used by using the --userdata switch with the location of the file.
This will copy the file into the image, create a boot menu entry called custom, and set that to default.

This can be customised as per examples section to use a custom drive, network device,
and many other options (e.g. username and password)

This script also supports creating ISOs via docker for non Linux platforms.
On Apple Silicon support for creating arm64 and amd64 is available by using the platform flag of docker.

This method doesn't support the older preseed method (i.e. Ubuntu 18.04 or earlier).
Preseed method could be added reasonably easily I expect, but I've only need for Ubuntu 20.04 or later.

So that the additional packages added to the install do not require network access,
the squashfs filesystem is mounted and the packages are installed into it with the download option,
then the packages are copied to the ISO image that is created.
Doing it this way also ensures packages dependencies are also handled.

An example of the grub menu when booting from the ISO:

![Boot menu example](https://raw.githubusercontent.com/lateralblast/guige/master/grubmenu.jpg)

The current disk layouts are default one root partition configs, i.e. no separate
var or home partitions. This could be changed, but in my experience testing recent
cloud-init autoinstall versions/configs on Ubuntu it takes quite a bit of testing
to get more complex layouts working without issue.

This script can also be used to create a KVM/QEMU VM to test the ISO created.
This is useful for troubleshooting by connecting to the KVM VM in console mode and watching install.

I've started collecting manual install configs to help with troubleshooting.
These are located in the configs directory

Usage
-----

You can get help using the -h or --help switch:

```
  Usage: guige.sh [OPTIONS...]

    --oldrelease           Old release (used for copying file from an older release ISO)
    --country              Country (used for sources.list mirror - default: us)
    --isourl               Specify ISO URL
    --prefix               Prefix to add to ISO name
    --suffix               Suffix to add to ISO name
    --block                Block kernel module(s)
    --allow                Load additional kernel modules(s)
    --oldisourl            Old release ISO URL (used with --oldrelease)
    --oldinputfile         Old release ISO (used with --oldrelease)
    --search               Search output for value (eg --action listallisos --search efi)
    --codename|--disto     Linux release codename or distribution
    --action:              Action to perform (e.g. createiso, justiso, runchrootscript, checkdocker, installrequired)
    --layout|--vmsize:     Layout or VM disk size (default: us/20G)
    --bootserverip:        NFS/Bootserver IP
    --cidr:                CIDR (default: 24)
    --sshkeyfile:          SSH key file to use as SSH key (default: /Users/spindler/.ssh/id_rsa.pub)
    --dns:                 DNS Server (ddefault: 8.8.8.8)
    --bootdisk:            Boot Disk devices (default: first-disk)
    --locale:              LANGUAGE (default: en_US.UTF-8)
    --lcall:               LC_ALL (default: en_US)
    --bmcusername:         BMC/iDRAC User (default: root)
    --delete:              Remove previously created files (default: false)
    --gateway:             Gateway (default 192.168.1.254)
    --grubmenu|--vmname:   Set default grub menu or VM name (default: 0/guige)
    --hostname             Hostname (default: ubuntu)
    --help                 Help/Usage Information
    --ip:                  IP Address (default: 192.168.1.2)
    --inputiso|--vmiso:    Input/base ISO file
    --grubfile             GRUB file
    --autoinstalldir       Directory where autoinstall config files are stored on ISO
    --kernel|--vmtype:     Kernel package or VM type (default: linux-generic/kvm)
    --kernelargs|--vmcpus: Kernel arguments (default: console=tty0 console=vt0)
    --release:             LSB release (default: )
    --bmcip:               BMC/iDRAC IP (default: 192.168.1.3)
    --installtarget:       Where the install mounts the target filesystem (default: )
    --installmount:        Where the install mounts the CD during install (default: )
    --bootserverfile       Boot sever file (default: )
    --nic|--vmnic:         Network device (default: first-nic/default)
    --isopackages:         List of packages to install (default: zfsutils-linux zfs-initramfs net-tools curl lftp wget sudo file rsync dialog setserial ansible apt-utils whois squashfs-tools duperemove jq)
    --outputiso:           Output ISO file (default: )
    --password:            Password (default: ubuntu)
    --chrootpackages:      List of packages to add to ISO (default: )
    --build:               Type of ISO to build (default: live-server)
    --arch:                Architecture (default: )
    --realname:            Realname (default Ubuntu)
    --serialportspeed:     Serial Port Speed (default: 115200,115200)
    --swapsize|--vmram:    Swap or VM memory size (default 2G/2048000)
    --squashfsfile:        Squashfs file (default: )
    --timezone:            Timezone (default: Australia/Melbourne)
    --serialportaddress:   Serial Port Address (default: 0x03f8,0x02f8)
    --username:            Username (default: ubuntu)
    --postinstall:         Postinstall action (e.g. installpackages, upgrade, distupgrade, installdrivers, all, autoupgrades)
    --version              Display Script Version
    --serialport:          Serial Port (default: ttyS0,ttyS1)
    --workdir:             Work directory
    --preworkdir:          Docker work directory (used internally)
    --isovolid:            ISO Volume ID
    --grubtimeout:         Grub timeout (default: 10)
    --allowpassword        Allow password access via SSH (default: false)
    --bmcpassword:         BMC/iDRAC password (default: calvin)
    --options:             Options (e.g. nounmount, testmode, bios, uefi, verbose, interactive)
    --volumemanager:       Volume Managers (default: zfs lvm xfs btrfs)
    --zfsfilesystems:      ZFS filesystems (default: /var /var/lib /var/lib/AccountsService /var/lib/apt /var/lib/dpkg /var/lib/NetworkManager /srv /usr /usr/local /var/games /var/log /var/mail /var/snap /var/spool /var/www)
    --userdata:            Use a custom user-data file (default: generate automatically)
    --oeminstall:          OEM Install Type (default: auto)
    --sourceid:            Source ID (default: ubuntu-server)
    --installmode:         Install Mode (default: text)
    --passwordalgorithm:   Password Algorithm (default: sha512)
    --bootloader:          Boot Loader Location (default: mbr)
    --selinux:             SELinux Mode (default: enforcing)
    --firewall:            Firewall (default: enabled)
    --allow:               Allow Services (default: ssh)
    --onboot:              Enable Network on Boot (default: on)
    --enableservice        Enable Service (default: sshd)
    --disableservice       Disable Service (default: cupsd)
    --gecos                GECOS Field Entry (default: cupsd)
    --installsource        Install Source (default: cdrom)
    --bootsize             Boot partition size (default: 2048)
    --rootsize             Root partition size (default: -1)
    --installuser          Temporary install username for remote access during install (default: install)
    --installpassword      Temporary install password for remote access during install (default: install)
    --pesize               PE size (default: 32768)
    --vgname               Volume Group Name (default: system)
```

You can get more usage information by using the usage tag with the action switch:

```
./guige.sh --usage

  actions
  -------

  checkracadm:            Check RACADM requirements are installed
  runracadm:              Run racadm to deploy image
  createexport:           Create export for image (e.g. NFS)
  createansible:          Create ansible stanza
  runansible:             Run ansible stanza
  printenv:               Prints environment
  checkdocker:            Check docker config
  checkdirs:              Check work directories
  getiso:                 Download ISO
  justiso:                Just perform the ISO creation steps rather than all steps
  checkrequired:          Check required packages
  installrequired:        Install required packages
  createautoinstall:      Just create autoinstall files
  runchrootscript:        Just run chroot script
  createiso:              Create ISO
  createisoandsquashfs:   Create ISO and squashfs
  dockeriso:              Use Docker to create ISO
  dockerisoandsquashfs:   Use Docker to create ISO
  queryiso:               Query ISO for information
  listalliso:             List all ISOs
  listiso:                List ISOs
  createkvmvm:            Create KVM VM
  deletekvmvm:            Delete KVM VM

  options
  -------

  cluster                 Install cluster related packages (pcs, gluster, etc)  (default: false)
  kvm                     Install KVM related packages (virt-manager, cloud-image-utils, etc) (default: (false)
  sshkey                  Add SSH key from ~/.ssh if present (default: false)
  biosdevname:            Enable biosdevname kernel parameters (default: false)
  nounmount:              Don't unmount filesystems (useful for troubleshooting) (default: false)
  testmode:               Don't execute commands (useful for testing and generating a script) (deafault: false)
  efi:                    Create UEFI based ISO
  bios:                   Create BIOS based ISO
  verbose:                Verbose output (default: false)
  interactive:            Interactively ask questions (default: false)
  autoupgrades:           Allow autoupgrades
  nohwekernel:            Don't install HWE kernel packages (Ubuntu) (deafault: false)
  nomultipath:            Don't load multipath kernel module (default: false)
  plaintextpassword:      Use plaintext password (default: false)
  mediacheck              Do media check (default: false)
  nolockroot              Don't lock root account
  noactivate              Don't activate network
  noipv4                  Disable IPv4
  noipv6                  Disable IPv6
  plaintext               Plain text password
  nohwekernel             Don't install HWE kernel package
  staticip                Use static IP
  dhcp                    Use DHCP

  postinstall
  -----------

  distupgrade:            Do distribution upgrade as part of install process
  packages:               Install packages as part of install process
  updates:                Do updates as part of install process
  upgrades:               Do upgrades as part of install process
  all:                    Do all updates as part of install process

  Examples
  --------

  Create an ISO with a static IP configuration:

  guige.sh --action createiso --options verbose --ip 192.168.1.211 --cidr 24 --dns 8.8.8.8 --gateway 192.168.1.254
```

Todo
----

Things I plan to do:

- Get ZFS root to work with BIOS baes installs (currently ZFS root only works with EFI based installs)

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

Create an Ubuntu 22.04 ISO (UEFI - default - ZFS and LVM install options):

```
./guige.sh --action createiso --release 22.04
```

Create an Ubuntu 22.04 ISO (BIOS - LVM install option only):

```
./guige.sh --action createiso --release 22.04 --options bios
```

Create a test (and call it test) Ubuntu KVM VM (requires an Ubuntu 22.04 ISO to have been created)

```
./guige.sh --action createkvmvm --vmname test  --release 22.04
To start the VM and connect to console run the following commands:

sudo virsh start test ; sudo virsh console test
```

Delete a test KVM VM named test

```
./guige.sh --action deletekvmvm --vmname test
```

Create a KVM VM and specify the amount of RAM and number of CPUs

```
./guige.sh --action createkvmvm --vmname test  --release 22.04 --vmram 2G --vmcpus 4
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
./guige.sh --action justiso --options verbose --postinstall distupgrade
```

Build ISO using daily build (this is useful for ARM where daily builds tend to have more hardware support, e.g. being virtualised on Apple Silicon)

```
./guige.sh --action createiso --build daily-live
```

Create an ISO with a static IP configuration:

```
./guige.sh --action createiso --options verbose --ip 192.168.1.211 --cidr 24 --dns 8.8.8.8 --gateway 192.168.1.254
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

Create an Ubuntu 23.04 ISO, using the daily-live server image as a basis, set the default username and password, and copy the local SSH keys into the cloud-init configuration if present:

```
./guige.sh --action createiso --release 23.04 --options verbose,sshkeys --build daily-live --username uadmin --password uadmin
```

List ISOs with efi in name:

```
./guige.sh --action listallisos --search efi
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
