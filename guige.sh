#!/usr/bin/env bash

# Name:         guige (Generic Ubuntu ISO Generation Engine)
# Version:      0.6.7
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

SCRIPT_ARGS="$@"
SCRIPT_FILE="$0"
START_PATH=$( pwd )
SCRIPT_BIN=$( basename $0 |sed "s/^\.\///g")
SCRIPT_FILE="$START_PATH/$SCRIPT_BIN"

# Default variables

SCRIPT_NAME="guige"
CURRENT_ISO_RELEASE="22.04.1"
CURRENT_DOCKER_UBUNTU_RELEASE="22.04"
CURRENT_ISO_CODENAME="jammy"
CURRENT_ISO_ARCH="amd64"
CURRENT_ISO_OSNAME="Ubuntu"
DEFAULT_ISO_HOSTNAME="ubuntu"
DEFAULT_ISO_REALNAME="Ubuntu"
DEFAULT_ISO_USERNAME="ubuntu"
DEFAULT_ISO_TIMEZONE="Australia/Melbourne"
DEFAULT_ISO_PASSWORD="ubuntu"
DEFAULT_ISO_KERNEL="linux-generic"
DEFAULT_ISO_KERNEL_ARGS="net.ifnames=0 biosdevname=0"
DEFAULT_ISO_NIC="eth0"
DEFAULT_ISO_IP="192.168.1.2"
DEFAULT_ISO_NETMASK="255.255.255.0"
DEFAULT_ISO_GATEWAY="192.168.1.254"
DEFAULT_ISO_SWAPSIZE="2G"
DEFAULT_ISO_MENU="0"
DEFAULT_ISO_DEVICES="ROOT_DEV"
DEFAULT_ISO_VOLMGRS="zfs lvm"
DEFAULT_ISO_GRUB_MENU="0"
DEFAULT_ISO_GRUB_TIMEOUT="10"
DEFAULT_ISO_LOCALE="en_US.UTF-8"
DEFAULT_ISO_LC_ALL="en_US"
DEFAULT_ISO_LAYOUT="us"
DEFAULT_ISO_BUILD_TYPE="live-server"
DEFAULT_ISO_PACKAGES="zfsutils-linux grub-efi zfs-initramfs net-tools curl wget sudo file rsync"
REQUIRED_PACKAGES="p7zip-full wget xorriso whois squashfs-tools sudo file rsync"
DEFAULT_DOCKER_ARCH="amd64 arm64"

# Default flags

ISO_DHCP="true"
TEST_MODE="false"
FORCE_MODE="false"
FULL_FORCE_MODE="false"
VERBOSE_MODE="false"
TEMP_VERBOSE_MODE="false"
DEFAULT_MODE="defaults"
DEFAULT_ACTION="none"
INTERACTIVE_MODE="false"
ISO_HWE_KERNEL="false"
DO_DAILY_ISO="false"
DO_CHECK_DOCKER="false"

# Set function variables

DO_INSTALL_REQUIRED_PACKAGES="false"
DO_INSTALL_ISO_PACKAGES="false"
DO_GET_BASE_ISO="false"
DO_CHECK_WORK_DIR="false"
DO_PREPARE_AUTOINSTALL_ISO="false"
DO_CREATE_AUTOINSTALL_ISO_FULL="false"
DO_CREATE_AUTOINSTALL_ISO_ONLY="false"
DO_EXECUTE_ISO_CHROOT_SCRIPT="false"
DO_PRINT_HELP="true"
DO_NO_UNMOUNT_ISO="false"
DO_INSTALL_ISO_UPDATE="false"
DO_INSTALL_ISO_UPGRADE="false"
DO_INSTALL_ISO_DIST_UPGRADE="false"
DO_ISO_SQUASHFS_UPDATE="false"
DO_ISO_QUERY="false"
DO_DOCKER="false"

# Get OS name

if [ -f "/usr/bin/lsb_release" ]; then
  DEFAULT_ISO_OSNAME=$( lsb_release -d |awk '{print $2}' )
else
  DEFAULT_ISO_OSNAME="$CURRENT_ISO_OSNAME"
fi

# Get Architecture

if [ -f "/usr/bin/uname" ]; then
  DEFAULT_ISO_ARCH=$( uname -m )
  if [ "$DEFAULT_ISO_OSNAME" = "Ubuntu" ]; then
    if [ "$DEFAULT_ISO_ARCH" = "x86_64" ]; then
      DEFAULT_ISO_ARCH="amd64"
    fi
    if [ "$DEFAULT_ISO_ARCH" = "aarch64" ]; then
      DEFAULT_ISO_ARCH="arm64"
    fi
  fi
else
  DEFAULT_ISO_ARCH="$CURRENT_ISO_ARCH"
fi

# Get default release

if [ -f "/usr/bin/lsb_release" ]; then
  if [ "$DEFAULT_OSNAME" = "Ubuntu" ]; then
    DEFAULT_ISO_RELEASE=$( lsb_release -d |awk '{print $3}' )
  else
    DEFAULT_ISO_RELEASE="$CURRENT_ISO_RELEASE"
  fi
else
  DEFAULT_ISO_RELEASE="$CURRENT_ISO_RELEASE"
fi

# Get default codename

if [ -f "/usr/bin/lsb_release" ]; then
  if [ "$DEFAULT_ISO_OSNAME" = "Ubuntu" ]; then
    DEFAULT_ISO_CODENAME=$( lsb_release -cs )
  else
    DEFAULT_ISO_CODENAME="$CURRENT_ISO_CODENAME"
  fi
else
  DEFAULT_ISO_CODENAME="$CURRENT_ISO_CODENAME"
fi

# Check default arches for Docker

if [ "$( uname -o )" = "Darwin" ]; then
  if [ "$( uname -m )" = "arm64" ]; then
    DEFAULT_DOCKER_ARCH="amd64 arm64"
  else
    DEFAULT_DOCKER_ARCH="amd64"
  fi
else
  DEFAULT_DOCKER_ARCH="amd64"
fi

# Default work directories

DEFAULT_WORK_DIR=$HOME/ubuntu-iso/$DEFAULT_ISO_RELEASE
DEFAULT_DOCKER_WORK_DIR=/root/ubuntu-iso/$DEFAULT_ISO_RELEASE
DEFAULT_ISO_MOUNT_DIR="$DEFAULT_WORK_DIR/isomount"
DEFAULT_ISO_NEW_DIR="$DEFAULT_WORK_DIR/isonew"
DEFAULT_ISO_SOURCE_DIR="$DEFAULT_WORK_DIR/source-files"

DEFAULT_ISO_AUTOINSTALL_DIR="autoinstall"
DEFAULT_ISO_TARGET_MOUNT="/target"
DEFAULT_ISO_INSTALL_MOUNT="/cdrom"

# Default file names/locations

DEFAULT_INPUT_FILE="$DEFAULT_WORK_DIR/files/ubuntu-$DEFAULT_ISO_RELEASE-live-server-$DEFAULT_ISO_ARCH.iso"
DEFAULT_OUTPUT_FILE="$DEFAULT_WORK_DIR/files/ubuntu-$DEFAULT_ISO_RELEASE-live-server-$DEFAULT_ISO_ARCH-autoinstall.iso"
DEFAULT_ISO_SQUASHFS_FILE="$DEFAULT_ISO_MOUNT_DIR/casper/ubuntu-server-minimal.squashfs"
DEFAULT_GRUB_FILE="$DEFAULT_WORK_DIR/grub.cfg"
DEFAULT_ISO_VOLID="$DEFAULT_ISO_OSNAME $DEFAULT_ISO_RELEASE Server"

# Basename of files

DEFAULT_INPUT_FILE_BASE=$( basename $DEFAULT_INPUT_FILE )
DEFAULT_OUTPUT_FILE_BASE=$( basename $DEFAULT_OUTPUT_FILE )

# Get the version of the script from the script itself

SCRIPT_VERSION=$( cd $START_PATH ; cat $0 | grep '^# Version' | awk '{print $3}' )

# Function: Print help

print_help () {
  cat <<-HELP
  Usage: ${0##*/} [OPTIONS...]
    -A|--codename         Linux release codename (default: $DEFAULT_ISO_CODENAME)
    -a|--action           Action to perform (e.g. createiso, justiso, runchrootscript, checkdocker, installrequired)
    -B|--layout           Layout (default: $DEFAULT_ISO_LAYOUT)
    -D|--mode             Mode (default: $DEFAULT_MODE)
    -d|--bootdisk         Boot Disk devices (default: $DEFAULT_ISO_DEVICES)
    -E|--locale           LANGUAGE (default: $DEFAULT_ISO_LOCALE)
    -e|--lcall            LC_ALL (default: $DEFAULT_ISO_LC_ALL)
    -F|--updatesquashfs   Copy updated squashfs to ISO
    -f|--delete           Remove previously created files (default: $FORCE_MODE)
    -G|--isovolid         ISO Volume ID (default: $DEFAULT_ISO_VOLID)
    -g|--grubmenu:        Set default grub menu (default: $DEFAULT_ISO_GRUB_MENU)
    -H|--hostname:        Hostname (default: $DEFAULT_ISO_HOSTNAME)
    -h|--help             Help/Usage Information
    -i|--inputiso:        Input/base ISO file (default: $DEFAULT_INPUT_FILE_BASE)
    -J|--hwe              Use HWE kernel (defaults: $ISO_HWE_KERNEL)
    -j|--autoinstalldir   Directory where autoinstall config files are stored on ISO (default: $DEFAULT_ISO_AUTOINSTALL_DIR)
    -K|--kernel:          Kernel package (default: $DEFAULT_ISO_KERNEL)
    -k|--kernelargs:      Kernel arguments (default: $DEFAULT_ISO_KERNEL_ARGS)
    -L|--release:         LSB release (default: $DEFAULT_ISO_RELEASE)
    -M|--installtarget    Where the install mounts the target filesystem (default: $DEFAULT_ISO_TARGET_DIR)
    -m|--installmount     Where the install mounts the CD during install (default: $DEFAULT_ISO_INSTALL_MOUNT)
    -N|--nic:             Network device (default: $DEFAULT_ISO_NIC)
    -n|--nounmount        Do not unmount loopback filesystems (useful for troubleshooting)
    -O|--ospackages:      List of packages to install (default: $DEFAULT_ISO_PACKAGES)
    -o|--outputiso:       Output ISO file (default: $DEFAULT_OUTPUT_FILE_BASE)
    -P|--password:        Password (default: $DEFAULT_ISO_USERNAME)
    -p|--chrootpackages:  List of packages to add to ISO (default: $DEFAULT_PACKAGES)
    -Q|--build:           Type of ISO to build (default: $DEFAULT_ISO_BUILD_TYPE)
    -q|--arch             Architecture (default: $DEFAULT_ISO_ARCH)
    -R|--realname:        Realname (default $DEFAULT_ISO_REALNAME)
    -S|--swapsize:        Swap size (default $DEFAULT_ISO_SWAPSIZE)
    -s|--staticip         Static IP configuration (default DHCP)
    -T|--timezone:        Timezone (default: $DEFAULT_ISO_TIMEZONE)
    -t|--testmode         Test mode (display commands but don't run them)
    -U|--username:        Username (default: $DEFAULT_ISO_USERNAME)
    -u|--postinstall      Postinstall action (e.g. installpackages, upgrade, distupgrade)
    -V|--version          Display Script Version
    -v|--verbose          Verbose output (default: $VERBOSE_MODE)
    -W|--workdir:         Work directory (default: $DEFAULT_WORK_DIR)
    -w|--checkdirs        Check work directories exist
    -x|--grubtimeout:     Grub timeout (default: $DEFAULT_ISO_GRUB_TIMEOUT)
    -z|--volumemanager:   Volume Managers (defauls: $DEFAULT_ISO_VOLMGRS)
HELP
  exit
}

# Function: Handle output

handle_output () {
  OUTPUT_TEXT=$1
  OUTPUT_TYPE=$2
  if [ "$VERBOSE_MODE" = "true" ] || [ "$TEMP_VERBOSE_MODE" = "true" ]; then
    if [ "$TEST_MODE" = "true" ]; then
      echo "$OUTPUT_TEXT"
    else
      if [ "$OUTPUT_TYPE" = "TEXT" ]; then
        echo "$OUTPUT_TEXT"
      else
        echo "# Executing: $OUTPUT_TEXT"
      fi
    fi
  fi
}

# Function: Create docker config
#
# Create a docker config so we can run this from a non Linux platform
#
# docker-compose.yml
#
# version: "3"
#
# services:
#  ostrich:
#    build:
#      context: .
#      dockerfile: Dockerfile
#    image: guige-ubuntu-amd64
#    container_name: ostrich
#    entrypoint: /bin/bash
#    working_dir: /root
#
# Dockerfile
#
# FROM ubuntu:22.04
# RUN apt-get update && apt-get install -y p7zip-full wget xorriso whois squashfs-tools

check_docker_config () {
  if ! [ -f "/.dockerenv" ]; then
    handle_output "# Create Docker configs" TEXT
    for DIR_ARCH in $DOCKER_ARCH; do
      if ! [ -d "$WORK_DIR/$DIR_ARCH" ]; then
        handle_output "mkdir $WORK_DIR/$DIR_ARCH"
        mkdir $WORK_DIR/$DIR_ARCH
      fi
      handle_output "# Check docker images" TEXT
      handle_output "docker images |grep \"^$SCRIPT_NAME-$DIR_ARCH\" |awk '{print \$1}'"
      handle_output "# Check volume images" TEXT
      handle_output "docker volume list |grep \"^$SCRIPT_NAME-$DIR_ARCH\" |awk '{print \$1}'"
      handle_output "# Create Docker config $WORK_DIR/$DIR_ARCH/docker-compose.yml" TEXT
      handle_output "echo \"version: \\\"3\\\"\" > $WORK_DIR/$DIR_ARCH/docker-compose.yml"
      handle_output "echo \"\" >> $WORK_DIR/$DIR_ARCH/docker-compose.yml"
      handle_output "echo \"services:\" >> $WORK_DIR/$DIR_ARCH/docker-compose.yml"
      handle_output "echo \"  $SCRIPT_NAME-$DIR_ARCH:\" >> $WORK_DIR/$DOCKER_ARCH/docker-compose.yml"
      handle_output "echo \"    build:\" >> $WORK_DIR/$DIR_ARCH/docker-compose.yml"
      handle_output "echo \"      context: .\" >> $WORK_DIR/$DOCKER_ARCH/docker-compose.yml"
      handle_output "echo \"      dockerfile: Dockerfile\" >> $WORK_DIR/$DIR_ARCH/docker-compose.yml"
      handle_output "echo \"    image: $SCRIPT_NAME-$DIR_ARCH\" >> $WORK_DIR/$DIR_ARCH/docker-compose.yml"
      handle_output "echo \"    container_name: $SCRIPT_NAME-$DIR_ARCH\" >> $WORK_DIR/$DIR_ARCH/docker-compose.yml"
      handle_output "echo \"    entrypoint: /bin/bash\" >> $WORK_DIR/$DIR_ARCH/docker-compose.yml"
      handle_output "echo \"    working_dir: /root\" >> $WORK_DIR/$DIR_ARCH/docker-compose.yml"
      handle_output "echo \"    platform: linux/$DIR_ARCH\" >> $WORK_DIR/$DIR_ARCH/docker-compose.yml"
      handle_output "echo \"    volumes:\" >> $WORK_DIR/$DIR_ARCH/docker-compose.yml"
      handle_output "echo \"      - /docker/$SCRIPT_NAME-$DIR_ARCH/:/root/ubuntu-iso/\" >> $WORK_DIR/$DIR_ARCH/docker-compose.yml"
      handle_output "# Create Docker config $WORK_DIR/$DIR_ARCH/Dockerfile" TEXT
      handle_output "echo \"FROM ubuntu:$CURRENT_DOCKER_UBUNTU_RELEASE\" > $WORK_DIR/$DIR_ARCH/Dockerfile"
      handle_output "echo \"RUN apt-get update && apt-get install -y $REQUIRED_PACKAGES\" >> $WORK_DIR/$DIR_ARCH/Dockerfile"
      handle_output "# Build docker"
      handle_output "cd $WORK_DIR/$DIR_ARCH ; docker build . --tag $SCRIPT_NAME-$DIR_ARCH --platform linux/$DIR_ARCH"
      DOCKER_IMAGE_CHECK=$( docker images |grep "^$SCRIPT_NAME-$DIR_ARCH" |awk '{print $1}' )
      DOCKER_VOLUME_CHECK=$( docker volume list |grep "^$SCRIPT_NAME-$DIR_ARCH" |awk '{print $1}' )
      if ! [ "$DOCKER_VOLUME_CHECK" = "$SCRIPT_NAME-$DIR_ARCH" ]; then
        if [ "$TEST_MODE" = "false" ]; then
          docker volume create $SCRIPT_NAME-$DIR_ARCH
        fi
      fi
      if ! [ "$DOCKER_IMAGE_CHECK" = "$SCRIPT_NAME-$DIR_ARCH" ]; then
        if [ "$TEST_MODE" = "false" ]; then
          echo "version: \"3\"" > $WORK_DIR/$DIR_ARCH/docker-compose.yml
          echo "" >> $WORK_DIR/$DIR_ARCH/docker-compose.yml
          echo "services:" >> $WORK_DIR/$DIR_ARCH/docker-compose.yml
          echo "  $SCRIPT_NAME-$DIR_ARCH:" >> $WORK_DIR/$DIR_ARCH/docker-compose.yml
          echo "    build:" >> $WORK_DIR/$DIR_ARCH/docker-compose.yml
          echo "      context: ." >> $WORK_DIR/$DIR_ARCH/docker-compose.yml
          echo "      dockerfile: Dockerfile" >> $WORK_DIR/$DIR_ARCH/docker-compose.yml
          echo "    image: $SCRIPT_NAME-$DIR_ARCH" >> $WORK_DIR/$DIR_ARCH/docker-compose.yml
          echo "    container_name: $SCRIPT_NAME-$DIR_ARCH" >> $WORK_DIR/$DIR_ARCH/docker-compose.yml
          echo "    entrypoint: /bin/bash" >> $WORK_DIR/$DIR_ARCH/docker-compose.yml
          echo "    working_dir: /root" >> $WORK_DIR/$DIR_ARCH/docker-compose.yml
          echo "    platform: linux/$DIR_ARCH" >> $WORK_DIR/$DIR_ARCH/docker-compose.yml
          echo "    volumes:" >> $WORK_DIR/$DIR_ARCH/docker-compose.yml
          echo "      - /docker/$SCRIPT_NAME-$DIR_ARCH/:/root/ubuntu-iso/" >> $WORK_DIR/$DIR_ARCH/docker-compose.yml
          echo "FROM ubuntu:$CURRENT_DOCKER_UBUNTU_RELEASE" > $WORK_DIR/$DIR_ARCH/Dockerfile
          echo "RUN apt-get update && apt-get install -y $REQUIRED_PACKAGES" >> $WORK_DIR/$DIR_ARCH/Dockerfile
          cd $WORK_DIR/$DIR_ARCH ; docker build . --tag $SCRIPT_NAME-$DIR_ARCH --platform linux/$DIR_ARCH
        fi
      fi
    done
  fi
}

# Function: Get info from iso

get_info_from_iso () {
  handle_output "# Analysing $INPUT_FILE"
  TEST_FILE=$( basename $INPUT_FILE )
  TEST_NAME=$( echo $TEST_FILE | cut -f1 -d- )
  TEST_TYPE=$( echo $TEST_FILE | cut -f2 -d- )
  case $TEST_NAME in
    "jammy")
      ISO_RELEASE="22.04"
      ISO_DISTRO="Ubuntu"
      ;;
    "focal")
      ISO_RELEASE="20.04"
      ISO_DISTRO="Ubuntu"
      ;;
    "ubuntu")
      ISO_RELEASE=$(echo $TEST_FILE |cut -f2 -d- )
      ISO_DISTRO="Ubuntu"
      ;;
    *)
      ISO_RELEASE="$DEFAULT_ISO_RELEASE"
      ;;
  esac
  if [ "$TEST_NAME" = "ubuntu" ]; then
    if [ "$TEST_TYPE" = "desktop" ]; then
      ISO_ARCH=$( echo $TEST_FILE |cut -f4 -d- |cut -f1 -d. )
    else
      ISO_ARCH=$( echo $TEST_FILE |cut -f5 -d- |cut -f1 -d. )
      TEST_TYPE="live-server"
    fi
  else
    if [ "$TEST_TYPE" = "desktop" ]; then
      ISO_ARCH=$( echo $TEST_FILE |cut -f3 -d- |cut -f1 -d. )
    else
      ISO_ARCH=$( echo $TEST_FILE |cut -f4 -d- |cut -f1 -d. )
      TEST_TYPE="live-server"
    fi
  fi
  OUTPUT_FILE="$WORK_DIR/files/$TEST_NAME-$ISO_RELEASE-$TEST_TYPE-$ISO_ARCH.iso"
  TEMP_VERBOSE_MODE="true"
  handle_output "# Input ISO:     $INPUT_FILE" TEXT
  handle_output "# Distribution:  $ISO_DISTRO" TEXT
  handle_output "# Release:       $ISO_RELEASE" TEXT
  handle_output "# Codename:      $ISO_CODENAME" TEXT
  handle_output "# Architecture:  $ISO_ARCH" TEXT
  handle_output "# Output ISO:    $OUTPUT_FILE" TEXT
  TEMP_VERBOSE_MODE="false"
}

# Function: Check work directories exist
#
# Example:
# mkdir -p ./isomount ./isonew/squashfs ./isonew/cd ./isonew/custom

check_work_dir () {
  handle_output "# Check work directories" TEXT
  for ISO_DIR in $ISO_MOUNT_DIR $ISO_NEW_DIR/squashfs $ISO_NEW_DIR/mksquash $ISO_NEW_DIR/cd $ISO_NEW_DIR/custom $WORK_DIR/bin $WORK_DIR/files; do
    handle_output "# Check directory $ISO_DIR exists" TEXT
    handle_output "mkdir -p $ISO_DIR"
    if [ "$FORCE_MODE" = "true" ]; then
      if [ -d "$ISO_DIR" ]; then
        handle_output "# Remove existing directory $ISO_DIR"
        handle_output "sudo rm -rf $ISO_DIR"
        if [[ $ISO_DIR =~ [0-9a-zA-Z] ]]; then
          if [ "$TEST_MODE" = "false" ]; then
            sudo rm -rf $ISO_DIR
          fi
        fi
      fi
    fi
    if ! [ -d "$ISO_DIR" ]; then
      handle_output "# Create $ISO_DIR if it doesn't exist" TEXT
      if [ "$TEST_MODE" = "false" ]; then
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
    PACKAGE_VERSION=$( apt show $PACKAGE 2>&1 |grep Version )
    if ! [ -x "$PACKAGE_VERSION" ]; then
      handle_output "sudo apt install -y $PACKAGE"
      if [ "$TEST_MODE" = "false" ]; then
        sudo apt install -y $PACKAGE
      fi
    fi
  done
}

# Function: Check base ISO file

check_base_iso_file () {
  if [ -f "$INPUT_FILE" ]; then
    BASE_INPUT_FILE=$( basename $INPUT_FILE )
    FILE_TYPE=$( file $WORK_DIR/files/$BASE_INPUT_FILE | awk '{print $2}' )
    if ! [ "$FILE_TYPE" = "ISO" ] || [ "$FILE_TYPE" = "DOS/MBR" ]; then
      TEMP_VERBOSE_MODE="true"
      handle_output "# Warning: $WORK_DIR/files/$BASE_INPUT_FILE is not a valid ISO file" TEXT
      exit
    fi
  fi
}

# Function: Grab ISO from Ubuntu
# 
# Examples:
#
# Live Server
#
# https://cdimage.ubuntu.com/ubuntu-server/jammy/daily-live/current/jammy-live-server-amd64.iso
# wget https://cdimage.ubuntu.com/releases/22.04/release/ubuntu-22.04.1-live-server-amd64.iso
#
# Daily Live Server
#
# https://cdimage.ubuntu.com/ubuntu-server/jammy/daily-live/current/
#
# Desktop
#
# https://releases.ubuntu.com/22.04/
#
# Daily desktop
#
# https://cdimage.ubuntu.com/jammy/daily-live/current/
#

get_base_iso () {
  handle_output "# Check source ISO exists and grab it if it doesn't" TEXT
  BASE_INPUT_FILE=$( basename $INPUT_FILE )
  if [ "$FULL_FORCE_MODE" = "true" ]; then
    handle_output "rm $WORK_DIR/files/$BASE_INPUT_FILE" 
    if [ "$TEST_MODE" = "false" ]; then
      rm $WORK_DIR/files/$BASE_INPUT_FILE
    fi
  fi
  check_base_iso_file
  handle_output "wget $ISO_URL -O $WORK_DIR/files/$BASE_INPUT_FILE"
  if ! [ -f "$WORK_DIR/files/$BASE_INPUT_FILE" ]; then
    if [ "$TEST_MODE" = "false" ]; then
      wget $ISO_URL -O $WORK_DIR/files/$BASE_INPUT_FILE
    fi
  fi
}
# Function unmount loopback ISO filesystem
#
# Examples:
# sudo umount -l /home/user/ubuntu-iso/isomount

unmount_iso () {
  handle_output "sudo umount -l $ISO_MOUNT_DIR"
  if [ "$TEST_MODE" = "false" ]; then
    sudo umount -l $ISO_MOUNT_DIR
  fi
}

# Mount base ISO as loopback device so contents can be copied
#
# sudo mount -o loop ./ubuntu-22.04.1-live-server-arm64.iso ./isomount
# sudo mount -o loop ./ubuntu-22.04.1-live-server-amd64.iso ./isomount

mount_iso () {
  get_base_iso
  check_base_iso_file
  handle_output "sudo mount -o loop $WORK_DIR/files/$BASE_INPUT_FILE $ISO_MOUNT_DIR"
  if [ "$TEST_MODE" = "false" ]; then
    sudo mount -o loop $WORK_DIR/files/$BASE_INPUT_FILE $ISO_MOUNT_DIR
  fi
}

unmount_squashfs () {
  handle_output "sudo umount $ISO_NEW_DIR/squashfs"
  if [ "$TEST_MODE" = "false" ]; then
    sudo umount $ISO_NEW_DIR/squashfs
  fi
}

# Function: Copy contents of ISO to a RW location so we can work with them
#
# Examples:
# rsync --exclude=/casper/ubuntu-server-minimal.squashfs -av ./isomount/ ./isonew/cd
# rsync -av ./isomount/ ./isonew/cd

copy_iso () {
  if [ "$VERBOSE_MODE" = "true" ]; then
    handle_output "rsync -av $ISO_MOUNT_DIR/ $ISO_NEW_DIR/cd"
    if [ "$TEST_MODE" = "false" ]; then
      rsync -av $ISO_MOUNT_DIR/ $ISO_NEW_DIR/cd
    fi
  else
    handle_output "rsync -a $ISO_MOUNT_DIR/ $ISO_NEW_DIR/cd"
    if [ "$TEST_MODE" = "false" ]; then
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

copy_squashfs () {
  handle_output "sudo mount -t squashfs -o loop $ISO_SQUASHFS_FILE $ISO_NEW_DIR/squashfs/"
  if [ "$TEST_MODE" = "false" ]; then
    sudo mount -t squashfs -o loop $ISO_SQUASHFS_FILE $ISO_NEW_DIR/squashfs/
  fi
  if [ "$VERBOSE_MODE" = "true" ]; then
    handle_output "sudo rsync -av $ISO_NEW_DIR/squashfs/ $ISO_NEW_DIR/custom"
    if [ "$TEST_MODE" = "false" ]; then
      sudo rsync -av $ISO_NEW_DIR/squashfs/ $ISO_NEW_DIR/custom
    fi
  else
    handle_output "sudo rsync -a $ISO_NEW_DIR/squashfs/ $ISO_NEW_DIR/custom"
    if [ "$TEST_MODE" = "false" ]; then
      sudo rsync -a $ISO_NEW_DIR/squashfs/ $ISO_NEW_DIR/custom
    fi
  fi
  handle_output "sudo cp /etc/resolv.conf /etc/hosts $ISO_NEW_DIR/custom/etc/"
  if [ "$TEST_MODE" = "false" ]; then
    sudo cp /etc/resolv.conf /etc/hosts $ISO_NEW_DIR/custom/etc/
  fi
}

# Function: Chroot into environment and run script on chrooted environmnet
#
# Examples:
# sudo chroot ./isonew/custom

execute_chroot_script () {
  handle_output "sudo chroot $ISO_NEW_DIR/custom /tmp/modify_chroot.sh"
  if [ "$TEST_MODE" = "false" ]; then
    sudo chroot $ISO_NEW_DIR/custom /tmp/modify_chroot.sh
  fi
}

# Function: Update ISO squashfs 

update_iso_squashfs () {
  handle_output "# Making squashfs (this will take a while)"
  handle_output "cd $ISO_NEW_DIR ; sudo mksquashfs $ISO_NEW_DIR/custom $ISO_NEW_DIR/mksquash/filesystem.squashfs -noappend"
  handle_output "cd $ISO_NEW_DIR ; sudo cp $ISO_NEW_DIR/mksquash/filesystem.squashfs $ISO_NEW_DIR/cd/casper/filesystem.squashfs"
  handle_output "cd $ISO_NEW_DIR ; sudo chmod 0444 $ISO_NEW_DIR/cd/casper/filesystem.squashfs"
  handle_output "# Making filesystem.size"
  handle_output "cd $ISO_NEW_DIR ; sudo echo -n \$( sudo du -s --block-size=1 $ISO_NEW_DIR/custom | tail -1 | awk '{print \$1}') | sudo tee $ISO_NEW_DIR/mksquash/filesystem.size"
  handle_output "cd $ISO_NEW_DIR ; sudo cp $ISO_NEW_DIR/mksquash/filesystem.size $ISO_NEW_DIR/cd/casper/filesystem.size"
  handle_output "cd $ISO_NEW_DIR ; sudo chmod 0444 $ISO_NEW_DIR/cd/casper/filesystem.size"
  handle_output "# Making md5sum"
  handle_output "cd $ISO_NEW_DIR ; sudo find . -type f -print0 | xargs -0 md5sum | sed \"s@$ISO_NEW_DIR@.@\" | grep -v md5sum.txt | sudo tee $ISO_NEW_DIR/cd/md5sum.txt"
  if [ "$TEST_MODE" = "false" ]; then
    sudo mksquashfs $ISO_NEW_DIR/custom $ISO_NEW_DIR/mksquash/filesystem.squashfs -noappend
    sudo cp $ISO_NEW_DIR/mksquash/filesystem.squashfs $NEW_SQUASHFS_FILE
    sudo chmod 0444 $NEW_SQUASHFS_FILE
    sudo echo -n $( sudo du -s --block-size=1 $ISO_NEW_DIR/custom | tail -1 | awk '{print $1}') | sudo tee $ISO_NEW_DIR/mksquash/filesystem.size
    sudo cp $ISO_NEW_DIR/mksquash/filesystem.size $ISO_SOURCE_DIR/casper/filesystem.size
    sudo chmod 0444 $ISO_SOURCE_DIR/casper/filesystem.size
    cd $ISO_SOURCE_DIR ; sudo find . -type f -print0 | xargs -0 md5sum | sed "s@${ISO_NEW_DIR}@.@" | grep -v md5sum.txt | sudo tee $ISO_SOURCE_DIR/md5sum.txt
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
  ISO_CHROOT_SCRIPT="$ISO_NEW_DIR/custom/tmp/modify_chroot.sh"
  handle_output "echo \"#!/usr/bin/bash\" > $ORIG_SCRIPT"
  handle_output "echo \"mount -t proc none /proc/\" >> $ORIG_SCRIPT"
  handle_output "echo \"mount -t sysfs none /sys/\" >> $ORIG_SCRIPT"
  handle_output "echo \"mount -t devpts none /dev/pts\" >> $ORIG_SCRIPT"
  handle_output "echo \"export HOME=/root\" >> $ORIG_SCRIPT"
  handle_output "echo \"apt update\" >> $ORIG_SCRIPT"
  handle_output "echo \"export LC_ALL=C ; apt install -y --download-only $ISO_CHROOT_PACKAGES\" >> $ORIG_SCRIPT"
  handle_output "echo \"export LC_ALL=C ; apt install -y $ISO_CHROOT_PACKAGES\" >> $ORIG_SCRIPT"
  handle_output "echo \"umount /proc/\" >> $ORIG_SCRIPT"
  handle_output "echo \"umount /sys/\" >> $ORIG_SCRIPT"
  handle_output "echo \"umount /dev/pts/\" >> $ORIG_SCRIPT"
  handle_output "echo \"exit\" >> $ORIG_SCRIPT"
  handle_output "sudo cp $ORIG_SCRIPT $ISO_CHROOT_SCRIPT"
  handle_output "sudo chmod +x $ISO_CHROOT_SCRIPT"
  if [ "$TEST_MODE" = "false" ]; then
    echo "#!/usr/bin/bash" > $ORIG_SCRIPT
    echo "mount -t proc none /proc/" >> $ORIG_SCRIPT
    echo "mount -t sysfs none /sys/" >> $ORIG_SCRIPT
    echo "mount -t devpts none /dev/pts" >> $ORIG_SCRIPT
    echo "export HOME=/root" >> $ORIG_SCRIPT
    echo "apt update" >> $ORIG_SCRIPT
    echo "export LC_ALL=C ; apt install -y --download-only $ISO_CHROOT_PACKAGES" >> $ORIG_SCRIPT
    echo "export LC_ALL=C ; apt install -y $ISO_CHROOT_PACKAGES" >> $ORIG_SCRIPT
    echo "umount /proc/" >> $ORIG_SCRIPT
    echo "umount /sys/" >> $ORIG_SCRIPT
    echo "umount /dev/pts/" >> $ORIG_SCRIPT
    echo "exit" >> $ORIG_SCRIPT
    sudo cp $ORIG_SCRIPT $ISO_CHROOT_SCRIPT
    sudo chmod +x $ISO_CHROOT_SCRIPT
  fi
}

# Get password crypt
#
# echo test |mkpasswd --method=SHA-512 --stdin

get_password_crypt () {
  ISO_PASSWORD=$1
  handle_output "export PASSWORD_CRYPT=\$(echo $ISO_PASSWORD |mkpasswd --method=SHA-512 --stdin)"
  if [ "$TEST_MODE" = "false" ]; then
    ISO_PASSWORD_CRYPT=$( echo $ISO_PASSWORD |mkpasswd --method=SHA-512 --stdin )
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
  handle_output "cd $WORK_DIR ; export ISO_MBR_PART_TYPE=\$( xorriso -indev $INPUT_FILE -report_el_torito as_mkisofs |grep iso_mbr_part_type |tail -1 |awk '{print \$2}' 2>&1 )"
  handle_output "cd $WORK_DIR ; export BOOT_CATALOG=\$( xorriso -indev $INPUT_FILE -report_el_torito as_mkisofs |grep '^-c '|tail -1 |awk '{print \$2}' |cut -f2 -d\"'\" 2>&1 )"
  handle_output "cd $WORK_DIR ; export BOOT_IMAGE=\$( xorriso -indev $INPUT_FILE -report_el_torito as_mkisofs |grep '^-b ' |tail -1 |awk '{print \$2}' |cut -f2 -d\"'\" 2>&1 )"
  ISO_MBR_PART_TYPE=$( xorriso -indev $INPUT_FILE -report_el_torito as_mkisofs |grep iso_mbr_part_type |tail -1 |awk '{print $2}' 2>&1 )
  BOOT_CATALOG=$( xorriso -indev $INPUT_FILE -report_el_torito as_mkisofs |grep "^-c " |tail -1 |awk '{print $2}' |cut -f2 -d"'" 2>&1 )
  BOOT_IMAGE=$( xorriso -indev $INPUT_FILE -report_el_torito as_mkisofs |grep "^-b " |tail -1 |awk '{print $2}' |cut -f2 -d"'" 2>&1 )
  EFI_BOOT_SIZE=$( xorriso -indev $INPUT_FILE -report_el_torito as_mkisofs |grep "^-boot-load-size" |tail -1 |awk '{print $2}' |cut -f2 -d"'" 2>&1 )
  DOS_BOOT_SIZE=$( xorriso -indev $INPUT_FILE -report_el_torito as_mkisofs |grep "^-boot-load-size" |head -1 |awk '{print $2}' |cut -f2 -d"'" 2>&1 )
  if [ "$ISO_MAJOR_REL" = "22" ]; then
    handle_output "cd $WORK_DIR ; export APPEND_PART=\$( xorriso -indev $INPUT_FILE -report_el_torito as_mkisofs |grep append_partition |tail -1 |awk '{print \$3}' 2>&1 )"
    handle_output "export EFI_IMAGE=\"--interval:appended_partition_2:::\""
    APPEND_PART=$( xorriso -indev $INPUT_FILE -report_el_torito as_mkisofs |grep append_partition |tail -1 |awk '{print $3}' 2>&1 )
    EFI_IMAGE="--interval:appended_partition_2:::"
  else
    handle_output "export APPEND_PART=\"0exf\""
    handle_output "cd $WORK_DIR ; export EFI_IMAGE=\$( xorriso -indev $INPUT_FILE -report_el_torito as_mkisofs |grep '^-e ' |tail -1 |awk '{print \$2}' |cut -f2 -d\"'\" 2>&1 )"
    APPEND_PART="0xef"
    EFI_IMAGE=$( xorriso -indev $INPUT_FILE -report_el_torito as_mkisofs |grep "^-e " |tail -1 |awk '{print $2}' |cut -f2 -d"'" 2>&1 )
  fi
  if [ "$TEST_MODE" = "false" ]; then
    if [ "$ISO_ARCH" = "amd64" ]; then
      handle_output "cd $ISO_SOURCE_DIR ; xorriso -as mkisofs -r -V \"$ISO_VOLID\" -o $OUTPUT_FILE \
      --grub2-mbr ../BOOT/1-Boot-NoEmul.img --protective-msdos-label \
      -partition_cyl_align off -partition_offset 16 --mbr-force-bootable \
      -append_partition 2 $APPEND_PART ../BOOT/2-Boot-NoEmul.img -appended_part_as_gpt \
      -iso_mbr_part_type $ISO_MBR_PART_TYPE -c $BOOT_CATALOG -b $BOOT_IMAGE \
      -no-emul-boot -boot-load-size $DOS_BOOT_SIZE -boot-info-table --grub2-boot-info -eltorito-alt-boot \
      -e $EFI_IMAGE -no-emul-boot -boot-load-size $EFI_BOOT_SIZE ."
      cd $ISO_SOURCE_DIR ; xorriso -as mkisofs -r -V "$ISO_VOLID" -o $OUTPUT_FILE \
      --grub2-mbr ../BOOT/1-Boot-NoEmul.img --protective-msdos-label -partition_cyl_align off \
      -partition_offset 16 --mbr-force-bootable -append_partition 2 $APPEND_PART ../BOOT/2-Boot-NoEmul.img \
      -appended_part_as_gpt -iso_mbr_part_type $ISO_MBR_PART_TYPE -c $BOOT_CATALOG -b $BOOT_IMAGE \
      -no-emul-boot -boot-load-size $DOS_BOOT_SIZE -boot-info-table --grub2-boot-info -eltorito-alt-boot \
      -e "$EFI_IMAGE" -no-emul-boot -boot-load-size $EFI_BOOT_SIZE .
    else
      handle_output "cd $ISO_SOURCE_DIR ; xorriso -as mkisofs -r -V \"$ISO_VOLID\" -o $OUTPUT_FILE \
      -partition_cyl_align all -partition_offset 16 -partition_hd_cyl 86 -partition_sec_hd 32 \
      -append_partition 2 $APPEND_PART ../BOOT/Boot-NoEmul.img -G ../BOOT/Boot-NoEmul.img \
      -iso_mbr_part_type $ISO_MBR_PART_TYPE -c $BOOT_CATALOG \
      -e "$EFI_IMAGE" -no-emul-boot -boot-load-size $EFI_BOOT_SIZE ."
      cd $ISO_SOURCE_DIR ; xorriso -as mkisofs -r -V "$ISO_VOLID" -o $OUTPUT_FILE \
      -partition_cyl_align all -partition_offset 16 -partition_hd_cyl 86 -partition_sec_hd 32 \
      -append_partition 2 $APPEND_PART ../BOOT/Boot-NoEmul.img -G ../BOOT/Boot-NoEmul.img \
      -iso_mbr_part_type $ISO_MBR_PART_TYPE -c $BOOT_CATALOG \
      -e "$EFI_IMAGE" -no-emul-boot -boot-load-size $EFI_BOOT_SIZE .
    fi
    if [ "$DO_DOCKER" = "true" ]; then
      BASE_DOCKER_OUTPUT_FILE=$( basename $OUTPUT_FILE )
      echo "# Output file will be at $OLD_WORK_DIR/files/$BASE_DOCKER_OUTPUT_FILE" 
    fi
  fi
}

prepare_autoinstall_iso () {
  handle_output "# Create autoinstall files"
  get_password_crypt $ISO_PASSWORD
  PACKAGE_DIR="$ISO_SOURCE_DIR/$ISO_AUTOINSTALL_DIR/packages"
  SCRIPT_DIR="$ISO_SOURCE_DIR/$ISO_AUTOINSTALL_DIR/scripts"
  CONFIG_DIR="$ISO_SOURCE_DIR/$ISO_AUTOINSTALL_DIR/configs"
  BASE_INPUT_FILE=$( basename $INPUT_FILE )
  handle_output "7z -y x $WORK_DIR/files/$BASE_INPUT_FILE -o$ISO_SOURCE_DIR"
  handle_output "rm -rf $WORK_DIR/BOOT"
  handle_output "mkdir -p $PACKAGE_DIR"
  handle_output "mkdir -p $SCRIPT_DIR"
  handle_output "cp $ISO_NEW_DIR/custom/var/cache/apt/archives/*.deb $PACKAGE_DIR"
  for ISO_DEVICE in $ISO_DEVICES; do
    for ISO_VOLMGR in $ISO_VOLMGRS; do
      handle_output "mkdir -p $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE"
      handle_output "touch $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/meta-data"
    done
  done
  if [ "$TEST_MODE" = "false" ]; then
    7z -y x $WORK_DIR/files/$BASE_INPUT_FILE -o$ISO_SOURCE_DIR
    mkdir -p $PACKAGE_DIR
    mkdir -p $SCRIPT_DIR
    for ISO_DEVICE in $ISO_DEVICES; do
      for ISO_VOLMGR in $ISO_VOLMGRS; do
        mkdir -p $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE
        touch $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/meta-data
      done
    done
    if [ "$VERBOSE_MODE" = "true" ]; then
      sudo cp -v $ISO_NEW_DIR/custom/var/cache/apt/archives/*.deb $PACKAGE_DIR
    else
      sudo cp -v $ISO_NEW_DIR/custom/var/cache/apt/archives/*.deb $PACKAGE_DIR
    fi
  fi
  if [ -d "$WORK_DIR/BOOT" ]; then
    if [ "$TEST_MODE" = "false" ]; then
      if [ "$FORCE_MODE" = "true" ]; then
        rm -rf $WORK_DIR/BOOT
        mv $ISO_SOURCE_DIR/\[BOOT\] $WORK_DIR/BOOT
      fi
    fi
  else
    if [ "$TEST_MODE" = "false" ]; then
      mv $ISO_SOURCE_DIR/\[BOOT\] $WORK_DIR/BOOT
    fi
  fi
  if [ -f "$WORK_DIR/grub.cfg" ]; then
    handle_output "cp $WORK_DIR/grub.cfg $ISO_SOURCE_DIR/boot/grub/grub.cfg"
    if [ "$TEST_MODE" = "false" ]; then
      cp $WORK_DIR/grub.cfg $ISO_SOURCE_DIR/boot/grub/grub.cfg
    fi
  else
    handle_output "echo \"set timeout=$ISO_GRUB_TIMEOUT\" > $ISO_SOURCE_DIR/boot/grub/grub.cfg"
    handle_output "echo \"default=$ISO_GRUB_MENU\" >> $ISO_SOURCE_DIR/boot/grub/grub.cfg"
    handle_output "echo \"loadfont unicode\" >> $ISO_SOURCE_DIR/boot/grub/grub.cfg"
    handle_output "echo \"timeout $GRUB_TIMEOUT\" > $ISO_SOURCE_DIR/boot/grub/grub.cfg"
    handle_output "echo \"default $GRUB_MENU\" >> $ISO_SOURCE_DIR/boot/grub/grub.cfg"
    handle_output "echo \"if loadfont /boot/grub/font.pf2 ; then\" >> $ISO_SOURCE_DIR/boot/grub/grub.cfg"
    handle_output "echo \"  set gfxmode=auto\" >> $ISO_SOURCE_DIR/boot/grub/grub.cfg"
    handle_output "echo \"  insmod efi_gop\" >> $ISO_SOURCE_DIR/boot/grub/grub.cfg"
    handle_output "echo \"  insmod efi_uga\" >> $ISO_SOURCE_DIR/boot/grub/grub.cfg"
    handle_output "echo \"  insmod gfxterm\" >> $ISO_SOURCE_DIR/boot/grub/grub.cfg"
    handle_output "echo \"  terminal_output gfxterm\" >> $ISO_SOURCE_DIR/boot/grub/grub.cfg"
    handle_output "echo \"fi\" >> $ISO_SOURCE_DIR/boot/grub/grub.cfg"
    handle_output "echo \"set menu_color_normal=white/black\" >> $ISO_SOURCE_DIR/boot/grub/grub.cfg"
    handle_output "echo \"set menu_color_highlight=black/light-gray\" >> $ISO_SOURCE_DIR/boot/grub/grub.cfg"
    for ISO_DEVICE in $ISO_DEVICES; do
      for ISO_VOLMGR in $ISO_VOLMGRS; do
        if [ "$ISO_DEVICE" = "ROOT_DEV" ]; then
          handle_output "echo \"menuentry '$ISO_VOLID - $ISO_VOLMGR on first disk - $ISO_KERNEL_ARGS' {\" >> $ISO_SOURCE_DIR/boot/grub/grub.cfg"
        else
          handle_output "echo \"menuentry '$ISO_VOLID - $ISO_VOLMGR on $ISO_DEVICE - $ISO_KERNEL_ARGS' {\" >> $ISO_SOURCE_DIR/boot/grub/grub.cfg"
        fi
        handle_output "echo \"  set gfxpayload=keep\" >> $ISO_SOURCE_DIR/boot/grub/grub.cfg"
        if [ "$ISO_HWE_KERNEL" = "true" ]; then
          handle_output "echo \"  linux   /casper/hwe-vmlinuz $ISO_KERNEL_ARGS quiet autoinstall ds=nocloud\;s=/$ISO_INSTALL_MOUNT/$ISO_AUTOINSTALL_DIR/configs/$ISO_VOLMGR/$ISO_DEVICE/  ---\" >> $ISO_SOURCE_DIR/boot/grub/grub.cfg"
          handle_output "echo \"  initrd  /casper/hwe-initrd\" >> $ISO_SOURCE_DIR/boot/grub/grub.cfg"
        else
          handle_output "echo \"  linux   /casper/vmlinuz $ISO_KERNEL_ARGS quiet autoinstall ds=nocloud\;s=/$ISO_INSTALL_MOUNT/$ISO_AUTOINSTALL_DIR/configs/$ISO_VOLMGR/$ISO_DEVICE/  ---\" >> $ISO_SOURCE_DIR/boot/grub/grub.cfg"
          handle_output "echo \"  initrd  /casper/initrd\" >> $ISO_SOURCE_DIR/boot/grub/grub.cfg"
        fi
        handle_output "echo \"}\" >> $ISO_SOURCE_DIR/boot/grub/grub.cfg"
      done
    done
    handle_output "echo \"menuentry 'Try or Install $ISO_VOLID' {\" >> $ISO_SOURCE_DIR/boot/grub/grub.cfg"
    handle_output "echo \"  set gfxpayload=keep\" >> $ISO_SOURCE_DIR/boot/grub/grub.cfg"
    if [ "$ISO_HWE_KERNEL" = "true" ]; then
      handle_output "echo \"  linux /casper/hwe-vmlinuz quiet ---\" >> $ISO_SOURCE_DIR/boot/grub/grub.cfg"
      handle_output "echo \"  initrd  /casper/hwe-initrd\" >> $ISO_SOURCE_DIR/boot/grub/grub.cfg"
    else
      handle_output "echo \"  linux /casper/vmlinuz quiet ---\" >> $ISO_SOURCE_DIR/boot/grub/grub.cfg"
      handle_output "echo \"  initrd  /casper/initrd\" >> $ISO_SOURCE_DIR/boot/grub/grub.cfg"
    fi
    handle_output "echo \"}\" >> $ISO_SOURCE_DIR/boot/grub/grub.cfg"
    handle_output "echo \"menuentry 'Boot from next volume' {\" >> $ISO_SOURCE_DIR/boot/grub/grub.cfg"
    handle_output "echo \"  exit 1\" >> $ISO_SOURCE_DIR/boot/grub/grub.cfg"
    handle_output "echo \"}\" >> $ISO_SOURCE_DIR/boot/grub/grub.cfg"
    handle_output "echo \"menuentry 'UEFI Firmware Settings' {\" >> $ISO_SOURCE_DIR/boot/grub/grub.cfg"
    handle_output "echo \"  fwsetup\" >> $ISO_SOURCE_DIR/boot/grub/grub.cfg"
    handle_output "echo \"}\" >> $ISO_SOURCE_DIR/boot/grub/grub.cfg"
    if ! [ "$ISO_MAJOR_REL" = "22" ]; then
      handle_output "echo \"default $ISO_GRUB_MENU\" > $ISO_SOURCE_DIR/isolinux/txt.cfg"
      COUNTER=0
      for ISO_DEVICE in $ISO_DEVICES; do
        for ISO_VOLMGR in $ISO_VOLMGRS; do
          handle_output "echo \"label $COUNTER\" >> $ISO_SOURCE_DIR/isolinux/txt.cfg"
          if [ "$ISO_DEVICE" = "ROOT_DEV" ]; then
            handle_output "echo \"  menu label ^$ISO_VOLID - $ISO_VOLMGR on first disk - $ISO_KERNEL_ARGS\" >> $ISO_SOURCE_DIR/isolinux/txt.cfg"
          else
            handle_output "echo \"  menu label ^$ISO_VOLID - $ISO_VOLMGR on $ISO_DEVICE - $ISO_KERNEL_ARGS\" >> $ISO_SOURCE_DIR/isolinux/txt.cfg"
          fi
          if [ "$ISO_HWE_KERNEL" = "true" ]; then
            handle_output "echo \"  kernel /casper/hwe-vmlinuz" >> $ISO_SOURCE_DIR/isolinux/txt.cfg\"
            handle_output "echo \"  append  initrd=/casper/hwe-initrd $ISO_KERNEL_ARGS quiet autoinstall fsck.mode=skip ds=nocloud;s=$ISO_INSTALL_MOUNT/$ISO_AUTOINSTALL_DIR/configs/$ISO_VOLMGR/$ISO_DEVICE/  ---\" >> $ISO_SOURCE_DIR/isolinux/txt.cfg"
          else
            handle_output "echo \"  kernel /casper/vmlinuz" >> $ISO_SOURCE_DIR/isolinux/txt.cfg\"
            handle_output "echo \"  append  initrd=/casper/initrd $ISO_KERNEL_ARGS quiet autoinstall fsck.mode=skip ds=nocloud;s=$ISO_INSTALL_MOUNT/$ISO_AUTOINSTALL_DIR/configs/$ISO_VOLMGR/$ISO_DEVICE/  ---\" >> $ISO_SOURCE_DIR/isolinux/txt.cfg"
          fi
          COUNTER=$( expr $COUNTER + 1 )
        done
        handle_output "echo \"label memtest\" >> $ISO_SOURCE_DIR/isolinux/txt.cfg"
        handle_output "echo \"  menu label Test ^Memory\" >> $ISO_SOURCE_DIR/isolinux/txt.cfg"
        handle_output "echo \"  kernel /install/mt86plus\" >> $ISO_SOURCE_DIR/isolinux/txt.cfg"
        handle_output "echo \"label hd\" >> $ISO_SOURCE_DIR/isolinux/txt.cfg"
        handle_output "echo \"  menu label ^Boot from first hard drive\" >> $ISO_SOURCE_DIR/isolinux/txt.cfg"
        handle_output "echo \"  localboot 0x80\" >> $ISO_SOURCE_DIR/isolinux/txt.cfg"
      done
      if [ "$TEST_MODE" = "false" ]; then
        echo "default $ISO_GRUB_MENU" > $ISO_SOURCE_DIR/isolinux/txt.cfg
        COUNTER=0
        for ISO_DEVICE in $ISO_DEVICES; do
          for ISO_VOLMGR in $ISO_VOLMGRS; do
            echo "label $COUNTER" >> $ISO_SOURCE_DIR/isolinux/txt.cfg
            if [ "$ISO_DEVICE" = "ROOT_DEV" ]; then
              echo "  menu label ^$ISO_VOLID - $ISO_VOLMGR on first disk - $ISO_KERNEL_ARGS" >> $ISO_SOURCE_DIR/isolinux/txt.cfg
            else
              echo "  menu label ^$ISO_VOLID - $ISO_VOLMGR on $ISO_DEVICE - $ISO_KERNEL_ARGS" >> $ISO_SOURCE_DIR/isolinux/txt.cfg
            fi
            if [ "$ISO_HWE_KERNEL" = "true" ]; then
              echo "  kernel /casper/hwe-vmlinuz" >> $ISO_SOURCE_DIR/isolinux/txt.cfg
              echo "  append  initrd=/casper/hwe-initrd $ISO_KERNEL_ARGS quiet autoinstall fsck.mode=skip ds=nocloud;s=$ISO_INSTALL_MOUNT/$ISO_AUTOINSTALL_DIR/configs/$ISO_VOLMGR/$ISO_DEVICE/  ---" >> $ISO_SOURCE_DIR/isolinux/txt.cfg
            else 
              echo "  kernel /casper/vmlinuz" >> $ISO_SOURCE_DIR/isolinux/txt.cfg
              echo "  append  initrd=/casper/initrd $ISO_KERNEL_ARGS quiet autoinstall fsck.mode=skip ds=nocloud;s=$ISO_INSTALL_MOUNT/$ISO_AUTOINSTALL_DIR/configs/$ISO_VOLMGR/$ISO_DEVICE/  ---" >> $ISO_SOURCE_DIR/isolinux/txt.cfg
            fi
            COUNTER=$( expr $COUNTER + 1 )
          done
        done
        echo "label memtest" >> $ISO_SOURCE_DIR/isolinux/txt.cfg
        echo "  menu label Test ^Memory" >> $ISO_SOURCE_DIR/isolinux/txt.cfg
        echo "  kernel /install/mt86plus" >> $ISO_SOURCE_DIR/isolinux/txt.cfg
        echo "label hd" >> $ISO_SOURCE_DIR/isolinux/txt.cfg
        echo "  menu label ^Boot from first hard drive" >> $ISO_SOURCE_DIR/isolinux/txt.cfg
        echo "  localboot 0x80" >> $ISO_SOURCE_DIR/isolinux/txt.cfg
      fi
    fi
    if [ "$TEST_MODE" = "false" ]; then
      echo "set timeout=$ISO_GRUB_TIMEOUT" > $ISO_SOURCE_DIR/boot/grub/grub.cfg
      echo "default=$ISO_GRUB_MENU" >> $ISO_SOURCE_DIR/boot/grub/grub.cfg
      echo "loadfont unicode" >> $ISO_SOURCE_DIR/boot/grub/grub.cfg
      for ISO_DEVICE in $ISO_DEVICES; do
        for ISO_VOLMGR in $ISO_VOLMGRS; do
          if [ "$ISO_DEVICE" = "ROOT_DEV" ]; then
            echo "menuentry '$ISO_VOLID - $ISO_VOLMGR on first disk - $ISO_KERNEL_ARGS' {" >> $ISO_SOURCE_DIR/boot/grub/grub.cfg
          else
            echo "menuentry '$ISO_VOLID - $ISO_VOLMGR on $ISO_DEVICE - $ISO_KERNEL_ARGS' {" >> $ISO_SOURCE_DIR/boot/grub/grub.cfg
          fi
          echo "  set gfxpayload=keep" >> $ISO_SOURCE_DIR/boot/grub/grub.cfg
          if [ "$ISO_HWE_KERNEL" = "true" ]; then
            echo "  linux   /casper/hwe-vmlinuz $ISO_KERNEL_ARGS quiet autoinstall ds=nocloud\;s=$ISO_INSTALL_MOUNT/$ISO_AUTOINSTALL_DIR/configs/$ISO_VOLMGR/$ISO_DEVICE/  ---" >> $ISO_SOURCE_DIR/boot/grub/grub.cfg
            echo "  initrd  /casper/hwe-initrd" >> $ISO_SOURCE_DIR/boot/grub/grub.cfg
          else
            echo "  linux   /casper/vmlinuz $ISO_KERNEL_ARGS quiet autoinstall ds=nocloud\;s=$ISO_INSTALL_MOUNT/$ISO_AUTOINSTALL_DIR/configs/$ISO_VOLMGR/$ISO_DEVICE/  ---" >> $ISO_SOURCE_DIR/boot/grub/grub.cfg
            echo "  initrd  /casper/initrd" >> $ISO_SOURCE_DIR/boot/grub/grub.cfg
          fi
          echo "}" >> $ISO_SOURCE_DIR/boot/grub/grub.cfg
        done
      done
      echo "menuentry 'Try or Install $ISO_VOLID' {" >> $ISO_SOURCE_DIR/boot/grub/grub.cfg
      echo "  set gfxpayload=keep" >> $ISO_SOURCE_DIR/boot/grub/grub.cfg
      if [ "$ISO_HWE_KERNEL" = "true" ]; then
        echo "  linux /casper/hwe-vmlinuz quiet ---" >> $ISO_SOURCE_DIR/boot/grub/grub.cfg
        echo "  initrd  /casper/hwe-initrd" >> $ISO_SOURCE_DIR/boot/grub/grub.cfg
      else
        echo "  linux /casper/vmlinuz quiet ---" >> $ISO_SOURCE_DIR/boot/grub/grub.cfg
        echo "  initrd  /casper/initrd" >> $ISO_SOURCE_DIR/boot/grub/grub.cfg
      fi
      echo "}" >> $ISO_SOURCE_DIR/boot/grub/grub.cfg
      echo "menuentry 'Boot from next volume' {" >> $ISO_SOURCE_DIR/boot/grub/grub.cfg
      echo "  exit 1" >> $ISO_SOURCE_DIR/boot/grub/grub.cfg
      echo "}" >> $ISO_SOURCE_DIR/boot/grub/grub.cfg
      echo "menuentry 'UEFI Firmware Settings' {" >> $ISO_SOURCE_DIR/boot/grub/grub.cfg
      echo "  fwsetup" >> $ISO_SOURCE_DIR/boot/grub/grub.cfg
      echo "}" >> $ISO_SOURCE_DIR/boot/grub/grub.cfg
    fi
  fi
  for ISO_DEVICE in $ISO_DEVICES; do 
    for ISO_VOLMGR in $ISO_VOLMGRS; do
      if [ -f "$WORK_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data" ]; then
        handle_output "cp $WORK_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
        if [ "$TEST_MODE" = "false" ]; then
          cp $WORK_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data
        fi
      else
        handle_output "echo \"#cloud-config\" > $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
        handle_output "echo \"autoinstall:\" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
        handle_output "echo \"  apt:\" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
        handle_output "echo \"    preferences:\" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
        handle_output "echo \"      - package: \\\"*\\\"\" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
        handle_output "echo \"        pin: \\\"release a=$CODENAME-security\\\"\" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
        handle_output "echo \"        pin-priority: 200\" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
        handle_output "echo \"    disable_components: []\" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
        handle_output "echo \"    geoip: true\" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
        handle_output "echo \"    preserve_sources_list: false\" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
        handle_output "echo \"    primary:\" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
        handle_output "echo \"    - arches:\" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
        handle_output "echo \"      - $ISO_ARCH\" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
        handle_output "echo \"      uri: http://archive.ubuntu.com/ubuntu\" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
        handle_output "echo \"    - arches:\" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
        handle_output "echo \"      - default\" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
        handle_output "echo \"      uri: http://ports.ubuntu.com/ubuntu-ports\" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
        handle_output "echo \"  package_update: false\" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
        handle_output "echo \"  package_upgrade: false\" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
        handle_output "echo \"  drivers:\" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
        handle_output "echo \"    install: false\" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
        handle_output "echo \"  user-data:\" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
        handle_output "echo \"    timezone: $TIMEZONE\" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
        handle_output "echo \"  identity:\" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
        handle_output "echo \"    hostname: $ISO_HOSTNAME\" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
        handle_output "echo \"    password: \\\"$ISO_PASSWORD_CRYPT\\\"\" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
        handle_output "echo \"    realname: $ISO_REALNAME\" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
        handle_output "echo \"    username: $ISO_USERNAME\" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
        handle_output "echo \"  kernel:\" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
        handle_output "echo \"    package: $ISO_KERNEL\" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
        handle_output "echo \"  keyboard:\" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
        handle_output "echo \"    layout: $ISO_LAYOUT\" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
        handle_output "echo \"  locale: $ISO_LOCALE\" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
        handle_output "echo \"  network:\" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
        handle_output "echo \"    ethernets:\" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
        handle_output "echo \"      $NIC:\" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
        handle_output "echo \"        critical: true\" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
        handle_output "echo \"        dhcp-identifier: mac\" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
        handle_output "echo \"        dhcp4: $ISO_DHCP\" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
        handle_output "echo \"    version: 2\" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
        handle_output "echo \"  ssh:\" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
        handle_output "echo \"    allow-pw: true\" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
        handle_output "echo \"    authorized-keys: []\" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
        handle_output "echo \"    install-server: true\" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
        handle_output "echo \"  storage:\" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
        if [ "$ISO_VOLMGR" = "zfs" ]; then
          handle_output "echo \"    config:\" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
          handle_output "echo \"    - ptable: gpt\" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
          handle_output "echo \"      path: /dev/$ISO_DEVICE\" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
          handle_output "echo \"      wipe: superblock-recursive\" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
          handle_output "echo \"      preserve: false\" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
          handle_output "echo \"      name: ''\" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
          handle_output "echo \"      grub_device: true\" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
          handle_output "echo \"      type: disk\" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
          handle_output "echo \"      id: disk1\" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
          handle_output "echo \"    - device: disk1\" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
          handle_output "echo \"      size: 1127219200\" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
          handle_output "echo \"      wipe: superblock-recursive\" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
          handle_output "echo \"      flag: boot\" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
          handle_output "echo \"      number: 1\" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
          handle_output "echo \"      preserve: false\" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
          handle_output "echo \"      grub_device: true\" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
          handle_output "echo \"      type: partition\" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
          handle_output "echo \"      ptable: gpt\" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
          handle_output "echo \"      id: disk1p1\" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
          handle_output "echo \"    - fstype: fat32\" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
          handle_output "echo \"      volume: disk1p1\" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
          handle_output "echo \"      preserve: false\" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
          handle_output "echo \"      type: format\" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
          handle_output "echo \"      id: disk1p1fs1\" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
          handle_output "echo \"    - path: /boot/efi\" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
          handle_output "echo \"      device: disk1p1fs1\" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
          handle_output "echo \"      type: mount\" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
          handle_output "echo \"      id: mount-2\" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
          handle_output "echo \"    - device: disk1\" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
          handle_output "echo \"      size: -1\" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
          handle_output "echo \"      wipe: superblock-recursive\" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
          handle_output "echo \"      flag: root\" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
          handle_output "echo \"      number: 2\" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
          handle_output "echo \"      preserve: false\" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
          handle_output "echo \"      grub_device: false\" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
          handle_output "echo \"      type: partition\" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
          handle_output "echo \"      id: disk1p2\" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
          handle_output "echo \"    - id: disk1p2fs1\" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
          handle_output "echo \"      type: format\" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
          handle_output "echo \"      fstype: zfsroot\" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
          handle_output "echo \"      volume: disk1p2\" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
          handle_output "echo \"      preserve: false\" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
          handle_output "echo \"    - id: disk1p2f1_rootpool\" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
          handle_output "echo \"      mountpoint: /\" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
          handle_output "echo \"      pool: rpool\" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
          handle_output "echo \"      type: zpool\" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
          handle_output "echo \"      device: disk1p2fs1\" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
          handle_output "echo \"      preserve: false\" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
          handle_output "echo \"      vdevs:\" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
          handle_output "echo \"        - disk1p2fs1\" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
          handle_output "echo \"    - id: disk1_rootpool_container\" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
          handle_output "echo \"      pool: disk1p2f1_rootpool\" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
          handle_output "echo \"      preserve: false\" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
          handle_output "echo \"      properties:\" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
          handle_output "echo \"        canmount: \\\"off\\\"\" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
          handle_output "echo \"        mountpoint: \\\"none\\\"\" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
          handle_output "echo \"      type: zfs\" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
          handle_output "echo \"      volume: /ROOT\" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
          handle_output "echo \"    - id: disk1_rootpool_rootfs\" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
          handle_output "echo \"      pool: disk1p2f1_rootpool\" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
          handle_output "echo \"      preserve: false\" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
          handle_output "echo \"      properties:\" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
          handle_output "echo \"        canmount: noauto\" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
          handle_output "echo \"        mountpoint: /\" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
          handle_output "echo \"      type: zfs\" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
          handle_output "echo \"      volume: /ROOT/zfsroot\" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
          handle_output "echo \"    - path: /\" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
          handle_output "echo \"      device: disk1p2fs1\" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
          handle_output "echo \"      type: mount\" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
          handle_output "echo \"      id: mount-disk1p2\" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
          handle_output "echo \"    swap:\" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
          handle_output "echo \"      swap: $SWAPSIZE\" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
        fi
        if [ "$ISO_VOLMGR" = "lvm" ]; then
            handle_output "echo \"    layout:\" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
            handle_output "echo \"      name: lvm\" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
        fi
        handle_output "echo \"  early-commands:\" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
        handle_output "echo \"    - \\\"sudo dpkg --auto-deconfigure --force-depends -i $ISO_INSTALL_MOUNT/$ISO_AUTOINSTALL_DIR/packages/*.deb\\\"\" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
        if [ "$ISO_VOLMGR" = "zfs" ]; then
          handle_output "echo \"    - \\\"sed -i \\\\\"s/ROOT_DEV/\$(lsblk -x TYPE|grep disk |head -1 |awk '{print \$1}')/g\\\\\" /autoinstall.yaml\\\"\" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
        fi
        handle_output "echo \"  late-commands:\" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
        handle_output "echo \"    - \\\"echo 'GRUB_CMDLINE_LINUX=\\\\\\\"$ISO_KERNEL_ARGS\\\\\\\"' >> $ISO_TARGET_MOUNT/etc/default/grub\\\"\" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
        handle_output "echo \"    - \\\"curtin in-target --target=$ISO_TARGET_MOUNT -- /usr/sbin/update-grub\\\"\" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
        if [ "$DO_INSTALL_ISO_UPDATE" = "true" ] || [ "$DO_INSTALL_PACKAGES" = "true" ] || [ "$DO_DIST_UPGRADE" = "true" ]; then
          handle_output "echo \"    - \\\"curtin in-target --target=$ISO_TARGET_MOUNT -- apt update\\\"\" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
        fi
        if [ "$DO_INSTALL_ISO_UPGRADE" = "true" ]; then
          handle_output "echo \"    - \\\"curtin in-target --target=$ISO_TARGET_MOUNT -- apt upgrade -y\\\"\" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
        fi
        if [ "$DO_INSTALL_ISO_DIST_UPGRADE" = "true" ]; then
          handle_output "echo \"    - \\\"curtin in-target --target=$ISO_TARGET_MOUNT -- apt dist-upgrade -y\\\"\" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
        fi
        if [ "$DO_INSTALL_ISO_PACKAGES" = "true" ]; then
          handle_output "echo \"    - \\\"curtin in-target --target=$ISO_TARGET_MOUNT -- apt install -y $ISO_INSTALL_PACKAGES\\\"\" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
        fi
        handle_output "echo \"  version: 1\" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
        if [ "$TEST_MODE" = "false" ]; then
          echo "#cloud-config" > $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data
          echo "autoinstall:" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data
          echo "  apt:" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data
          echo "    preferences:" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data
          echo "      - package: \"*\"" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data
          echo "        pin: \"release a=$CODENAME-security\"" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data
          echo "        pin-priority: 200" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data
          echo "    disable_components: []" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data
          echo "    geoip: true" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data
          echo "    preserve_sources_list: false" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data
          echo "    primary:" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data
          echo "    - arches:" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data
          echo "      - $ISO_ARCH" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data
          echo "      uri: http://archive.ubuntu.com/ubuntu" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data
          echo "    - arches:" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data
          echo "      - default" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data
          echo "      uri: http://ports.ubuntu.com/ubuntu-ports" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data
          echo "  package_update: false" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data
          echo "  package_upgrade: false" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data
          echo "  drivers:" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data
          echo "    install: false" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data
          echo "  user-data:" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data
          echo "    timezone: $TIMEZONE" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data
          echo "  identity:" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data
          echo "    hostname: $ISO_HOSTNAME" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data
          echo "    password: \"$ISO_PASSWORD_CRYPT\"" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data
          echo "    realname: $ISO_REALNAME" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data
          echo "    username: $ISO_USERNAME" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data
          echo "  kernel:" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data
          echo "    package: $ISO_KERNEL" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data
          echo "  keyboard:" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data
          echo "    layout: $ISO_LAYOUT" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data
          echo "  locale: $ISO_LOCALE" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data
          echo "  network:" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data
          echo "    ethernets:" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data
          echo "      $ISO_NIC:" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data
          echo "        critical: true" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data
          echo "        dhcp-identifier: mac" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data
          echo "        dhcp4: $ISO_DHCP" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data
          echo "    version: 2" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data
          echo "  ssh:" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data
          echo "    allow-pw: true" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data
          echo "    authorized-keys: []" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data
          echo "    install-server: true" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data
          echo "  storage:" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data
          if [ "$ISO_VOLMGR" = "zfs" ]; then
            echo "    config:" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data
            echo "    - ptable: gpt" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data
            echo "      path: /dev/$ISO_DEVICE" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data
            echo "      wipe: superblock-recursive" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data
            echo "      preserve: false" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data
            echo "      name: ''" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data
            echo "      grub_device: true" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data
            echo "      type: disk" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data
            echo "      id: disk1" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data
            echo "    - device: disk1" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data
            echo "      size: 1127219200" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data
            echo "      wipe: superblock-recursive" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data
            echo "      flag: boot" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data
            echo "      number: 1" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data
            echo "      preserve: false" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data
            echo "      grub_device: true" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data
            echo "      type: partition" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data
            echo "      ptable: gpt" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data
            echo "      id: disk1p1" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data
            echo "    - fstype: fat32" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data
            echo "      volume: disk1p1" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data
            echo "      preserve: false" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data
            echo "      type: format" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data
            echo "      id: disk1p1fs1" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data
            echo "    - path: /boot/efi" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data
            echo "      device: disk1p1fs1" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data
            echo "      type: mount" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data
            echo "      id: mount-2" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data
            echo "    - device: disk1" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data
            echo "      size: -1" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data
            echo "      wipe: superblock-recursive" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data
            echo "      flag: root" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data
            echo "      number: 2" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data
            echo "      preserve: false" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data
            echo "      grub_device: false" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data
            echo "      type: partition" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data
            echo "      id: disk1p2" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data
            echo "    - id: disk1p2fs1" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data
            echo "      type: format" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data
            echo "      fstype: zfsroot" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data
            echo "      volume: disk1p2" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data
            echo "      preserve: false" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data
            echo "    - id: disk1p2f1_rootpool" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data
            echo "      mountpoint: /" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data
            echo "      pool: rpool" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data
            echo "      type: zpool" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data
            echo "      device: disk1p2fs1" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data
            echo "      preserve: false" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data
            echo "      vdevs:" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data
            echo "        - disk1p2fs1" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data
            echo "    - id: disk1_rootpool_container" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data
            echo "      pool: disk1p2f1_rootpool" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data
            echo "      preserve: false" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data
            echo "      properties:" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data
            echo "        canmount: \"off\"" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data
            echo "        mountpoint: \"none\"" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data
            echo "      type: zfs" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data
            echo "      volume: /ROOT" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data
            echo "    - id: disk1_rootpool_rootfs" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data
            echo "      pool: disk1p2f1_rootpool" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data
            echo "      preserve: false" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data
            echo "      properties:" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data
            echo "        canmount: noauto" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data
            echo "        mountpoint: /" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data
            echo "      type: zfs" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data
            echo "      volume: /ROOT/zfsroot" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data
            echo "    - path: /" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data
            echo "      device: disk1p2fs1" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data
            echo "      type: mount" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data
            echo "      id: mount-disk1p2" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data
            echo "    swap:" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data
            echo "      swap: $SWAPSIZE" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data
          fi
          if [ "$ISO_VOLMGR" = "lvm" ]; then
            echo "    layout:" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data
            echo "      name: lvm" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data
          fi
          echo "  early-commands:" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data
          if [ "$ISO_VOLMGR" = "zfs" ]; then
            echo "    - \"sed -i \\\"s/ROOT_DEV/\$(lsblk -x TYPE|grep disk |head -1 |awk '{print \$1}')/g\\\" /autoinstall.yaml\"" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data
          fi
          echo "    - \"dpkg --auto-deconfigure --force-depends -i $ISO_INSTALL_MOUNT/$ISO_AUTOINSTALL_DIR/packages/*.deb\"" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data
          echo "  late-commands:" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data
          echo "    - \"echo 'GRUB_CMDLINE_LINUX=\\\"$ISO_KERNEL_ARGS\\\"' >> $ISO_TARGET_MOUNT/etc/default/grub\"" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data
          echo "    - \"curtin in-target --target=$ISO_TARGET_MOUNT -- update-grub\"" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data
          if [ "$DO_ISO_INSTALL_UPDATE" = "true" ] || [ "$DO_INSTALL_PACKAGES" = "true" ] || [ "$DO_DIST_UPGRADE" = "true" ]; then
            echo "    - \"curtin in-target --target=$ISO_TARGET_MOUNT -- apt update\"" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data
          fi
          if [ "$DO_ISO_INSTALL_UPGRADE" = "true" ]; then
            echo "    - \"curtin in-target --target=$ISO_TARGET_MOUNT -- apt upgrade -y\"" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data
          fi
          if [ "$DO_ISO_DIST_UPGRADE" = "true" ]; then
            echo "    - \"curtin in-target --target=$ISO_TARGET_MOUNT -- apt dist-upgrade -y\"" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data
          fi
          if [ "$DO_ISO_INSTALL_PACKAGES" = "true" ]; then
            echo "    - \"curtin in-target --target=$ISO_TARGET_MOUNT -- apt install -y $ISO_INSTALL_PACKAGES\"" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data
          fi
          echo "  version: 1" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data
        fi
      fi
    done
  done
}

# Handle command line arguments

if [ $? -ne 0 ]; then
  print_help
fi

while test $# -gt 0
do
  case $1 in
    -A|--codename)
      ISO_CODENAME="$2"
      shift 2
      ;;
    -a|--action)
      ACTION=="$2"
      shift 2
      ;;
    -B|--layout)
      ISO_LAYOUT="$2"
      shift 2
      ;;
    -D|--mode)
      MODE="$2"
      shift 2
      ;;
    -d|--bootdisk)
      ISO_DEVICES+="$2"
      shift 2
      ;;
    -E|--locale)
      ISO_LOCALE="$2"
      shift 2
      ;;
    -e|--lcall)
      ISO_LC_ALL="$2"
      shift 2
      ;;
    -F|--updatesquashfs)
      DO_ISO_SQUASHFS_UPDATE="true"
      shift
      ;;
    -f|--delete)
      FORCE_MODE="true"
      shift
      ;;
    -G|--isovolid)
      ISO_VOLID="$2"
      shift 2
      ;;
    -g|--grubmenu)
      ISO_GRUB_MENU="$2"
      shift
      ;;
    -H|--hostname)
      ISO_HOSTNAME="$2"
      shift 2
      ;;
    -h|--help)
      print_help 
      exit
      ;;
    -i|--inputiso)
      INPUT_FILE="$2"
      shift 2
      ;;
    -J|--hwe)
      ISO_HWE_KERNEL="true"
      ISO_KERNEL="linux-generic-hwe"
      shift
      ;;
    -j|--autoinstalldir)
      ISO_AUTOINSTALL_DIR="$2"
      shift 2
      ;;
    -K|--kernel)
      ISO_KERNEL="$2"
      shift 2
      ;;
    -k|--kernelargs)
      ISO_KERNEL_ARGS="$2"
      shift 2
      ;;
    -L|--release)
      ISO_RELEASE="$2"
      shift 2
      ;;
    -M|--installtarget)
      ISO_TARGET_MOUNT="$2"
      shift 2 
      ;;
    -m|--installmount)
      ISO_INSTALL_MOUNT="$2"
      shift 2 
      ;;
    -N|--nic)
      ISO_NIC="$2"
      shift 2
      ;;
    -n|--nounmount)
      DO_NO_UNMOUNT_ISO="true";
      shift
      ;;
    -O|--ospackages)
      ISO_INSTALL_PACKAGES="$2"
      shift 2
      ;;
    -o|--outputiso)
      OUTPUT_FILE="$2"
      shift 2
      ;;
    -P|--password)
      ISO_PASSWORD="$2"
      shift 2
      ;;
    -p|--packages)
      ISO_CHROOT_PACKAGES="$2"
      shift 2
      ;;
    -Q|--build)
      DO_DAILY_ISO="true"
      ISO_BUILD_TYPE="$2"
      shift 2
      ;;
    -q|--arch)
      ISO_ARCH="$2"
      shift 2
      ;;
    -R|--realname)
      ISO_REALNAME="$2"
      shift 2
      ;;
    -S|--swapsize)
      ISO_SWAPSIZE="$2"
      shift 2
      ;;
    -s|--staticip)
      ISO_DHCP="false"
      shift
      ;;
    -T|--timezone)
      ISO_TIMEZONE="$2"
      shift 2
      ;;
    -t|--testmode)
      TEST_MODE="true"
      shift
      ;;
    -U|--username)
      ISO_USERNAME="$2"
      shift 2
      ;;
    -u|--postinstall)
      POSTINSTALL="$2"
      shift 2
      ;;
    -V|--version)
      echo "$SCRIPT_VERSION"
      shift
      exit
      ;;
    -v|--verbose)
      VERBOSE_MODE="true"
      shift
      ;;
    -W|--workdir)
      WORK_DIR="$2"
      shift 2
      ;;
    -w|--oldworkdir)
      OLD_WORK_DIR="$2"
      shift 2
      ;;
    -X|--deleteall)
      FULL_FORCE_MODE="true"
      shift
      ;;
    -x|--grubtimeout)
      ISO_GRUB_TIMEOUT="$2"
      shift 2
      ;;
    -z|--volumemanager)
      ISO_VOLMGR="$2"
      shift 2
      ;;
    --)
      shift
      break
      ;;
    *)
      print_help
      exit
      ;;
  esac
done

# If run in interactive mode ask for values for required parameters
# Set any unset values to defaults

if [ "$INTERACTIVE_MODE" == "true" ]; then
  read -p "Enter hostname:" ISO_HOSTNAME
  read -p "Enter TIMEZONE" ISO_TIMEZONE
  read -p "Enter username:" ISO_USERNAME
  read -p "Enter user real name" ISO_REALNAME
  read -s -p "Enter password:" ISO_PASSWORD
  read -p "Enter additional packages:" ISO_CHROOT_PACKAGES
  read -p "Enter source ISO file:" INPUT_FILE
  read -p "Enter output ISO file:" OUTPUT_FILE
fi

# Process action switch

case $ACTION in
  "=checkdocker")
    DO_DOCKER="false"
    DO_CHECK_DOCKER="true"
    DO_CHECK_WORK_DIR="true"
    ;;
  "=getiso")
    DO_CHECK_WORK_DIR="true"
    DO_GET_BASE_ISO="true"
    ;;
  "=installrequired")
    DO_INSTALL_REQUIRED_PACKAGES="true"
    ;;
  "=checkdirs")
    DO_CHECK_WORK_DIR="true"
    ;;
  "=justiso")
    DO_CREATE_AUTOINSTALL_ISO_ONLY="true"
    ;;
  "=runchrootscript")
    DO_EXECUTE_ISO_CHROOT_SCRIPT="true"
    ;;
  "=createiso")
    DO_CHECK_WORK_DIR="true"
    DO_INSTALL_REQUIRED_PACKAGES="true"
    DO_GET_BASE_PACKAGES="true"
    DO_PREPARE_ISO_AUTOINSTALL="true"
    DO_EXECUTE_ISO_CHROOT_SCRIPT="true"
    DO_CREATE_AUTOINSTALL_ISO_FULL="true"
    ;;
  "=createdockeriso")
    DO_DOCKER="true"
    DO_CHECK_DOCKER="true"
    DO_CHECK_WORK_DIR="true"
    DO_INSTALL_REQUIRED_PACKAGES="true"
    DO_GET_BASE_PACKAGES="true"
    DO_PREPARE_ISO_AUTOINSTALL="true"
    DO_EXECUTE_ISO_CHROOT_SCRIPT="true"
    DO_CREATE_AUTOINSTALL_ISO_FULL="true"
    ;;
  "=queryiso")
    DO_ISO_QUERY="true"
    ;;
  "=unmount")
    DO_UMOUNT_ISO="true"
    ;;
  *)
    handle_output "Action: $ACTION is not a valid action"
    exit
    ;;
esac

# Process postinstall switch

case $POSTINSTALL in
  "=distupgrade"|="dist-upgrade")
    DO_INSTALL_ISO_DIST_UPGRADE="true"
    ;;
  "=packages")
    DO_INSTALL_ISO_PACKAGES="true"
    ;;
  "=updates"|"=upgrades")
    DO_INSTALL_ISO_UPDATE="true"
    DO_INSTALL_ISO_UPGRADE="true"
    ;;
  *)
    DO_INSTALL_ISO_PACKAGES="true"
    ;;
esac

# Mode: interactive or defaults

case $MODE in 
  "=defaults")
    DEFAULTS_MODE="true"
    ;;
  "=interactive")
    INTERACTIVE_MODE="true"
    ;;
  *)
    DEFAULTS_MODE="true"
    ;;
esac

if [ "$ISO_ARCH" = "" ] || [ "$DEFAULTS_MODE" = "true" ]; then
  ISO_ARCH="$DEFAULT_ISO_ARCH"
  DOCKER_ARCH="$DEFAULT_DOCKER_ARCH"
else
  DOCKER_ARCH="$ISO_ARCH"
fi
if [ "$ISO_RELEASE" = "" ] || [ "$DEFAULTS_MODE" = "true" ]; then
  ISO_RELEASE="$DEFAULT_ISO_RELEASE"
fi
ISO_MAJOR_REL=$(echo $ISO_RELEASE |cut -f1 -d.)
if [ "$ISO_USERNAME" = "" ] || [ "$DEFAULTS_MODE" = "true" ]; then
  ISO_USERNAME="$DEFAULT_ISO_USERNAME"
fi
if [ "$ISO_REALNAME" = "" ] || [ "$DEFAULTS_MODE" = "true" ]; then
  ISO_REALNAME="$DEFAULT_ISO_REALNAME"
fi
if [ "$ISO_HOSTNAME" = "" ] || [ "$DEFAULTS_MODE" = "true" ]; then
  ISO_HOSTNAME="$DEFAULT_ISO_HOSTNAME"
fi
if [ "$ISO_PASSWORD" = "" ] || [ "$DEFAULTS_MODE" = "true" ]; then
  ISO_PASSWORD="$DEFAULT_ISO_PASSWORD"
fi
if [ "$ISO_CHROOT_PACKAGES" = "" ] || [ "$DEFAULTS_MODE" = "true" ]; then
  ISO_CHROOT_PACKAGES="$DEFAULT_ISO_PACKAGES"
fi
if [ "$ISO_INSTALL_PACKAGES" = "" ] || [ "$DEFAULTS_MODE" = "true" ]; then
  ISO_INSTALL_PACKAGES="$DEFAULT_ISO_PACKAGES"
fi
if [ "$TIMEZONE" = "" ] || [ "$DEFAULTS_MODE" = "true" ]; then
  ISO_IMEZONE="$DEFAULT_ISO_TIMEZONE"
fi
if [ "$OUTPUT_FILE" = "" ] || [ "$DEFAULTS_MODE" = "true" ]; then
  OUTPUT_FILE="$DEFAULT_OUTPUT_FILE"
fi
if [ "$ISO_NIC" = "" ] || [ "$DEFAULTS_MODE" = "true" ]; then
  ISO_NIC="$DEFAULT_ISO_NIC"
fi
if [ "$SWAPSIZE" = "" ] || [ "$DEFAULTS_MODE" = "true" ]; then
  ISO_SWAPSIZE="$DEFAULT_ISO_SWAPSIZE"
fi
if [ "$ISO_DEVICES" = "" ] || [ "$DEFAULTS_MODE" = "true" ]; then
  ISO_DEVICES="$DEFAULT_ISO_DEVICES"
fi
if [ "$ISO_VOLMGRS" = "" ] || [ "$DEFAULTS_MODE" = "true" ]; then
  ISO_VOLMGRS="$DEFAULT_ISO_VOLMGRS"
fi
if [ "$GRUB_MENU" = "" ] || [ "$DEFAULTS_MODE" = "true" ]; then
  ISO_GRUB_MENU="$DEFAULT_ISO_GRUB_MENU"
fi
if [ "$GRUB_TIMEOUT" = "" ] || [ "$DEFAULTS_MODE" = "true" ]; then
  ISO_GRUB_TIMEOUT="$DEFAULT_ISO_GRUB_TIMEOUT"
fi
if [ "$ISO_KERNEL_ARGS" = "" ] || [ "$DEFAULTS_MODE" = "true" ]; then
  ISO_KERNEL_ARGS="$DEFAULT_ISO_KERNEL_ARGS"
fi
if [ "$ISO_KERNEL" = "" ] || [ "$DEFAULTS_MODE" = "true" ]; then
  ISO_KERNEL="$DEFAULT_ISO_KERNEL"
fi
if [ "$CODENAME" = "" ] || [ "$DEFAULTS_MODE" = "true" ]; then
  ISO_CODENAME="$DEFAULT_ISO_CODENAME"
fi
if [ "$ISO_LOCALE" = "" ] || [ "$DEFAULTS_MODE" = "true" ]; then
  ISO_LOCALE="$DEFAULT_ISO_LOCALE"
fi
if [ "$ISO_LC_ALL" = "" ] || [ "$DEFAULTS_MODE" = "true" ]; then
  ISO_LC_ALL="$DEFAULT_LC_ALL"
fi
if [ "$ISO_LAYOUT" = "" ] || [ "$DEFAULTS_MODE" = "true" ]; then
  ISO_LAYOUT="$DEFAULT_ISO_LAYOUT"
fi
if [ "$ISO_VOLID" = "" ] || [ "$DEFAULTS_MODE" = "true" ]; then
  ISO_VOLID="$DEFAULT_ISO_VOLID"
fi
if [ "$ISO_INSTALL_MOUNT" = "" ] || [ "$DEFAULTS_MODE" = "true" ]; then
  ISO_INSTALL_MOUNT="$DEFAULT_ISO_INSTALL_MOUNT"
fi
if [ "$ISO_TARGET_MOUNT" = "" ] || [ "$DEFAULTS_MODE" = "true" ]; then
  ISO_TARGET_MOUNT="$DEFAULT_ISO_TARGET_MOUNT"
fi
if [ "$ISO_AUTOINSTALL_DIR" = "" ] || [ "$DEFAULTS_MODE" = "true" ]; then
  ISO_AUTOINSTALL_DIR="$DEFAULT_ISO_AUTOINSTALL_DIR"
fi
if [ "$WORK_DIR" = "" ] || [ "$DEFAULTS_MODE" = "true" ]; then 
  if [ "$DO_DAILY_ISO" = "true" ]; then
    WORK_DIR="$HOME/ubuntu-iso/$ISO_CODENAME"
    DOCKER_WORK_DIR="/root/ubuntu-iso/$ISO_CODENAME"
  else
    WORK_DIR="$DEFAULT_WORK_DIR"
    DOCKER_WORK_DIR="$DEFAULT_DOCKER_WORK_DIR"
  fi
else
  if [ "$DO_DAILY_ISO" = "true" ]; then
    WORK_DIR="$HOME/ubuntu-iso/$ISO_CODENAME"
    DOCKER_WORK_DIR="/root/ubuntu-iso/$ISO_CODENAME"
  fi
fi
if [ "$ISO_BUILD_TYPE" = "" ] || [ "$DEFAULTS_MODE" = "true" ]; then
  ISO_BUILD_TYPE="$DEFAULT_ISO_BUILD_TYPE"
fi
if [ "$INPUT_FILE" = "" ] || [ "$DEFAULTS_MODE" = "true" ]; then
  INPUT_FILE="$DEFAULT_INPUT_FILE"
fi

if [ "$DO_ISO_QUERY" = "true" ]; then
  get_info_from_iso
else
  case $ISO_BUILD_TYPE in
    "daily-live"|"daily-live-server")
      INPUT_FILE="$WORK_DIR/files/$ISO_CODENAME-live-server-$ISO_ARCH.iso"
      OUTPUT_FILE="$WORK_DIR/files/$ISO_CODENAME-live-server-$ISO_ARCH-autoinstall.iso"
      ;;
    "daily-desktop")
      INPUT_FILE="$WORK_DIR/files/$ISO_CODENAME-desktop-$ISO_ARCH.iso"
      OUTPUT_FILE="$WORK_DIR/files/$ISO_CODENAME-desktop-$ISO_ARCH-autoinstall.iso"
      ;;
    "desktop")
      INPUT_FILE="$WORK_DIR/files/ubuntu-$ISO_RELEASE-desktop-$ISO_ARCH.iso"
      OUTPUT_FILE="$WORK_DIR/files/ubuntu-$ISO_RELEASE-desktop-$ISO_ARCH-autoinstall.iso"
      ;;
    *)
      INPUT_FILE="$WORK_DIR/files/ubuntu-$ISO_RELEASE-live-server-$ISO_ARCH.iso"
      OUTPUT_FILE="$WORK_DIR/files/ubuntu-$ISO_RELEASE-live-server-$ISO_ARCH-autoinstall.iso"
      ;;
  esac 
fi

# Update Default work directories

ISO_MOUNT_DIR="$WORK_DIR/isomount"
ISO_NEW_DIR="$WORK_DIR/isonew"
ISO_SOURCE_DIR="$WORK_DIR/source-files"

# Default file names/locations

ISO_GRUB_FILE="$WORK_DIR/grub.cfg"

if [ "$ISO_MAJOR_REL" = "22" ]; then
  ISO_SQUASHFS_FILE="$ISO_MOUNT_DIR/casper/ubuntu-server-minimal.squashfs"
  NEW_SQUASHFS_FILE="$ISO_SOURCE_DIR/casper/ubuntu-server-minimal.squashfs"
else
  ISO_SQUASHFS_FILE="$ISO_MOUNT_DIR/casper/filesystem.squashfs"
  NEW_SQUASHFS_FILE="$ISO_SOURCE_DIR/casper/filesystem.squashfs"
fi

BASE_INPUT_FILE=$( basename $INPUT_FILE )
case $ISO_BUILD_TYPE in 
  "daily-live"|"daily-live-server")
    ISO_URL="https://cdimage.ubuntu.com/ubuntu-server/$ISO_CODENAME/daily-live/current/$BASE_INPUT_FILE"
   ;;
  "daily-desktop") 
    ISO_URL="https://cdimage.ubuntu.com/$ISO_CODENAME/daily-live/current/$BASE_INPUT_FILE"
    ;;
  "desktop")
    ISO_URL="https://releases.ubuntu.com/$ISO_RELEASE/$BASE_INPUT_FILE"
    ;;
  *)
    if [ "$ISO_ARCH" = "amd64" ]; then
      URL_RELEASE=$( echo "$ISO_RELEASE" |awk -F. '{print $1"."$2}' )
      ISO_URL=" https://releases.ubuntu.com/$URL_RELEASE/$BASE_INPUT_FILE"
    else
      ISO_URL=" https://cdimage.ubuntu.com/releases/$ISO_RELEASE/release/$BASE_INPUT_FILE"
    fi
    ;;
esac

if [ "$DO_DOCKER" = "true" ] || [ "$DO_CHECK_DOCKER" = "true" ]; then
  if ! [ -f "/.dockerenv" ]; then
    DOCKER_BIN="$WORK_DIR/files/$SCRIPT_BIN"
    LOCAL_SCRIPT="$WORK_DIR/files/guige_docker_script.sh"
    DOCKER_DIR=$( dirname $DOCKER_BIN )
    DOCKER_SCRIPT="$DOCKER_WORK_DIR/files/guige_docker_script.sh"
    if ! [ "$DOCKER_BIN" = "$SCRIPT_FILE" ]; then
      cp $SCRIPT_FILE $DOCKER_BIN
      chmod +x $DOCKER_BIN
    fi
    check_work_dir
    check_docker_config
    handle_output
    if [ "$DO_DOCKER" = "false" ]; then
      exit
    fi
    handle_output "echo \"#!/bin/bash\" > $LOCAL_SCRIPT"
    handle_output "echo \"$DOCKER_WORK_DIR/files/$SCRIPT_BIN $SCRIPT_ARGS --workdir $DOCKER_WORK_DIR --oldworkdir $WORK_DIR\" >> $LOCAL_SCRIPT"
    handle_output "docker run --privileged=true --cap-add=CAP_MKNOD --device-cgroup-rule=\"b 7:* rmw\" --platform linux/$ISO_ARCH --mount source=$SCRIPT_NAME-$ISO_ARCH,target=/root/ubuntu-iso --mount type=bind,source=$WORK_DIR/files,target=/root/ubuntu-iso/$ISO_RELEASE/files  $SCRIPT_NAME-$ISO_ARCH /bin/bash $DOCKER_SCRIPT"
    if ! [ "$TEST_MODE" = "true" ]; then
      echo "#!/bin/bash" > $LOCAL_SCRIPT
      echo "$DOCKER_WORK_DIR/files/$SCRIPT_BIN $SCRIPT_ARGS --workdir $DOCKER_WORK_DIR --oldworkdir $WORK_DIR" >> $LOCAL_SCRIPT
      if [ "$DO_DOCKER" = "true" ]; then
        BASE_DOCKER_OUTPUT_FILE=$( basename $OUTPUT_FILE )
        echo "# Output file will be at $WORK_DIR/files/$BASE_DOCKER_OUTPUT_FILE" 
      fi
      exec docker run --privileged=true --cap-add=CAP_MKNOD --device-cgroup-rule="b 7:* rmw" --platform linux/$ISO_ARCH --mount source=$SCRIPT_NAME-$ISO_ARCH,target=/root/ubuntu-iso --mount type=bind,source=$WORK_DIR/files,target=/root/ubuntu-iso/$ISO_RELEASE/files  $SCRIPT_NAME-$ISO_ARCH /bin/bash $DOCKER_SCRIPT
    fi
  fi
  DO_PRINT_HELP="false"
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

if [ "$DO_CHECK_WORK_DIR" = "true" ]; then
  DO_PRINT_HELP="false"
  check_work_dir
fi
if [ "$DO_INSTALL_REQUIRED_PACKAGES" = "true" ]; then
  DO_PRINT_HELP="false"
  install_required_packages
fi
if [ "$DO_GET_BASE_ISO" = "true" ]; then
  DO_PRINT_HELP="false"
  get_base_iso
fi
if [ "$DO_CREATE_AUTOINSTALL_ISO_FULL" = "true" ]; then
  DO_PRINT_HELP="false"
  unmount_iso
  unmount_squashfs
  mount_iso
  copy_iso
  copy_squashfs
  create_chroot_script
  execute_chroot_script
  if [ "$DO_ISO_SQUASHFS_UPDATE" = "true" ]; then
    update_iso_squashfs
  fi
  prepare_autoinstall_iso
  create_autoinstall_iso
  if ! [ "$DO_NO_UNMOUNT_ISO" = "true" ]; then
    unmount_iso
    unmount_squashfs
  fi
else
  if [ "$DO_EXECUTE_ISO_CHROOT_SCRIPT" = "true" ]; then
    DO_PRINT_HELP="false"
    mount_iso
    execute_chroot_script 
  fi
  if [ "$DO_PREPARE_AUTOINSTALL_ISO" = "true" ]; then
    DO_PRINT_HELP="false"
    prepare_autoinstall_iso
  fi
  if [ "$DO_CREATE_AUTOINSTALL_ISO_ONLY" = "true" ]; then
    DO_PRINT_HELP="false"
    prepare_autoinstall_iso
    create_autoinstall_iso
  fi
  if [ "$DO_UMOUNT_ISO" = "true" ]; then
    DO_PRINT_HELP="false"
    unmount_iso
    unmount_squashfs
  fi
fi

if [ "$DO_PRINT_HELP" = "true" ]; then
  print_help
fi
