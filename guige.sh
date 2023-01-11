#!/bin/bash

# Name:         guige (Generic Ubuntu ISO Generation Engine)
# Version:      0.1.9
# Release:      1
# License:      CC-BA (Creative Commons By Attribution)
#               http://creativecommons.org/licenses/by/4.0/legalcode
# Group:        System
# Source:       N/A
# URL:          http://lateralblast.com.au/
# Distribution: Ubuntu Linux
# Vendor:       UNIX
# Packager:     Richard Spindler <richard@lateralblast.com.au>
# Description:  Shell script designed to simplify creation of custom Ubuntu

# Defaults

ARGS=$@
CURRENT_RELEASE="jammy"
DEFAULT_HOSTNAME="ubuntu"
DEFAULT_REALNAME="Ubuntu"
DEFAULT_USERNAME="ubuntu"
DEFAULT_TIMEZONE="Australia/Melbourne"
DEFAULT_PASSWORD="P455w0rD"
RELEASE=""
HOSTNAME=""
REALNAME=""
USERNAME=""
TIMEZONE=""
PASSWORD=""
ARCH="amd64"
TEST_MODE="0"
FORCE_MODE="0"
FULL_FORCE_MODE="0"
VERBOSE_MODE="0"
DEFAULTS_MODE="0"
INTERACTIVE_MODE="0"
GRUB_TIMEOUT="10"
CHROOT_PACKAGES=""
DEFAULT_PACKAGES="zfsutils-linux grub-efi zfs-initramfs net-tools curl wget"
REQUIRED_PACKAGES="p7zip-full wget xorriso whois"

# Get default release

if [ -f "/usr/bin/lsb_release" ]; then
  if [ "$( lsb_release -d |awk '{print $2}' )" = "Ubuntu" ]; then
    DEFAULT_RELEASE=$( lsb_release -cs )
  else
    DEFAULT_RELEASE="$CURRENT_RELEASE"
  fi
else
  DEFAULT_RELEASE="$CURRENT_RELEASE"
fi


# Default work directories

WORK_DIR=$HOME/ubuntu-iso
ISO_MOUNT_DIR="$WORK_DIR/isomount"
ISO_NEW_DIR="$WORK_DIR/isonew"
ISO_SOURCE_DIR="$WORK_DIR/source-files"
INSTALL_DIR="autoinstall"
INSTALL_MOUNT="/cdrom"

# Default file names/locations

DEFAULT_ISO_FILE="$WORK_DIR/$DEFAULT_RELEASE-live-server-$ARCH.iso"
DEFAULT_OUTPUT_FILE="$WORK_DIR/$DEFAULT_RELEASE-live-server-$ARCH-autoinstall.iso"
SQUASHFS_FILE="$ISO_MOUNT_DIR/casper/ubuntu-server-minimal.squashfs"
GRUB_FILE="$WORK_DIR/grub.cfg"
SDA_USER_FILE="$WORK_DIR/sda-user-data"
VDA_USER_FILE="$WORK_DIR/vda-user-data"

# Get the path the script starts from

start_path=$( pwd )

# Get the version of the script from the script itself

script_version=$( cd $start_path ; cat $0 | grep '^# Version' | awk '{print $3}' )

# Function: Print help

print_help () {
  cat <<-HELP
  Usage: ${0##*/} [OPTIONS...]
    -C  Run chroot script
    -c  Create ISO (perform all steps - e.g. grub, packages, etc)
    -D  Use defaults
    -d  Get base ISO
    -f  Remove previously created files
    -H: Hostname
    -h  Help/Usage Information
    -I  Interactive mode (will ask for input rather than using command line options or defaults)
    -i: Input/base ISO file
    -L: LSB release
    -l  Create ISO (perform last step only - just run xoriso)
    -o: Output ISO file
    -P: Password
    -p: Packages to add to ISO
    -R: Realname
    -r  Install required packages on host
    -T: Timezone
    -t  Test mode
    -U: Username
    -u  Unmount loopback filesystems
    -V  Script Version
    -v  Verbose output
    -W: Work directory
    -w  Check work directories
HELP
}

# If given no command line arguments print usage information

if [ $( expr "$ARGS" : "\-" ) != 1 ]; then
  print_help
  exit
fi

# Function: Handle output

handle_output () {
  OUTPUT_TEXT=$1
  OUTPUT_TYPE=$2
  if [ "$VERBOSE_MODE" = "1" ]; then
    if [ "$TEST_MODE" = "1" ]; then
      echo "$OUTPUT_TEXT"
    else
      if [ "$OUTPUT_TYPE" = "TEXT" ]; then
        echo "$OUTPUT_TEXT"
      else
        echo "Executing: $OUTPUT_TEXT"
      fi
    fi
  fi
}

# Function: Check work directories exist
#
# Example:
# mkdir -p ./isomount ./isonew/squashfs ./isonew/cd ./isonew/custom

check_work_dir () {
  handle_output "# Check work directories" TEXT
  for ISO_DIR in $ISO_MOUNT_DIR $ISO_NEW_DIR/squashfs $ISO_NEW_DIR/cd $ISO_NEW_DIR/custom; do
    handle_output "# Check directory $ISO_DIR exists" TEXT
    handle_output "mkdir -p $ISO_DIR"
    if [ "$FORCE_MODE" = "1" ]; then
      if [ -d "$ISO_DIR" ]; then
        handle_output "# Remove existing directory $ISO_DIR"
        handle_output "sudo rm -rf $ISO_DIR"
        if [[ $ISO_DIR =~ [0-9a-zA-Z] ]]; then
          if [ "$TEST_MODE" = "0" ]; then
            sudo rm -rf $ISO_DIR
          fi
        fi
      fi
    fi
    if ! [ -d "$ISO_DIR" ]; then
      handle_output "# Create $ISO_DIR if it doesn't exist" TEXT
      if [ "$TEST_MODE" = "0" ]; then
        mkdir -p $ISO_DIR
      fi
    fi
  done
}

# Function: Install required packages
#
# Example:
# sudo apt install -y p7zip-full wget xorriso

install_required_packages () {
  handle_output "# Check required packages are installed" TEXT
  for PACKAGE in $REQUIRED_PACKAGES; do
    VERSION=$( apt show $PACKAGE 2>&1 |grep Version )
    if ! [ -x "$VERSION" ]; then
      handle_output "sudo apt install -y $PACKAGE"
      if [ "$TEST_MODE" = "0" ]; then
        sudo apt install -y $PACKAGE
      fi
    fi
  done
}

# Function: Grab ISO from Ubuntu
# 
# Examples:
# https://cdimage.ubuntu.com/ubuntu-server/jammy/daily-live/current/jammy-live-server-amd64.iso
# wget https://cdimage.ubuntu.com/releases/22.04/RELEASE/ubuntu-22.04.1-live-server-amd64.iso

get_base_iso () {
  handle_output "# Check source ISO exists and grab it if it doesn't" TEXT
  BASE_ISO_FILE=$( basename $ISO_FILE )
  if [ "$FULL_FORCE_MODE" = "1" ]; then
    handle_output "rm $WORK_DIR/$ISO_FILE" 
    if [ "$TEST_MODE" = "0" ]; then
      rm $WORK_DIR/$ISO_FILE
    fi
  fi
  ISO_URL="https://cdimage.ubuntu.com/ubuntu-server/$RELEASE/daily-live/current/$BASE_ISO_FILE"
  handle_output "wget $ISO_URL -O $WORK_DIR/$BASE_ISO_FILE"
  if ! [ -f "$WORK_DIR/$BASE_ISO_FILE" ]; then
    if [ "$TEST_MODE" = "0" ]; then
      wget $ISO_URL -O $WORK_DIR/$BASE_ISO_FILE
    fi
  fi
}
# Function unmount loopback ISO filesystem
#
# Examples:
# sudo umount -l /home/user/ubuntu-iso/isomount

unmount_iso () {
  handle_output "sudo umount -l $ISO_MOUNT_DIR"
  if [ "$TEST_MODE" = "0" ]; then
    sudo umount -l $ISO_MOUNT_DIR
  fi
}

# Mount base ISO as loopback device so contents can be copy
#
# sudo mount -o loop ./ubuntu-22.04.1-live-server-arm64.iso ./isomount
# sudo mount -o loop ./ubuntu-22.04.1-live-server-amd64.iso ./isomount

mount_iso () {
  get_base_iso
  BASE_ISO_FILE=$( basename $ISO_FILE )
  handle_output "sudo mount -o loop $WORK_DIR/$BASE_ISO_FILE $ISO_MOUNT_DIR"
  if [ "$TEST_MODE" = "0" ]; then
    sudo mount -o loop $WORK_DIR/$BASE_ISO_FILE $ISO_MOUNT_DIR
  fi
}

unmount_squashfs () {
  handle_output "sudo umount $ISO_NEW_DIR/squashfs"
  if [ "$TEST_MODE" = "0" ]; then
    sudo umount $ISO_NEW_DIR/squashfs
  fi
}

# Function: Copy contents of ISO to a RW location so we can work with them
#
# Examples:
# rsync --exclude=/casper/ubuntu-server-minimal.squashfs -av ./isomount/ ./isonew/cd
# rsync -av ./isomount/ ./isonew/cd

copy_iso () {
  if [ "$VERBOSE_MODE" = "1" ]; then
    handle_output "rsync -av $ISO_MOUNT_DIR/ $ISO_NEW_DIR/cd"
    if [ "$TEST_MODE" = "0" ]; then
      rsync -av $ISO_MOUNT_DIR/ $ISO_NEW_DIR/cd
    fi
  else
    handle_output "rsync -a $ISO_MOUNT_DIR/ $ISO_NEW_DIR/cd"
    if [ "$TEST_MODE" = "0" ]; then
      rsync -a $ISO_MOUNT_DIR/ $ISO_NEW_DIR/cd
    fi
  fi
}

# Function: Mount squashfs and copy giles into it
#
# Examples:
# sudo mount -t squashfs -o loop ./isomount/casper/ubuntu-server-minimal.squashfs ./isonew/squashfs/
# sudo rsync -av ./isonew/squashfs/ ./isonew/custom
# sudo cp /etc/resolv.conf /etc/hosts ./isonew/custom/etc/
# sudo cp /etc/apt/sources.list ./isonew/custom/etc/apt/

copy_squashfs () {
  handle_output "sudo mount -t squashfs -o loop $SQUASHFS_FILE $ISO_NEW_DIR/squashfs/"
  if [ "$TEST_MODE" = "0" ]; then
    sudo mount -t squashfs -o loop $SQUASHFS_FILE $ISO_NEW_DIR/squashfs/
  fi
  if [ "$VERBOSE_MODE" = "1" ]; then
    handle_output "sudo rsync -av $ISO_NEW_DIR/squashfs/ $ISO_NEW_DIR/custom"
    if [ "$TEST_MODE" = "0" ]; then
      sudo rsync -av $ISO_NEW_DIR/squashfs/ $ISO_NEW_DIR/custom
    fi
  else
    handle_output "sudo rsync -a $ISO_NEW_DIR/squashfs/ $ISO_NEW_DIR/custom"
    if [ "$TEST_MODE" = "0" ]; then
      sudo rsync -a $ISO_NEW_DIR/squashfs/ $ISO_NEW_DIR/custom
    fi
  fi
  handle_output "sudo cp /etc/resolv.conf /etc/hosts $ISO_NEW_DIR/custom/etc/"
  handle_output "sudo cp /etc/apt/sources.list $ISO_NEW_DIR/etc/apt/"
  if [ "$TEST_MODE" = "0" ]; then
    sudo cp /etc/resolv.conf /etc/hosts $ISO_NEW_DIR/custom/etc/
    sudo cp /etc/apt/sources.list $ISO_NEW_DIR/etc/apt/
  fi
}

# Function: Chroot into environment and run script on chrooted environmnet
#
# Examples:
# sudo chroot ./isonew/custom

execute_chroot_script () {
  handle_output "sudo chroot $ISO_NEW_DIR/custom /tmp/modify_chroot.sh"
  if [ "$TEST_MODE" = "0" ]; then
    sudo chroot $ISO_NEW_DIR/custom /tmp/modify_chroot.sh
  fi
}

# Function: Create script to drop into chrooted environment
#           Inside chrooted environment, mount filesystems and packages
# 
# Examples:
# mount -t proc none /proc/
# mount -t sysfs none /sys/
# mount -t devpts none /dev/pts
# export HOME=/root
# sudo apt update
# sudo apt install -y --download-only zfsutils-linux grub-efi zfs-initramfs net-tools curl wget
# sudo apt install -y zfsutils-linux grub-efi zfs-initramfs net-tools curl wget
# umount /proc/
# umount /sys/
# umount /dev/pts/
# exit

create_chroot_script () {
  ORIG_SCRIPT="$WORK_DIR/modify_chroot.sh"
  CHROOT_SCRIPT="$ISO_NEW_DIR/custom/tmp/modify_chroot.sh"
  handle_output "echo \"#!/usr/bin/bash\" > $ORIG_SCRIPT"
  handle_output "echo \"mount -t proc none /proc/\" >> $ORIG_SCRIPT"
  handle_output "echo \"mount -t sysfs none /sys/\" >> $ORIG_SCRIPT"
  handle_output "echo \"mount -t devpts none /dev/pts\" >> $ORIG_SCRIPT"
  handle_output "echo \"export HOME=/root\" >> $ORIG_SCRIPT"
  handle_output "echo \"sudo apt update\" >> $ORIG_SCRIPT"
  handle_output "echo \"sudo apt clean\" >> $ORIG_SCRIPT"
  handle_output "echo \"rm /var/cache/apt/archives/*.deb\" >> $ORIG_SCRIPT"
  handle_output "echo \"sudo apt install -y --download-only $CHROOT_PACKAGES\" >> $ORIG_SCRIPT"
  handle_output "echo \"sudo apt install -y $CHROOT_PACKAGES\" >> $ORIG_SCRIPT"
  handle_output "echo \"umount /proc/\" >> $ORIG_SCRIPT"
  handle_output "echo \"umount /sys/\" >> $ORIG_SCRIPT"
  handle_output "echo \"umount /dev/pts/\" >> $ORIG_SCRIPT"
  handle_output "echo \"exit\" >> $ORIG_SCRIPT"
  handle_output "sudo cp $ORIG_SCRIPT $CHROOT_SCRIPT"
  handle_output "sudo chmod +x $CHROOT_SCRIPT"
  if [ "$TEST_MODE" = "0" ]; then
    if ! [ -f "$ORIG_SCRIPT" ]; then
      echo "#!/usr/bin/bash" > $ORIG_SCRIPT
      echo "mount -t proc none /proc/" >> $ORIG_SCRIPT
      echo "mount -t sysfs none /sys/" >> $ORIG_SCRIPT
      echo "mount -t devpts none /dev/pts" >> $ORIG_SCRIPT
      echo "export HOME=/root" >> $ORIG_SCRIPT
      echo "sudo apt update" >> $ORIG_SCRIPT
      echo "sudo apt clean" >> $ORIG_SCRIPT
      echo "rm /var/cache/apt/archives/*.deb" >> $ORIG_SCRIPT
      echo "sudo apt install -y --download-only $CHROOT_PACKAGES" >> $ORIG_SCRIPT
      echo "sudo apt install -y $CHROOT_PACKAGES" >> $ORIG_SCRIPT
      echo "umount /proc/" >> $ORIG_SCRIPT
      echo "umount /sys/" >> $ORIG_SCRIPT
      echo "umount /dev/pts/" >> $ORIG_SCRIPT
      echo "exit" >> $ORIG_SCRIPT
    fi
    if ! [ -f "$CHROOT_SCRIPT" ]; then
      sudo cp $ORIG_SCRIPT $CHROOT_SCRIPT
      sudo chmod +x $CHROOT_SCRIPT
    fi
  fi
}

# Get password crypt
#
# echo test |mkpasswd --method=SHA-512 --stdin

get_password_crypt () {
  PASSWORD=$1
  handle_output "export PASSWORD_CRYPT=\$(echo $PASSWORD |mkpasswd --method=SHA-512 --stdin)"
  if [ "$TEST_MODE" = "0" ]; then
    PASSWORD_CRYPT=$( echo $PASSWORD |mkpasswd --method=SHA-512 --stdin )
  fi
}

# Uncompress ISO and copy autoinstall files into it
#
# 7z -y x ubuntu-22.04.1-live-server-arm64.iso -osource-files
# 7z -y x ubuntu-22.04.1-live-server-amd64.iso -osource-files
# mv source-files/\[BOOT\] ./BOOT
# mkdir -p source-files/autoinstall/configs/sda
# mkdir -p source-files/autoinstall/configs/vda
# mkdir -p source-files/autoinstall/packages
# touch source-files/autoinstall/configs/sda/meta-data
# touch source-files/autoinstall/configs/vda/meta-data
# cp isonew/custom/var/cache/apt/archives/*.deb source-files/autoinstall/packages/
#
# Example grub file creation
#
# cat <<EOF > source-files/boot/grub/grub.cfg
# set timeout=10
# loadfont unicode
# set menu_color_normal=white/black
# set menu_color_highlight=black/light-gray
# menuentry "Autoinstall Ubuntu Server - Physical" {
#     set gfxpayload=keep
#     linux   /casper/vmlinuz quiet autoinstall ds=nocloud\;s=/cdrom/autoinstall/configs/sda/  ---
#     initrd  /casper/initrd
# }
# menuentry "Autoinstall Ubuntu Server - KVM" {
#     set gfxpayload=keep
#     linux   /casper/vmlinuz quiet autoinstall ds=nocloud\;s=/cdrom/autoinstall/configd/vda/  ---
#     initrd  /casper/initrd
# }
# menuentry "Try or Install Ubuntu Server" {
#   set gfxpayload=keep
#   linux /casper/vmlinuz quiet ---
#   initrd  /casper/initrd
# }
# menuentry 'Boot from next volume' {
#   exit 1
# }
# menuentry 'UEFI Firmware Settings' {
#   fwsetup
# }
# EOF
#
# Example user-data file creation
#
# cat <<EOF > source-files/autoinstall/configs/sda/user-data
# #cloud-config
# autoinstall:
#   apt:
#     preferences:
#       - package: "*"
#         pin: "release a=jammy-security"
#         pin-priority: 200
#     disable_components: []
#     geoip: true
#     preserve_sources_list: false
#     primary:
#     - arches:
#       - amd64
#       - i386
#       uri: http://archive.ubuntu.com/ubuntu
#     - arches:
#       - default
#       uri: http://ports.ubuntu.com/ubuntu-ports
#   package_update: false
#   package_upgrade: false
#   drivers:
#     install: false
#   user-data:
#     timezone: Australia/Melbourne
#   identity:
#     hostname: ubuntu
#     password: PASSWORD-CRYPT
#     realname: Ubuntu
#     username: ubuntu
#   kernel:
#     package: linux-generic
#   keyboard:
#     layout: us
#   locale: en_US.UTF-8
#   network:
#     ethernets:
#       ens33:
#         critical: true
#         dhcp-identifier: mac
#         dhcp4: true
#     version: 2
#   ssh:
#     allow-pw: true
#     authorized-keys: []
#     install-server: true
#   storage:
#     config:
#     - ptable: gpt
#       path: /dev/sda
#       wipe: superblock-recursive
#       preserve: false
#       name: ''
#       grub_device: true
#       type: disk
#       id: disk1
#     - device: disk1
#       size: 1127219200
#       wipe: superblock-recursive
#       flag: boot
#       number: 1
#       preserve: false
#       grub_device: true
#       type: partition
#       ptable: gpt
#       id: disk1p1
#     - fstype: fat32
#       volume: disk1p1
#       preserve: false
#       type: format
#       id: disk1p1fs1
#     - path: /boot/efi
#       device: disk1p1fs1
#       type: mount
#       id: mount-2
#     - device: disk1
#       size: -1
#       wipe: superblock-recursive
#       flag: root
#       number: 2
#       preserve: false
#       grub_device: false
#       type: partition
#       id: disk1p2
#     - id: disk1p2fs1
#       type: format
#       fstype: zfsroot
#       volume: disk1p2
#       preserve: false
#     - id: disk1p2f1_rootpool
#       mountpoint: /
#       pool: rpool
#       type: zpool
#       device: disk1p2fs1
#       preserve: false
#       vdevs:
#         - disk1p2fs1
#     - id: disk1_rootpool_container
#       pool: disk1p2f1_rootpool
#       preserve: false
#       properties:
#         canmount: "off"
#         mountpoint: "none"
#       type: zfs
#       volume: /ROOT
#     - id: disk1_rootpool_rootfs
#       pool: disk1p2f1_rootpool
#       preserve: false
#       properties:
#         canmount: noauto
#         mountpoint: /
#       type: zfs
#       volume: /ROOT/zfsroot
#     - path: /
#       device: disk1p2fs1
#       type: mount
#       id: mount-disk1p2
#     swap:
#       swap: 0
#   early-commands:
#     - "sudo dpkg --auto-deconfigure --force-depends -i /cdrom/autoinstall/packages/*.deb"
#   version: 1
# EOF
#
# get ISO formatting information
# 
# xorriso -indev ubuntu-22.04.1-live-server-amd64.iso -report_el_torito as_mkisofs
# xorriso 1.5.4 : RockRidge filesystem manipulator, libburnia project.
#
# xorriso : NOTE : Loading ISO image tree from LBA 0
# xorriso : UPDATE :     803 nodes read in 1 seconds
# libisofs: NOTE : Found hidden El-Torito image for EFI.
# libisofs: NOTE : EFI image start and size: 717863 * 2048 , 8496 * 512
# xorriso : NOTE : Detected El-Torito boot information which currently is set to be discarded
# Drive current: -indev 'ubuntu-22.04.1-live-server-amd64.iso'
# Media current: stdio file, overwriteable
# Media status : is written , is appendable
# Boot record  : El Torito , MBR protective-msdos-label grub2-mbr cyl-align-off GPT
# Media summary: 1 session, 720153 data blocks, 1407m data,  401g free
# Volume id    : 'Ubuntu-Server 22.04.1 LTS amd64'
# -V 'Ubuntu-Server 22.04.1 LTS amd64'
# --modification-date='2022080916483300'
# --grub2-mbr --interval:local_fs:0s-15s:zero_mbrpt,zero_gpt:'ubuntu-22.04.1-live-server-amd64.iso'
# --protective-msdos-label
# -partition_cyl_align off
# -partition_offset 16
# --mbr-force-bootable
# -append_partition 2 28732ac11ff8d211ba4b00a0c93ec93b --interval:local_fs:2871452d-2879947d::'ubuntu-22.04.1-live-server-amd64.iso'
# -appended_part_as_gpt
# -iso_mbr_part_type a2a0d0ebe5b9334487c068b6b72699c7
# -c '/boot.catalog'
# -b '/boot/grub/i386-pc/eltorito.img'
# -no-emul-boot
# -boot-load-size 4
# -boot-info-table
# --grub2-boot-info
# -eltorito-alt-boot
# -e '--interval:appended_partition_2_start_717863s_size_8496d:all::'
# -no-emul-boot
# -boot-load-size 8496
#
# export APPEND_PARTITION=$(xorriso -indev ubuntu-22.04.1-live-server-amd64.iso -report_el_torito as_mkisofs |grep append_partition |tail -1 |awk '{print $3}' 2>&1)
# export ISO_MBR_PART_TYPE=$(xorriso -indev ubuntu-22.04.1-live-server-amd64.iso -report_el_torito as_mkisofs |grep iso_mbr_part_type |tail -1 |awk '{print $2}' 2>&1)
# xorriso -as mkisofs -r -V 'Ubuntu-Server 22.04.1 LTS arm64' -o ../ubuntu-22.04-autoinstall-arm64.iso --grub2-mbr \
# ../BOOT/Boot-NoEmul.img -partition_offset 16 --mbr-force-bootable -append_partition 2 $APPEND_PARTITION ../BOOT/Boot-NoEmul.img \
# -appended_part_as_gpt -iso_mbr_part_type $ISO_MBR_PART_TYPE -c '/boot/boot.cat' -e '--interval:appended_partition_2:::' -no-emul-boot

create_autoinstall_iso () {
  handle_output "# Create ISO"
  handle_output "cd $WORK_DIR ; export APPEND_PART=\$( xorriso -indev $ISO_FILE -report_el_torito as_mkisofs |grep append_partition |tail -1 |awk '{print \$3}' 2>&1 )"
  handle_output "cd $WORK_DIR ; export ISO_MBR_PART_TYPE=\$( xorriso -indev $ISO_FILE -report_el_torito as_mkisofs |grep iso_mbr_part_type |tail -1 |awk '{print \$2}' 2>&1 )"
  handle_output "cd $ISO_SOURCE_DIR ; xorriso -as mkisofs -r -V 'Ubuntu 22.04 LTS AUTO (EFIBIOS)' -o ../$OUTPUT_FILE \
  --grub2-mbr ../BOOT/1-Boot-NoEmul.img -partition_offset 16 --mbr-force-bootable \
  -append_partition 2 $APPEND_PART ../BOOT/2-Boot-NoEmul.img -appended_part_as_gpt \
  -iso_mbr_part_type $ISO_MBR_PART_TYPE -c /boot.catalog -b /boot/grub/i386-pc/eltorito.img \
  -no-emul-boot -boot-load-size 4 -boot-info-table --grub2-boot-info -eltorito-alt-boot \
  -e '--interval:appended_partition_2:::' -no-emul-boot ."
  if [ "$TEST_MODE" = "0" ]; then
    APPEND_PART=$( xorriso -indev $ISO_FILE -report_el_torito as_mkisofs |grep append_partition |tail -1 |awk '{print $3}' 2>&1 )
    ISO_MBR_PART_TYPE=$( xorriso -indev $ISO_FILE -report_el_torito as_mkisofs |grep iso_mbr_part_type |tail -1 |awk '{print $2}' 2>&1 )
    cd $ISO_SOURCE_DIR ; xorriso -as mkisofs -r -V 'Ubuntu 22.04 LTS AUTO (EFIBIOS)' -o $OUTPUT_FILE \
    --grub2-mbr ../BOOT/1-Boot-NoEmul.img -partition_offset 16 --mbr-force-bootable \
    -append_partition 2 $APPEND_PART ../BOOT/2-Boot-NoEmul.img -appended_part_as_gpt \
    -iso_mbr_part_type $ISO_MBR_PART_TYPE -c /boot.catalog -b /boot/grub/i386-pc/eltorito.img \
    -no-emul-boot -boot-load-size 4 -boot-info-table --grub2-boot-info -eltorito-alt-boot \
    -e '--interval:appended_partition_2:::' -no-emul-boot .
  fi
}

prepare_autoinstall_iso () {
  handle_output "# Create autoinstall files"
  get_password_crypt $PASSWORD
  PACKAGE_DIR="$ISO_SOURCE_DIR/$INSTALL_DIR/packages"
  CONFIG_DIR="$ISO_SOURCE_DIR/$INSTALL_DIR/configs"
  BASE_ISO_FILE=$( basename $ISO_FILE )
  handle_output "7z -y x $WORK_DIR/$BASE_ISO_FILE -o$ISO_SOURCE_DIR"
  handle_output "rm -rf $WORK_DIR/BOOT"
  handle_output "mkdir -p $PACKAGE_DIR"
  handle_output "cp $ISO_CUSTOM_DIR/var/cache/apt/archives/*.deb $PACKAGE_DIR"
  for SUB_DIR in sda vda; do
    handle_output "mkdir -p $CONFIG_DIR/$SUB_DIR"
    handle_output "touch $CONFIG_DIR/$SUB_DIR/meta-data"
  done
  if [ "$TEST_MODE" = "0" ]; then
    7z -y x $WORK_DIR/$BASE_ISO_FILE -o$ISO_SOURCE_DIR
    mkdir -p $PACKAGE_DIR
    for SUB_DIR in sda vda; do
      mkdir -p $CONFIG_DIR/$SUB_DIR
      touch $CONFIG_DIR/$SUB_DIR/meta-data
    done
    cp $ISO_CUSTOM_DIR/var/cache/apt/archives/*.deb $PACKAGE_DIR
  fi
  if [ -d "$WORK_DIR/BOOT" ]; then
    if [ "$TEST_MODE" = "0" ]; then
      if [ "$FORCE_MODE" = "1" ]; then
        rm -rf $WORK_DIR/BOOT
        mv $ISO_SOURCE_DIR/\[BOOT\] $WORK_DIR/BOOT
      fi
    fi
  else
    if [ "$TEST_MODE" = "0" ]; then
      mv $ISO_SOURCE_DIR/\[BOOT\] $WORK_DIR/BOOT
    fi
  fi
  if [ -f "$WORK_DIR/grub.cfg" ]; then
    handle_output "cp $WORK_DIR/grub.cfg $ISO_SOURCE_DIR/boot/grub/grub.cfg"
    if [ "$TEST_MODE" = "0" ]; then
      cp $WORK_DIR/grub.cfg $ISO_SOURCE_DIR/boot/grub/grub.cfg
    fi
  else
    handle_output "echo \"set timeout=$GRUB_TIMEOUT\" > $ISO_SOURCE_DIR/boot/grub/grub.cfg"
    handle_output "echo \"loadfont unicode\" >> $ISO_SOURCE_DIR/boot/grub/grub.cfg"
    handle_output "echo \"menuentry 'Autoinstall Ubuntu Server - Physical' {\" >> $ISO_SOURCE_DIR/boot/grub/grub.cfg"
    handle_output "echo \"  set gfxpayload=keep\" >> $ISO_SOURCE_DIR/boot/grub/grub.cfg"
    handle_output "echo \"  linux   /casper/vmlinuz quiet autoinstall ds=nocloud\;s=/$INSTALL_MOUNT/$INSTALL_DIRs/configs/sda/  ---\" >> $ISO_SOURCE_DIR/boot/grub/grub.cfg"
    handle_output "echo \"  initrd  /casper/initrd\" >> $ISO_SOURCE_DIR/boot/grub/grub.cfg"
    handle_output "echo \"}\" >> $ISO_SOURCE_DIR/boot/grub/grub.cfg"
    handle_output "echo \"  menuentry 'Autoinstall Ubuntu Server - Virtual - KVM' {\" >> $ISO_SOURCE_DIR/boot/grub/grub.cfg"
    handle_output "echo \"  set gfxpayload=keep\" >> $ISO_SOURCE_DIR/boot/grub/grub.cfg"
    handle_output "echo \"  linux   /casper/vmlinuz quiet autoinstall ds=nocloud\;s=/$INSTALL_MOUNT/$INSTALL_DIRs/configs/vda/  ---\" >> $ISO_SOURCE_DIR/boot/grub/grub.cfg"
    handle_output "echo \"  initrd  /casper/initrd\" >> $ISO_SOURCE_DIR/boot/grub/grub.cfg"
    handle_output "echo \"}\" >> $ISO_SOURCE_DIR/boot/grub/grub.cfg"
    handle_output "echo \"menuentry 'Try or Install Ubuntu Server' {\" >> $ISO_SOURCE_DIR/boot/grub/grub.cfg"
    handle_output "echo \"  set gfxpayload=keep\" >> $ISO_SOURCE_DIR/boot/grub/grub.cfg"
    handle_output "echo \"  linux /casper/vmlinuz quiet ---\" >> $ISO_SOURCE_DIR/boot/grub/grub.cfg"
    handle_output "echo \"  initrd  /casper/initrd\" >> $ISO_SOURCE_DIR/boot/grub/grub.cfg"
    handle_output "echo \"}\" >> $ISO_SOURCE_DIR/boot/grub/grub.cfg"
    handle_output "echo \"menuentry 'Boot from next volume' {\" >> $ISO_SOURCE_DIR/boot/grub/grub.cfg"
    handle_output "echo \"  exit 1\" >> $ISO_SOURCE_DIR/boot/grub/grub.cfg"
    handle_output "echo \"}\" >> $ISO_SOURCE_DIR/boot/grub/grub.cfg"
    handle_output "echo \"menuentry 'UEFI Firmware Settings' {\" >> $ISO_SOURCE_DIR/boot/grub/grub.cfg"
    handle_output "echo \"  fwsetup\" >> $ISO_SOURCE_DIR/boot/grub/grub.cfg"
    handle_output "echo \"}\" >> $ISO_SOURCE_DIR/boot/grub/grub.cfg"
    if [ "$TEST_MODE" = "0" ]; then
      echo "set timeout=$GRUB_TIMEOUT" > $ISO_SOURCE_DIR/boot/grub/grub.cfg
      echo "loadfont unicode" >> $ISO_SOURCE_DIR/boot/grub/grub.cfg
      echo "menuentry 'Autoinstall Ubuntu Server - Physical' {" >> $ISO_SOURCE_DIR/boot/grub/grub.cfg
      echo "  set gfxpayload=keep" >> $ISO_SOURCE_DIR/boot/grub/grub.cfg
      echo "  linux   /casper/vmlinuz quiet autoinstall ds=nocloud\;s=$INSTALL_MOUNT/$INSTALL_DIR/configs/sda/  ---" >> $ISO_SOURCE_DIR/boot/grub/grub.cfg
      echo "  initrd  /casper/initrd" >> $ISO_SOURCE_DIR/boot/grub/grub.cfg
      echo "}" >> $ISO_SOURCE_DIR/boot/grub/grub.cfg
      echo "  menuentry 'Autoinstall Ubuntu Server - Virtual - KVM' {" >> $ISO_SOURCE_DIR/boot/grub/grub.cfg
      echo "  set gfxpayload=keep" >> $ISO_SOURCE_DIR/boot/grub/grub.cfg
      echo "  linux   /casper/vmlinuz quiet autoinstall ds=nocloud\;s=$INSTALL_MOUNT/$INSTALL_DIR/configs/vda/  ---" >> $ISO_SOURCE_DIR/boot/grub/grub.cfg
      echo "  initrd  /casper/initrd" >> $ISO_SOURCE_DIR/boot/grub/grub.cfg
      echo "}" >> $ISO_SOURCE_DIR/boot/grub/grub.cfg
      echo "menuentry 'Try or Install Ubuntu Server' {" >> $ISO_SOURCE_DIR/boot/grub/grub.cfg
      echo "  set gfxpayload=keep" >> $ISO_SOURCE_DIR/boot/grub/grub.cfg
      echo "  linux /casper/vmlinuz quiet ---" >> $ISO_SOURCE_DIR/boot/grub/grub.cfg
      echo "  initrd  /casper/initrd" >> $ISO_SOURCE_DIR/boot/grub/grub.cfg
      echo "}" >> $ISO_SOURCE_DIR/boot/grub/grub.cfg
      echo "menuentry 'Boot from next volume' {" >> $ISO_SOURCE_DIR/boot/grub/grub.cfg
      echo "  exit 1" >> $ISO_SOURCE_DIR/boot/grub/grub.cfg
      echo "}" >> $ISO_SOURCE_DIR/boot/grub/grub.cfg
      echo "menuentry 'UEFI Firmware Settings' {" >> $ISO_SOURCE_DIR/boot/grub/grub.cfg
      echo "  fwsetup" >> $ISO_SOURCE_DIR/boot/grub/grub.cfg
    fi
  fi
  for DEVICE in sda vda; do 
    if [ -f "$WORK_DIR/$DEVICE-user-data" ]; then
      handle_output "cp $WORK_DIR/$DEVICE-user-data $CONFIG_DIR/$DEVICE/user-data"
      if [ "$TEST_MODE" = "0" ]; then
        cp $WORK_DIR/$DEVICE-user-data $CONFIG_DIR/$DEVICE/user-data
      fi
    else
      handle_output "echo \"#cloud-config\" > $CONFIG_DIR/$DEVICE/user-data"
      handle_output "echo \"autoinstall:\" >> $CONFIG_DIR/$DEVICE/user-data"
      handle_output "echo \"  apt:\" >> $CONFIG_DIR/$DEVICE/user-data"
      handle_output "echo \"    preferences:\" >> $CONFIG_DIR/$DEVICE/user-data"
      handle_output "echo \"      - package: \\\"*\\\"\" >> $CONFIG_DIR/$DEVICE/user-data"
      handle_output "echo \"        pin: \\\"release a=$RELEASE-security\\\"\" >> $CONFIG_DIR/$DEVICE/user-data"
      handle_output "echo \"        pin-priority: 200\" >> $CONFIG_DIR/$DEVICE/user-data"
      handle_output "echo \"    disable_components: []\" >> $CONFIG_DIR/$DEVICE/user-data"
      handle_output "echo \"    geoip: true\" >> $CONFIG_DIR/$DEVICE/user-data"
      handle_output "echo \"    preserve_sources_list: false\" >> $CONFIG_DIR/$DEVICE/user-data"
      handle_output "echo \"    primary:\" >> $CONFIG_DIR/$DEVICE/user-data"
      handle_output "echo \"    - arches:\" >> $CONFIG_DIR/$DEVICE/user-data"
      handle_output "echo \"      - $ARCH\" >> $CONFIG_DIR/$DEVICE/user-data"
      handle_output "echo \"      uri: http://archive.ubuntu.com/ubuntu\" >> $CONFIG_DIR/$DEVICE/user-data"
      handle_output "echo \"    - arches:\" >> $CONFIG_DIR/$DEVICE/user-data"
      handle_output "echo \"      - default\" >> $CONFIG_DIR/$DEVICE/user-data"
      handle_output "echo \"      uri: http://ports.ubuntu.com/ubuntu-ports\" >> $CONFIG_DIR/$DEVICE/user-data"
      handle_output "echo \"  package_update: false\" >> $CONFIG_DIR/$DEVICE/user-data"
      handle_output "echo \"  package_upgrade: false\" >> $CONFIG_DIR/$DEVICE/user-data"
      handle_output "echo \"  drivers:\" >> $CONFIG_DIR/$DEVICE/user-data"
      handle_output "echo \"    install: false\" >> $CONFIG_DIR/$DEVICE/user-data"
      handle_output "echo \"  user-data:\" >> $CONFIG_DIR/$DEVICE/user-data"
      handle_output "echo \"    timezone: $TIMEZONE\" >> $CONFIG_DIR/$DEVICE/user-data"
      handle_output "echo \"  identity:\" >> $CONFIG_DIR/$DEVICE/user-data"
      handle_output "echo \"    hostname: $HOSTNAME\" >> $CONFIG_DIR/$DEVICE/user-data"
      handle_output "echo \"    password: \\\"$PASSWORD_CRYPT\\\"\" >> $CONFIG_DIR/$DEVICE/user-data"
      handle_output "echo \"    realname: $REALNAME\" >> $CONFIG_DIR/$DEVICE/user-data"
      handle_output "echo \"    username: $USERNAME\" >> $CONFIG_DIR/$DEVICE/user-data"
      handle_output "echo \"  kernel:\" >> $CONFIG_DIR/$DEVICE/user-data"
      handle_output "echo \"    package: linux-generic\" >> $CONFIG_DIR/$DEVICE/user-data"
      handle_output "echo \"  keyboard:\" >> $CONFIG_DIR/$DEVICE/user-data"
      handle_output "echo \"    layout: us\" >> $CONFIG_DIR/$DEVICE/user-data"
      handle_output "echo \"  locale: en_US.UTF-8\" >> $CONFIG_DIR/$DEVICE/user-data"
      handle_output "echo \"  network:\" >> $CONFIG_DIR/$DEVICE/user-data"
      handle_output "echo \"    ethernets:\" >> $CONFIG_DIR/$DEVICE/user-data"
      handle_output "echo \"      ens33:\" >> $CONFIG_DIR/$DEVICE/user-data"
      handle_output "echo \"        critical: true\" >> $CONFIG_DIR/$DEVICE/user-data"
      handle_output "echo \"        dhcp-identifier: mac\" >> $CONFIG_DIR/$DEVICE/user-data"
      handle_output "echo \"        dhcp4: true\" >> $CONFIG_DIR/$DEVICE/user-data"
      handle_output "echo \"    version: 2\" >> $CONFIG_DIR/$DEVICE/user-data"
      handle_output "echo \"  ssh:\" >> $CONFIG_DIR/$DEVICE/user-data"
      handle_output "echo \"    allow-pw: true\" >> $CONFIG_DIR/$DEVICE/user-data"
      handle_output "echo \"    authorized-keys: []\" >> $CONFIG_DIR/$DEVICE/user-data"
      handle_output "echo \"    install-server: true\" >> $CONFIG_DIR/$DEVICE/user-data"
      handle_output "echo \"  storage:\" >> $CONFIG_DIR/$DEVICE/user-data"
      handle_output "echo \"    config:\" >> $CONFIG_DIR/$DEVICE/user-data"
      handle_output "echo \"    - ptable: gpt\" >> $CONFIG_DIR/$DEVICE/user-data"
      handle_output "echo \"      path: /dev/$DEVICE\" >> $CONFIG_DIR/$DEVICE/user-data"
      handle_output "echo \"      wipe: superblock-recursive\" >> $CONFIG_DIR/$DEVICE/user-data"
      handle_output "echo \"      preserve: false\" >> $CONFIG_DIR/$DEVICE/user-data"
      handle_output "echo \"      name: ''\" >> $CONFIG_DIR/$DEVICE/user-data"
      handle_output "echo \"      grub_device: true\" >> $CONFIG_DIR/$DEVICE/user-data"
      handle_output "echo \"      type: disk\" >> $CONFIG_DIR/$DEVICE/user-data"
      handle_output "echo \"      id: disk1\" >> $CONFIG_DIR/$DEVICE/user-data"
      handle_output "echo \"    - device: disk1\" >> $CONFIG_DIR/$DEVICE/user-data"
      handle_output "echo \"      size: 1127219200\" >> $CONFIG_DIR/$DEVICE/user-data"
      handle_output "echo \"      wipe: superblock-recursive\" >> $CONFIG_DIR/$DEVICE/user-data"
      handle_output "echo \"      flag: boot\" >> $CONFIG_DIR/$DEVICE/user-data"
      handle_output "echo \"      number: 1\" >> $CONFIG_DIR/$DEVICE/user-data"
      handle_output "echo \"      preserve: false\" >> $CONFIG_DIR/$DEVICE/user-data"
      handle_output "echo \"      grub_device: true\" >> $CONFIG_DIR/$DEVICE/user-data"
      handle_output "echo \"      type: partition\" >> $CONFIG_DIR/$DEVICE/user-data"
      handle_output "echo \"      ptable: gpt\" >> $CONFIG_DIR/$DEVICE/user-data"
      handle_output "echo \"      id: disk1p1\" >> $CONFIG_DIR/$DEVICE/user-data"
      handle_output "echo \"    - fstype: fat32\" >> $CONFIG_DIR/$DEVICE/user-data"
      handle_output "echo \"      volume: disk1p1\" >> $CONFIG_DIR/$DEVICE/user-data"
      handle_output "echo \"      preserve: false\" >> $CONFIG_DIR/$DEVICE/user-data"
      handle_output "echo \"      type: format\" >> $CONFIG_DIR/$DEVICE/user-data"
      handle_output "echo \"      id: disk1p1fs1\" >> $CONFIG_DIR/$DEVICE/user-data"
      handle_output "echo \"    - path: /boot/efi\" >> $CONFIG_DIR/$DEVICE/user-data"
      handle_output "echo \"      device: disk1p1fs1\" >> $CONFIG_DIR/$DEVICE/user-data"
      handle_output "echo \"      type: mount\" >> $CONFIG_DIR/$DEVICE/user-data"
      handle_output "echo \"      id: mount-2\" >> $CONFIG_DIR/$DEVICE/user-data"
      handle_output "echo \"    - device: disk1\" >> $CONFIG_DIR/$DEVICE/user-data"
      handle_output "echo \"      size: -1\" >> $CONFIG_DIR/$DEVICE/user-data"
      handle_output "echo \"      wipe: superblock-recursive\" >> $CONFIG_DIR/$DEVICE/user-data"
      handle_output "echo \"      flag: root\" >> $CONFIG_DIR/$DEVICE/user-data"
      handle_output "echo \"      number: 2\" >> $CONFIG_DIR/$DEVICE/user-data"
      handle_output "echo \"      preserve: false\" >> $CONFIG_DIR/$DEVICE/user-data"
      handle_output "echo \"      grub_device: false\" >> $CONFIG_DIR/$DEVICE/user-data"
      handle_output "echo \"      type: partition\" >> $CONFIG_DIR/$DEVICE/user-data"
      handle_output "echo \"      id: disk1p2\" >> $CONFIG_DIR/$DEVICE/user-data"
      handle_output "echo \"    - id: disk1p2fs1\" >> $CONFIG_DIR/$DEVICE/user-data"
      handle_output "echo \"      type: format\" >> $CONFIG_DIR/$DEVICE/user-data"
      handle_output "echo \"      fstype: zfsroot\" >> $CONFIG_DIR/$DEVICE/user-data"
      handle_output "echo \"      volume: disk1p2\" >> $CONFIG_DIR/$DEVICE/user-data"
      handle_output "echo \"      preserve: false\" >> $CONFIG_DIR/$DEVICE/user-data"
      handle_output "echo \"    - id: disk1p2f1_rootpool\" >> $CONFIG_DIR/$DEVICE/user-data"
      handle_output "echo \"      mountpoint: /\" >> $CONFIG_DIR/$DEVICE/user-data"
      handle_output "echo \"      pool: rpool\" >> $CONFIG_DIR/$DEVICE/user-data"
      handle_output "echo \"      type: zpool\" >> $CONFIG_DIR/$DEVICE/user-data"
      handle_output "echo \"      device: disk1p2fs1\" >> $CONFIG_DIR/$DEVICE/user-data"
      handle_output "echo \"      preserve: false\" >> $CONFIG_DIR/$DEVICE/user-data"
      handle_output "echo \"      vdevs:\" >> $CONFIG_DIR/$DEVICE/user-data"
      handle_output "echo \"        - disk1p2fs1\" >> $CONFIG_DIR/$DEVICE/user-data"
      handle_output "echo \"    - id: disk1_rootpool_container\" >> $CONFIG_DIR/$DEVICE/user-data"
      handle_output "echo \"      pool: disk1p2f1_rootpool\" >> $CONFIG_DIR/$DEVICE/user-data"
      handle_output "echo \"      preserve: false\" >> $CONFIG_DIR/$DEVICE/user-data"
      handle_output "echo \"      properties:\" >> $CONFIG_DIR/$DEVICE/user-data"
      handle_output "echo \"        canmount: \\\"off\\\"\" >> $CONFIG_DIR/$DEVICE/user-data"
      handle_output "echo \"        mountpoint: \\\"none\\\"\" >> $CONFIG_DIR/$DEVICE/user-data"
      handle_output "echo \"      type: zfs\" >> $CONFIG_DIR/$DEVICE/user-data"
      handle_output "echo \"      volume: /ROOT\" >> $CONFIG_DIR/$DEVICE/user-data"
      handle_output "echo \"    - id: disk1_rootpool_rootfs\" >> $CONFIG_DIR/$DEVICE/user-data"
      handle_output "echo \"      pool: disk1p2f1_rootpool\" >> $CONFIG_DIR/$DEVICE/user-data"
      handle_output "echo \"      preserve: false\" >> $CONFIG_DIR/$DEVICE/user-data"
      handle_output "echo \"      properties:\" >> $CONFIG_DIR/$DEVICE/user-data"
      handle_output "echo \"        canmount: noauto\" >> $CONFIG_DIR/$DEVICE/user-data"
      handle_output "echo \"        mountpoint: /\" >> $CONFIG_DIR/$DEVICE/user-data"
      handle_output "echo \"      type: zfs\" >> $CONFIG_DIR/$DEVICE/user-data"
      handle_output "echo \"      volume: /ROOT/zfsroot\" >> $CONFIG_DIR/$DEVICE/user-data"
      handle_output "echo \"    - path: /\" >> $CONFIG_DIR/$DEVICE/user-data"
      handle_output "echo \"      device: disk1p2fs1\" >> $CONFIG_DIR/$DEVICE/user-data"
      handle_output "echo \"      type: mount\" >> $CONFIG_DIR/$DEVICE/user-data"
      handle_output "echo \"      id: mount-disk1p2\" >> $CONFIG_DIR/$DEVICE/user-data"
      handle_output "echo \"    swap:\" >> $CONFIG_DIR/$DEVICE/user-data"
      handle_output "echo \"      swap: 0\" >> $CONFIG_DIR/$DEVICE/user-data"
      handle_output "echo \"  early-commands:\" >> $CONFIG_DIR/$DEVICE/user-data"
      handle_output "echo \"    - \\\"sudo dpkg --auto-deconfigure --force-depends -i /$INSTALL_MOUNT/$INSTALL_DIR/packages/*.deb\\\"\" >> $CONFIG_DIR/$DEVICE/user-data"
      handle_output "echo \"  version: 1\" >> $CONFIG_DIR/$DEVICE/user-data"
      if [ "$TEST_MODE" = "0" ]; then
        echo "#cloud-config" > $CONFIG_DIR/$DEVICE/user-data
        echo "autoinstall:" >> $CONFIG_DIR/$DEVICE/user-data
        echo "  apt:" >> $CONFIG_DIR/$DEVICE/user-data
        echo "    preferences:" >> $CONFIG_DIR/$DEVICE/user-data
        echo "      - package: \"*\"" >> $CONFIG_DIR/$DEVICE/user-data
        echo "        pin: \"release a=$RELEASE-security\"" >> $CONFIG_DIR/$DEVICE/user-data
        echo "        pin-priority: 200" >> $CONFIG_DIR/$DEVICE/user-data
        echo "    disable_components: []" >> $CONFIG_DIR/$DEVICE/user-data
        echo "    geoip: true" >> $CONFIG_DIR/$DEVICE/user-data
        echo "    preserve_sources_list: false" >> $CONFIG_DIR/$DEVICE/user-data
        echo "    primary:" >> $CONFIG_DIR/$DEVICE/user-data
        echo "    - arches:" >> $CONFIG_DIR/$DEVICE/user-data
        echo "      - $ARCH" >> $CONFIG_DIR/$DEVICE/user-data
        echo "      uri: http://archive.ubuntu.com/ubuntu" >> $CONFIG_DIR/$DEVICE/user-data
        echo "    - arches:" >> $CONFIG_DIR/$DEVICE/user-data
        echo "      - default" >> $CONFIG_DIR/$DEVICE/user-data
        echo "      uri: http://ports.ubuntu.com/ubuntu-ports" >> $CONFIG_DIR/$DEVICE/user-data
        echo "  package_update: false" >> $CONFIG_DIR/$DEVICE/user-data
        echo "  package_upgrade: false" >> $CONFIG_DIR/$DEVICE/user-data
        echo "  drivers:" >> $CONFIG_DIR/$DEVICE/user-data
        echo "    install: false" >> $CONFIG_DIR/$DEVICE/user-data
        echo "  user-data:" >> $CONFIG_DIR/$DEVICE/user-data
        echo "    timezone: $TIMEZONE" >> $CONFIG_DIR/$DEVICE/user-data
        echo "  identity:" >> $CONFIG_DIR/$DEVICE/user-data
        echo "    hostname: $HOSTNAME" >> $CONFIG_DIR/$DEVICE/user-data
        echo "    password: \"$PASSWORD_CRYPT\"" >> $CONFIG_DIR/$DEVICE/user-data
        echo "    realname: $REALNAME" >> $CONFIG_DIR/$DEVICE/user-data
        echo "    username: $USERNAME" >> $CONFIG_DIR/$DEVICE/user-data
        echo "  kernel:" >> $CONFIG_DIR/$DEVICE/user-data
        echo "    package: linux-generic" >> $CONFIG_DIR/$DEVICE/user-data
        echo "  keyboard:" >> $CONFIG_DIR/$DEVICE/user-data
        echo "    layout: us" >> $CONFIG_DIR/$DEVICE/user-data
        echo "  locale: en_US.UTF-8" >> $CONFIG_DIR/$DEVICE/user-data
        echo "  network:" >> $CONFIG_DIR/$DEVICE/user-data
        echo "    ethernets:" >> $CONFIG_DIR/$DEVICE/user-data
        echo "      ens33:" >> $CONFIG_DIR/$DEVICE/user-data
        echo "        critical: true" >> $CONFIG_DIR/$DEVICE/user-data
        echo "        dhcp-identifier: mac" >> $CONFIG_DIR/$DEVICE/user-data
        echo "        dhcp4: true" >> $CONFIG_DIR/$DEVICE/user-data
        echo "    version: 2" >> $CONFIG_DIR/$DEVICE/user-data
        echo "  ssh:" >> $CONFIG_DIR/$DEVICE/user-data
        echo "    allow-pw: true" >> $CONFIG_DIR/$DEVICE/user-data
        echo "    authorized-keys: []" >> $CONFIG_DIR/$DEVICE/user-data
        echo "    install-server: true" >> $CONFIG_DIR/$DEVICE/user-data
        echo "  storage:" >> $CONFIG_DIR/$DEVICE/user-data
        echo "    config:" >> $CONFIG_DIR/$DEVICE/user-data
        echo "    - ptable: gpt" >> $CONFIG_DIR/$DEVICE/user-data
        echo "      path: /dev/$DEVICE" >> $CONFIG_DIR/$DEVICE/user-data
        echo "      wipe: superblock-recursive" >> $CONFIG_DIR/$DEVICE/user-data
        echo "      preserve: false" >> $CONFIG_DIR/$DEVICE/user-data
        echo "      name: ''" >> $CONFIG_DIR/$DEVICE/user-data
        echo "      grub_device: true" >> $CONFIG_DIR/$DEVICE/user-data
        echo "      type: disk" >> $CONFIG_DIR/$DEVICE/user-data
        echo "      id: disk1" >> $CONFIG_DIR/$DEVICE/user-data
        echo "    - device: disk1" >> $CONFIG_DIR/$DEVICE/user-data
        echo "      size: 1127219200" >> $CONFIG_DIR/$DEVICE/user-data
        echo "      wipe: superblock-recursive" >> $CONFIG_DIR/$DEVICE/user-data
        echo "      flag: boot" >> $CONFIG_DIR/$DEVICE/user-data
        echo "      number: 1" >> $CONFIG_DIR/$DEVICE/user-data
        echo "      preserve: false" >> $CONFIG_DIR/$DEVICE/user-data
        echo "      grub_device: true" >> $CONFIG_DIR/$DEVICE/user-data
        echo "      type: partition" >> $CONFIG_DIR/$DEVICE/user-data
        echo "      ptable: gpt" >> $CONFIG_DIR/$DEVICE/user-data
        echo "      id: disk1p1" >> $CONFIG_DIR/$DEVICE/user-data
        echo "    - fstype: fat32" >> $CONFIG_DIR/$DEVICE/user-data
        echo "      volume: disk1p1" >> $CONFIG_DIR/$DEVICE/user-data
        echo "      preserve: false" >> $CONFIG_DIR/$DEVICE/user-data
        echo "      type: format" >> $CONFIG_DIR/$DEVICE/user-data
        echo "      id: disk1p1fs1" >> $CONFIG_DIR/$DEVICE/user-data
        echo "    - path: /boot/efi" >> $CONFIG_DIR/$DEVICE/user-data
        echo "      device: disk1p1fs1" >> $CONFIG_DIR/$DEVICE/user-data
        echo "      type: mount" >> $CONFIG_DIR/$DEVICE/user-data
        echo "      id: mount-2" >> $CONFIG_DIR/$DEVICE/user-data
        echo "    - device: disk1" >> $CONFIG_DIR/$DEVICE/user-data
        echo "      size: -1" >> $CONFIG_DIR/$DEVICE/user-data
        echo "      wipe: superblock-recursive" >> $CONFIG_DIR/$DEVICE/user-data
        echo "      flag: root" >> $CONFIG_DIR/$DEVICE/user-data
        echo "      number: 2" >> $CONFIG_DIR/$DEVICE/user-data
        echo "      preserve: false" >> $CONFIG_DIR/$DEVICE/user-data
        echo "      grub_device: false" >> $CONFIG_DIR/$DEVICE/user-data
        echo "      type: partition" >> $CONFIG_DIR/$DEVICE/user-data
        echo "      id: disk1p2" >> $CONFIG_DIR/$DEVICE/user-data
        echo "    - id: disk1p2fs1" >> $CONFIG_DIR/$DEVICE/user-data
        echo "      type: format" >> $CONFIG_DIR/$DEVICE/user-data
        echo "      fstype: zfsroot" >> $CONFIG_DIR/$DEVICE/user-data
        echo "      volume: disk1p2" >> $CONFIG_DIR/$DEVICE/user-data
        echo "      preserve: false" >> $CONFIG_DIR/$DEVICE/user-data
        echo "    - id: disk1p2f1_rootpool" >> $CONFIG_DIR/$DEVICE/user-data
        echo "      mountpoint: /" >> $CONFIG_DIR/$DEVICE/user-data
        echo "      pool: rpool" >> $CONFIG_DIR/$DEVICE/user-data
        echo "      type: zpool" >> $CONFIG_DIR/$DEVICE/user-data
        echo "      device: disk1p2fs1" >> $CONFIG_DIR/$DEVICE/user-data
        echo "      preserve: false" >> $CONFIG_DIR/$DEVICE/user-data
        echo "      vdevs:" >> $CONFIG_DIR/$DEVICE/user-data
        echo "        - disk1p2fs1" >> $CONFIG_DIR/$DEVICE/user-data
        echo "    - id: disk1_rootpool_container" >> $CONFIG_DIR/$DEVICE/user-data
        echo "      pool: disk1p2f1_rootpool" >> $CONFIG_DIR/$DEVICE/user-data
        echo "      preserve: false" >> $CONFIG_DIR/$DEVICE/user-data
        echo "      properties:" >> $CONFIG_DIR/$DEVICE/user-data
        echo "        canmount: \"off\"" >> $CONFIG_DIR/$DEVICE/user-data
        echo "        mountpoint: \"none\"" >> $CONFIG_DIR/$DEVICE/user-data
        echo "      type: zfs" >> $CONFIG_DIR/$DEVICE/user-data
        echo "      volume: /ROOT" >> $CONFIG_DIR/$DEVICE/user-data
        echo "    - id: disk1_rootpool_rootfs" >> $CONFIG_DIR/$DEVICE/user-data
        echo "      pool: disk1p2f1_rootpool" >> $CONFIG_DIR/$DEVICE/user-data
        echo "      preserve: false" >> $CONFIG_DIR/$DEVICE/user-data
        echo "      properties:" >> $CONFIG_DIR/$DEVICE/user-data
        echo "        canmount: noauto" >> $CONFIG_DIR/$DEVICE/user-data
        echo "        mountpoint: /" >> $CONFIG_DIR/$DEVICE/user-data
        echo "      type: zfs" >> $CONFIG_DIR/$DEVICE/user-data
        echo "      volume: /ROOT/zfsroot" >> $CONFIG_DIR/$DEVICE/user-data
        echo "    - path: /" >> $CONFIG_DIR/$DEVICE/user-data
        echo "      device: disk1p2fs1" >> $CONFIG_DIR/$DEVICE/user-data
        echo "      type: mount" >> $CONFIG_DIR/$DEVICE/user-data
        echo "      id: mount-disk1p2" >> $CONFIG_DIR/$DEVICE/user-data
        echo "    swap:" >> $CONFIG_DIR/$DEVICE/user-data
        echo "      swap: 0" >> $CONFIG_DIR/$DEVICE/user-data
        echo "  early-commands:" >> $CONFIG_DIR/$DEVICE/user-data
        echo "    - \"sudo dpkg --auto-deconfigure --force-depends -i /$INSTALL_MOUNT/$INSTALL_DIR/packages/*.deb\"" >> $CONFIG_DIR/$DEVICE/user-data
        echo "  version: 1" >> $CONFIG_DIR/$DEVICE/user-data
      fi
    fi
  done
}

# Set function variables

DO_INSTALL_REQUIRED_PACKAGES="0"
DO_GET_BASE_ISO="0"
DO_CHECK_WORK_DIR="0"
DO_PREPARE_AUTOINSTALL_ISO="0"
DO_CREATE_AUTOINSTALL_ISO="0"
DO_CREATE_AUTOINSTALL_ISO_ONLY="0"
DO_EXECUTE_CHROOT_SCRIPT="0"
DO_PRINT_HELP="1"

# Handle command line arguments

while getopts ":CcDdfFhH:hIi:L:lo:P:p:R:rT:tU:uVvW:w" OPTS; do
  case $OPTS in
    C)
      DO_EXECUTE_CHROOT_SCRIPT="1"
      ;;
    c)
      DO_CHECK_WORK_DIR="1"
      DO_INSTALL_REQUIRED_PACKAGES="1"
      DO_GET_BASE_PACKAGES="1"
      DO_PREPARE_AUTOINSTALL_ISO="1"
      DO_EXECUTE_CHROOT_SCRIPT="1"
      DO_CREATE_AUTOINSTALL_ISO="1"
      ;;
    D)
      DEFAULTS_MODE="1"
      ;;
    d)
      DO_CHECK_WORK_DIR="1"
      DO_GET_BASE_ISO="1"
      ;;
    f)
      FORCE_MODE="1"
      ;;
    F)
      FULL_FORCE_MODE="1"
      ;;
    h)
      print_help
      exit
      ;;
    I)
      INTERACTIVE_MODE="I"
      ;;
    i)
      ISO_FILE="$OPTARG"
      ;;
    l)
      DO_CREATE_AUTOINSTALL_ISO_ONLY="1"
      ;;
    L)
      RELEASE="$OPTARG"
      DEFAULT_ISO_FILE="$WORK_DIR/$RELEASE-live-server-$ARCH.iso"
      DEFAULT_OUTPUT_FILE="$WORK_DIR/$RELEASE-live-server-$ARCH-autoinstall.iso"
      ;;
    o)
      OUTPUT_FILE="$OPTARG"
      ;;
    p)
      CHROOT_PACKAGES="$OPTARG"
      ;;
    P)
      PASSWORD="$OPTARG"
      ;;
    R)
      REALNAME="$OPTARG"
      ;;
    r)
      DO_INSTALL_REQUIRED_PACKAGES="1"
      ;;
    T)
      TIMEZONE="$OPTARG"
      ;;
    t)
      TEST_MODE="1"
      ;;
    U)
      USERNAME="$OPTARG"
      ;;
    u)
      DO_UMOUNT_ISO="1"
      ;;
    V)
      echo $script_version
      exit
      ;;
    v)
      VERBOSE_MODE="1"
      ;;
    W)
      WORK_DIR="$OPTARG"
      ;;
    w)
      DO_CHECK_WORK_DIR="1"
      ;;
  esac
done

# If run in interactive mode ask for values for required parameters
# Set any unset values to defaults

if [ "$INTERACTIVE_MODE" == "1" ]; then
  read -p "Enter hostname:" HOSTNAME
  read -p "Enter TIMEZONE" TIMEZONE
  read -p "Enter username:" USERNAME
  read -p "Enter user real name" REALNAME
  read -s -p "Enter password:" PASSWORD
  read -p "Enter additional packages:" CHROOT_PACKAGES
  read -p "Enter source ISO file:" ISO_FILE
  read -p "Enter output ISO file:" OUTPUT_FILE
fi
if [ "$USERNAME" = "" ] || [ "$DEFAULTS_MODE" = "1" ]; then
  USERNAME=$DEFAULT_USERNAME
fi
if [ "$REALNAME" = "" ] || [ "$DEFAULTS_MODE" = "1" ]; then
  REALNAME=$DEFAULT_REALNAME
fi
if [ "$HOSTNAME" = "" ] || [ "$DEFAULTS_MODE" = "1" ]; then
  HOSTNAME=$DEFAULT_HOSTNAME
fi
if [ "$PASSWORD" = "" ] || [ "$DEFAULTS_MODE" = "1" ]; then
  PASSWORD=$DEFAULT_PASSWORD
fi
if [ "$CHROOT_PACKAGES" = "" ] || [ "$DEFAULTS_MODE" = "1" ]; then
  CHROOT_PACKAGES=$DEFAULT_PACKAGES
fi
if [ "$TIMEZONE" = "" ] || [ "$DEFAULTS_MODE" = "1" ]; then
  TIMEZONE=$DEFAULT_TIMEZONE
fi
if [ "$ISO_FILE" = "" ] || [ "$DEFAULTS_MODE" = "1" ]; then
  ISO_FILE=$DEFAULT_ISO_FILE
fi
if [ "$OUTPUT_FILE" = "" ] || [ "$DEFAULTS_MODE" = "1" ]; then
  OUTPUT_FILE=$DEFAULT_OUTPUT_FILE
fi

# Handle specific functions
#
# Check work directories
# Check required packages are installed
# Check we have a base iso to work with
# Mount ISO
# Copy ISO
# Copy squashfs
# Execute chroot script
# Prepare ISO
# Create ISO

if [ "$DO_CHECK_WORK_DIR" = "1" ]; then
  DO_PRINT_HELP="0"
  check_work_dir
fi
if [ "$DO_INSTALL_REQUIRED_PACKAGES" = "1" ]; then
  DO_PRINT_HELP="0"
  install_required_packages
fi
if [ "$DO_GET_BASE_ISO" = "1" ]; then
  DO_PRINT_HELP="0"
  get_base_iso
fi
if [ "$DO_CREATE_AUTOINSTALL_ISO" = "1" ]; then
  DO_PRINT_HELP="0"
  unmount_iso
  unmount_squashfs
  mount_iso
  copy_iso
  copy_squashfs
  create_chroot_script
  execute_chroot_script
  prepare_autoinstall_iso
  create_autoinstall_iso
  unmount_iso
  unmount_squashfs
else
  if [ "$DO_EXECUTE_CHROOT_SCRIPT" = "1" ]; then
    DO_PRINT_HELP="0"
    mount_iso
    execute_chroot_script 
  fi
  if [ "$DO_PREPARE_AUTOINSTALL_ISO" = "1" ]; then
    DO_PRINT_HELP="0"
    prepare_autoinstall_iso
  fi
  if [ "$DO_CREATE_AUTOINSTALL_ISO_ONLY" = "1" ]; then
    create_autoinstall_iso
  fi
  if [ "$DO_UMOUNT_ISO" = "1" ]; then
    unmount_iso
    unmount_squashfs
  fi
fi

if [ "$DO_PRINT_HELP" = "1" ]; then
  print_help
fi
