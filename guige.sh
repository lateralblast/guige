#!/usr/bin/env bash

# Name:         guige (Generic Ubuntu ISO Generation Engine)
# Version:      0.8.2
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

SCRIPT_ARGS="$*"
SCRIPT_FILE="$0"
START_PATH=$( pwd )
SCRIPT_BIN=$( basename "$0" |sed "s/^\.\///g")
SCRIPT_FILE="$START_PATH/$SCRIPT_BIN"
OS_NAME=$( uname )
OS_ARCH=$( uname -m | sed "s/aarch64/arm64/g" |sed "s/x86_64/amd64/g")
OS_USER="$USER"
BMC_PORT="443"
BMC_EXPOSE_DURATION="180"

# Default variables

SCRIPT_NAME="guige"
CURRENT_ISO_RELEASE="22.04.1"
CURRENT_DOCKER_UBUNTU_RELEASE="22.04"
CURRENT_ISO_CODENAME="jammy"
CURRENT_ISO_ARCH="amd64"
DEFAULT_ISO_HOSTNAME="ubuntu"
DEFAULT_ISO_REALNAME="Ubuntu"
DEFAULT_ISO_USERNAME="ubuntu"
DEFAULT_ISO_TIMEZONE="Australia/Melbourne"
DEFAULT_ISO_PASSWORD="ubuntu"
DEFAULT_ISO_KERNEL="linux-generic"
DEFAULT_ISO_KERNEL_ARGS="net.ifnames=0 biosdevname=0"
DEFAULT_ISO_NIC="eth0"
DEFAULT_ISO_IP="192.168.1.2"
DEFAULT_ISO_CIDR="24"
DEFAULT_ISO_GATEWAY="192.168.1.254"
DEFAULT_ISO_SWAPSIZE="2G"
DEFAULT_ISO_DEVICES="ROOT_DEV"
DEFAULT_ISO_VOLMGRS="zfs lvm"
DEFAULT_ISO_GRUB_MENU="0"
DEFAULT_ISO_GRUB_TIMEOUT="10"
DEFAULT_ISO_LOCALE="en_US.UTF-8"
DEFAULT_ISO_LC_ALL="en_US"
DEFAULT_ISO_LAYOUT="us"
DEFAULT_ISO_BUILD_TYPE="live-server"
DEFAULT_ISO_PACKAGES="zfsutils-linux grub-efi zfs-initramfs net-tools curl wget sudo file rsync"
REQUIRED_PACKAGES="p7zip-full wget xorriso whois squashfs-tools sudo file rsync net-tools nfs-server ansible"
DEFAULT_DOCKER_ARCH="amd64 arm64"
DEFAULT_ISO_SSH_KEY_FILE="$HOME/.ssh/id_rsa.pub"
DEFAULT_ISO_SSH_KEY=""
DEFAULT_ISO_ALLOW_PASSWORD="false"
DEFAULT_ISO_INSTALL_DRIVERS="false"
DEFAULT_BMC_USERNAME="root"
DEFAULT_BMC_PASSWORD="calvin"
DEFAULT_BMC_IP="192.168.1.3"

if [ "$OS_NAME" = "Darwin" ]; then
  REQUIRED_PACKAGES="p7zip wget xorriso ansible squashfs"
fi

# Default flags

ISO_DHCP="true"
TEST_MODE="false"
FORCE_MODE="false"
FULL_FORCE_MODE="false"
VERBOSE_MODE="false"
TEMP_VERBOSE_MODE="false"
DEFAULT_MODE="defaults"
INTERACTIVE_MODE="false"
ISO_HWE_KERNEL="false"
DO_DAILY_ISO="false"
DO_CHECK_DOCKER="false"
DO_CUSTOM_BOOT_SERVER_FILE="false"

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
DO_PRINT_ENV="false"
DO_INSTALL_SERVER="false"
DO_CREATE_EXPORT="false"
DO_CREATE_ANSIBLE="false"
DO_CHECK_RACADM="false"
DO_EXECUTE_RACADM="false"


# Get OS name

if [ -f "/usr/bin/lsb_release" ]; then
  DEFAULT_ISO_OS_NAME=$( lsb_release -d |awk '{print $2}' )
else
  DEFAULT_ISO_OS_NAME="$CURRENT_ISO_OS_NAME"
fi

# Get Architecture

if [ -f "/usr/bin/uname" ]; then
  DEFAULT_ISO_ARCH=$( uname -m | sed "s/aarch64/arm64/g" |sed "s/x86_64/amd64/g" )
  if [ "$OS_NAME" = "Ubuntu" ]; then
    DEFAULT_BOOT_SERVER_IP=$( ip addr | grep "inet " | grep -v "127.0.0.1" |head -1 |awk '{print $2}' |cut -f1 -d/ )
    if [ "$DEFAULT_ISO_ARCH" = "x86_64" ] || [ "$DEFAULT_ISO_ARCH" = "amd64" ]; then
      DEFAULT_ISO_ARCH="amd64"
    fi
    if [ "$DEFAULT_ISO_ARCH" = "aarch64" ] || [ "$DEFAULT_ISO_ARCH" = "arm64" ]; then
      DEFAULT_ISO_ARCH="arm64"
    fi
  else
    DEFAULT_BOOT_SERVER_IP=$( ifconfig | grep "inet " | grep -v "127.0.0.1" |head -1 |awk '{print $2}' )
  fi
else
  DEFAULT_ISO_ARCH="$CURRENT_ISO_ARCH"
  DEFAULT_BOOT_SERVER_IP=$( ifconfig | grep "inet " | grep -v "127.0.0.1" |head -1 |awk '{print $2}' )
fi

# Get default release

if [ -f "/usr/bin/lsb_release" ]; then
  if [ "$DEFAULT_OS_NAME" = "Ubuntu" ]; then
    DEFAULT_ISO_RELEASE=$( lsb_release -d |awk '{print $3}' )
  else
    DEFAULT_ISO_RELEASE="$CURRENT_ISO_RELEASE"
  fi
else
  DEFAULT_ISO_RELEASE="$CURRENT_ISO_RELEASE"
fi

# Get default codename

if [ -f "/usr/bin/lsb_release" ]; then
  if [ "$DEFAULT_ISO_OS_NAME" = "Ubuntu" ]; then
    DEFAULT_ISO_CODENAME=$( lsb_release -cs )
  else
    DEFAULT_ISO_CODENAME="$CURRENT_ISO_CODENAME"
  fi
else
  DEFAULT_ISO_CODENAME="$CURRENT_ISO_CODENAME"
fi

# Check default arches for Docker

if [ "$OS_NAME" = "Darwin" ]; then
  if [ "$OS_ARCH" = "arm64" ]; then
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

DEFAULT_ISO_AUTOINSTALL_DIR="autoinstall"
DEFAULT_ISO_TARGET_MOUNT="/target"
DEFAULT_ISO_INSTALL_MOUNT="/cdrom"

# Default file names/locations

DEFAULT_INPUT_FILE="$DEFAULT_WORK_DIR/files/ubuntu-$DEFAULT_ISO_RELEASE-live-server-$DEFAULT_ISO_ARCH.iso"
DEFAULT_OUTPUT_FILE="$DEFAULT_WORK_DIR/files/ubuntu-$DEFAULT_ISO_RELEASE-live-server-$DEFAULT_ISO_ARCH-autoinstall.iso"
DEFAULT_BOOT_SERVER_FILE="$DEFAULT_OUTPUT_FILE"
DEFAULT_ISO_SQUASHFS_FILE="$DEFAULT_ISO_MOUNT_DIR/casper/ubuntu-server-minimal.squashfs"
DEFAULT_ISO_GRUB_FILE="$DEFAULT_WORK_DIR/grub.cfg"
DEFAULT_ISO_VOLID="$DEFAULT_ISO_OS_NAME $DEFAULT_ISO_RELEASE Server"

# Basename of files

DEFAULT_INPUT_FILE_BASE=$( basename "$DEFAULT_INPUT_FILE" )
DEFAULT_OUTPUT_FILE_BASE=$( basename "$DEFAULT_OUTPUT_FILE" )

# Get the version of the script from the script itself

SCRIPT_VERSION=$( grep '^# Version' < "$0" | awk '{print $3}' )

# Function: Print help

DEFAULT_BOOT_SERVER_FILE_BASE=$(basename "$DEFAULT_BOOT_SERVER_FILE")
DEFAULT_ISO_SQUASHFS_FILE_BASE=$( basename "$DEFAULT_ISO_SQUASHFS_FILE" )
DEFAULT_ISO_GRUB_FILE_BASE=$( basename "$DEFAULT_ISO_GRUB_FILE" )

print_help () {
  cat <<-HELP
  Usage: ${0##*/} [OPTIONS...]
    -1|--bootserverfile   Boot sever file (default: $DEFAULT_BOOT_SERVER_FILE_BASE)
    -2|--squashfsfile     Squashfs file (default: $DEFAULT_ISO_SQUASHFS_FILE_BASE)
    -3|--grubfile         GRUB file (default: $DEFAULT_ISO_GRUB_FILE_BASE)
    -A|--codename         Linux release codename (default: $DEFAULT_ISO_CODENAME)
    -a|--action:          Action to perform (e.g. createiso, justiso, runchrootscript, checkdocker, installrequired)
    -B|--layout           Layout (default: $DEFAULT_ISO_LAYOUT)
    -b|--bootserverip:    NFS/Bootserver IP (default: $DEFAULT_BOOT_SERVER_IP)
    -C|--cidr:            CIDR (default: $DEFAULT_ISO_CIDR)
    -c|--sshkeyfile:      SSH key file to use as SSH key (default: $DEFAULT_ISO_SSH_KEY_FILE)
    -D|--installdrivers   Install additional drivers (default: $DEFAULT_ISO_INSTALL_DRIVERS)
    -d|--bootdisk:        Boot Disk devices (default: $DEFAULT_ISO_DEVICES)
    -E|--locale:          LANGUAGE (default: $DEFAULT_ISO_LOCALE)
    -e|--lcall:           LC_ALL (default: $DEFAULT_ISO_LC_ALL)
    -F|--bmcusername:     BMC/iDRAC User (default: $DEFAULT_BMC_USERNAME)
    -f|--delete:          Remove previously created files (default: $FORCE_MODE)
    -G|--gateway:         Gateway (default $DEFAULT_ISO_GATEWAY)
    -g|--grubmenu:        Set default grub menu (default: $DEFAULT_ISO_GRUB_MENU)
    -H|--hostname:        Hostname (default: $DEFAULT_ISO_HOSTNAME)
    -h|--help             Help/Usage Information
    -I|--ip:              IP Address (default: $DEFAULT_ISO_IP)
    -i|--inputiso:        Input/base ISO file (default: $DEFAULT_INPUT_FILE_BASE)
    -J|--hwe              Use HWE kernel (defaults: $ISO_HWE_KERNEL)
    -j|--autoinstalldir   Directory where autoinstall config files are stored on ISO (default: $DEFAULT_ISO_AUTOINSTALL_DIR)
    -K|--kernel:          Kernel package (default: $DEFAULT_ISO_KERNEL)
    -k|--kernelargs:      Kernel arguments (default: $DEFAULT_ISO_KERNEL_ARGS)
    -L|--release:         LSB release (default: $DEFAULT_ISO_RELEASE)
    -l|--bmcip:           BMC/iDRAC IP (default: $DEFAULT_BMC_IP)
    -M|--installtarget:   Where the install mounts the target filesystem (default: $DEFAULT_ISO_TARGET_DIR)
    -m|--installmount:    Where the install mounts the CD during install (default: $DEFAULT_ISO_INSTALL_MOUNT)
    -N|--dns:             DNS Server (ddefault: $DEFAULT_ISO_DNS)
    -n|--nic:             Network device (default: $DEFAULT_ISO_NIC)
    -O|--isopackages:     List of packages to install (default: $DEFAULT_ISO_PACKAGES)
    -o|--outputiso:       Output ISO file (default: $DEFAULT_OUTPUT_FILE_BASE)
    -P|--password:        Password (default: $DEFAULT_ISO_USERNAME)
    -p|--chrootpackages:  List of packages to add to ISO (default: $DEFAULT_PACKAGES)
    -Q|--build:           Type of ISO to build (default: $DEFAULT_ISO_BUILD_TYPE)
    -q|--arch:            Architecture (default: $DEFAULT_ISO_ARCH)
    -R|--realname:        Realname (default $DEFAULT_ISO_REALNAME)
    -r|--mode:            Mode (default: $DEFAULT_MODE)
    -S|--swapsize:        Swap size (default $DEFAULT_ISO_SWAPSIZE)
    -s|--staticip         Static IP configuration (default DHCP)
    -T|--timezone:        Timezone (default: $DEFAULT_ISO_TIMEZONE)
    -t|--testmode         Test mode (display commands but don't run them)
    -U|--username:        Username (default: $DEFAULT_ISO_USERNAME)
    -u|--postinstall:     Postinstall action (e.g. installpackages, upgrade, distupgrade)
    -V|--version          Display Script Version
    -v|--verbose          Verbose output (default: $VERBOSE_MODE)
    -W|--workdir:         Work directory (default: $DEFAULT_WORK_DIR)
    -w|--checkdirs        Check work directories exist
    -X|--isovolid:        ISO Volume ID (default: $DEFAULT_ISO_VOLID)
    -x|--grubtimeout:     Grub timeout (default: $DEFAULT_ISO_GRUB_TIMEOUT)
    -Y|--allowpassword    Allow password access via SSH (default: $DEFAULT_ISO_ALLOW_PASSWORD)
    -y|--bmcpassword:     BMC/iDRAC password (default: $DEFAULT_BMC_PASSWORD)
    -Z|--nounmount        Do not unmount loopback filesystems (useful for troubleshooting)
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
        mkdir -p "$WORK_DIR/$DIR_ARCH"
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
          docker volume create "$SCRIPT_NAME-$DIR_ARCH"
        fi
      fi
      if ! [ "$DOCKER_IMAGE_CHECK" = "$SCRIPT_NAME-$DIR_ARCH" ]; then
        if [ "$TEST_MODE" = "false" ]; then
          echo "version: \"3\"" > "$WORK_DIR/$DIR_ARCH/docker-compose.yml"
          echo "" >> "$WORK_DIR/$DIR_ARCH/docker-compose.yml"
          echo "services:" >> "$WORK_DIR/$DIR_ARCH/docker-compose.yml"
          echo "  $SCRIPT_NAME-$DIR_ARCH:" >> "$WORK_DIR/$DIR_ARCH/docker-compose.yml"
          echo "    build:" >> "$WORK_DIR/$DIR_ARCH/docker-compose.yml"
          echo "      context: ." >> "$WORK_DIR/$DIR_ARCH/docker-compose.yml"
          echo "      dockerfile: Dockerfile" >> "$WORK_DIR/$DIR_ARCH/docker-compose.yml"
          echo "    image: $SCRIPT_NAME-$DIR_ARCH" >> "$WORK_DIR/$DIR_ARCH/docker-compose.yml"
          echo "    container_name: $SCRIPT_NAME-$DIR_ARCH" >> "$WORK_DIR/$DIR_ARCH/docker-compose.yml"
          echo "    entrypoint: /bin/bash" >> "$WORK_DIR/$DIR_ARCH/docker-compose.yml"
          echo "    working_dir: /root" >> "$WORK_DIR/$DIR_ARCH/docker-compose.yml"
          echo "    platform: linux/$DIR_ARCH" >> "$WORK_DIR/$DIR_ARCH/docker-compose.yml"
          echo "    volumes:" >> "$WORK_DIR/$DIR_ARCH/docker-compose.yml"
          echo "      - /docker/$SCRIPT_NAME-$DIR_ARCH/:/root/ubuntu-iso/" >> "$WORK_DIR/$DIR_ARCH/docker-compose.yml"
          echo "FROM ubuntu:$CURRENT_DOCKER_UBUNTU_RELEASE" > "$WORK_DIR/$DIR_ARCH/Dockerfile"
          echo "RUN apt-get update && apt-get install -y $REQUIRED_PACKAGES" >> "$WORK_DIR/$DIR_ARCH/Dockerfile"
          docker build "$WORK_DIR/$DIR_ARCH" --tag "$SCRIPT_NAME-$DIR_ARCH" --platform linux/$DIR_ARCH
        fi
      fi
    done
  fi
}

# Function: Get info from iso

get_info_from_iso () {
  handle_output "# Analysing $INPUT_FILE"
  TEST_FILE=$( basename "$INPUT_FILE" )
  TEST_NAME=$( echo "$TEST_FILE" | cut -f1 -d- )
  TEST_TYPE=$( echo "$TEST_FILE" | cut -f2 -d- )
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
      ISO_RELEASE=$(echo "$TEST_FILE" |cut -f2 -d- )
      ISO_DISTRO="Ubuntu"
      ;;
    *)
      ISO_RELEASE="$DEFAULT_ISO_RELEASE"
      ;;
  esac
  if [ "$TEST_NAME" = "ubuntu" ]; then
    if [ "$TEST_TYPE" = "desktop" ]; then
      ISO_ARCH=$( echo "$TEST_FILE" |cut -f4 -d- |cut -f1 -d. )
    else
      ISO_ARCH=$( echo "$TEST_FILE" |cut -f5 -d- |cut -f1 -d. )
      TEST_TYPE="live-server"
    fi
  else
    if [ "$TEST_TYPE" = "desktop" ]; then
      ISO_ARCH=$( echo "$TEST_FILE" |cut -f3 -d- |cut -f1 -d. )
    else
      ISO_ARCH=$( echo "$TEST_FILE" |cut -f4 -d- |cut -f1 -d. )
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
            sudo rm -rf "$ISO_DIR"
          fi
        fi
      fi
    fi
    if ! [ -d "$ISO_DIR" ]; then
      handle_output "# Create $ISO_DIR if it doesn't exist" TEXT
      if [ "$TEST_MODE" = "false" ]; then
        mkdir -p "$ISO_DIR"
      fi
    fi
  done
}

# Function: Execute racadm

execute_racadm () {
  handle_output "# Execute racadm" TEXT
  handle_output "$RACADM_BIN -H \"$BMC_IP\" -u \"$BMC_USERNAME\" -p \"$BMC_PASSWORD\" -c \"remoteimage -d\""
  handle_output "$RACADM_BIN -H \"$BMC_IP\" -u \"$BMC_USERNAME\" -p \"$BMC_PASSWORD\" -c \"remoteimage -c -l $BOOT_SERVER_IP:BOOT_SERVER_FILE\""
  handle_output "$RACADM_BIN -H \"$BMC_IP\" -u \"$BMC_USERNAME\" -p \"$BMC_PASSWORD\" -c \"config -g cfgServerInfo -o cfgServerBootOnce 1\""
  handle_output "$RACADM_BIN -H \"$BMC_IP\" -u \"$BMC_USERNAME\" -p \"$BMC_PASSWORD\" -c \"config -g cfgServerInfo -o cfgServerFirstBootDevice VCD-DVD\""
  handle_output "$RACADM_BIN -H \"$BMC_IP\" -u \"$BMC_USERNAME\" -p \"$BMC_PASSWORD\" -c \"racadm serveraction powercycle\""
  if [ "$TEST_MODE" = "false" ]; then
    $RACADM_BIN -H "$BMC_IP" -u "$BMC_USERNAME" -p "$BMC_PASSWORD" -c "remoteimage -d"
    $RACADM_BIN -H "$BMC_IP" -u "$BMC_USERNAME" -p "$BMC_PASSWORD" -c "remoteimage -c -l $BOOT_SERVER_IP:BOOT_SERVER_FILE"
    $RACADM_BIN -H "$BMC_IP" -u "$BMC_USERNAME" -p "$BMC_PASSWORD" -c "config -g cfgServerInfo -o cfgServerBootOnce 1"
    $RACADM_BIN -H "$BMC_IP" -u "$BMC_USERNAME" -p "$BMC_PASSWORD" -c "config -g cfgServerInfo -o cfgServerFirstBootDevice VCD-DVD"
    $RACADM_BIN -H "$BMC_IP" -u "$BMC_USERNAME" -p "$BMC_PASSWORD" -c "racadm serveraction powercycle"
  fi
}

# Function: Check racadm

check_racadm () {
  handle_output "# Check racadm" TEXT
  RACADM_TEST=$( which racadm |grep "^/" )
  if [ -z "$RACADM_TEST" ]; then
    if ! [ -f "$HOME/.local/bin/racadm" ]; then
      PIP_TEST=$( which pip |grep "^/" )
      if [ -n "$PIP_TEST" ]; then
        PIP_TEST=$( pip list |grep rac |awk '{print $1}')
        if [ -z "$PIP_TEST" ]; then
          handle_output "pip install --user rac"
          if [ "$TEST_MODE" = "false" ]; then
            pip install --user rac
            RACADM_BIN="$HOME/.local/bin/racadm"
          else
            handle_output "# No racadm found" TEXT
            exit
          fi
        else
          handle_output "# No racadm found" TEXT
          handle_output "# No pip found to install Python racadm module" TEXT
          exit
        fi
      fi
    else
      RACADM_BIN="$HOME/.local/bin/racadm"
    fi
  else
    RACADM_BIN="$RACADM_TEST"
  fi
}

# Function: Install required packages
#
# Example:
# sudo apt install -y p7zip-full wget xorriso

install_required_packages () {
  handle_output "# Check required packages are installed" TEXT
  for PACKAGE in $REQUIRED_PACKAGES; do
    if [ "$OS_NAME" = "Darwin" ]; then
      PACKAGE_VERSION=$( brew list |grep "$PACKAGE" )
      COMMAND="brew install \"$PACKAGE\""
    else
      PACKAGE_VERSION=$( apt show "$PACKAGE" 2>&1 |grep Version )
      COMMAND="sudo apt install -y \"$PACKAGE\""
    fi
    if [ -z "$PACKAGE_VERSION" ]; then
      handle_output "$COMMAND"
      if [ "$TEST_MODE" = "false" ]; then
        $COMMAND
      fi
    fi
  done
}

# Function: Check base ISO file

check_base_iso_file () {
  if [ -f "$INPUT_FILE" ]; then
    BASE_INPUT_FILE=$( basename "$INPUT_FILE" )
    FILE_TYPE=$( file "$WORK_DIR/files/$BASE_INPUT_FILE" | awk '{print $2}' )
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
  BASE_INPUT_FILE=$( basename "$INPUT_FILE" )
  if [ "$FULL_FORCE_MODE" = "true" ]; then
    handle_output "rm $WORK_DIR/files/$BASE_INPUT_FILE" 
    if [ "$TEST_MODE" = "false" ]; then
      rm "$WORK_DIR/files/$BASE_INPUT_FILE"
    fi
  fi
  check_base_iso_file
  handle_output "wget $ISO_URL -O $WORK_DIR/files/$BASE_INPUT_FILE"
  if ! [ -f "$WORK_DIR/files/$BASE_INPUT_FILE" ]; then
    if [ "$TEST_MODE" = "false" ]; then
      wget "$ISO_URL" -O "$WORK_DIR/files/$BASE_INPUT_FILE"
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
    sudo umount -l "$ISO_MOUNT_DIR"
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
    sudo mount -o loop "$WORK_DIR/files/$BASE_INPUT_FILE $ISO_MOUNT_DIR"
  fi
}

unmount_squashfs () {
  handle_output "sudo umount $ISO_NEW_DIR/squashfs"
  if [ "$TEST_MODE" = "false" ]; then
    sudo umount "$ISO_NEW_DIR/squashfs"
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
      rsync -av "$ISO_MOUNT_DIR" "$ISO_NEW_DIR/cd"
    fi
  else
    handle_output "rsync -a $ISO_MOUNT_DIR/ $ISO_NEW_DIR/cd"
    if [ "$TEST_MODE" = "false" ]; then
      rsync -a "$ISO_MOUNT_DIR" "$ISO_NEW_DIR/cd"
    fi
  fi
}

# Function: Check ansible

check_ansible () {
  handle_output "# Check ansible is installed" TEXT
  handle_output "ANSIBLE_BIN=\$( which ansible )"
  handle_output  "ANSIBLE_CHECK=\$( basename $ANSIBLE_BIN )" 
  ANSIBLE_BIN=$( which ansible )
  ANSIBLE_CHECK=$( basename "$ANSIBLE_BIN" ) 
  if [ "$OS_NAME" = "Darwin" ]; then
    COMMAND="brew install ansible"
  else
    COMMAND="sudo apt install -y ansible"
  fi
  handle_output "$COMMAND"
  if ! [ "$ANSIBLE_CHECK" = "ansible" ]; then
    if [ "$TEST_MODE" = "false" ]; then
      $COMMAND
    fi
  fi
  handle_output "# Check ansible collection is installed" TEXT
  handle_output "ANSIBLE_CHECK=\$( ansible-galaxy collection list |grep \"dellemc.openmanage\" |awk '{print \$1}' |uniq )"
  ANSIBLE_CHECK=$( ansible-galaxy collection list |grep "dellemc.openmanage" |awk '{print $1}' |uniq )
    handle_output "ansible-galaxy collection install dellemc.openmanage"
  if ! [ "$ANSIBLE_CHECK" = "dellemc.openmanage" ]; then
    if [ "$TEST_MODE" = "false" ]; then
      ansible-galaxy collection install dellemc.openmanage
    fi
  fi
}

# Function: Create Ansible

create_ansible () {
  HOSTS_YAML="$WORK_DIR/hosts.yaml"
  handle_output "# Create $HOSTS_YAML" TEXT
  handle_output "echo \"---\" > $HOSTS_YAML"
  handle_output "echo \"idrac:\" >> $HOSTS_YAML"
  handle_output "echo \"  hosts:\" >> $HOSTS_YAML"
  handle_output "echo \"    $ISO_HOSTNAME:\" >> $HOSTS_YAML"
  handle_output "echo \"      ansible_host:   $BMC_IP\" >> $HOSTS_YAML"
  handle_output "echo \"      baseuri:        $BMC_IP\" >> $HOSTS_YAML"
  handle_output "echo \"      idrac_user:     $BMC_USERNAME\" >> $HOSTS_YAML"
  handle_output "echo \"      idrac_password: $BMC_PASSWORD\" >> $HOSTS_YAML"
  if [ "$TEST_MODE" = "false" ]; then
    echo "---" > "$HOSTS_YAML"
    echo "idrac:" >> "$HOSTS_YAML"
    echo "  hosts:" >> "$HOSTS_YAML"
    echo "    $ISO_HOSTNAME:" >> "$HOSTS_YAML"
    echo "      ansible_host:   $BMC_IP" >> "$HOSTS_YAML"
    echo "      baseuri:        $BMC_IP" >> "$HOSTS_YAML"
    echo "      idrac_user:     $BMC_USERNAME" >> "$HOSTS_YAML"
    echo "      idrac_password: $BMC_PASSWORD" >> "$HOSTS_YAML"
  fi
  IDRAC_YAML="$WORK_DIR/idrac.yaml"
  NFS_FILE=$( basename "$BOOT_SERVER_FILE" )
  NFS_DIR=$( dirname "$BOOT_SERVER_FILE" )
  handle_output "# Create $HOSTS_YAML" TEXT
  handle_output "echo \"- hosts: idrac\" > $IDRAC_YAML"
  handle_output "echo \"  name: $ISO_VOLID\" >> $IDRAC_YAML"
  handle_output "echo \"  gather_facts: False\" >> $IDRAC_YAML"
  handle_output "echo \"  vars:\" >> $IDRAC_YAML"
  handle_output "echo \"    idrac_osd_command_allowable_values: [\\\"BootToNetworkISO\\\", \\\"GetAttachStatus\\\", \\\"DetachISOImage\\\"]\" >> $IDRAC_YAML"
  handle_output "echo \"    idrac_osd_command_default: \\\"GetAttachStatus\\\"\" >> $IDRAC_YAML"
  handle_output "echo \"    GetAttachStatus_Code:\" >> $IDRAC_YAML"
  handle_output "echo \"      DriversAttachStatus:\" >> $IDRAC_YAML"
  handle_output "echo \"        \\\"0\\\": \\\"NotAttached\\\"\" >> $IDRAC_YAML"
  handle_output "echo \"        \\\"1\\\": \\\"Attached\\\"\" >> $IDRAC_YAML"
  handle_output "echo \"      ISOAttachStatus:\" >> $IDRAC_YAML"
  handle_output "echo \"        \\\"0\\\": \\\"NotAttached\\\"\" >> $IDRAC_YAML"
  handle_output "echo \"        \\\"1\\\": \\\"Attached\\\"\" >> $IDRAC_YAML"
  handle_output "echo \"    idrac_https_port:           $BMC_PORT\" >> $IDRAC_YAML"
  handle_output "echo \"    expose_duration:            $BMC_EXPOSE_DURATION\" >> $IDRAC_YAML"
  handle_output "echo \"    command:                    \\\"{{ idrac_osd_command_default }}\\\"\" >> $IDRAC_YAML"
  handle_output "echo \"    validate_certs:             no\" >> $IDRAC_YAML"
  handle_output "echo \"    force_basic_auth:           yes\" >> $IDRAC_YAML"
  handle_output "echo \"    share_name:                 $BOOT_SERVER_IP:$NFS_DIR/\" >> $IDRAC_YAML"
  handle_output "echo \"    ubuntu_iso:                 $NFS_FILE\" >> $IDRAC_YAML"
  handle_output "echo \"  collections:\" >> $IDRAC_YAML"
  handle_output "echo \"    - dellemc.openmanage\" >> $IDRAC_YAML"
  handle_output "echo \"  tasks:\" >> $IDRAC_YAML"
  handle_output "echo \"    - name: find the URL for the DellOSDeploymentService\" >> $IDRAC_YAML"
  handle_output "echo \"      ansible.builtin.uri:\" >> $IDRAC_YAML"
  handle_output "echo \"        url: \\\"https://{{ baseuri }}/redfish/v1/Systems/System.Embedded.1\\\"\" >> $IDRAC_YAML"
  handle_output "echo \"        user: \\\"{{ idrac_user }}\\\"\" >> $IDRAC_YAML"
  handle_output "echo \"        password: \\\"{{ idrac_password }}\\\"\" >> $IDRAC_YAML"
  handle_output "echo \"        method: GET\" >> $IDRAC_YAML"
  handle_output "echo \"        headers:\" >> $IDRAC_YAML"
  handle_output "echo \"          Accept: \\\"application/json\\\"\" >> $IDRAC_YAML"
  handle_output "echo \"          OData-Version: \\\"4.0\\\"\" >> $IDRAC_YAML"
  handle_output "echo \"        status_code: 200\" >> $IDRAC_YAML"
  handle_output "echo \"        validate_certs: \\\"{{ validate_certs }}\\\"\" >> $IDRAC_YAML"
  handle_output "echo \"        force_basic_auth: \\\"{{ force_basic_auth }}\\\"\" >> $IDRAC_YAML"
  handle_output "echo \"      register: result\" >> $IDRAC_YAML"
  handle_output "echo \"      delegate_to: localhost\" >> $IDRAC_YAML"
  handle_output "echo \"    - name: find the URL for the DellOSDeploymentService\" >> $IDRAC_YAML"
  handle_output "echo \"      ansible.builtin.set_fact:\" >> $IDRAC_YAML"
  handle_output "echo \"        idrac_osd_service_url: \\\"{{ result.json.Links.Oem.Dell.DellOSDeploymentService['@odata.id'] }}\\\"\" >> $IDRAC_YAML"
  handle_output "echo \"      when:\" >> $IDRAC_YAML"
  handle_output "echo \"        - result.json.Links.Oem.Dell.DellOSDeploymentService is defined\" >> $IDRAC_YAML"
  handle_output "echo \"    - block:\" >> $IDRAC_YAML"
  handle_output "echo \"        - name: get ISO attach status\" >> $IDRAC_YAML"
  handle_output "echo \"          ansible.builtin.uri:\" >> $IDRAC_YAML"
  handle_output "echo \"            url: \\\"https://{{ baseuri }}{{ idrac_osd_service_url }}/Actions/DellOSDeploymentService.GetAttachStatus\\\"\" >> $IDRAC_YAML"
  handle_output "echo \"            user: \\\"{{ idrac_user }}\\\"\" >> $IDRAC_YAML"
  handle_output "echo \"            password: \\\"{{ idrac_password }}\\\"\" >> $IDRAC_YAML"
  handle_output "echo \"            method: POST\" >> $IDRAC_YAML"
  handle_output "echo \"            headers:\" >> $IDRAC_YAML"
  handle_output "echo \"              Accept: \\\"application/json\\\"\" >> $IDRAC_YAML"
  handle_output "echo \"              Content-Type: \\\"application/json\\\"\" >> $IDRAC_YAML"
  handle_output "echo \"              OData-Version: \\\"4.0\\\"\" >> $IDRAC_YAML"
  handle_output "echo \"            body: \\\"{}\\\"\" >> $IDRAC_YAML"
  handle_output "echo \"            status_code: 200\" >> $IDRAC_YAML"
  handle_output "echo \"            force_basic_auth: \\\"{{ force_basic_auth }}\\\"\" >> $IDRAC_YAML"
  handle_output "echo \"          register: attach_status\" >> $IDRAC_YAML"
  handle_output "echo \"          delegate_to: localhost\" >> $IDRAC_YAML"
  handle_output "echo \"        - name: set ISO attach status as a fact variable\" >> $IDRAC_YAML"
  handle_output "echo \"          ansible.builtin.set_fact:\" >> $IDRAC_YAML"
  handle_output "echo \"            idrac_iso_attach_status: \\\"{{ idrac_iso_attach_status | default({}) | combine({item.key: item.value}) }}\\\"\" >> $IDRAC_YAML"
  handle_output "echo \"          with_dict:\" >> $IDRAC_YAML"
  handle_output "echo \"            DriversAttachStatus: \\\"{{ attach_status.json.DriversAttachStatus }}\\\"\" >> $IDRAC_YAML"
  handle_output "echo \"            ISOAttachStatus: \\\"{{ attach_status.json.ISOAttachStatus }}\\\"\" >> $IDRAC_YAML"
  handle_output "echo \"      when:\" >> $IDRAC_YAML"
  handle_output "echo \"        - idrac_osd_service_url is defined\" >> $IDRAC_YAML"
  handle_output "echo \"        - idrac_osd_service_url|length > 0\" >> $IDRAC_YAML"
  handle_output "echo \"    - block:\" >> $IDRAC_YAML"
  handle_output "echo \"        - name: detach ISO image if attached\" >> $IDRAC_YAML"
  handle_output "echo \"          ansible.builtin.uri:\" >> $IDRAC_YAML"
  handle_output "echo \"            url: \\\"https://{{ baseuri }}{{ idrac_osd_service_url }}/Actions/DellOSDeploymentService.DetachISOImage\\\"\" >> $IDRAC_YAML"
  handle_output "echo \"            user: \\\"{{ idrac_user }}\\\"\" >> $IDRAC_YAML"
  handle_output "echo \"            password: \\\"{{ idrac_password }}\\\"\" >> $IDRAC_YAML"
  handle_output "echo \"            method: POST\" >> $IDRAC_YAML"
  handle_output "echo \"            headers:\" >> $IDRAC_YAML"
  handle_output "echo \"              Accept: \\\"application/json\\\"\" >> $IDRAC_YAML"
  handle_output "echo \"              Content-Type: \\\"application/json\\\"\" >> $IDRAC_YAML"
  handle_output "echo \"              OData-Version: \\\"4.0\\\"\" >> $IDRAC_YAML"
  handle_output "echo \"            body: \\\"{}\\\"\" >> $IDRAC_YAML"
  handle_output "echo \"            status_code: 200\" >> $IDRAC_YAML"
  handle_output "echo \"            force_basic_auth: \\\"{{ force_basic_auth }}\\\"\" >> $IDRAC_YAML"
  handle_output "echo \"          register: detach_status\" >> $IDRAC_YAML"
  handle_output "echo \"          delegate_to: localhost\" >> $IDRAC_YAML"
  handle_output "echo \"        - ansible.builtin.debug:\" >> $IDRAC_YAML"
  handle_output "echo \"            msg: \\\"Successfuly detached the ISO image\\\"\" >> $IDRAC_YAML"
  handle_output "echo \"      when:\" >> $IDRAC_YAML"
  handle_output "echo \"        - idrac_osd_service_url is defined and idrac_osd_service_url|length > 0\" >> $IDRAC_YAML"
  handle_output "echo \"        - idrac_iso_attach_status\" >> $IDRAC_YAML"
  handle_output "echo \"        - idrac_iso_attach_status.ISOAttachStatus == \\\"Attached\\\" or\" >> $IDRAC_YAML"
  handle_output "echo \"          idrac_iso_attach_status.DriversAttachStatus == \\\"Attached\\\"\" >> $IDRAC_YAML"
  handle_output "echo \"    - name: boot to network ISO\" >> $IDRAC_YAML"
  handle_output "echo \"      dellemc.openmanage.idrac_os_deployment:\" >> $IDRAC_YAML"
  handle_output "echo \"        idrac_ip: \\\"{{ baseuri }}\\\"\" >> $IDRAC_YAML"
  handle_output "echo \"        idrac_user: \\\"{{ idrac_user }}\\\"\" >> $IDRAC_YAML"
  handle_output "echo \"        idrac_password: \"{{ idrac_password }}\\\"\" >> $IDRAC_YAML"
  handle_output "echo \"        share_name: \\\"{{ share_name }}\\\"\" >> $IDRAC_YAML"
  handle_output "echo \"        iso_image: \\\"{{ ubuntu_iso }}\\\"\" >> $IDRAC_YAML"
  handle_output "echo \"        expose_duration: \\\"{{ expose_duration }}\\\"\" >> $IDRAC_YAML"
  handle_output "echo \"      register: boot_to_network_iso_status\" >> $IDRAC_YAML"
  handle_output "echo \"      delegate_to: localhost\" >> $IDRAC_YAML"
  if [ "$TEST_MODE" = "false" ]; then
    echo "- hosts: idrac" > "$IDRAC_YAML"
    echo "  name: $ISO_VOLID" >> "$IDRAC_YAML"
    echo "  gather_facts: False" >> "$IDRAC_YAML"
    echo "  vars:" >> "$IDRAC_YAML"
    echo "    idrac_osd_command_allowable_values: [\"BootToNetworkISO\", \"GetAttachStatus\", \"DetachISOImage\"]" >> "$IDRAC_YAML"
    echo "    idrac_osd_command_default: \"GetAttachStatus\"" >> "$IDRAC_YAML"
    echo "    GetAttachStatus_Code:" >> "$IDRAC_YAML"
    echo "      DriversAttachStatus:" >> "$IDRAC_YAML"
    echo "        \"0\": \"NotAttached\"" >> "$IDRAC_YAML"
    echo "        \"1\": \"Attached\"" >> "$IDRAC_YAML"
    echo "      ISOAttachStatus:" >> "$IDRAC_YAML"
    echo "        \"0\": \"NotAttached\"" >> "$IDRAC_YAML"
    echo "        \"1\": \"Attached\"" >> "$IDRAC_YAML"
    echo "    idrac_https_port:           $BMC_PORT" >> "$IDRAC_YAML"
    echo "    expose_duration:            $BMC_EXPOSE_DURATION" >> "$IDRAC_YAML"
    echo "    command:                    \"{{ idrac_osd_command_default }}\"" >> "$IDRAC_YAML"
    echo "    validate_certs:             no" >> "$IDRAC_YAML"
    echo "    force_basic_auth:           yes" >> "$IDRAC_YAML"
    echo "    share_name:                 $BOOT_SERVER_IP:$NFS_DIR/" >> "$IDRAC_YAML"
    echo "    ubuntu_iso:                 $NFS_FILE" >> "$IDRAC_YAML"
    echo "  collections:" >> "$IDRAC_YAML"
    echo "    - dellemc.openmanage" >> "$IDRAC_YAML"
    echo "  tasks:" >> "$IDRAC_YAML"
    echo "    - name: find the URL for the DellOSDeploymentService" >> "$IDRAC_YAML"
    echo "      ansible.builtin.uri:" >> "$IDRAC_YAML"
    echo "        url: \"https://{{ baseuri }}/redfish/v1/Systems/System.Embedded.1\"" >> "$IDRAC_YAML"
    echo "        user: \"{{ idrac_user }}\"" >> "$IDRAC_YAML"
    echo "        password: \"{{ idrac_password }}\"" >> "$IDRAC_YAML"
    echo "        method: GET" >> "$IDRAC_YAML"
    echo "        headers:" >> "$IDRAC_YAML"
    echo "          Accept: \"application/json\"" >> "$IDRAC_YAML"
    echo "          OData-Version: \"4.0\"" >> "$IDRAC_YAML"
    echo "        status_code: 200" >> "$IDRAC_YAML"
    echo "        validate_certs: \"{{ validate_certs }}\"" >> "$IDRAC_YAML"
    echo "        force_basic_auth: \"{{ force_basic_auth }}\"" >> "$IDRAC_YAML"
    echo "      register: result" >> "$IDRAC_YAML"
    echo "      delegate_to: localhost" >> "$IDRAC_YAML"
    echo "    - name: find the URL for the DellOSDeploymentService" >> "$IDRAC_YAML"
    echo "      ansible.builtin.set_fact:" >> "$IDRAC_YAML"
    echo "        idrac_osd_service_url: \"{{ result.json.Links.Oem.Dell.DellOSDeploymentService['@odata.id'] }}\"" >> "$IDRAC_YAML"
    echo "      when:" >> "$IDRAC_YAML"
    echo "        - result.json.Links.Oem.Dell.DellOSDeploymentService is defined" >> "$IDRAC_YAML"
    echo "    - block:" >> "$IDRAC_YAML"
    echo "        - name: get ISO attach status" >> "$IDRAC_YAML"
    echo "          ansible.builtin.uri:" >> "$IDRAC_YAML"
    echo "            url: \"https://{{ baseuri }}{{ idrac_osd_service_url }}/Actions/DellOSDeploymentService.GetAttachStatus\"" >> "$IDRAC_YAML"
    echo "            user: \"{{ idrac_user }}\"" >> "$IDRAC_YAML"
    echo "            password: \"{{ idrac_password }}\"" >> "$IDRAC_YAML"
    echo "            method: POST" >> "$IDRAC_YAML"
    echo "            headers:" >> "$IDRAC_YAML"
    echo "              Accept: \"application/json\"" >> "$IDRAC_YAML"
    echo "              Content-Type: \"application/json\"" >> "$IDRAC_YAML"
    echo "              OData-Version: \"4.0\"" >> "$IDRAC_YAML"
    echo "            body: \"{}\"" >> "$IDRAC_YAML"
    echo "            status_code: 200" >> "$IDRAC_YAML"
    echo "            force_basic_auth: \"{{ force_basic_auth }}\"" >> "$IDRAC_YAML"
    echo "          register: attach_status" >> "$IDRAC_YAML"
    echo "          delegate_to: localhost" >> "$IDRAC_YAML"
    echo "        - name: set ISO attach status as a fact variable" >> "$IDRAC_YAML"
    echo "          ansible.builtin.set_fact:" >> "$IDRAC_YAML"
    echo "            idrac_iso_attach_status: \"{{ idrac_iso_attach_status | default({}) | combine({item.key: item.value}) }}\"" >> "$IDRAC_YAML"
    echo "          with_dict:" >> "$IDRAC_YAML"
    echo "            DriversAttachStatus: \"{{ attach_status.json.DriversAttachStatus }}\"" >> "$IDRAC_YAML"
    echo "            ISOAttachStatus: \"{{ attach_status.json.ISOAttachStatus }}\"" >> "$IDRAC_YAML"
    echo "      when:" >> "$IDRAC_YAML"
    echo "        - idrac_osd_service_url is defined" >> "$IDRAC_YAML"
    echo "        - idrac_osd_service_url|length > 0" >> "$IDRAC_YAML"
    echo "    - block:" >> "$IDRAC_YAML"
    echo "        - name: detach ISO image if attached" >> "$IDRAC_YAML"
    echo "          ansible.builtin.uri:" >> "$IDRAC_YAML"
    echo "            url: \"https://{{ baseuri }}{{ idrac_osd_service_url }}/Actions/DellOSDeploymentService.DetachISOImage\"" >> "$IDRAC_YAML"
    echo "            user: \"{{ idrac_user }}\"" >> "$IDRAC_YAML"
    echo "            password: \"{{ idrac_password }}\"" >> "$IDRAC_YAML"
    echo "            method: POST" >> "$IDRAC_YAML"
    echo "            headers:" >> "$IDRAC_YAML"
    echo "              Accept: \"application/json\"" >> "$IDRAC_YAML"
    echo "              Content-Type: \"application/json\"" >> "$IDRAC_YAML"
    echo "              OData-Version: \"4.0\"" >> "$IDRAC_YAML"
    echo "            body: \"{}\"" >> "$IDRAC_YAML"
    echo "            status_code: 200" >> "$IDRAC_YAML"
    echo "            force_basic_auth: \"{{ force_basic_auth }}\"" >> "$IDRAC_YAML"
    echo "          register: detach_status" >> "$IDRAC_YAML"
    echo "          delegate_to: localhost" >> "$IDRAC_YAML"
    echo "        - ansible.builtin.debug:" >> "$IDRAC_YAML"
    echo "            msg: \"Successfuly detached the ISO image\"" >> "$IDRAC_YAML"
    echo "      when:" >> "$IDRAC_YAML"
    echo "        - idrac_osd_service_url is defined and idrac_osd_service_url|length > 0" >> "$IDRAC_YAML"
    echo "        - idrac_iso_attach_status" >> "$IDRAC_YAML"
    echo "        - idrac_iso_attach_status.ISOAttachStatus == \"Attached\" or" >> "$IDRAC_YAML"
    echo "          idrac_iso_attach_status.DriversAttachStatus == \"Attached\"" >> "$IDRAC_YAML"
    echo "    - name: boot to network ISO" >> "$IDRAC_YAML"
    echo "      dellemc.openmanage.idrac_os_deployment:" >> "$IDRAC_YAML"
    echo "        idrac_ip: \"{{ baseuri }}\"" >> "$IDRAC_YAML"
    echo "        idrac_user: \"{{ idrac_user }}\"" >> "$IDRAC_YAML"
    echo "        idrac_password: \"{{ idrac_password }}\"" >> "$IDRAC_YAML"
    echo "        share_name: \"{{ share_name }}\"" >> "$IDRAC_YAML"
    echo "        iso_image: \"{{ ubuntu_iso }}\"" >> "$IDRAC_YAML"
    echo "        expose_duration: \"{{ expose_duration }}\"" >> "$IDRAC_YAML"
    echo "      register: boot_to_network_iso_status" >> "$IDRAC_YAML"
    echo "      delegate_to: localhost" >> "$IDRAC_YAML"
  fi
}

# Function: Install server

install_server () {
  HOSTS_YAML="$WORK_DIR/hosts.yaml"
  IDRAC_YAML="$WORK_DIR/idrac.yaml"
  handle_output "# Execute ansible" TEXT
  handle_output "cd $WORK_DIR ; ansible-playbook $IDRAC_YAML -i $HOSTS_YAML"
  if [ "$TEST_MODE" = "false" ]; then
    cd "$WORK_DIR/$ISO_RELEASE" ; ansible-playbook "$IDRAC_YAML" -i "$HOSTS_YAML"
  fi
}

# Function: Setup NFS server to export ISO

create_export () {
  NFS_DIR="$WORK_DIR/files"
  handle_output "# Check export is enabled" TEXT
  if [ -f "/etc/exports" ]; then
    EXPORT_CHECK=$( cat /etc/exports |grep -v ^# |grep "$NFS_DIR" |grep "$BMC_IP" |awk '{print $1}' | head -1 )
  else
    EXPORT_CHECK=""
  fi
  if [ -z "$EXPORT_CHECK" ]; then
    if [ "$OS_NAME" = "Darwin" ]; then
      handle_output "echo \"$NFS_DIR --mapall=$OS_USER $BMC_IP\" |sudo tee -a /etc/exports"
      handle_output "sudo nfsd enable"
      handle_output "sudo nfsd restart"
      echo "$NFS_DIR --mapall=$OS_USER $BMC_IP" |sudo tee -a /etc/exports
      sudo nfsd enable
      sudo nfsd restart
    else
      handle_output "echo \"$NFS_DIR $BMC_IP(sync,wdelay,hide,no_subtree_check,sec=sys,rw,secure,root_squash,no_all_squash)\" |sudo tee -a /etc/exports"
      handle_output "sudo exportfs -a"
      echo "$NFS_DIR $BMC_IP(sync,wdelay,hide,no_subtree_check,sec=sys,rw,secure,root_squash,no_all_squash)" |sudo tee -a /etc/exports
      sudo exportfs -a
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
  handle_output "sudo mount -t squashfs -o loop $ISO_SQUASHFS_FILE $ISO_NEW_DIR/squashfs"
  if [ "$TEST_MODE" = "false" ]; then
    sudo mount -t squashfs -o loop "$ISO_SQUASHFS_FILE" "$ISO_NEW_DIR/squashfs"
  fi
  if [ "$VERBOSE_MODE" = "true" ]; then
    handle_output "sudo rsync -av $ISO_NEW_DIR/squashfs/ $ISO_NEW_DIR/custom"
    if [ "$TEST_MODE" = "false" ]; then
      sudo rsync -av "$ISO_NEW_DIR/squashfs" "$ISO_NEW_DIR/custom"
    fi
  else
    handle_output "sudo rsync -a $ISO_NEW_DIR/squashfs/ $ISO_NEW_DIR/custom"
    if [ "$TEST_MODE" = "false" ]; then
      sudo rsync -a "$ISO_NEW_DIR/squashfs" "$ISO_NEW_DIR/custom"
    fi
  fi
  handle_output "sudo cp /etc/resolv.conf /etc/hosts $ISO_NEW_DIR/custom/etc/"
  if [ "$TEST_MODE" = "false" ]; then
    sudo cp /etc/resolv.conf /etc/hosts "$ISO_NEW_DIR/custom/etc"
  fi
}

# Function: Chroot into environment and run script on chrooted environmnet
#
# Examples:
# sudo chroot ./isonew/custom

execute_chroot_script () {
  handle_output "sudo chroot $ISO_NEW_DIR/custom /tmp/modify_chroot.sh"
  if [ "$TEST_MODE" = "false" ]; then
    sudo chroot "$ISO_NEW_DIR/custom /tmp/modify_chroot.sh"
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
    sudo mksquashfs "$ISO_NEW_DIR/custom" "$ISO_NEW_DIR/mksquash/filesystem.squashfs" -noappend
    sudo cp "$ISO_NEW_DIR/mksquash/filesystem.squashfs" "$NEW_SQUASHFS_FILE"
    sudo chmod 0444 i"$NEW_SQUASHFS_FILE"
    sudo echo -n $( sudo du -s --block-size=1 "$ISO_NEW_DIR/custom" | tail -1 | awk '{print $1}') | sudo tee "$ISO_NEW_DIR/mksquash/filesystem.size";
    sudo cp "$ISO_NEW_DIR/mksquash/filesystem.size" "$ISO_SOURCE_DIR/casper/filesystem.size"
    sudo chmod 0444 $ISO_SOURCE_DIR/casper/filesystem.size
    cd $ISO_SOURCE_DIR ; sudo find . -type f -print0 | xargs -0 md5sum | sed "s@${ISO_NEW_DIR}@.@" | grep -v md5sum.txt | sudo tee "$ISO_SOURCE_DIR/md5sum.txt"
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
        handle_output "echo \"        pin: \\\"release a=$ISO_CODENAME-security\\\"\" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
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
        handle_output "echo \"  package_update: $DO_INSTALL_ISO_UPDATE\" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
        handle_output "echo \"  package_upgrade: $DO_INSTALL_ISO_UPGRADE\" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
        handle_output "echo \"  drivers:\" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
        handle_output "echo \"    install: $ISO_INSTALL_DRIVERS\" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
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
        handle_output "echo \"      $ISO_NIC:\" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
        if [ "$ISO_DHCP" = "true" ]; then
          handle_output "echo \"        critical: true\" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
          handle_output "echo \"        dhcp-identifier: mac\" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
          handle_output "echo \"        dhcp4: $ISO_DHCP\" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
        else
          handle_output "echo \"        addresses:\" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
          handle_output "echo \"        - $ISO_IP/$ISO_CIDR\" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
          handle_output "echo \"        gateway4; $ISO_GATEWAY\" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
          handle_output "echo \"        nameservers:\" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
          handle_output "echo \"          addresses:\" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
          handle_output "echo \"          - $ISO_DNS\" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
        fi
        handle_output "echo \"    version: 2\" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
        handle_output "echo \"  ssh:\" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
        handle_output "echo \"    allow-pw: $ISO_ALLOW_PASSWORD\" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
        handle_output "echo \"    authorized-keys: [$ISO_SSH_KEY]\" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
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
          handle_output "echo \"      swap: $ISO_SWAPSIZE\" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
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
          echo "        pin: \"release a=$ISO_CODENAME-security\"" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data
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
          echo "  package_update: $DO_ISO_INSTALL_UPDATE" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data
          echo "  package_upgrade: $DO_INSTALL_ISO_UPGRADE" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data
          echo "  drivers:" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data
          echo "    install: $ISO_INSTALL_DRIVERS" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data
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
          if [ "$ISO_DHCP" = "true" ]; then
            echo "        critical: true" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data
            echo "        dhcp-identifier: mac" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data
            echo "        dhcp4: $ISO_DHCP" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data
          else
            echo "        addresses:" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data
            echo "        - $ISO_IP/$ISO_CIDR" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data
            echo "        gateway4: $ISO_GATEWAY" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data
            echo "        nameservers:" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data
            echo "          addresses:" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data
            echo "          - $ISO_DNS" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data
          fi
          echo "    version: 2" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data
          echo "  ssh:" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data
          echo "    allow-pw: $ISO_ALLOW_PASSWORD" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data
          echo "    authorized-keys: [$ISO_SSH_KEY]" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data
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
            echo "      swap: $ISO_SWAPSIZE" >> $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data
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
    -1|--bootserverfile)
      BOOT_SERVER_FILE="$2"
      DO_CUSTOM_BOOT_SERVER_FILE="true"
      shift 2
      ;;
    -2|--squashfsfile)
      ISO_SQUASHFS_FILE="$2"
      shift 2
      ;;
    -3|--grubfile)
      ISO_GRUB_FILE="$2"
      shift 2
      ;;
    -A|--codename)
      ISO_CODENAME="$2"
      shift 2
      ;;
    -a|--action)
      ACTION="$2"
      shift 2
      ;;
    -B|--layout)
      ISO_LAYOUT="$2"
      shift 2
      ;;
    -b|--bootserverip)
      BOOT_SERVER_IP="$2"
      shift 2
      ;;
    -C|--cidr)
      ISO_CIDR="$2"
      shift 2
      ;;
    -c|--sshkeyfile)
      ISO_SSH_KEY_FILE="$2"
      shift 2
      DO_ISO_SSH_KEY="true"
      shift
      ;;
    -D|--installdrivers)
      ISO_INSTALL_DRIVERS="true"
      shift
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
    -F|--bmcusername)
      BMC_USERNAME="$2"
      shift 2
      ;;
    -f|--delete)
      DELETE="$2"
      shift 2
      ;;
    -G|--gateway)
      ISO_GATEWAY="$2"
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
    -I|--ip)
      ISO_IP="$2"
      shift 2
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
    -l|--bmcip)
      BMC_IP="$2"
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
    -N|--dns)
      ISO_DNS="$2"
      shift 2
      ;;
    -n|--nic)
      ISO_NIC="$2"
      shift 2
      ;;
    -n|--nounmount)
      DO_NO_UNMOUNT_ISO="true";
      shift
      ;;
    -O|--isopackages)
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
    -p|--chrootpackages)
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
      ISO_ARCH=$( echo "$ISO_ARCH" |sed "s/aarch64/arm64/g" |sed "s/x86_64/amd64/g" )
      ;;
    -R|--realname)
      ISO_REALNAME="$2"
      shift 2
      ;;
    -r|--mode)
      MODE="$2"
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
      ISO_POSTINSTALL="$2"
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
    -X|--isovolid)
      ISO_VOLID="$2"
      shift 2
      ;;
    -x|--grubtimeout)
      ISO_GRUB_TIMEOUT="$2"
      shift 2
      ;;
    -Y|--allowpassword)
      ISO_ALLOW_PASSWORD="true"
      shift
      ;;
    -y|--bmcpassword)
      BMC_PASSWORD="$2"
      shift 2
      ;;
    -Z|--nounmount)
      DO_NO_UNMOUNT_ISO="true";
      shift
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

# Process action switch

case $ACTION in
  "checkracadm")
    DO_CHECK_RACADM="true"
    ;;
  "runracadm")
    DO_CHECK_RACADM="true"
    DO_EXECUTE_RACADM="true"
    ;;
  "createexport")
    DO_CHECK_WORK_DIR="true"
    DO_INSTALL_REQUIRED_PACKAGES="true"
    DO_CREATE_EXPORT="true"
    ;;
  "createansible")
    DO_CHECK_WORK_DIR="true"
    DO_INSTALL_REQUIRED_PACKAGES="true"
    DO_CREATE_ANSIBLE="true"
    ;;
  "runansible")
    DO_CHECK_WORK_DIR="true"
    DO_INSTALL_REQUIRED_PACKAGES="true"
    DO_CREATE_EXPORT="true"
    DO_CREATE_ANSIBLE="true"
    DO_INSTALL_SERVER="true"
    ;;
  "printenv")
    DO_PRINT_ENV="true"
    ;;
  "checkdocker")
    DO_DOCKER="false"
    DO_CHECK_DOCKER="true"
    DO_CHECK_WORK_DIR="true"
    ;;
  "getiso")
    DO_CHECK_WORK_DIR="true"
    DO_GET_BASE_ISO="true"
    ;;
  "installrequired"|"checkrequired")
    DO_INSTALL_REQUIRED_PACKAGES="true"
    ;;
  "checkdirs")
    DO_CHECK_WORK_DIR="true"
    ;;
  "justiso")
    DO_CREATE_AUTOINSTALL_ISO_ONLY="true"
    ;;
  "runchrootscript")
    DO_EXECUTE_ISO_CHROOT_SCRIPT="true"
    ;;
  "createiso")
    DO_CHECK_WORK_DIR="true"
    DO_INSTALL_REQUIRED_PACKAGES="true"
    DO_GET_BASE_PACKAGES="true"
    DO_PREPARE_ISO_AUTOINSTALL="true"
    DO_EXECUTE_ISO_CHROOT_SCRIPT="true"
    DO_CREATE_AUTOINSTALL_ISO_FULL="true"
    ;;
  "createisoandsquashfs")
    DO_ISO_SQUASHFS_UPDATE="true"
    DO_CHECK_WORK_DIR="true"
    DO_INSTALL_REQUIRED_PACKAGES="true"
    DO_GET_BASE_PACKAGES="true"
    DO_PREPARE_ISO_AUTOINSTALL="true"
    DO_EXECUTE_ISO_CHROOT_SCRIPT="true"
    DO_CREATE_AUTOINSTALL_ISO_FULL="true"
   ;; 
  "createdockeriso")
    DO_DOCKER="true"
    DO_CHECK_DOCKER="true"
    DO_CHECK_WORK_DIR="true"
    DO_INSTALL_REQUIRED_PACKAGES="true"
    DO_GET_BASE_PACKAGES="true"
    DO_PREPARE_ISO_AUTOINSTALL="true"
    DO_EXECUTE_ISO_CHROOT_SCRIPT="true"
    DO_CREATE_AUTOINSTALL_ISO_FULL="true"
    ;;
  "createdockerisoandsquashfs")
    DO_ISO_SQUASHFS_UPDATE="true"
    DO_DOCKER="true"
    DO_CHECK_DOCKER="true"
    DO_CHECK_WORK_DIR="true"
    DO_INSTALL_REQUIRED_PACKAGES="true"
    DO_GET_BASE_PACKAGES="true"
    DO_PREPARE_ISO_AUTOINSTALL="true"
    DO_EXECUTE_ISO_CHROOT_SCRIPT="true"
    DO_CREATE_AUTOINSTALL_ISO_FULL="true"
    ;;
  "queryiso")
    DO_ISO_QUERY="true"
    ;;
  "unmount")
    DO_UMOUNT_ISO="true"
    ;;
  *)
    handle_output "Action: $ACTION is not a valid action"
    exit
    ;;
esac

# Process postinstall switch

case $ISO_POSTINSTALL in
  "distupgrade"|"dist-upgrade")
    DO_INSTALL_ISO_DIST_UPGRADE="true"
    ;;
  "packages")
    DO_INSTALL_ISO_PACKAGES="true"
    ;;
  "updates"|"upgrades")
    DO_INSTALL_ISO_UPDATE="true"
    DO_INSTALL_ISO_UPGRADE="true"
    ;;
  *)
    DO_INSTALL_ISO_PACKAGES="true"
    ;;
esac

# Mode: interactive or defaults

case $MODE in 
  "defaults")
    DEFAULTS_MODE="true"
    ;;
  "interactive")
    INTERACTIVE_MODE="true"
    ;;
  *)
    DEFAULTS_MODE="true"
    ;;
esac

# Delete files

case $DELETE in
  "files")
    FORCE_MODE="true"
    ;;
  "all")
    FULL_FORCE_MODE="true"
    ;;
  *)
    FORCE_MODE="false"
    FULL_FORCE_MODE="false"
esac

if [ "$ISO_ARCH" = "" ]; then
  ISO_ARCH="$DEFAULT_ISO_ARCH"
  DOCKER_ARCH="$DEFAULT_DOCKER_ARCH"
else
  DOCKER_ARCH="$ISO_ARCH"
fi
if [ "$ISO_SSH_KEY_FILE" = "" ]; then
  ISO_SSH_KEY_FILE="$DEFAULT_ISO_SSH_KEY_FILE"
else
  ISO_SSH_KEY="$DEFAULT_ISO_SSH_KEY"
fi
if [ "$BOOT_SERVER_IP" = "" ]; then
  BOOT_SERVER_IP="$DEFAULT_BOOT_SERVER_IP"
fi
if [ "$BOOT_SERVER_FILE" = "" ]; then
  BOOT_SERVER_FILE="$DEFAULT_BOOT_SERVER_FILE"
fi
if [ "$BMC_USERNAME" = "" ]; then
  BMC_USERNAME="$DEFAULT_BMC_USERNAME"
fi
if [ "$BMC_PASSWORD" = "" ]; then
  BMC_PASSWORD="$DEFAULT_BMC_PASSWORD"
fi
if [ "$BMC_IP" = "" ]; then
  BMC_IP="$DEFAULT_BMC_IP"
fi
if [ "$ISO_CIDR" = "" ]; then
  ISO_CIDR="$DEFAULT_ISO_CIDR"
fi
if [ "$ISO_INSTALL_DRIVERS" = "" ]; then
  ISO_INSTALL_DRIVERS="$DEFAULT_ISO_INSTALL_DRIVERS"
fi
if [ "$ISO_RELEASE" = "" ]; then
  ISO_RELEASE="$DEFAULT_ISO_RELEASE"
fi
ISO_MAJOR_REL=$(echo $ISO_RELEASE |cut -f1 -d.)
if [ "$ISO_USERNAME" = "" ]; then
  ISO_USERNAME="$DEFAULT_ISO_USERNAME"
fi
if [ "$ISO_REALNAME" = "" ]; then
  ISO_REALNAME="$DEFAULT_ISO_REALNAME"
fi
if [ "$ISO_HOSTNAME" = "" ]; then
  ISO_HOSTNAME="$DEFAULT_ISO_HOSTNAME"
fi
if [ "$ISO_GATEWAY" = "" ]; then
  ISO_GATEWAY="$DEFAULT_ISO_GATEWAY"
fi
if [ "$ISO_DNS" = "" ]; then
  ISO_DNS="$DEFAULT_ISO_DNS"
fi
if [ "$ISO_IP" = "" ]; then
  ISO_IP="$DEFAULT_ISO_IP"
fi
if [ "$ISO_ALLOW_PASSWORD" = "" ]; then
  ISO_ALLOW_PASSWORD="$DEFAULT_ISO_ALLOW_PASSWORD"
fi
if [ "$ISO_PASSWORD" = "" ]; then
  ISO_PASSWORD="$DEFAULT_ISO_PASSWORD"
fi
if [ "$ISO_CHROOT_PACKAGES" = "" ]; then
  ISO_CHROOT_PACKAGES="$DEFAULT_ISO_PACKAGES"
fi
if [ "$ISO_INSTALL_PACKAGES" = "" ]; then
  ISO_INSTALL_PACKAGES="$DEFAULT_ISO_PACKAGES"
fi
if [ "$ISO_TIMEZONE" = "" ]; then
  ISO_TIMEZONE="$DEFAULT_ISO_TIMEZONE"
fi
if [ "$OUTPUT_FILE" = "" ]; then
  OUTPUT_FILE="$DEFAULT_OUTPUT_FILE"
fi
if [ "$ISO_NIC" = "" ]; then
  ISO_NIC="$DEFAULT_ISO_NIC"
fi
if [ "$SWAPSIZE" = "" ]; then
  ISO_SWAPSIZE="$DEFAULT_ISO_SWAPSIZE"
fi
if [ "$ISO_DEVICES" = "" ]; then
  ISO_DEVICES="$DEFAULT_ISO_DEVICES"
fi
if [ "$ISO_VOLMGRS" = "" ]; then
  ISO_VOLMGRS="$DEFAULT_ISO_VOLMGRS"
fi
if [ "$GRUB_MENU" = "" ]; then
  ISO_GRUB_MENU="$DEFAULT_ISO_GRUB_MENU"
fi
if [ "$GRUB_TIMEOUT" = "" ]; then
  ISO_GRUB_TIMEOUT="$DEFAULT_ISO_GRUB_TIMEOUT"
fi
if [ "$ISO_KERNEL_ARGS" = "" ]; then
  ISO_KERNEL_ARGS="$DEFAULT_ISO_KERNEL_ARGS"
fi
if [ "$ISO_KERNEL" = "" ]; then
  ISO_KERNEL="$DEFAULT_ISO_KERNEL"
fi
if [ "$CODENAME" = "" ]; then
  ISO_CODENAME="$DEFAULT_ISO_CODENAME"
fi
if [ "$ISO_LOCALE" = "" ]; then
  ISO_LOCALE="$DEFAULT_ISO_LOCALE"
fi
if [ "$ISO_LC_ALL" = "" ]; then
  ISO_LC_ALL="$DEFAULT_ISO_LC_ALL"
fi
if [ "$ISO_LAYOUT" = "" ]; then
  ISO_LAYOUT="$DEFAULT_ISO_LAYOUT"
fi
if [ "$ISO_VOLID" = "" ]; then
  ISO_VOLID="$DEFAULT_ISO_VOLID"
fi
if [ "$ISO_INSTALL_MOUNT" = "" ]; then
  ISO_INSTALL_MOUNT="$DEFAULT_ISO_INSTALL_MOUNT"
fi
if [ "$ISO_TARGET_MOUNT" = "" ]; then
  ISO_TARGET_MOUNT="$DEFAULT_ISO_TARGET_MOUNT"
fi
if [ "$ISO_AUTOINSTALL_DIR" = "" ]; then
  ISO_AUTOINSTALL_DIR="$DEFAULT_ISO_AUTOINSTALL_DIR"
fi
if [ "$WORK_DIR" = "" ]; then 
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
if [ "$ISO_BUILD_TYPE" = "" ]; then
  ISO_BUILD_TYPE="$DEFAULT_ISO_BUILD_TYPE"
fi
if [ "$INPUT_FILE" = "" ]; then
  INPUT_FILE="$DEFAULT_INPUT_FILE"
fi
if [ "$DO_ISO_QUERY" = "true" ]; then
  get_info_from_iso
else
  if [ "$DO_CUSTOM_BOOT_SERVER_FILE" = "false" ]; then
    case $ISO_BUILD_TYPE in
      "daily-live"|"daily-live-server")
        INPUT_FILE="$WORK_DIR/files/$ISO_CODENAME-live-server-$ISO_ARCH.iso"
        OUTPUT_FILE="$WORK_DIR/files/$ISO_CODENAME-live-server-$ISO_ARCH-autoinstall.iso"
        BOOT_SERVER_FILE="$OUTPUT_FILE"
        ;;
      "daily-desktop")
        INPUT_FILE="$WORK_DIR/files/$ISO_CODENAME-desktop-$ISO_ARCH.iso"
        OUTPUT_FILE="$WORK_DIR/files/$ISO_CODENAME-desktop-$ISO_ARCH-autoinstall.iso"
        BOOT_SERVER_FILE="$OUTPUT_FILE"
        ;;
      "desktop")
        INPUT_FILE="$WORK_DIR/files/ubuntu-$ISO_RELEASE-desktop-$ISO_ARCH.iso"
        OUTPUT_FILE="$WORK_DIR/files/ubuntu-$ISO_RELEASE-desktop-$ISO_ARCH-autoinstall.iso"
        BOOT_SERVER_FILE="$OUTPUT_FILE"
        ;;
      *)
        INPUT_FILE="$WORK_DIR/files/ubuntu-$ISO_RELEASE-live-server-$ISO_ARCH.iso"
        OUTPUT_FILE="$WORK_DIR/files/ubuntu-$ISO_RELEASE-live-server-$ISO_ARCH-autoinstall.iso"
        BOOT_SERVER_FILE="$OUTPUT_FILE"
        ;;
    esac 
  fi
fi
if [ "$ISO_SQUASHFS_FILE" = "" ]; then
  ISO_SQUASHFS_FILE="$DEFAULT_ISO_SQUASHFS_FILE"
fi
if [ "$ISO_GRUB_FILE" = "" ]; then
  ISO_GRUB_FILE="$DEFAULT_ISO_GRUB_FILE"
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
      ISO_URL="https://releases.ubuntu.com/$URL_RELEASE/$BASE_INPUT_FILE"
    else
      ISO_URL="https://cdimage.ubuntu.com/releases/$ISO_RELEASE/release/$BASE_INPUT_FILE"
    fi
    ;;
esac

# Output variables

if [ "$DO_PRINT_ENV" ] || [ "$INTERACTIVE_MODE" = "true" ]; then
  TEMP_VERBOSE_MODE="true"
fi

handle_output "# Setting Variables" TEXT
handle_output "# Release:              $ISO_RELEASE" TEXT
handle_output "# Codename:             $ISO_CODENAME" TEXT
handle_output "# Architecture:         $ISO_ARCH" TEXT
handle_output "# Work directory:       $WORK_DIR" TEXT
handle_output "# Required packages:    $REQUIRED_PACKAGES" TEXT
handle_output "# ISO input file:       $INPUT_FILE" TEXT
handle_output "# ISO output file:      $OUTPUT_FILE" TEXT
handle_output "# ISO URL:              $ISO_URL" TEXT
handle_output "# ISO Volume ID:        $ISO_VOLID" TEXT
handle_output "# Hostname:             $ISO_HOSTNAME" TEXT
handle_output "# Username:             $ISO_USERNAME" TEXT
handle_output "# Realname:             $ISO_REALNAME" TEXT
handle_output "# Timezone:             $ISO_TIMEZONE" TEXT
handle_output "# NIC:                  $ISO_NIC" TEXT
handle_output "# DHCP:                 $ISO_DHCP" TEXT
if [ "$ISO_DHCP" = "false" ]; then
  handle_output "# IP:                   $ISO_IP/$ISO_CIDR" TEXT
  handle_output "# Gateway:              $ISO_GATEWAY" TEXT
  handle_output "# Nameservers:          $ISO_DNS" TEXT
fi
handle_output "# Kernel:               $ISO_KERNEL" TEXT
handle_output "# Kernel arguments:     $ISO_KERNEL_ARGS" TEXT
handle_output "# Keyboard Layout:      $ISO_LAYOUT" TEXT
handle_output "# Locale:               $ISO_LOCALE" TEXT
handle_output "# LC_ALL:               $ISO_LC_ALL" TEXT
handle_output "# Root disk(s):         $ISO_DEVICES" TEXT
handle_output "# Volme Manager(s):     $ISO_VOLMGRS" TEXT
handle_output "# GRUB Menu:            $ISO_GRUB_MENU" TEXT
handle_output "# GRUB Timeout:         $ISO_GRUB_TIMEOUT" TEXT
handle_output "# AI Directory:         $ISO_AUTOINSTALL_DIR" TEXT
handle_output "# Install mount:        $ISO_INSTALL_MOUNT" TEXT
handle_output "# Install target:       $ISO_TARGET_MOUNT" TEXT
handle_output "# Recreate squashfs:    $DO_ISO_SQUASHFS_UPDATE" TEXT
handle_output "# Squashfs packages:    $ISO_CHROOT_PACKAGES" TEXT
handle_output "# Additional packages:  $ISO_INSTALL_PACKAGES" TEXT
handle_output "# Install packages:     $DO_INSTALL_ISO_PACKAGES" TEXT
handle_output "# Install updates:      $DO_INSTALL_ISO_UPDATE" TEXT
handle_output "# Install upgrades:     $DO_INSTALL_ISO_UPGRADE" TEXT
handle_output "# Dist upgrades:        $DO_INSTALL_ISO_DIST_UPGRADE" TEXT
handle_output "# Swap size:            $ISO_SWAPSIZE" TEXT
if [ "$DO_CREATE_EXPORT" = "true" ] || [ "$DO_CREATE_ANSIBLE" = "true" ]; then
  handle_output "# Bootserver IP:        $BOOT_SERVER_IP" TEXT
  handle_output "# Bootserver file:      $BOOT_SERVER_FILE" TEXT
fi
if [ "$DO_CREATE_ANSIBLE" = "true" ] ; then
  handle_output "# BMC IP:               $BMC_IP" TEXT
  handle_output "# BMC Username:         $BMC_USERNAME" TEXT
  handle_output "# BMC Password:         $BMC_PASSWORD" TEXT
fi

if [ "$DO_PRINT_ENV" = "true" ] || [ "$INTERACTIVE_MODE" = "true" ]; then
  TEMP_VERBOSE_MODE="false"
fi

if [ "$DO_PRINT_ENV" = "true" ]; then
  exit
fi

# Exit if we're just printing environment variables

# If run in interactive mode ask for values for required parameters
# Set any unset values to defaults

if [ "$INTERACTIVE_MODE" = "true" ]; then
  if [ "$DO_CREATE_EXPORT" = "true" ] || [ "$DO_CREATE_ANSIBLE" = "true" ]; then
    if [ "$DO_CREATE_EXPORT" = "true" ] || [ "$DO_CREATE_ANSIBLE" = "true" ]; then
      # Get bootserver IP
      read -p "Enter Bootserver IP [$BOOT_SERVER_IP]: " NEW_BOOT_SERVER_IP
      BOOT_SERVER_IP=${NEW_BOOT_SERVER_IP:-$BOOT_SERVER_IP}
      # Get bootserver file 
      read -p "Enter Bootserver file [$BOOT_SERVER_FILE]: " NEW_BOOT_SERVER_FILE
      BOOT_SERVER_FILE=${NEW_BOOT_SERVER_FILE:-$BOOT_SERVER_FILE}
    fi
    if [ "$DO_CREATE_ANSIBLE" = "true" ]; then
      # Get BMC IP
      read -p "Enter BMC/iDRAC IP [$BMC_IP]: " NEW_BMC_IP
      BMC_IP=${NEW_BMC_IP:-$BMC_IP}
      # Get BMC Username 
      read -p "Enter BMC/iDRAC Username [$BMC_USERNAME]: " NEW_BMC_USERNAME
      BMC_USERNAME=${NEW_BMC_USERNAME:-$BMC_USERNAME}
      # Get BMC Password
      read -p "Enter BMC/iDRAC Password [$BMC_PASSWORD]: " NEW_BMC_PASSWORD
      BMC_PASSWORD=${NEW_BMC_PASSWORD:-$BMC_PASSWORD}
    fi
  else
    # Get release
    read -p "Enter Release [$ISO_RELEASE]: " NEW_ISO_RELEASE
    ISO_RELEASE=${NEW_ISO_RELEASE:-$ISO_RELEASE}
    # Get codename
    read -p "Enter Codename [$ISO_CODENAME: " NEW_ISO_CODENAME
    ISO_CODENAME=${NEW_ISO_CODENAME:-$ISO_CODENAME}
    # Get Architecture
    read -p "Architecture [$ISO_ARCH]: "
    ISO_ARCH=${NEW_ISO_ARCH:-$ISO_ARCH}
    # Get Work directory
    read -p "Enter Work directory [$WORK_DIR]: " NEW_WORK_DIR
    WORK_DIR=${NEW_WORK_DIR:-$WORK_DIR}
    # Get ISO input file
    read -p "Enter ISO input file [$INPUT_FILE]: " NEW_INPUT_FILE
    INPUT_FILE=${NEW_INPUT_FILE:-$INPUT_FILE}
    # Get output file
    read -p "Enter ISO output file [$OUTPUT_FILE]: " NEW_OUTPUT_FILE
    OUTPUT_FILE=${NEW_OUTPUT_FILE:-$OUTPUT_FILE}
    # Get ISO URL
    read -p "Enter ISO URL [$ISO_URL]: " NEW_ISO_URL
    ISO_URL=${NEW_ISO_URL:-$ISO_URL}
    # Get ISO Volume ID
    read -p "Enter ISO Volume ID [$ISO_VOLID]: " NEW_ISO_VOLID
    ISO_VOLID=${NEW_ISO_VOLID:-$ISO_VOLID}
    # Get Hostname
    read -p "Enter Hostname[$ISO_HOSTNAME]: " NEW_ISO_HOSTNAME
    ISO_HOSTNAME=${NEW_ISO_HOSTNAME:-$ISO_HOSTNAME}
    # Get Username
    read -p "Enter Username [$ISO_USERNAME]: " NEW_ISO_USERNAME
    ISO_USERNAME=${NEW_ISO_USERNAME:-$ISO_USERNAME}
    # Get User Real NAme
    read -p "Enter User Realname [$ISO_REALNAME]: " NEW_ISO_REALNAME
    ISO_REALNAME=${NEW_ISO_REALNAME:-$ISO_REALNAME}
    # Get Password
    read -s -p "Enter password [$ISO_PASSWORD]: " NEW_ISO_PASSWORD
    ISO_PASSWORD=${NEW_ISO_PASSWORD:-$ISO_PASSWORD}
    # Get wether to allow SSH Password
    read -s -p "Allow SSH access with password [$ISO_ALLOW_PASSWORD]: " NEW_ISO_ALLOW_PASSWORD
    ISO_ALLOW_PASSWORD=${NEW_ISO_ALLOW_PASSWORD:-$ISO_ALLOW_PASSWORD}
    # Get Timezone
    read -p "Enter Timezone: " NEW_ISO_TIMEZONE
    ISO_TIMEZONE=${NEW_ISO_TIMEZONE:-$ISO_TIMEZONE}
    # Get NIC
    read -p "Enter NIC [$ISO_NIC]: " NEW_ISO_NIC
    ISO_NIC=${NEW_ISO_NIC:-$ISO_NIC}
    # Get DHCP
    read -p "Use DHCP? [$ISO_DHCP]: " NEW_ISO_DHCP
    ISO_DHCP=${NEW_ISO_DHCP:-$ISO_DHCP}
    # Get Static IP information if no DHCP
    if [ "$ISO_DHCP" = "false" ]; then
      # Get IP
      read -p "Enter IP [$ISO_IP]: " NEW_ISO_IP
      ISO_IP=${NEW_ISO_IP:-$ISO_IP}
      # Get CIDR 
      read -p "Enter CIDR [$ISO_CIDR]: " NEW_ISO_CIDR
      ISO_CIDR=${NEW_ISO_CIDR:-$ISO_CIDR}
      # Get Geteway 
      read -p "Enter Gateway [$ISO_GATEWAY]: " NEW_ISO_GATEWAY
      ISO_GATEWAY=${NEW_ISO_GATEWAY:-$ISO_GATEWAY}
      # Get DNS
      read -p "Enter DNS [$ISO_DNS]: " NEW_ISO_DNS
      ISO_DNS=${NEW_ISO_DNS:-$ISO_DNS}
    fi
    # Get Kernel
    read -p "Enter Kernel [$ISO_KERNEL]: " NEW_ISO_KERNEL
    ISO_KERNEL=${NEW_ISO_KERNEL:-$ISO_KERNEL}
    # Get Kernel Arguments
    read -p "Enter Kernel Arguments [$ISO_KERNEL_ARGS]: " NEW_ISO_KERNEL_ARGS
    ISO_KERNEL_ARGS=${NEW_ISO_KERNEL_ARGS:-$ISO_KERNEL_ARGS}
    # Get Keyboard Layout
    read -p "Enter IP [$ISO_LAYOUT]: " NEW_ISO_LAYOUT
    ISO_LAYOUT=${NEW_ISO_LAYOUT:-$ISO_LAYOUT}
    # Get Locale
    read -p "Enter IP [$ISO_LOCALE]: " NEW_ISO_LOCALE
    ISO_LOCALE=${NEW_ISO_LOCALE:-$ISO_LOCALE}
    # Get LC _ALL
    read -p "Enter LC_ALL [$ISO_LC_ALL]: " NEW_ISO_LC_ALL
    ISO_LC_ALL=${NEW_ISO_LC_ALL:-$ISO_LC_ALL}
    # Get Root Disk(s) 
    read -p "Enter Root Disk(s) [$ISO_DEVICES]: " NEW_ISO_DEVICES
    ISO_DEVICES=${NEW_ISO_DEVICES:-$ISO_DEVICES}
    # Get Volume Managers 
    read -p "Enter Volume Manager(s) [$ISO_VOLMGRS]: " NEW_ISO_VOLMGRS
    ISO_VOLMGRS=${NEW_ISO_VOLMGRS:-$ISO_VOLMGRS}
    # Get Default Grub Menu selection
    read -p "Enter Default Grub Menu [$ISO_GRUB_MENU]: " NEW_ISO_GRUB_MENU
    ISO_GRUB_MENU=${NEW_ISO_GRUB_MENU:-$ISO_GRUB_MENU}
    # Get Grub Timeout
    read -p "Enter Grub Timeout [$ISO_GRUB_TIMEOUT]: " NEW_ISO_GRUB_TIMEOUT
    ISO_GRUB_TIMEOUT=${NEW_ISO_GRUB_TIMEOUT:-$ISO_GRUB_TIMEOUT}
    # Get Autoinstall directory 
    read -p "Enter Auttoinstall Directory [$ISO_AUTOINSTALL_DIR]: " NEW_ISO_AUTOINSTALL_DIR
    ISO_AUTOINSTALL_DIR=${NEW_ISO_AUTOINSTALL_DIR:-$ISO_AUTOINSTALL_DIR}
    # Get Install Mount
    read -p "Enter Install Mount [$ISO_INSTALL_MOUNT]: " NEW_ISO_INSTALL_MOUNT
    ISO_INSTALL_MOUNT=${NEW_ISO_INSTALL_MOUNT:-$ISO_INSTALL_MOUNT}
    # Get Install Target
    read -p "Enter Install Target [$ISO_TARGET_MOUNT]: " NEW_ISO_TARGET_MOUNT
    ISO_TARGET_MOUNT=${NEW_ISO_TARGET_MOUNT:-$ISO_TARGET_MOUNT}
    # Get whether to do squashfs
    read -p "Recreate squashfs? [$DO_ISO_SQUASHFS_UPDATE]: " NEW_DO_ISO_SQUASHFS_UPDATE
    DO_ISO_SQUASHFS_UPDATE=${NEW_DO_ISO_SQUASHFS_UPDATE:-$DO_ISO_SQUASHFS_UPDATE}
    if  [ "$DO_ISO_SQUASHFS_UPDATE" = "true" ]; then
      # Get squashfs packages
      read -p "Enter Squashfs Packages [$ISO_CHROOT_PACKAGEP]: " NEW_ISO_CHROOT_PACKAGE
      ISO_CHROOT_PACKAGE=${NEW_ISO_CHROOT_PACKAGE:-$IISO_CHROOT_PACKAGE}
    fi
    # Get whether to install packages as part of install
    read -p "Install additional packages [$DO_INSTALL_ISO_PACKAGES]: " NEW_DO_INSTALL_ISO_PACKAGES
    DO_INSTALL_ISO_PACKAGES=${NEW_DO_INSTALL_ISO_PACKAGES:-$DO_INSTALL_ISO_PACKAGES}
    if [ "$DO_INSTALL_ISO_PACKAGES" = "true" ]; then
      # Get IP
      read -p "Enter Additional Packages to install[$ISO_INSTALL_PACKAGES]: " NEW_ISO_INSTALL_PACKAGES
      ISO_INSTALL_PACKAGES=${NEW_ISO_INSTALL_PACKAGES:-$ISO_INSTALL_PACKAGES}
    fi
    # Get whether to install updates
    read -p "Install updates? [$DO_INSTALL_ISO_UPDATE]: " NEW_DO_INSTALL_ISO_UPDATE
    DO_INSTALL_ISO_UPDATE=${NEW_DO_INSTALL_ISO_UPDATEP:-$DO_INSTALL_ISO_UPDATE}
    if [ "$DO_INSTALL_ISO_UPDATE" = "true" ]; then
      # Get wether to install upgrades 
      read -p "Upgrade packages? [$DO_INSTALL_ISO_UPGRADE]: " NEW_DO_INSTALL_ISO_UPGRADE
      DO_INSTALL_ISO_UPGRADE=${NEW_DO_INSTALL_ISO_UPGRADE:-$DO_INSTALL_ISO_UPGRADE}
      # Get whether to do a dist-updrage
      read -p "Install Distribution Upgrade if available (e.g. 20.04.4 -> 20.04.5)? [$DO_INSTALL_ISO_DIST_UPGRADE]: " NEW_DO_INSTALL_ISO_DIST_UPGRADE
      DO_INSTALL_ISO_DIST_UPGRADE=${NEW_DO_INSTALL_ISO_DIST_UPGRADE:-$DO_INSTALL_ISO_DIST_UPGRADE}
    fi
    # Get swap size 
    read -p "Enter Swap Size [$ISO_SWAPSIZE]: " NEW_ISO_SWAPSIZE
    ISO_SWAPSIZE=${NEW_ISO_SWAPSIZE:-$ISO_SWAPSIZE}
    # Determine wether we use an SSH key
    read -p "Use SSH keys? [$DO_ISO_SSH_KEY]: " NEW_DO_ISO_SSH_KEY
    DO_ISO_SSH_KEY=${NEW_DO_ISO_SSH_KEY:-$DO_ISO_SSH_KEY}
    if [ "$DO_ISO_SSH_KEY" = "true" ]; then
      # Determine wether we use an SSH key
      read -p "SSH keys file [$ISO_SSH_KEY_FILE]: " NEW_ISO_SSH_KEY_FILE
      ISO_SSH_KEY_FILE=${NEW_ISO_SSH_KEY_FILE:-$ISO_SSH_KEY_FILE}
    fi
    # Get wether to install drivers 
    read -p "Enter Swap Size [$ISO_INSTALL_DRIVERS]: " NEW_ISO_INSTALL_DRIVERS
    ISO_INSTALL_DRIVERS=${NEW_ISO_INSTALL_DRIVERS:-$ISO_INSTALL_DRIVERS}
  fi
fi

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

# Get SSH key

if [ "$DO_ISO_SSH_KEY" = "true" ]; then
  if ! [ -f "$ISO_SSH_KEY_FILE" ]; then
    echo "SSH Key file ($ISO_SSH_KEY_FILE) does not exist"
  else
    ISO_SSH_KEY=$(cat $ISO_SSH_KEY_FILE)
  fi
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

if [ "$DO_CHECK_RACADM" = "true" ]; then
  check_racadm
  exit
fi
if [ "$DO_EXECUTE_RACADM" = "true" ]; then
  check_racadm
  execute_racadm
  exit
fi
if [ "$DO_CHECK_WORK_DIR" = "true" ]; then
  DO_PRINT_HELP="false"
  check_work_dir
fi
if [ "$DO_INSTALL_REQUIRED_PACKAGES" = "true" ]; then
  DO_PRINT_HELP="false"
  install_required_packages
fi
if [ "$DO_CREATE_EXPORT" = "true" ]; then
  create_export
fi
if [ "$DO_CREATE_ANSIBLE" = "true" ]; then
  check_ansible
  create_ansible
fi
if [ "$DO_INSTALL_SERVER" = "true" ]; then
  install_server
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
