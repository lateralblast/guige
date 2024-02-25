#!/usr/bin/env bash

# Name:         guige (Generic Ubuntu/Unix ISO Generation Engine)
# Version:      1.9.4
# Release:      1
# License:      CC-BA (Creative Commons By Attribution)
#               http://creativecommons.org/licenses/by/4.0/legalcode
# Group:        System
# Source:       N/A
# URL:          http://lateralblast.com.au/
# Distribution: Ubuntu Linux
# Vendor:       UNIX
# Packager:     Richard Spindler <richard@lateralblast.com.au>
# Description:  Shell script designed to simplify creation of custom Ubuntu Install ISOs

# shellcheck disable=SC2129

SCRIPT_ARGS="$*"
SCRIPT_FILE="$0"
SCRIPT_NAME="guige"
START_PATH=$( pwd )
SCRIPT_BIN=$( basename "$0" |sed "s/^\.\///g")
SCRIPT_FILE="$START_PATH/$SCRIPT_BIN"
SCRIPT_VERSION=$( grep '^# Version' < "$0" | awk '{print $3}' )
OS_NAME=$( uname )
OS_ARCH=$( uname -m |sed "s/aarch64/arm64/g" |sed "s/x86_64/amd64/g")
OS_USER="$USER"
MY_USERNAME=$(whoami)

# Function: set_defaults 
# 
# Set defaults

set_defaults () {
  CURRENT_ISO_RELEASE_1404="14.04.6"
  CURRENT_ISO_RELEASE_1604="16.04.7"
  CURRENT_ISO_RELEASE_1804="18.04.6"
  CURRENT_ISO_RELEASE_2004="20.04.6"
  CURRENT_ISO_RELEASE_2204="22.04.3"
  CURRENT_ISO_RELEASE_2210="22.10"
  CURRENT_ISO_RELEASE_2304="23.04"
  CURRENT_ISO_RELEASE_2310="23.10.1"
  CURRENT_ISO_RELEASE_2404="24.04"
  CURRENT_ISO_RELEASE="22.04.3"
  CURRENT_OLD_ISO_RELEASE="23.04"
  CURRENT_ISO_DEV_RELEASE="24.04"
  CURRENT_ISO_OS_NAME="ubuntu"
  CURRENT_DOCKER_UBUNTU_RELEASE="22.04"
  CURRENT_ISO_CODENAME="jammy"
  CURRENT_ISO_ARCH="amd64"
  DEFAULT_ISO_HOSTNAME="ubuntu"
  DEFAULT_ISO_REALNAME="Ubuntu"
  DEFAULT_ISO_USERNAME="ubuntu"
  DEFAULT_ISO_TIMEZONE="Australia/Melbourne"
  DEFAULT_ISO_PASSWORD="ubuntu"
  DEFAULT_ISO_KERNEL="linux-generic"
  DEFAULT_ISO_NIC="first-net"
  DEFAULT_ISO_IP="192.168.1.2"
  DEFAULT_ISO_DNS="8.8.8.8"
  DEFAULT_ISO_CIDR="24"
  DEFAULT_ISO_BLOCKLIST=""
  DEFAULT_ISO_ALLOWLIST=""
  DEFAULT_ISO_GATEWAY="192.168.1.254"
  DEFAULT_ISO_SWAPSIZE="2G"
  DEFAULT_ISO_DEVICES="first-disk"
  DEFAULT_ISO_VOLMGRS="zfs lvm xfs btrfs"
  DEFAULT_ISO_GRUB_MENU="0"
  DEFAULT_ISO_GRUB_TIMEOUT="10"
  DEFAULT_ISO_LOCALE="en_US.UTF-8"
  DEFAULT_ISO_LC_ALL="en_US"
  DEFAULT_ISO_LAYOUT="us"
  DEFAULT_ISO_COUNTRY="us"
  DEFAULT_ISO_BUILD_TYPE="live-server"
  DEFAULT_ISO_BOOT_TYPE="efi"
  DEFAULT_ISO_SERIAL_PORT0="ttyS0"
  DEFAULT_ISO_SERIAL_PORT_ADDRESS0="0x03f8"
  DEFAULT_ISO_SERIAL_PORT_SPEED0="115200"
  DEFAULT_ISO_SERIAL_PORT1="ttyS1"
  DEFAULT_ISO_SERIAL_PORT_ADDRESS1="0x02f8"
  DEFAULT_ISO_SERIAL_PORT_SPEED1="115200"
  DEFAULT_ISO_INSTALL_PACKAGES="zfsutils-linux zfs-initramfs net-tools curl lftp wget sudo file rsync dialog setserial ansible apt-utils whois squashfs-tools duperemove"
  REQUIRED_PACKAGES="p7zip-full lftp wget xorriso whois squashfs-tools sudo file rsync net-tools nfs-kernel-server ansible dialog apt-utils"
  DEFAULT_DOCKER_ARCH="amd64 arm64"
  DEFAULT_ISO_SSH_KEY_FILE="$HOME/.ssh/id_rsa.pub"
  MASKED_DEFAULT_ISO_SSH_KEY_FILE="$HOME/.ssh/id_rsa.pub"
  DEFAULT_ISO_SSH_KEY=""
  DEFAULT_ISO_ALLOW_PASSWORD="false"
  DEFAULT_BMC_USERNAME="root"
  DEFAULT_BMC_PASSWORD="calvin"
  DEFAULT_BMC_IP="192.168.1.3"
  DEFAULT_ISO_KERNEL_ARGS="console=tty0 console=vt0"
  DEFAULT_ISO_SEARCH=""
  DEFAULT_ISO_DPKG_CONF="--force-confnew"
  DEFAULT_ISO_DPKG_OVERWRITE="--force-overwrite"
  DEFAULT_ISO_DPKG_DEPENDS="--force-depends"
  DEFAULT_VM_TYPE="kvm"
  DEFAULT_VM_RAM="2048000"
  DEFAULT_VM_CPUS="2"
  DEFAULT_VM_SIZE="20G"
  DEFAULT_VM_NIC="default"
  DEFAULT_ZFS_FILESYSTEMS="/var /var/lib /var/lib/AccountsService /var/lib/apt /var/lib/dpkg /var/lib/NetworkManager /srv /usr /usr/local /var/games /var/log /var/mail /var/snap /var/spool /var/www"
  VM_EXISTS="false"
  ISO_DHCP="true"
  TEST_MODE="false"
  FORCE_MODE="false"
  FULL_FORCE_MODE="false"
  VERBOSE_MODE="false"
  TEMP_VERBOSE_MODE="false"
  INTERACTIVE_MODE="false"
  ISO_USE_BIOSDEVNAME="false"
  ISO_PREFIX=""
  ISO_SUFFIX=""
  BMC_PORT="443"
  BMC_EXPOSE_DURATION="180"
}

# Function: reset_defaults 
# 
# Reset defaults

reset_defaults () {
  if [[ "$ISO_CODENAME" =~ "rocky" ]]; then
    CURRENT_ISO_RELEASE="9.3"
    CURRENT_ISO_OS_NAME="rocky"
    DEFAULT_ISO_HOSTNAME="rocky"
    DEFAULT_ISO_REALNAME="Rocky"
    DEFAULT_ISO_USERNAME="rocky"
    DEFAULT_ISO_PASSWORD="rocky"
    DEFAULT_WORK_DIR="$HOME/$SCRIPT_NAME/$DEFAULT_ISO_OS_NAME/$DEFAULT_ISO_RELEASE"
    DEFAULT_ISO_MOUNT_DIR="$DEFAULT_WORK_DIR/isomount"
    DEFAULT_INPUT_FILE_BASE=$( basename "$DEFAULT_INPUT_FILE" )
    DEFAULT_OUTPUT_FILE_BASE=$( basename "$DEFAULT_OUTPUT_FILE" )
    DEFAULT_OLD_ISO_URL="https://download.rockylinux.org/pub/rocky/9/isos/$DEFAULT_ISO_ARCH/"
  fi
}

# Function: set_default_flags
#
# Set default flags 

set_default_flags () {
  DO_DAILY_ISO="false"
  DO_CHECK_DOCKER="false"
  DO_CHECK_ISO="false"
  DO_CREATE_VM="false"
  DO_DELETE_VM="false"
  DO_OLD_INSTALLER="false"
  DO_CUSTOM_BOOT_SERVER_FILE="false"
  DO_INSTALL_REQUIRED_PACKAGES="false"
  DO_INSTALL_ISO_NETWORK_UPDATES="false"
  DO_INSTALL_ISO_PACKAGES="false"
  DO_INSTALL_ISO_DRIVERS="false"
  DO_ISO_AUTO_UPGRADES="false"
  DO_ISO_APT_NEWS="false"
  DO_GET_BASE_ISO="false"
  DO_CHECK_WORK_DIR="false"
  DO_PREPARE_AUTOINSTALL_ISO_ONLY="false"
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
  DO_LIST_ISOS="false"
  DO_SCP_HEADER="false"
  DO_SERIAL="true"
  DO_CUSTOM_AUTO_INSTALL="false"
}

# Function: set_default_os_name
#
# Set default OS name

set_default_os_name () {
  if [ -f "/usr/bin/lsb_release" ]; then
    LSB_RELEASE=$( lsb_release -s -a )
    if [[ "$LSB_RELEASE" =~ "Ubuntu" ]]; then
      DEFAULT_ISO_OS_NAME=$( lsb_release -d |awk '{print $2}' |tr '[:upper:]' '[:lower:]' )
    else
      DEFAULT_ISO_OS_NAME="$CURRENT_ISO_OS_NAME"
      if [[ "$LSB_RELEASE" =~ "Arch" ]] || [[ "$LSB_RELEASE" =~ "Endeavour" ]]; then
        REQUIRED_PACKAGES="p7zip lftp wget xorriso whois squashfs-tools sudo file rsync ansible dialog"
      fi
    fi
  else
    DEFAULT_ISO_OS_NAME="$CURRENT_ISO_OS_NAME"
  fi
}

# Function: set_default_arch
#
# Set default zrchitecture

set_default_arch () {
  if [ -f "/usr/bin/uname" ]; then
    DEFAULT_ISO_ARCH=$( uname -m | sed "s/aarch64/arm64/g" |sed "s/x86_64/amd64/g" )
    if [ "$OS_NAME" = "Linux" ]; then
      if [ "$( command -v ifconfig )" ]; then
        DEFAULT_BOOT_SERVER_IP=$( ifconfig | grep "inet " | grep -v "127.0.0.1" |head -1 |awk '{print $2}' )
      else
        DEFAULT_BOOT_SERVER_IP=$( ip addr | grep "inet " | grep -v "127.0.0.1" |head -1 |awk '{print $2}' |cut -f1 -d/ )
      fi
      if [ "$DEFAULT_ISO_ARCH" = "x86_64" ] || [ "$DEFAULT_ISO_ARCH" = "amd64" ]; then
        DEFAULT_ISO_ARCH="amd64"
      fi
      if [ "$DEFAULT_ISO_ARCH" = "aarch64" ] || [ "$DEFAULT_ISO_ARCH" = "arm64" ]; then
        DEFAULT_ISO_ARCH="arm64"
      fi
    else
      if [ "$( command -v ifconfig )" ]; then
        DEFAULT_BOOT_SERVER_IP=$( ifconfig | grep "inet " | grep -v "127.0.0.1" |head -1 |awk '{print $2}' )
      else
        DEFAULT_BOOT_SERVER_IP=$( ip add | grep "inet " | grep -v "127.0.0.1" |head -1 |awk '{print $2}' |cut -f1 -d/ )
      fi
    fi
  else
    DEFAULT_ISO_ARCH="$CURRENT_ISO_ARCH"
    DEFAULT_BOOT_SERVER_IP=$( ifconfig | grep "inet " | grep -v "127.0.0.1" |head -1 |awk '{print $2}' )
  fi
}

# Function: set_default_release
#
# Set default release

set_default_release () {
  if [ -f "/usr/bin/lsb_release" ]; then
    if [ "$DEFAULT_ISO_OS_NAME" = "Ubuntu" ]; then
      DEFAULT_ISO_RELEASE=$( lsb_release -d |awk '{print $3}' )
    else
      DEFAULT_ISO_RELEASE="$CURRENT_ISO_RELEASE"
    fi
  else
    DEFAULT_ISO_RELEASE="$CURRENT_ISO_RELEASE"
  fi
  DEFAULT_OLD_ISO_RELEASE="$CURRENT_OLD_ISO_RELEASE"
}

# Funtion: set_default_codename
#
# Set default codename

set_default_codename () {
  if [ -f "/usr/bin/lsb_release" ]; then
    if [ "$DEFAULT_ISO_OS_NAME" = "Ubuntu" ]; then
      DEFAULT_ISO_CODENAME=$( lsb_release -cs )
    else
      DEFAULT_ISO_CODENAME="$CURRENT_ISO_CODENAME"
    fi
  else
    DEFAULT_ISO_CODENAME="$CURRENT_ISO_CODENAME"
  fi
}

# Function: set_default_old_url
#
# Set default old ISO URL

set_default_old_url () {
  DEFAULT_OLD_ISO_URL="https://old-releases.ubuntu.com/releases/$DEFAULT_OLD_ISO_RELEASE/ubuntu-$DEFAULT_OLD_ISO_RELEASE-live-server-$DEFAULT_ISO_ARCH.iso"
}

# Function: set_default_docker_arch
#
# Set default arches for Docker

set_default_docker_arch () {
  if [ "$OS_NAME" = "Darwin" ]; then
    if [ "$OS_ARCH" = "arm64" ]; then
      DEFAULT_DOCKER_ARCH="amd64 arm64"
    else
      DEFAULT_DOCKER_ARCH="amd64"
    fi
  else
    DEFAULT_DOCKER_ARCH="amd64"
  fi
}

# Function: set_default_dirs
#
# Set default work directories

set_default_dirs () {
  DEFAULT_WORK_DIR="$HOME/$SCRIPT_NAME/$DEFAULT_ISO_OS_NAME/$DEFAULT_ISO_RELEASE"
  DEFAULT_OLD_WORK_DIR="$HOME/$SCRIPT_NAME/$DEFAULT_ISO_OS_NAME/$DEFAULT_OLD_ISO_RELEASE"
  MASKED_DEFAULT_WORK_DIR="$HOME/$SCRIPT_NAME/$DEFAULT_ISO_OS_NAME/$DEFAULT_ISO_RELEASE"
  DEFAULT_ISO_MOUNT_DIR="$DEFAULT_WORK_DIR/isomount"
  DEFAULT_OLD_ISO_MOUNT_DIR="$DEFAULT_OLD_WORK_DIR/isomount"
  DEFAULT_ISO_AUTOINSTALL_DIR="autoinstall"
  DEFAULT_ISO_TARGET_MOUNT="/target"
  DEFAULT_ISO_INSTALL_MOUNT="/cdrom"
}

# Function: reset_default_dirs
#
# Update Default work directories

reset_default_dirs () {
  ISO_MOUNT_DIR="$WORK_DIR/isomount"
  OLD_ISO_MOUNT_DIR="$OLD_WORK_DIR/isomount"
  ISO_NEW_DIR="$WORK_DIR/isonew"
  ISO_SOURCE_DIR="$WORK_DIR/source-files"
}

# Function: set_default_files
#
# Set default file names/locations

set_default_files () {
  DEFAULT_INPUT_FILE="$DEFAULT_WORK_DIR/files/ubuntu-$DEFAULT_ISO_RELEASE-live-server-$DEFAULT_ISO_ARCH.iso"
  DEFAULT_OLD_INPUT_FILE="$DEFAULT_OLD_WORK_DIR/files/ubuntu-$DEFAULT_OLD_ISO_RELEASE-live-server-$DEFAULT_ISO_ARCH.iso"
  DEFAULT_OUTPUT_FILE="$DEFAULT_WORK_DIR/files/ubuntu-$DEFAULT_ISO_RELEASE-live-server-$DEFAULT_ISO_ARCH-$DEFAULT_ISO_BOOT_TYPE-autoinstall.iso"
  DEFAULT_BOOT_SERVER_FILE="$DEFAULT_OUTPUT_FILE"
  DEFAULT_ISO_SQUASHFS_FILE="$DEFAULT_ISO_MOUNT_DIR/casper/ubuntu-server-minimal.squashfs"
  DEFAULT_OLD_INSTALL_SQUASHFS_FILE="$DEFAULT_OLD_ISO_MOUNT_DIR/casper/ubuntu-server-minimal.ubuntu-server.installer.squashfs"
  DEFAULT_ISO_GRUB_FILE="$DEFAULT_WORK_DIR/grub.cfg"
  DEFAULT_ISO_VOLID="$DEFAULT_ISO_OS_NAME $DEFAULT_ISO_RELEASE Server"
  DEFAULT_INPUT_FILE_BASE=$( basename "$DEFAULT_INPUT_FILE" )
  DEFAULT_OUTPUT_FILE_BASE=$( basename "$DEFAULT_OUTPUT_FILE" )
  DEFAULT_BOOT_SERVER_FILE_BASE=$(basename "$DEFAULT_BOOT_SERVER_FILE")
  DEFAULT_ISO_SQUASHFS_FILE_BASE=$( basename "$DEFAULT_ISO_SQUASHFS_FILE" )
  DEFAULT_ISO_GRUB_FILE_BASE=$( basename "$DEFAULT_ISO_GRUB_FILE" )
}

# Function: reset_default_files
#
# Update default files

reset_default_files () {
  ISO_GRUB_FILE="$WORK_DIR/grub.cfg"
  if [ "$ISO_MAJOR_REL" -ge "22" ]; then
    ISO_SQUASHFS_FILE="$ISO_MOUNT_DIR/casper/ubuntu-server-minimal.squashfs"
    NEW_SQUASHFS_FILE="$ISO_SOURCE_DIR/casper/ubuntu-server-minimal.squashfs"
  else
    ISO_SQUASHFS_FILE="$ISO_MOUNT_DIR/casper/filesystem.squashfs"
    NEW_SQUASHFS_FILE="$ISO_SOURCE_DIR/casper/filesystem.squashfs"
  fi
}

# Function: print_usage
#
# Print script usage information

print_usage () {
  cat <<-USAGE

  action
  ------

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

  cluster                 Install cluster related packages (pcs, gluster, etc)
  kvm                     Install KVM related packages (virt-manager, cloud-image-utils, etc)
  sshkey                  Add SSH key from ~/.ssh if present
  biosdevname:            Enable biosdevname kernel parameters
  nounmount:              Don't unmount filesystems (useful for troubleshooting)
  testmode:               Don't execute commands (useful for testing and generating a script)
  uefi:                   Create UEFI based ISO
  bios:                   Create BIOS based ISO
  verbose:                Verbose output
  interactive:            Interactively ask questions
  autoupgrades:           Allow autoupgrades

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

  ${0##*/} --action createiso --options verbose --ip 192.168.1.211 --cidr 24 --dns 8.8.8.8 --gateway 192.168.1.254

USAGE
  exit
}

# Function: print_help
#
# Print script help information

print_help () {
  cat <<-HELP

  Usage: ${0##*/} [OPTIONS...]
    -0|--oldrelease           Old release (used for copying file from an older release ISO - default: $DEFAULT_OLD_ISO_RELEASE)
    -1|--country              Country (used for sources.list mirror - default: $DEFAULT_ISO_COUNTRY)
    -2|--isourl               Specify ISO URL (default: $DEFAULT_ISO_URL)
    -3|--prefix               Prefix to add to ISO name
    -4|--suffix               Suffix to add to ISO name
    -5|--block                Block kernel module(s) (default: $DEFAULT_ISO_BLOCKLIST)
    -6|--allow                Load additional kernel modules(s)
    -7|--oldisourl            Old release ISO URL (used with --oldrelease) (default: $DEFAULT_OLD_ISO_URL)
    -8|--oldinputfile         Old release ISO (used with --oldrelease) (default: $DEFAULT_OLD_ISO_RELEASE)
    -9|--search               Search output for value (eg --action listallisos --search efi)
    -A|--codename|--disto     Linux release codename or distribution (default: $DEFAULT_ISO_CODENAME)
    -a|--action:              Action to perform (e.g. createiso, justiso, runchrootscript, checkdocker, installrequired)
    -B|--layout|--vmsize:     Layout or VM disk size (default: $DEFAULT_ISO_LAYOUT/$DEFAULT_VM_SIZE)
    -b|--bootserverip:        NFS/Bootserver IP (default: $DEFAULT_BOOT_SERVER_IP)
    -C|--cidr:                CIDR (default: $DEFAULT_ISO_CIDR)
    -c|--sshkeyfile:          SSH key file to use as SSH key (default: $MASKED_DEFAULT_ISO_SSH_KEY_FILE)
    -D|--dns:                 DNS Server (ddefault: $DEFAULT_ISO_DNS)
    -d|--bootdisk:            Boot Disk devices (default: $DEFAULT_ISO_DEVICES)
    -E|--locale:              LANGUAGE (default: $DEFAULT_ISO_LOCALE)
    -e|--lcall:               LC_ALL (default: $DEFAULT_ISO_LC_ALL)
    -F|--bmcusername:         BMC/iDRAC User (default: $DEFAULT_BMC_USERNAME)
    -f|--delete:              Remove previously created files (default: $FORCE_MODE)
    -G|--gateway:             Gateway (default $DEFAULT_ISO_GATEWAY)
    -g|--grubmenu|--vmname:   Set default grub menu or VM name (default: $DEFAULT_ISO_GRUB_MENU/$SCRIPT_NAME)
    -H|--hostname|            Hostname (default: $DEFAULT_ISO_HOSTNAME)
    -h|--help                 Help/Usage Information
    -I|--ip:                  IP Address (default: $DEFAULT_ISO_IP)
    -i|--inputiso|--vmiso:    Input/base ISO file (default: $DEFAULT_INPUT_FILE_BASE)
    -J|--grubfile             GRUB file (default: $DEFAULT_ISO_GRUB_FILE_BASE)
    -j|--autoinstalldir       Directory where autoinstall config files are stored on ISO (default: $DEFAULT_ISO_AUTOINSTALL_DIR)
    -K|--kernel|--vmtype:     Kernel package or VM type (default: $DEFAULT_ISO_KERNEL/$DEFAULT_VM_TYPE)
    -k|--kernelargs|--vmcpus: Kernel arguments (default: $DEFAULT_ISO_KERNEL_ARGS)
    -L|--release:             LSB release (default: $DEFAULT_ISO_RELEASE)
    -l|--bmcip:               BMC/iDRAC IP (default: $DEFAULT_BMC_IP)
    -M|--installtarget:       Where the install mounts the target filesystem (default: $DEFAULT_ISO_TARGET_MOUNT)
    -m|--installmount:        Where the install mounts the CD during install (default: $DEFAULT_ISO_INSTALL_MOUNT)
    -N|--bootserverfile       Boot sever file (default: $DEFAULT_BOOT_SERVER_FILE_BASE)
    -n|--nic|--vmnic:         Network device (default: $DEFAULT_ISO_NIC/$DEFAULT_VM_NIC)
    -O|--isopackages:         List of packages to install (default: $DEFAULT_ISO_INSTALL_PACKAGES)
    -o|--outputiso:           Output ISO file (default: $DEFAULT_OUTPUT_FILE_BASE)
    -P|--password:            Password (default: $DEFAULT_ISO_PASSWORD)
    -p|--chrootpackages:      List of packages to add to ISO (default: $DEFAULT_PACKAGES)
    -Q|--build:               Type of ISO to build (default: $DEFAULT_ISO_BUILD_TYPE)
    -q|--arch:                Architecture (default: $DEFAULT_ISO_ARCH)
    -R|--realname:            Realname (default $DEFAULT_ISO_REALNAME)
    -r|--serialportspeed:     Serial Port Speed (default: $DEFAULT_ISO_SERIAL_PORT_SPEED0,$DEFAULT_ISO_SERIAL_PORT_SPEED1)
    -S|--swapsize|--vmram:    Swap or VM memory size (default $DEFAULT_ISO_SWAPSIZE/$DEFAULT_VM_RAM)
    -s|--squashfsfile:        Squashfs file (default: $DEFAULT_ISO_SQUASHFS_FILE_BASE)
    -T|--timezone:            Timezone (default: $DEFAULT_ISO_TIMEZONE)
    -t|--serialportaddress:   Serial Port Address (default: $DEFAULT_ISO_SERIAL_PORT_ADDRESS0,$DEFAULT_ISO_SERIAL_PORT_ADDRESS1)
    -U|--username:            Username (default: $DEFAULT_ISO_USERNAME)
    -u|--postinstall:         Postinstall action (e.g. installpackages, upgrade, distupgrade, installdrivers, all, autoupgrades)
    -V|--version              Display Script Version
    -v|--serialport:          Serial Port (default: $DEFAULT_ISO_SERIAL_PORT0,$DEFAULT_ISO_SERIAL_PORT1)
    -W|--workdir:             Work directory (default: $MASKED_DEFAULT_WORK_DIR)
    -w|--preworkdir:          Docker work directory (used internally)
    -X|--isovolid:            ISO Volume ID (default: $DEFAULT_ISO_VOLID)
    -x|--grubtimeout:         Grub timeout (default: $DEFAULT_ISO_GRUB_TIMEOUT)
    -Y|--allowpassword        Allow password access via SSH (default: $DEFAULT_ISO_ALLOW_PASSWORD)
    -y|--bmcpassword:         BMC/iDRAC password (default: $DEFAULT_BMC_PASSWORD)
    -Z|--options:             Options (e.g. nounmount, testmode, bios, uefi, verbose, interactive)
    -z|--volumemanager:       Volume Managers (default: $DEFAULT_ISO_VOLMGRS)
      |--zfsfilesystems:      ZFS filesystems (default: $DEFAULT_ZFS_FILESYSTEMS)
      |--autoinstall:         Use a custom autoinstall file (default: generate automatically)
HELP
  exit
}

# Function: execute_command
#
# Execute a command

execute_command () {
  COMMAND="$1"
  execution_message "$COMMAND"
  if [ "$TEST_MODE" = "false" ]; then
    $COMMAND
  fi
}

# Function: execution_message
#
#  Print command

execution_message () {
  OUTPUT_TEXT="$1"
  OUTPUT_TYPE="COMMAND"
  handle_output "$OUTPUT_TEXT" $OUTPUT_TYPE
}

# Function: information_message
#
# Print informational message

information_message () {
  OUTPUT_TEXT="$1"
  OUTPUT_TYPE="TEXT"
  handle_output "# Information: $OUTPUT_TEXT" $OUTPUT_TYPE
}

# Function: verbose_message
#
# Print verbose message

verbose_message () {
  OUTPUT_TEXT="$1"
  OUTPUT_TYPE="TEXT"
  TEMP_VERBOSE_MODE="true"
  handle_output "$OUTPUT_TEXT" $OUTPUT_TYPE
  TEMP_VERBOSE_MODE="false"
}

# Function: warning_message
#
# Print warning message

warning_message () {
  OUTPUT_TEXT="$1"
  OUTPUT_TYPE="TEXT"
  TEMP_VERBOSE_MODE="true"
  handle_output "# Warning: $OUTPUT_TEXT" $OUTPUT_TYPE
  TEMP_VERBOSE_MODE="false"
}

# Function: handle_output
#
# Handle text output

handle_output () {
  OUTPUT_TEXT="$1"
  OUTPUT_TYPE="$2"
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

# Function: create_dir
#
# Create directory

create_dir () {
  CREATE_DIR="$1"
  handle_output "# Checking directory $CREATE_DIR exists"
  if [ ! -d "$CREATE_DIR" ]; then
    if [ "$TEST_MODE" = "false" ]; then
      mkdir -p "$CREATE_DIR"
    fi
  fi
}

# Function: sudo_create_dir
#
# Create directory

sudo_create_dir () {
  CREATE_DIR="$1"
  handle_output "# Checking directory $CREATE_DIR exists"
  if [ ! -d "$CREATE_DIR" ]; then
    if [ "$TEST_MODE" = "false" ]; then
      if [ -f "/.dockerenv" ]; then
        mkdir -p "$CREATE_DIR"
      else
        sudo mkdir -p "$CREATE_DIR"
      fi
    fi
  fi
}

# Function: remove_dir
#
# Remove directory

remove_dir () {
  REMOVE_DIR="$1"
  handle_output "# Checking directory $REMOVE_DIR exists"
  if [ ! "$REMOVE_DIR" = "/" ]; then
    if [[ $REMOVE_DIR =~ [0-9a-zA-Z] ]]; then
      if [ -d "$REMOVE_DIR" ]; then
        if [ "$TEST_MODE" = "false" ]; then
          sudo rm -f "$REMOVE_DIR"
        fi
      fi
    fi
  fi
}

# Function: create_docker_config
#
# Create a docker config so we can run this from a non Linux platform
#
# docker-compose.yml
#
# version: "3"
#
# services:
#  guige:
#    build:
#      context: .
#      dockerfile: Dockerfile
#    image: guige-ubuntu-amd64
#    container_name: guige
#    entrypoint: /bin/bash
#    working_dir: /root
#
# Dockerfile
#
# FROM ubuntu:22.04
# RUN apt-get update && apt-get install -y p7zip-full lftp wget xorriso whois squashfs-tools

check_docker_config () {
  if ! [ -f "/.dockerenv" ]; then
    handle_output "# Checking Docker configs" TEXT
    for DIR_ARCH in $DOCKER_ARCH; do
      if ! [ -d "$WORK_DIR/$DIR_ARCH" ]; then
        handle_output "Creating directory $WORK_DIR/$DIR_ARCH" TEXT
        create_dir "$WORK_DIR/$DIR_ARCH"
      fi
      handle_output "# Checking docker images" TEXT
      DOCKER_IMAGE_CHECK=$( docker images |grep "^$SCRIPT_NAME-$DIR_ARCH" |awk '{print $1}' )
      handle_output "# Checking volume images" TEXT
      DOCKER_VOLUME_CHECK=$( docker volume list |grep "^$SCRIPT_NAME-$DIR_ARCH" |awk '{print $1}' )
      if ! [ "$DOCKER_VOLUME_CHECK" = "$SCRIPT_NAME-$DIR_ARCH" ]; then
        if [ "$TEST_MODE" = "false" ]; then
          docker volume create "$SCRIPT_NAME-$DIR_ARCH"
        fi
      fi
      if ! [ "$DOCKER_IMAGE_CHECK" = "$SCRIPT_NAME-$DIR_ARCH" ]; then
        if [ "$TEST_MODE" = "false" ]; then
          handle_output "# Creating Docker compose file $WORK_DIR/$DIR_ARCH/docker-compose.yml" TEXT
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
          echo "      - /docker/$SCRIPT_NAME-$DIR_ARCH/:/root/$SCRIPT_NAME/" >> "$WORK_DIR/$DIR_ARCH/docker-compose.yml"
          print_file "$WORK_DIR/$DIR_ARCH/docker-compose.yml"
          handle_output "# Creating Docker config $WORK_DIR/$DIR_ARCH/Dockerfile" TEXT
          echo "FROM ubuntu:$CURRENT_DOCKER_UBUNTU_RELEASE" > "$WORK_DIR/$DIR_ARCH/Dockerfile"
          echo "RUN apt-get update && apt-get -o Dpkg::Options::=\"--force-overwrite\" install -y $REQUIRED_PACKAGES" >> "$WORK_DIR/$DIR_ARCH/Dockerfile"
          print_file "$WORK_DIR/$DIR_ARCH/Dockerfile"
          handle_output "# Building docker image $SCRIPT_NAME-$DIR_ARCH" TEXT
          docker build "$WORK_DIR/$DIR_ARCH" --tag "$SCRIPT_NAME-$DIR_ARCH" --platform "linux/$DIR_ARCH"
        fi
      fi
    done
  fi
}

# Function: create_docker_iso
#
# Use docker to create ISO

create_docker_iso () {
  if ! [ -f "/.dockerenv" ]; then
    DOCKER_BIN="$WORK_DIR/files/$SCRIPT_BIN"
    LOCAL_SCRIPT="$WORK_DIR/files/guige_docker_script.sh"
    DOCKER_SCRIPT="$DOCKER_WORK_DIR/files/guige_docker_script.sh"
    cp "$SCRIPT_FILE" "$DOCKER_BIN"
    chmod +x "$DOCKER_BIN"
    check_work_dir
    if [ "$DO_OLD_INSTALLER" = "true" ]; then
      check_old_work_dir
    fi
    check_docker_config
    handle_output
    if [ "$DO_DOCKER" = "false" ]; then
      exit
    fi
    if ! [ "$TEST_MODE" = "true" ]; then
      echo "#!/bin/bash" > "$LOCAL_SCRIPT"
      echo "$DOCKER_WORK_DIR/files/$SCRIPT_BIN $SCRIPT_ARGS --workdir $DOCKER_WORK_DIR --preworkdir $WORK_DIR" >> "$LOCAL_SCRIPT"
      if [ "$DO_DOCKER" = "true" ]; then
        BASE_DOCKER_OUTPUT_FILE=$( basename "$OUTPUT_FILE" )
        echo "# Output file will be at \"$WORK_DIR/files/$BASE_DOCKER_OUTPUT_FILE\""
      fi
#      echo "exec docker run --privileged=true --cap-add=CAP_MKNOD --device-cgroup-rule=\"b 7:* rmw\" --platform \"linux/$ISO_ARCH\" --mount source=\"$SCRIPT_NAME-$ISO_ARCH,target=/root/$SCRIPT_NAME\" --mount type=bind,source=\"$WORK_DIR/files,target=/root/$SCRIPT_NAME/$NEW_DIR/files\"  \"$SCRIPT_NAME-$ISO_ARCH\" /bin/bash \"$DOCKER_SCRIPT\""
      exec docker run --privileged=true --cap-add=CAP_MKNOD --device-cgroup-rule="b 7:* rmw" --platform "linux/$ISO_ARCH" --mount source="$SCRIPT_NAME-$ISO_ARCH,target=/root/$SCRIPT_NAME" --mount type=bind,source="$WORK_DIR/files,target=/root/$SCRIPT_NAME/$NEW_DIR/files"  "$SCRIPT_NAME-$ISO_ARCH" /bin/bash "$DOCKER_SCRIPT"
      exit
    fi
  fi
  DO_PRINT_HELP="false"
}

# Function: get_codename
#
# Get Ubuntu relase codename

get_code_name() {
  REL_NO="$ISO_MAJOR_REL.$ISO_MINOR_REL"
  if [ "$REL_NO" = "." ]; then
    REL_NO="$ISO_RELEASE"
  fi
  case $REL_NO in
    "20.04")
      ISO_CODENAME="focal"
      ;;
    "20.10")
      ISO_CODENAME="groovy"
      ;;
    "21.04")
      ISO_CODENAME="hirsute"
      ;;
    "21.10")
      ISO_CODENAME="impish"
      ;;
    "22.04")
      ISO_CODENAME="jammy"
      ;;
    "22.10")
      ISO_CODENAME="kinetic"
      ;;
    "23.04")
      ISO_CODENAME="lunar"
      ;;
    "23.10")
      ISO_CODENAME="mantic"
      ;;
    "24.04")
      ISO_CODENAME="noble"
      ;;
  esac
}

# Function: get_info_from_iso
#
# Get info from iso

get_info_from_iso () {
  handle_output "# Analysing $INPUT_FILE" TEXT
  TEST_FILE=$( basename "$INPUT_FILE" )
  TEST_NAME=$( echo "$TEST_FILE" | cut -f1 -d- )
  TEST_TYPE=$( echo "$TEST_FILE" | cut -f2 -d- )
  ISO_DISTRO="Ubuntu"
  case $TEST_NAME in
    "bionic")
      ISO_RELEASE="$CURRENT_ISO_RELEASE_1804"
      ;;
    "focal")
      ISO_RELEASE="$CURRENT_ISO_RELEASE_2004"
      ;;
    "jammy")
      ISO_RELEASE="$CURRENT_ISO_RELEASE_2204"
      ;;
    "kinetic")
      ISO_RELEASE="$CURRENT_ISO_RELEASE_2210"
      ;;
    "lunar")
      ISO_RELEASE="$CURRENT_ISO_RELEASE_2304"
      ;;
    "mantic")
      ISO_RELEASE="$CURRENT_ISO_RELEASE_2310"
      ;;
    "nobile")
      ISO_RELEASE="$CURRENT_ISO_RELEASE_2404"
      ;;
    "ubuntu")
      ISO_RELEASE=$(echo "$TEST_FILE" |cut -f2 -d- )
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
  handle_output "# Input ISO:     $INPUT_FILE" TEXT
  handle_output "# Distribution:  $ISO_DISTRO" TEXT
  handle_output "# Release:       $ISO_RELEASE" TEXT
  handle_output "# Codename:      $ISO_CODENAME" TEXT
  handle_output "# Architecture:  $ISO_ARCH" TEXT
  handle_output "# Output ISO:    $OUTPUT_FILE" TEXT
}

# Function: get_my_ip
#
# Get my IP

get_my_ip () {
  if [ "$OS_NAME" = "Darwin" ]; then
    MY_IP=$(ifconfig | grep "inet " | grep -v 127.0.0.1 |head -1 |awk '{print $2}')
  else
    if [[ "$LSB_RELEASE" =~ "Arch" ]] || [[ "$LSB_RELEASE" =~ "Endeavour" ]]; then
      MY_IP=$(ip addr |grep 'inet ' |grep -v 127 |head -1 |awk '{print $2}' |cut -f1 -d/)
    else
      MY_IP=$(hostname -I |awk '{print $1}')
    fi
  fi
}

# Function: list_isos
#
# List ISOs

list_isos () {
  TEMP_VERBOSE_MODE="true"
  if [ "$ISO_SEARCH" = "" ]; then
    FILE_LIST=$(find "$WORK_DIR" -name "*.iso" 2> /dev/null)
  else
    FILE_LIST=$(find "$WORK_DIR" -name "*.iso" 2> /dev/null |grep "$ISO_SEARCH" )
  fi
  for FILE_NAME in $FILE_LIST; do
    if [ "$DO_SCP_HEADER" = "true" ]; then
      handle_output "$MY_USERNAME@$MY_IP:$FILE_NAME" TEXT
    else
      handle_output "$FILE_NAME" TEXT
    fi
  done
  TEMP_VERBOSE_MODE="false"
}

# Function: check_work_dir
#
# Check work directories exist
#
# Example:
# mkdir -p ./isomount ./isonew/squashfs ./isonew/cd ./isonew/custom

check_work_dir () {
  handle_output "# Check work directories" TEXT
  for ISO_DIR in $ISO_MOUNT_DIR $ISO_NEW_DIR/squashfs $ISO_NEW_DIR/mksquash $ISO_NEW_DIR/cd $ISO_NEW_DIR/custom $WORK_DIR/bin $WORK_DIR/files; do
    handle_output "# Check directory $ISO_DIR exists" TEXT
    if [ "$FORCE_MODE" = "true" ]; then
      remove_dir "$ISO_DIR"
    fi
    create_dir "$ISO_DIR"
  done
}

# Function: check_old_work_dir
#
# Check old release work directory
# Used when copying files from old release to a new release

check_old_work_dir () {
  handle_output "# Check old release work directories exist" TEXT
  for ISO_DIR in $OLD_ISO_MOUNT_DIR $OLD_WORK_DIR/files; do
    if [ "$FORCE_MODE" = "true" ]; then
      remove_dir "$ISO_DIR"
    fi
    create_dir "$ISO_DIR"
  done
}

# Function: execute_racadm
#
# Execute racadm commands

execute_racadm () {
  if [ "$TEST_MODE" = "false" ]; then
    handle_output "# Executing racadm" TEXT
    $RACADM_BIN -H "$BMC_IP" -u "$BMC_USERNAME" -p "$BMC_PASSWORD" -c "remoteimage -d"
    $RACADM_BIN -H "$BMC_IP" -u "$BMC_USERNAME" -p "$BMC_PASSWORD" -c "remoteimage -c -l $BOOT_SERVER_IP:BOOT_SERVER_FILE"
    $RACADM_BIN -H "$BMC_IP" -u "$BMC_USERNAME" -p "$BMC_PASSWORD" -c "config -g cfgServerInfo -o cfgServerBootOnce 1"
    $RACADM_BIN -H "$BMC_IP" -u "$BMC_USERNAME" -p "$BMC_PASSWORD" -c "config -g cfgServerInfo -o cfgServerFirstBootDevice VCD-DVD"
    $RACADM_BIN -H "$BMC_IP" -u "$BMC_USERNAME" -p "$BMC_PASSWORD" -c "serveraction powercycle"
  fi
}

# Function: check_racadm
#
# Check racadm

check_racadm () {
  handle_output "# Checking racadm" TEXT
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

# Function: install_required_packages
#
# Install required packages
#
# Example:
# sudo apt install -y p7zip-full lftp wget xorriso

install_required_packages () {
  handle_output "# Checking required packages are installed" TEXT
  for PACKAGE in $REQUIRED_PACKAGES; do
    PACKAGE_VERSION=""
    verbose_message "# Package: $PACKAGE" TEXT
    if [ "$OS_NAME" = "Darwin" ]; then
      PACKAGE_VERSION=$( brew list "$PACKAGE" 2>&1 |head -1 |awk -F"/" '{print $6}' )
    else
      if [[ "$LSB_RELEASE" =~ "Arch" ]] || [[ "$LSB_RELEASE" =~ "Endeavour" ]]; then
        PACKAGE_VERSION=$( sudo pacman -Q "$PACKAGE" 2>&1 |awk '{print $2}' )
      else
        PACKAGE_VERSION=$( sudo dpkg -l "$PACKAGE" 2>&1 |grep "^ii" |awk '{print $3}' )
      fi
    fi
    verbose_message "# $PACKAGE version: $PACKAGE_VERSION" TEXT
    if [ -z "$PACKAGE_VERSION" ]; then
      if [ "$TEST_MODE" = "false" ]; then
        if [ "$OS_NAME" = "Darwin" ]; then
          brew update
          brew install "$PACKAGE"
        else
          if [[ "$LSB_RELEASE" =~ "Arch" ]] || [[ "$LSB_RELEASE" =~ "Endeavour" ]]; then
            sudo pacman -Sy
            echo Y |sudo pacman -Sy "$PACKAGE"
          else
            sudo apt update
            sudo apt install -y "$PACKAGE"
          fi
        fi
      fi
    fi
  done
}

# Function: check_base_iso_file
#
# Check base ISO file exists

check_base_iso_file () {
  if [ -f "$INPUT_FILE" ]; then
    BASE_INPUT_FILE=$( basename "$INPUT_FILE" )
    FILE_TYPE=$( file "$WORK_DIR/files/$BASE_INPUT_FILE" |cut -f2 -d: |grep -E "MBR|ISO")
    if [ -z "$FILE_TYPE" ]; then
      warning_message "$WORK_DIR/files/$BASE_INPUT_FILE is not a valid ISO file"
      exit
    fi
  fi
}

# Function: check_old_base_iso_file
#
# Check previous release base ISO file exists
# Used when copying files from an old release to a new release

check_old_base_iso_file () {
  if [ -f "$OLD_INPUT_FILE" ]; then
    OLD_BASE_INPUT_FILE=$( basename "$OLD_INPUT_FILE" )
    OLD_FILE_TYPE=$( file "$OLD_WORK_DIR/files/$OLD_BASE_INPUT_FILE" |cut -f2 -d: |grep -E "MBR|ISO")
    if [ -z "$OLD_FILE_TYPE" ]; then
      warning_message "$OLD_WORK_DIR/files/$OLD_BASE_INPUT_FILE is not a valid ISO file"
      exit
    fi
  fi
}

# Function: get_base_iso
#
# Grab ISO from Ubuntu
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
  if [ "$DO_CHECK_ISO" = "true" ]; then
    cd "$WORK_DIR/files" || exit ; wget -N "$ISO_URL"
  else
    if ! [ -f "$WORK_DIR/files/$BASE_INPUT_FILE" ]; then
      if [ "$TEST_MODE" = "false" ]; then
        wget "$ISO_URL" -O "$WORK_DIR/files/$BASE_INPUT_FILE"
      fi
    fi
  fi
}

get_old_base_iso () {
  handle_output "# Check old source ISO exists and grab it if it doesn't" TEXT
  OLD_BASE_INPUT_FILE=$( basename "$OLD_INPUT_FILE" )
  if [ "$FULL_FORCE_MODE" = "true" ]; then
    handle_output "rm $WORK_DIR/files/$OLD_BASE_INPUT_FILE"
    if [ "$TEST_MODE" = "false" ]; then
      rm "$OLD_WORK_DIR/files/$OLD_BASE_INPUT_FILE"
    fi
  fi
  check_old_base_iso_file
  if [ "$DO_CHECK_ISO" = "true" ]; then
    cd "$OLD_WORK_DIR/files" || exit ; wget -N "$OLD_ISO_URL"
  else
    if ! [ -f "$OLD_WORK_DIR/files/$OLD_BASE_INPUT_FILE" ]; then
      if [ "$TEST_MODE" = "false" ]; then
        wget "$OLD_ISO_URL" -O "$OLD_WORK_DIR/files/$OLD_BASE_INPUT_FILE"
      fi
    fi
  fi
}

# Function: unmount_iso
#
# unmount loopback ISO filesystem
#
# Examples:
# sudo umount -l /home/user/ubuntu-iso/isomount

unmount_iso () {
  handle_output "sudo umount -l $ISO_MOUNT_DIR"
  if [ "$TEST_MODE" = "false" ]; then
    sudo umount -l "$ISO_MOUNT_DIR"
  fi
}

# Function: unmount_old_iso
#
# unmount loopback older release ISO filesystem
#
# Examples:
# sudo umount -l /home/user/ubuntu-old-iso/isomount

unmount_old_iso () {
  handle_output "sudo umount -l $OLD_ISO_MOUNT_DIR"
  if [ "$TEST_MODE" = "false" ]; then
    sudo umount -l "$OLD_ISO_MOUNT_DIR"
  fi
}

# Function: mount_iso
#
# Mount base ISO as loopback device so contents can be copied
#
# sudo mount -o loop ./ubuntu-22.04.1-live-server-arm64.iso ./isomount
# sudo mount -o loop ./ubuntu-22.04.1-live-server-amd64.iso ./isomount

mount_iso () {
  get_base_iso
  check_base_iso_file
  handle_output "sudo mount -o loop \"$WORK_DIR/files/$BASE_INPUT_FILE\" \"$ISO_MOUNT_DIR\""
  if [ "$TEST_MODE" = "false" ]; then
    sudo mount -o loop "$WORK_DIR/files/$BASE_INPUT_FILE" "$ISO_MOUNT_DIR"
  fi
}

# Function: unmount_old_iso
#
# Mount older revision base ISO as loopback device so contents can be copied
#
# sudo mount -o loop ./ubuntu-22.04.1-live-server-arm64.iso ./isomount
# sudo mount -o loop ./ubuntu-22.04.1-live-server-amd64.iso ./isomount

mount_old_iso () {
  get_old_base_iso
  check_old_base_iso_file
  handle_output "$ Mounting ISO $OLD_WORK_DIR/files/$OLD_BASE_INPUT_FILE at $OLD_ISO_MOUNT_DIR" TEXT
  if [ "$TEST_MODE" = "false" ]; then
    sudo mount -o loop "$OLD_WORK_DIR/files/$OLD_BASE_INPUT_FILE" "$OLD_ISO_MOUNT_DIR"
  fi
}

# Function: unmount_squashfs
#
# Unmount squahfs filesystem

unmount_squashfs () {
  handle_output "# Unmounting squashfs $ISO_NEW_DIR/squashfs" TEXT
  if [ "$TEST_MODE" = "false" ]; then
    sudo umount "$ISO_NEW_DIR/squashfs"
  fi
}

# Function: copy_iso
#
# Copy contents of ISO to a RW location so we can work with them
#
# Examples:
# rsync --exclude=/casper/ubuntu-server-minimal.squashfs -av ./isomount/ ./isonew/cd
# rsync -av ./isomount/ ./isonew/cd

copy_iso () {
  handle_output "# Copying ISO files from $ISO_MOUNT_DIR to $ISO_NEW_DIR/cd" TEXT
  if [ ! -f "/usr/bin/rsync" ]; then
    install_required_packages
  fi
  if [ "$VERBOSE_MODE" = "true" ]; then
    if [ "$TEST_MODE" = "false" ]; then
      rsync -av "$ISO_MOUNT_DIR/" "$ISO_NEW_DIR/cd"
    fi
  else
    if [ "$TEST_MODE" = "false" ]; then
      rsync -a "$ISO_MOUNT_DIR/" "$ISO_NEW_DIR/cd"
    fi
  fi
}

# Function: check_ansible
#
# Check ansible

check_ansible () {
  handle_output "# Checking ansible is installed" TEXT
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
  handle_output "# Checking ansible collection dellemc.openmanage is installed" TEXT
  ANSIBLE_CHECK=$( ansible-galaxy collection list |grep "dellemc.openmanage" |awk '{print $1}' |uniq )
  if ! [ "$ANSIBLE_CHECK" = "dellemc.openmanage" ]; then
    if [ "$TEST_MODE" = "false" ]; then
      ansible-galaxy collection install dellemc.openmanage
    fi
  fi
}

# Function: print_file
#
# Print contents of file

print_file () {
  FILE_NAME="$1"
  handle_output "# Contents of file $FILE_NAME"
  if [ "$TEST_MODE" = "false" ]; then
    cat "$FILE_NAME"
  fi
}


# Function: create_ansible
#
# Creates an ansible file for setting up boot device on iDRAC using Redfish

create_ansible () {
  HOSTS_YAML="$WORK_DIR/hosts.yaml"
  handle_output "# Creating ansible hosts file $HOSTS_YAML"
  if [ "$TEST_MODE" = "false" ]; then
    echo "---" > "$HOSTS_YAML"
    echo "idrac:" >> "$HOSTS_YAML"
    echo "  hosts:" >> "$HOSTS_YAML"
    echo "    $ISO_HOSTNAME:" >> "$HOSTS_YAML"
    echo "      ansible_host:   $BMC_IP" >> "$HOSTS_YAML"
    echo "      baseuri:        $BMC_IP" >> "$HOSTS_YAML"
    echo "      idrac_user:     $BMC_USERNAME" >> "$HOSTS_YAML"
    echo "      idrac_password: $BMC_PASSWORD" >> "$HOSTS_YAML"
    print_file "$HOSTS_YAML"
  fi
  IDRAC_YAML="$WORK_DIR/idrac.yaml"
  NFS_FILE=$( basename "$BOOT_SERVER_FILE" )
  NFS_DIR=$( dirname "$BOOT_SERVER_FILE" )
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
    print_file "$IDRAC_YAML"
  fi
}

# Function: install_server
#
# Run ansible playbook to boot server from ISO

install_server () {
  HOSTS_YAML="$WORK_DIR/hosts.yaml"
  IDRAC_YAML="$WORK_DIR/idrac.yaml"
  handle_output "# Executing ansible playbook $IDRAC_YAML" TEXT
  if [ "$TEST_MODE" = "false" ]; then
    ansible-playbook "$IDRAC_YAML" -i "$HOSTS_YAML"
  fi
}

# Function: create_export
#
# Setup NFS server to export ISO

create_export () {
  NFS_DIR="$WORK_DIR/files"
  EXPORTS_FILE="/etc/exports"
  handle_output "# Check NFS export is enabled" TEXT
  if [ -f "$EXPORTS_FILE" ]; then
    EXPORT_CHECK=$( grep -v "^#" < "$EXPORTS_FILE" |grep "$NFS_DIR" |grep "$BMC_IP" |awk '{print $1}' | head -1 )
  else
    EXPORT_CHECK=""
  fi
  if [ -z "$EXPORT_CHECK" ]; then
    if [ "$OS_NAME" = "Darwin" ]; then
      echo "$NFS_DIR --mapall=$OS_USER $BMC_IP" |sudo tee -a "$EXPORTS_FILE"
      sudo nfsd enable
      sudo nfsd restart
    else
      echo "$NFS_DIR $BMC_IP(sync,wdelay,hide,no_subtree_check,sec=sys,rw,secure,root_squash,no_all_squash)" |sudo tee -a "$EXPORTS_FILE"
      sudo exportfs -a
    fi
    print_file "$EXPORTS_FILE"
  fi
}

# Function: copy_squashfs
#
# Mount squashfs and copy files into it
#
# Examples:
# sudo mount -t squashfs -o loop ./isomount/casper/ubuntu-server-minimal.squashfs ./isonew/squashfs/
# sudo rsync -av ./isonew/squashfs/ ./isonew/custom
# sudo cp /etc/resolv.conf /etc/hosts ./isonew/custom/etc/

copy_squashfs () {
  handle_output "# Copying squashfs files" TEXT
  if [ ! -f "/usr/bin/rsync" ]; then
    install_required_packages
  fi
  CURRENT_KERNEL=$( uname -r )
  if [ -f "$CURRENT_KERNEL" ]; then
    if [ "$TEST_MODE" = "false" ]; then
      sudo mount -t squashfs -o loop "$ISO_SQUASHFS_FILE" "$ISO_NEW_DIR/squashfs"
    fi
    if [ "$VERBOSE_MODE" = "true" ]; then
      if [ "$TEST_MODE" = "false" ]; then
        sudo rsync -av "$ISO_NEW_DIR/squashfs/" "$ISO_NEW_DIR/custom"
      fi
    else
      if [ "$TEST_MODE" = "false" ]; then
        sudo rsync -a "$ISO_NEW_DIR/squashfs/" "$ISO_NEW_DIR/custom"
      fi
    fi
  else
    if [ "$TEST_MODE" = "false" ]; then
      sudo unsquashfs -f -d "$ISO_NEW_DIR/custom" "$ISO_SQUASHFS_FILE"
    fi
  fi
  if [ "$TEST_MODE" = "false" ]; then
    sudo cp /etc/resolv.conf /etc/hosts "$ISO_NEW_DIR/custom/etc"
  fi
}

# Function: execute_chroot_script
#
#  Chroot into environment and run script on chrooted environmnet
#
# Examples:
# sudo chroot ./isonew/custom

execute_chroot_script () {
  handle_output "# Executing chroot script" TEXT
  if [ "$TEST_MODE" = "false" ]; then
    sudo chroot "$ISO_NEW_DIR/custom" "/tmp/modify_chroot.sh"
  fi
}

# Function: update_iso_squashfs
#
# Update ISO squashfs

update_iso_squashfs () {
  handle_output "# Making squashfs (this will take a while)" TEXT
  if [ "$TEST_MODE" = "false" ]; then
    sudo mksquashfs "$ISO_NEW_DIR/custom" "$ISO_NEW_DIR/mksquash/filesystem.squashfs" -noappend
    sudo cp "$ISO_NEW_DIR/mksquash/filesystem.squashfs" "$NEW_SQUASHFS_FILE"
    sudo chmod 0444 i"$NEW_SQUASHFS_FILE"
    sudo echo -n $( sudo du -s --block-size=1 "$ISO_NEW_DIR/custom" | tail -1 | awk '{print $1}') | sudo tee "$ISO_NEW_DIR/mksquash/filesystem.size"
    sudo cp "$ISO_NEW_DIR/mksquash/filesystem.size" "$ISO_SOURCE_DIR/casper/filesystem.size"
    sudo chmod 0444 "$ISO_SOURCE_DIR/casper/filesystem.size"
    sudo find "$ISO_SOURCE_DIR" -type f -print0 | xargs -0 md5sum | sed "s@${ISO_NEW_DIR}@.@" | grep -v md5sum.txt | sudo tee "$ISO_SOURCE_DIR/md5sum.txt"
  fi
}

# Function: check_file_perms
#
# Check file permissions of file

check_file_perms () {
  handle_output "# Checking file permissions for $CHECK_FILE" TEXT
  CHECK_FILE="$1"
  if [ -f "$CHECK_FILE" ]; then
    MY_USER="$USER"
    MY_GROUP=$(groups |awk '{print $1}')
    FILE_USER=$(find "$OUTPUT_FILE" -ls |awk '{print $5}')
    if [ ! "$FILE_USER" = "$MY_USER" ]; then
      sudo chown "$MY_USER" "$CHECK_FILE"
      sudo chgrp "$MY_GROUP" "$CHECK_FILE"
    fi
  fi
}


# Function: create_chroot_script
#
# Create script to drop into chrooted environment
# Inside chrooted environment, mount filesystems and packages
#
# Examples:
# mount -t proc none /proc/
# mount -t sysfs none /sys/
# mount -t devpts none /dev/pts
# export HOME=/root
# sudo apt update
# sudo apt install -y --download-only zfsutils-linux grub-efi zfs-initramfs net-tools curl wget lftp
# sudo apt install -y zfsutils-linux grub-efi zfs-initramfs net-tools curl wget lftp
# umount /proc/
# umount /sys/
# umount /dev/pts/
# exit

create_chroot_script () {
  ORIG_SCRIPT="$WORK_DIR/files/modify_chroot.sh"
  ISO_CHROOT_SCRIPT="$ISO_NEW_DIR/custom/tmp/modify_chroot.sh"
  check_file_perms "$ORIG_SCRIPT"
  handle_output "# Creating chroot script $ISO_CHROOT_SCRIPT" TEXT
  if [ "$TEST_MODE" = "false" ]; then
    echo "#!/usr/bin/bash" > "$ORIG_SCRIPT"
    echo "mount -t proc none /proc/" >> "$ORIG_SCRIPT"
    echo "mount -t sysfs none /sys/" >> "$ORIG_SCRIPT"
    echo "mount -t devpts none /dev/pts" >> "$ORIG_SCRIPT"
    echo "export HOME=/root" >> "$ORIG_SCRIPT"
    echo "export DEBIAN_FRONTEND=noninteractive" >> "$ORIG_SCRIPT"
    if [ ! "$ISO_COUNTRY" = "us" ]; then
      echo "sed -i \"s/\\/archive/\\/$ISO_COUNTRY.archive/g\" /etc/apt/sources.list" >> "$ORIG_SCRIPT"
    fi
    echo "rm /var/cache/apt/archives/*.deb" >> "$ORIG_SCRIPT"
    echo "rm /etc/apt/apt.conf.d/20apt-esm-hook.conf" >> "$ORIG_SCRIPT"
    echo "rm /etc/update-motd.d/91-contract-ua-esm-status" >> "$ORIG_SCRIPT"
    echo "apt update" >> "$ORIG_SCRIPT"
    echo "export LC_ALL=C ; apt install -y --download-only $ISO_CHROOT_PACKAGES" >> "$ORIG_SCRIPT"
    echo "export LC_ALL=C ; apt install -y $ISO_CHROOT_PACKAGES --option=Dpkg::Options::=$ISO_DPKG_CONF" >> "$ORIG_SCRIPT"
    echo "umount /proc/" >> "$ORIG_SCRIPT"
    echo "umount /sys/" >> "$ORIG_SCRIPT"
    echo "umount /dev/pts/" >> "$ORIG_SCRIPT"
    echo "exit" >> "$ORIG_SCRIPT"
    if [ -f "/.dockerenv" ]; then
      if [ ! -d "$ISO_NEW_DIR/custom/tmp" ]; then
        sudo_create_dir "$ISO_NEW_DIR/custom/tmp"
      fi
    else
      if ! [[ "$OPTIONS" =~ "docker" ]]; then
        if [ ! -d "$ISO_NEW_DIR/custom/tmp" ]; then
          sudo_create_dir "$ISO_NEW_DIR/custom/tmp"
        fi
      fi
    fi
    sudo cp "$ORIG_SCRIPT" "$ISO_CHROOT_SCRIPT"
    sudo chmod +x "$ISO_CHROOT_SCRIPT"
    print_file "$ORIG_SCRIPT"
  fi
}

# Function: get_password_crypt
#
# Get password crypt
#
# echo test |mkpasswd --method=SHA-512 --stdin

get_password_crypt () {
  ISO_PASSWORD="$1"
  handle_output "# Generating password crypt" TEXT
  if [ "$OS_NAME" = "Darwin" ]; then
    if [ "$TEST_MODE" = "false" ]; then
      ISO_PASSWORD_CRYPT=$( echo -n "$ISO_PASSWORD" |openssl sha512 )
    fi
  else
    if [ ! -f "/usr/bin/mkpasswd" ]; then
      install_required_packages
    fi
    if [ "$TEST_MODE" = "false" ]; then
      ISO_PASSWORD_CRYPT=$( echo "$ISO_PASSWORD" |mkpasswd --method=SHA-512 --stdin )
    fi
  fi
  if [ "$ISO_PASSWORD_CRYPT" = "" ]; then
    warning_message "No Password Hash/Crypt created"
    exit
  fi
}

# Function: create_autoinstall_iso
#
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
  if [ ! -f "/usr/bin/xorriso" ]; then
    install_required_packages
  fi
  check_file_perms "$OUTPUT_FILE"
  handle_output "# Creating ISO" TEXT
  ISO_MBR_PART_TYPE=$( xorriso -indev "$INPUT_FILE" -report_el_torito as_mkisofs |grep iso_mbr_part_type |tail -1 |awk '{print $2}' 2>&1 )
  BOOT_CATALOG=$( xorriso -indev "$INPUT_FILE" -report_el_torito as_mkisofs |grep "^-c " |tail -1 |awk '{print $2}' |cut -f2 -d"'" 2>&1 )
  BOOT_IMAGE=$( xorriso -indev "$INPUT_FILE" -report_el_torito as_mkisofs |grep "^-b " |tail -1 |awk '{print $2}' |cut -f2 -d"'" 2>&1 )
  UEFI_BOOT_SIZE=$( xorriso -indev "$INPUT_FILE" -report_el_torito as_mkisofs |grep "^-boot-load-size" |tail -1 |awk '{print $2}' |cut -f2 -d"'" 2>&1 )
  DOS_BOOT_SIZE=$( xorriso -indev "$INPUT_FILE" -report_el_torito as_mkisofs |grep "^-boot-load-size" |head -1 |awk '{print $2}' |cut -f2 -d"'" 2>&1 )
  if [ "$ISO_MAJOR_REL" = "22" ]; then
    APPEND_PART=$( xorriso -indev "$INPUT_FILE" -report_el_torito as_mkisofs |grep append_partition |tail -1 |awk '{print $3}' 2>&1 )
    UEFI_IMAGE="--interval:appended_partition_2:::"
  else
    APPEND_PART="0xef"
    UEFI_IMAGE=$( xorriso -indev "$INPUT_FILE" -report_el_torito as_mkisofs |grep "^-e " |tail -1 |awk '{print $2}' |cut -f2 -d"'" 2>&1 )
  fi
  if [ "$TEST_MODE" = "false" ]; then
    if [ "$ISO_ARCH" = "amd64" ]; then
      xorriso -as mkisofs -r -V "$ISO_VOLID" -o "$OUTPUT_FILE" \
      --grub2-mbr "$WORK_DIR/BOOT/1-Boot-NoEmul.img" --protective-msdos-label -partition_cyl_align off \
      -partition_offset 16 --mbr-force-bootable -append_partition 2 "$APPEND_PART" "$WORK_DIR/BOOT/2-Boot-NoEmul.img" \
      -appended_part_as_gpt -iso_mbr_part_type "$ISO_MBR_PART_TYPE" -c "$BOOT_CATALOG" -b "$BOOT_IMAGE" \
      -no-emul-boot -boot-load-size "$DOS_BOOT_SIZE" -boot-info-table --grub2-boot-info -eltorito-alt-boot \
      -e "$UEFI_IMAGE" -no-emul-boot -boot-load-size "$UEFI_BOOT_SIZE" "$ISO_SOURCE_DIR"
    else
      xorriso -as mkisofs -r -V "$ISO_VOLID" -o "$OUTPUT_FILE" \
      -partition_cyl_align all -partition_offset 16 -partition_hd_cyl 86 -partition_sec_hd 32 \
      -append_partition 2 "$APPEND_PART" "$WORK_DIR/BOOT/Boot-NoEmul.img" -G "$WORK_DIR/BOOT/Boot-NoEmul.img" \
      -iso_mbr_part_type "$ISO_MBR_PART_TYPE" -c "$BOOT_CATALOG" \
      -e "$UEFI_IMAGE" -no-emul-boot -boot-load-size "$UEFI_BOOT_SIZE" "$ISO_SOURCE_DIR"
    fi
    if [ "$DO_DOCKER" = "true" ]; then
      BASE_DOCKER_OUTPUT_FILE=$( basename "$OUTPUT_FILE" )
      echo "# Output file will be at \"$PRE_WORK_DIR/files/$BASE_DOCKER_OUTPUT_FILE\""
    fi
  fi
}

# Function: prepare_autoinstall_iso
#
# Prepare sutoinstall ISO

prepare_autoinstall_iso () {
  if [ -f "/usr/bin/7z" ]; then
    install_required_packages
  fi
  handle_output "# Preparing autoinstall ISO" TEXT
  PACKAGE_DIR="$ISO_SOURCE_DIR/$ISO_AUTOINSTALL_DIR/packages"
  CASPER_DIR="$ISO_SOURCE_DIR/casper"
  SCRIPT_DIR="$ISO_SOURCE_DIR/$ISO_AUTOINSTALL_DIR/scripts"
  CONFIG_DIR="$ISO_SOURCE_DIR/$ISO_AUTOINSTALL_DIR/configs"
  FILES_DIR="$ISO_SOURCE_DIR/$ISO_AUTOINSTALL_DIR/files"
  BASE_INPUT_FILE=$( basename "$INPUT_FILE" )
  if [ "$TEST_MODE" = "false" ]; then
    7z -y x "$WORK_DIR/files/$BASE_INPUT_FILE" -o"$ISO_SOURCE_DIR"
    create_dir "$PACKAGE_DIR"
    cheate_dir "$SCRIPT_DIR"
    create_dir "$FILES_DIR"
    for ISO_DEVICE in $ISO_DEVICES; do
      for ISO_VOLMGR in $ISO_VOLMGRS; do
        handle_output "# Creating directory $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE" TEXT
        create_dir "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE"
        handle_output "# Creating $CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/meta-data"
        touch "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/meta-data"
      done
    done
    sudo rm "$PACKAGE_DIR"/*.deb
    handle_output "# Copying packages to $PACKAGE_DIR" TEXT
    if [ "$VERBOSE_MODE" = "true" ]; then
      sudo cp -v "$ISO_NEW_DIR"/custom/var/cache/apt/archives/*.deb "$PACKAGE_DIR"
    else
      sudo cp "$ISO_NEW_DIR"/custom/var/cache/apt/archives/*.deb "$PACKAGE_DIR"
    fi
    if [ "$DO_OLD_INSTALLER" = "true" ]; then
      handle_output "# Copying old installer files from $OLD_ISO_MOUNT_DIR/casper/ to $CASPER_DIR"
      mount_old_iso
      sudo cp "$OLD_ISO_MOUNT_DIR"/casper/*installer* "$CASPER_DIR/"
      umount_old_iso
    fi
  fi
  if [ -d "$WORK_DIR/BOOT" ]; then
    if [ "$TEST_MODE" = "false" ]; then
      if [ "$FORCE_MODE" = "true" ]; then
        rm -rf "$WORK_DIR/BOOT"
      fi
      create_dir "$WORK_DIR/BOOT"
      create_dir "$ISO_SOURCE_DIR/BOOT"
      cp -r "$ISO_SOURCE_DIR/[BOOT]"/* "$WORK_DIR/BOOT"/
      cp -r "$ISO_SOURCE_DIR/[BOOT]"/* "$ISO_SOURCE_DIR/BOOT"/
    fi
  else
    if [ "$TEST_MODE" = "false" ]; then
      create_dir "$WORK_DIR/BOOT"
      create_dir "$ISO_SOURCE_DIR/BOOT"
      cp -r "$ISO_SOURCE_DIR/[BOOT]"/* "$WORK_DIR/BOOT"/
      cp -r "$ISO_SOURCE_DIR/[BOOT]"/* "$ISO_SOURCE_DIR/BOOT"/
    fi
  fi
  if [ -f "$WORK_DIR/grub.cfg" ]; then
    handle_output "cp \"$WORK_DIR/grub.cfg\" \"$ISO_SOURCE_DIR/boot/grub/grub.cfg\""
    if [ "$TEST_MODE" = "false" ]; then
      cp "$WORK_DIR/grub.cfg" "$ISO_SOURCE_DIR/boot/grub/grub.cfg"
    fi
  else
    if [ "$TEST_MODE" = "false" ]; then
      sudo_create_dir "$ISO_SOURCE_DIR/isolinux"
      echo "default $ISO_GRUB_MENU" > "$ISO_SOURCE_DIR/isolinux/txt.cfg"
      COUNTER=0
      for ISO_DEVICE in $ISO_DEVICES; do
        for ISO_VOLMGR in $ISO_VOLMGRS; do
          echo "label $COUNTER" >> "$ISO_SOURCE_DIR/isolinux/txt.cfg"
          echo "  menu label ^$ISO_VOLID:$ISO_VOLMGR:$ISO_DEVICE:$ISO_NIC ($ISO_KERNEL_ARGS)" >> "$ISO_SOURCE_DIR/isolinux/txt.cfg"
          echo "  kernel /casper/vmlinuz" >> "$ISO_SOURCE_DIR/isolinux/txt.cfg"
          echo "  append  initrd=/casper/initrd $ISO_KERNEL_ARGS quiet autoinstall fsck.mode=skip ds=nocloud;s=$ISO_INSTALL_MOUNT/$ISO_AUTOINSTALL_DIR/configs/$ISO_VOLMGR/$ISO_DEVICE/  ---" >> "$ISO_SOURCE_DIR/isolinux/txt.cfg"
          COUNTER=$(( COUNTER+1 ))
        done
      done
      echo "label memtest" >> "$ISO_SOURCE_DIR/isolinux/txt.cfg"
      echo "  menu label Test ^Memory" >> "$ISO_SOURCE_DIR/isolinux/txt.cfg"
      echo "  kernel /install/mt86plus" >> "$ISO_SOURCE_DIR/isolinux/txt.cfg"
      echo "label hd" >> "$ISO_SOURCE_DIR/isolinux/txt.cfg"
      echo "  menu label ^Boot from first hard drive" >> "$ISO_SOURCE_DIR/isolinux/txt.cfg"
      echo "  localboot 0x80" >> "$ISO_SOURCE_DIR/isolinux/txt.cfg"
      echo "set timeout=$ISO_GRUB_TIMEOUT" > "$ISO_SOURCE_DIR/boot/grub/grub.cfg"
      echo "default=$ISO_GRUB_MENU" >> "$ISO_SOURCE_DIR/boot/grub/grub.cfg"
      echo "loadfont unicode" >> "$ISO_SOURCE_DIR/boot/grub/grub.cfg"
      for ISO_DEVICE in $ISO_DEVICES; do
        for ISO_VOLMGR in $ISO_VOLMGRS; do
          echo "menuentry '$ISO_VOLID:$ISO_VOLMGR:$ISO_DEVICE:$ISO_NIC ($ISO_KERNEL_ARGS)' {" >> "$ISO_SOURCE_DIR/boot/grub/grub.cfg"
          echo "  set gfxpayload=keep" >> "$ISO_SOURCE_DIR/boot/grub/grub.cfg"
          echo "  linux   /casper/vmlinuz $ISO_KERNEL_ARGS quiet autoinstall fsck.mode=skip ds=nocloud\;s=$ISO_INSTALL_MOUNT/$ISO_AUTOINSTALL_DIR/configs/$ISO_VOLMGR/$ISO_DEVICE/  ---" >> "$ISO_SOURCE_DIR/boot/grub/grub.cfg"
          echo "  initrd  /casper/initrd" >> "$ISO_SOURCE_DIR/boot/grub/grub.cfg"
          echo "}" >> "$ISO_SOURCE_DIR/boot/grub/grub.cfg"
        done
      done
      echo "menuentry 'Try or Install $ISO_VOLID' {" >> "$ISO_SOURCE_DIR/boot/grub/grub.cfg"
      echo "  set gfxpayload=keep" >> "$ISO_SOURCE_DIR/boot/grub/grub.cfg"
      echo "  linux /casper/vmlinuz quiet ---" >> "$ISO_SOURCE_DIR/boot/grub/grub.cfg"
      echo "  initrd  /casper/initrd" >> "$ISO_SOURCE_DIR/boot/grub/grub.cfg"
      echo "}" >> "$ISO_SOURCE_DIR/boot/grub/grub.cfg"
      echo "menuentry 'Boot from next volume' {" >> "$ISO_SOURCE_DIR/boot/grub/grub.cfg"
      echo "  exit 1" >> "$ISO_SOURCE_DIR/boot/grub/grub.cfg"
      echo "}" >> "$ISO_SOURCE_DIR/boot/grub/grub.cfg"
      if [[ "$ISO_BOOT_TYPE" =~ "efi" ]]; then
        echo "menuentry 'UEFI Firmware Settings' {" >> "$ISO_SOURCE_DIR/boot/grub/grub.cfg"
        echo "  fwsetup" >> "$ISO_SOURCE_DIR/boot/grub/grub.cfg"
        echo "}" >> "$ISO_SOURCE_DIR/boot/grub/grub.cfg"
      fi
    fi
  fi
  for ISO_DEVICE in $ISO_DEVICES; do
    for ISO_VOLMGR in $ISO_VOLMGRS; do
      if [ -e "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data" ]; then
        rm "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
      fi
      if [ "$TEST_MODE" = "false" ]; then
        if [ "$DO_CUSTOM_AUTO_INSTALL" = "true" ]; then
          cp "$AUTO_INSTALL_FILE" "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
        else
          echo "#cloud-config" > "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
          echo "autoinstall:" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
          echo "  apt:" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
          echo "    preferences:" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
          echo "      - package: \"*\"" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
          echo "        pin: \"release a=$ISO_CODENAME-security\"" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
          echo "        pin-priority: 200" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
          echo "    disable_components: []" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
          echo "    geoip: true" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
          echo "    preserve_sources_list: false" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
          echo "    primary:" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
          echo "    - arches:" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
          echo "      - $ISO_ARCH" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
          echo "      uri: http://archive.ubuntu.com/ubuntu" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
          echo "    - arches:" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
          echo "      - default" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
          echo "      uri: http://ports.ubuntu.com/ubuntu-ports" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
          echo "  package_update: $DO_INSTALL_ISO_UPDATE" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
          echo "  package_upgrade: $DO_INSTALL_ISO_UPGRADE" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
          echo "  drivers:" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
          echo "    install: $DO_INSTALL_ISO_DRIVERS" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
          echo "  user-data:" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
          echo "    timezone: $ISO_TIMEZONE" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
          echo "  identity:" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
          echo "    hostname: $ISO_HOSTNAME" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
          echo "    password: \"$ISO_PASSWORD_CRYPT\"" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
          echo "    realname: $ISO_REALNAME" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
          echo "    username: $ISO_USERNAME" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
          echo "  kernel:" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
          echo "    package: $ISO_KERNEL" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
          echo "  keyboard:" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
          echo "    layout: $ISO_LAYOUT" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
          echo "  locale: $ISO_LOCALE" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
          echo "  network:" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
          echo "    ethernets:" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
          echo "      $ISO_NIC:" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
          if [ "$ISO_DHCP" = "true" ]; then
            echo "        critical: true" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
            echo "        dhcp-identifier: mac" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
            echo "        dhcp4: $ISO_DHCP" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
          else
            echo "        addresses:" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
            echo "        - $ISO_IP/$ISO_CIDR" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
            echo "        gateway4: $ISO_GATEWAY" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
            echo "        nameservers:" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
            echo "          addresses:" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
            echo "          - $ISO_DNS" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
          fi
          echo "    version: 2" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
          echo "  ssh:" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
          echo "    allow-pw: $ISO_ALLOW_PASSWORD" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
          echo "    authorized-keys: [ \"$ISO_SSH_KEY\" ]" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
          echo "    install-server: true" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
          echo "  storage:" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
          if [[ "$ISO_VOLMGR" =~ "fs" ]]; then
            if [ "$ISO_VOLMGR" = "zfs-lvm" ]; then
              echo "    config:" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
              echo "    - ptable: gpt" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
              echo "      path: /dev/$ISO_DEVICE" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
              echo "      wipe: superblock-recursive" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
              echo "      preserve: false" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
              echo "      name: ''" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
              echo "      grub_device: false" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
              echo "      type: disk" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
              echo "      id: disk-$ISO_DEVICE" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
              echo "    - device: disk-$ISO_DEVICE" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
              echo "      size: 1127219200" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
              echo "      wipe: superblock" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
              echo "      flag: boot" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
              echo "      number: 1" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
              echo "      preserve: false" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
              echo "      grub_device: true" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
              echo "      offset: 1048576" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
              echo "      path: /dev/${ISO_DEVICE}1" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
              echo "      type: partition" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
              echo "      id: partition-0" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
              echo "    - fstype: fat32" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
              echo "      volume: partition-0" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
              echo "      preserve: false" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
              echo "      type: format" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
              echo "      id: format-0" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
              echo "    - device: disk-$ISO_DEVICE" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
              echo "      size: 2147483648" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
              echo "      wipe: superblock" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
              echo "      number: 2" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
              echo "      preserve: false" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
              echo "      grub_device: false" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
              echo "      offset: 1128267776" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
              echo "      path: /dev/${ISO_DEVICE}2" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
              echo "      type: partition" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
              echo "      id: partition-1" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
              if [[ "$ISO_VOLMGR" =~ "zfs" ]]; then
                echo "      type: partition" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "    - device: disk-$ISO_DEVICE" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      size: 4104126464" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      wipe: superblock" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      flag: swap" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      number: 3" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      preserve: false" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      offset: 3275751424" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      path: /dev/${ISO_DEVICE}3" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      id: partition-2" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      type: partition" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "    - fstype: swap" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      volume: partition-2" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      preserve: false" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      id: format-1" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      type: format" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "    - path: ''" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      device: format-1" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      id: mount-1" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      type: mount" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "    - device: disk-$ISO_DEVICE" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      size: -1" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      number: 4" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      preserve: false" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      offset: 7379877888" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      path: /dev/${ISO_DEVICE}4" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      id: partition-3" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      type: partition" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "    - vdevs:" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      - partition-1" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      pool: bpool" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      mountpoint: /boot" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      pool_properties:" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "        ashift: 12" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "        autotrim: 'on'" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "        feature@async_destroy: enabled" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "        feature@bookmarks: enabled" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "        feature@embedded_data: enabled" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "        feature@empty_bpobj: enabled" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "        feature@enabled_txg: enabled" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "        feature@extensible_dataset: enabled" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "        feature@filesystem_limits: enabled" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "        feature@hole_birth: enabled" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "        feature@large_blocks: enabled" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "        feature@lz4_compress: enabled" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "        feature@spacemap_histogram: enabled" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "        version: null" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      fs_properties:" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "        acltype: posixacl" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "        atime: null" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "        canmount: 'off'" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "        compression: lz4" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "        devices: 'off'" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "        normalization: formD" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "        relatime: 'on'" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "        sync: standard" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "        xattr: sa" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      default_features: false" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      id: zpool-0" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      type: zpool" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "    - pool: zpool-0" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      volume: BOOT" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      properties:" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "        canmount: 'off'" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "        mountpoint: none" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      id: zfs-0" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      type: zfs" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "    - vdevs:" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      - partition-3" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      pool: rpool" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      mountpoint: /" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      pool_properties:" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "        ashift: 12" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "        autotrim: 'on'" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "        version: null" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      fs_properties:" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "        acltype: posixacl" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "        atime: null" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "        canmount: 'off'" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "        compression: lz4" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "        devices: 'off'" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "        dnodesize: auto" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "        normalization: formD" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "        relatime: 'on'" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "        sync: standard" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "        xattr: sa" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      default_features: true" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      id: zpool-1" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      type: zpool" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "    - pool: zpool-1 " >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      volume: ROOT" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      properties:" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "        canmount: 'off'" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "        mountpoint: none" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      id: zfs-2" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      type: zfs" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "    - pool: zpool-1" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      volume: ROOT/ubuntu_install" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      properties:" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "        canmount: 'on'" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "        mountpoint: /" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      id: zfs-3" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      type: zfs" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                ZFS_FS_COUNTER=4
                for ZFS_FILESYSTEM in $ZFS_FILESYSTEMS; do
                  echo "    - pool: zpool-1" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                  echo "      volume: ROOT/ubuntu_install$ZFS_FILESYSTEM" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                  echo "      properties:" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                  echo "        canmount: 'on'" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                  echo "      id: zfs-$ZFS_FS_COUNTER" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                  echo "      type: zfs" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                  ZFS_FS_COUNTER=$(( ZFS_FS_COUNTER+1 ))
                done
                echo "    - zpool: zpool-0" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      volume: BOOT/ubuntu_install" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      properties:" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "        canmount: 'on'" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "        mountpoint: /boot" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      id: zfs-1" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      type: zfs" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "    - path: /boot/efi" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      device: format-0" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      id: mount-0" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      type: mount" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "    swap:" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      size: 0" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
              else
                echo "    - fstype: ext4" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      volume: partition-1" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      preserve: false" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      type: format" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      id: format-1" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "    - device: disk-$ISO_DEVICE" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      size: -1" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      wipe: superblock" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      number: 3" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      preserve: false" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      grub_device: false" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      offset: 3275751424" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      path: /dev/${ISO_DEVICE}3" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      type: partition" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      id: partition-2" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "    - name: ubuntu-vg" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      devices:" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      - partition-2" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      preserve: false" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      type: lvm_volgroup" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      id: lvm_volgroup-0" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "    - name: ubuntu-lv" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      volgroup: lvm_volgroup-0" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      size: -1" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      wipe: superblock" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      preserve: false" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      path: /dev/ubuntu-vg/ubuntu-lv" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      type: lvm_partition" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      id: lvm_partition-0" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "    - fstype: $ISO_VOLMGR" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      volume: lvm_partition-0" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      preserve: false" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      type: format" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      id: format-3" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "    - path: /" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      device: format-3" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      type: mount" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      id: mount-3" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "    - path: /boot" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      device: format-1" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      type: mount" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      id: mount-1" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "    - path: /boot/$ISO_BOOT_TYPE" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      device: format-0" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      type: mount" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      id: mount-0" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
              fi
            else
              if [ "$ISO_VOLMGR" = "zfs" ]; then
                echo "    config:" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "    - ptable: gpt" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      path: /dev/$ISO_DEVICE" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      wipe: superblock-recursive" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      preserve: false" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      name: ''" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      grub_device: true" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      type: disk" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      id: disk1" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "    - device: disk1" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      size: 1127219200" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      wipe: superblock-recursive" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      flag: boot" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      number: 1" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      preserve: false" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      grub_device: true" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      type: partition" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      ptable: gpt" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      id: disk1p1" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "    - fstype: fat32" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      volume: disk1p1" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      preserve: false" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      type: format" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      id: disk1p1fs1" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "    - path: /boot/$ISO_BOOT_TYPE" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      device: disk1p1fs1" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      type: mount" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      id: mount-2" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "    - device: disk1" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      size: -1" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      wipe: superblock-recursive" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      flag: root" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      number: 2" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      preserve: false" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      grub_device: false" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      type: partition" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      id: disk1p2" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "    - id: disk1p2fs1" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      type: format" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      fstype: zfsroot" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      volume: disk1p2" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      preserve: false" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "    - id: disk1p2f1_rootpool" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      mountpoint: /" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      pool: rpool" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      type: zpool" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      device: disk1p2fs1" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      preserve: false" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      vdevs:" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "        - disk1p2fs1" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "    - id: disk1_rootpool_container" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      pool: disk1p2f1_rootpool" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      preserve: false" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      properties:" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "        canmount: \"off\"" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "        mountpoint: \"none\"" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      type: zfs" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      volume: /ROOT" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "    - id: disk1_rootpool_rootfs" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      pool: disk1p2f1_rootpool" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      preserve: false" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      properties:" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "        canmount: noauto" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "        mountpoint: /" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      type: zfs" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      volume: /ROOT/zfsroot" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "    - path: /" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      device: disk1p2fs1" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      type: mount" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      id: mount-disk1p2fs1" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "    swap:" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      swap: $ISO_SWAPSIZE" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
              else
                echo "    config:" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "    - ptable: gpt" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      path: /dev/$ISO_DEVICE" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      wipe: superblock-recursive" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      preserve: false" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      name: ''" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      grub_device: true" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      type: disk" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      id: disk-$ISO_DEVICE" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "    - device: disk-$ISO_DEVICE" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      size: 1127219200" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      wipe: superblock" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      flag: boot" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      number: 1" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      preserve: false" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      grub_device: true" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      offset: 1048576" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      path: /dev/${ISO_DEVICE}1" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      type: partition" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      id: partition-0" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "    - fstype: fat32" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      volume: partition-0" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      preserve: false" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      type: format" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      id: format-0" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "    - device: disk-$ISO_DEVICE" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      size: 2147483648" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      wipe: superblock" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      number: 2" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      preserve: false" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      grub_device: false" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      offset: 1128267776" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      path: /dev/${ISO_DEVICE}2" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      type: partition" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      id: partition-1" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "    - fstype: ext4" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      volume: partition-1" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      preserve: false" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      type: format" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      id: format-1" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "    - device: disk-$ISO_DEVICE" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      size: -1" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      wipe: superblock" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      number: 3" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      preserve: false" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      grub_device: false" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      offset: 3275751424" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      path: /dev/${ISO_DEVICE}3" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      type: partition" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      id: partition-2" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "    - name: ubuntu-vg" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      devices:" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      - partition-2" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      preserve: false" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      type: lvm_volgroup" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      id: lvm_volgroup-0" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "    - name: ubuntu-lv" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      volgroup: lvm_volgroup-0" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      size: -1" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      wipe: superblock" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      preserve: false" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      path: /dev/ubuntu-vg/ubuntu-lv" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      type: lvm_partition" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      id: lvm_partition-0" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "    - fstype: $ISO_VOLMGR" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      volume: lvm_partition-0" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      preserve: false" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      type: format" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      id: format-3" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "    - path: /" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      device: format-3" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      type: mount" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      id: mount-3" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "    - path: /boot" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      device: format-1" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      type: mount" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      id: mount-1" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "    - path: /boot/$ISO_BOOT_TYPE" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      device: format-0" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      type: mount" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "      id: mount-0" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
              fi
            fi
          fi
          if [ "$ISO_VOLMGR" = "lvm" ]; then
            echo "    layout:" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
            echo "      name: lvm" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
          fi
          echo "  early-commands:" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
          if ! [ "$ISO_ALLOWLIST" = "" ]; then
            if [[ "$ISO_ALLOWLIST" =~ "," ]]; then
              for MODULE in $(${ISO_ALLOWLIST//,/ }); do
                echo "    - \"echo '$MODULE' > /etc/modules-load.d/$MODULE.conf\"" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "    - \"modprobe $MODULE\"" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
              done
            else
              echo "    - \"echo '$ISO_ALLOWLIST' > /etc/modules-load.d/$ISO_BLOCKLIST.conf\"" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
              echo "    - \"modprobe $ISO_ALLOWLIST\"" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
            fi
          fi
          if [ "$ISO_DEVICE" = "first-disk" ]; then
            if [ ! "$ISO_VOLMGR" = "lvm" ]; then
              echo "    - \"sed -i \\\"s/first-disk/\$(lsblk -x TYPE|grep disk |sort |head -1 |awk '{print \$1}')/g\\\" /autoinstall.yaml\"" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
            fi
          fi
          if [ "$ISO_NIC" = "first-net" ]; then
            echo "    - \"sed -i \\\"s/first-net/\$(lshw -class network -short |awk '{print \$2}' |grep ^e |head -1)/g\\\" /autoinstall.yaml\"" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
          fi
          NO_DEBS=$( ls "$PACKAGE_DIR"/*.deb |wc -l)
          if [ ! "$NO_DEBS" = "0" ]; then
            echo "    - \"export DEBIAN_FRONTEND=\\\"noninteractive\\\" && dpkg $ISO_DPKG_CONF $ISO_DPKG_OVERWRITE --auto-deconfigure $ISO_DPKG_DEPENDS -i $ISO_INSTALL_MOUNT/$ISO_AUTOINSTALL_DIR/packages/*.deb\"" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
          fi
          echo "    - \"rm /etc/resolv.conf\"" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
          echo "    - \"echo \\\"nameserver $ISO_DNS\\\" >> /etc/resolv.conf\"" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
          if ! [ "$ISO_BLOCKLIST" = "" ]; then
            if [[ "$ISO_BLOCKLIST" =~ "," ]]; then
              for MODULE in $(${ISO_BLOCKLIST//,/ }); do
                echo "    - \"echo 'blacklist $MODULE' > /etc/modprobe.d/$MODULE.conf\"" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
                echo "    - \"modprobe -r $MODULE --remove-dependencies\"" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
              done
            else
              echo "    - \"echo 'blacklist $ISO_BLOCKLIST' > /etc/modprobe.d/$ISO_BLOCKLIST.conf\"" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
              echo "    - \"modprobe -r $ISO_BLOCKLIST --remove-dependencies\"" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
            fi
          fi
          echo "  late-commands:" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
          if [ ! "$NO_DEBS" = "0" ]; then
            echo "    - \"mkdir -p $ISO_TARGET_MOUNT/var/postinstall/packages\"" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
            echo "    - \"cp $ISO_INSTALL_MOUNT/$ISO_AUTOINSTALL_DIR/packages/*.deb $ISO_TARGET_MOUNT/var/postinstall/packages/\"" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
            echo "    - \"echo '#!/bin/bash' > $ISO_TARGET_MOUNT/tmp/post.sh\"" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
            echo "    - \"echo 'export DEBIAN_FRONTEND=\\\"noninteractive\\\" && dpkg $ISO_DPKG_CONF $ISO_DPKG_OVERWRITE --auto-deconfigure $ISO_DPKG_DEPENDS -i /var/postinstall/packages/*.deb' >> $ISO_TARGET_MOUNT/tmp/post.sh\"" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
            echo "    - \"chmod +x $ISO_TARGET_MOUNT/tmp/post.sh\"" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
          fi
          echo "    - \"echo '$ISO_TIMEZONE' > $ISO_TARGET_MOUNT/etc/timezone\"" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
          echo "    - \"rm $ISO_TARGET_MOUNT/etc/localtime\"" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
          echo "    - \"curtin in-target --target=$ISO_TARGET_MOUNT -- ln -s /usr/share/zoneinfo/$ISO_TIMEZONE /etc/localtime\"" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
          if [ ! "$ISO_COUNTRY" = "us" ]; then
            echo "    - \"curtin in-target --target=$ISO_TARGET_MOUNT -- sed -i \\\"s/\\\/archive/\\\/$ISO_COUNTRY.archive/g\\\" /etc/apt/sources.list\"" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
          fi
          if [ ! "$NO_DEBS" = "0" ]; then
            echo "    - \"curtin in-target --target=$ISO_TARGET_MOUNT -- /tmp/post.sh\"" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
          fi
          if [ "$DO_SERIAL" = "true" ]; then
            echo "    - \"echo 'GRUB_TERMINAL=\\\"serial console\\\"' >> $ISO_TARGET_MOUNT/etc/default/grub\"" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
            echo "    - \"echo 'GRUB_SERIAL_COMMAND=\\\"serial --speed=$ISO_SERIAL_PORT_SPEED0 --port=$ISO_SERIAL_PORT_ADDRESS0\\\"' >> $ISO_TARGET_MOUNT/etc/default/grub\"" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
          else
            echo "    - \"echo 'GRUB_TERMINAL=\\\"console\\\"' >> $ISO_TARGET_MOUNT/etc/default/grub\"" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
          fi
          echo "    - \"echo 'GRUB_CMDLINE_LINUX=\\\"console=tty0 $ISO_KERNEL_ARGS\\\"' >> $ISO_TARGET_MOUNT/etc/default/grub\"" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
          echo "    - \"echo 'GRUB_TIMEOUT=\\\"$ISO_GRUB_TIMEOUT\\\"' >> $ISO_TARGET_MOUNT/etc/default/grub\"" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
          echo "    - \"echo '$ISO_USERNAME ALL=(ALL) NOPASSWD: ALL' >> $ISO_TARGET_MOUNT/etc/sudoers.d/$ISO_USERNAME\"" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
          if [ "$DO_ISO_AUTO_UPGRADES" = "false" ]; then
            echo "    - \"echo 'APT::Periodic::Update-Package-Lists \\\"0\\\";' > $ISO_TARGET_MOUNT/etc/apt/apt.conf.d/20auto-upgrades\"" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
            echo "    - \"echo 'APT::Periodic::Download-Upgradeable-Packages \\\"0\\\";' >> $ISO_TARGET_MOUNT/etc/apt/apt.conf.d/20auto-upgrades\"" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
            echo "    - \"echo 'APT::Periodic::AutocleanInterval \\\"0\\\";' >> $ISO_TARGET_MOUNT/etc/apt/apt.conf.d/20auto-upgrades\"" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
            echo "    - \"echo 'APT::Periodic::Unattended-Upgrade \\\"0\\\";' >> $ISO_TARGET_MOUNT/etc/apt/apt.conf.d/20auto-upgrades\"" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
          fi
          if [ "$DO_SERIAL" = "true" ]; then
            echo "    - \"curtin in-target --target=$ISO_TARGET_MOUNT -- systemctl enable serial-getty@ttyS0.service\"" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
            echo "    - \"curtin in-target --target=$ISO_TARGET_MOUNT -- systemctl start serial-getty@ttyS0.service\"" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
            echo "    - \"curtin in-target --target=$ISO_TARGET_MOUNT -- systemctl enable serial-getty@ttyS1.service\"" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
            echo "    - \"curtin in-target --target=$ISO_TARGET_MOUNT -- systemctl start serial-getty@ttyS1.service\"" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
            echo "    - \"curtin in-target --target=$ISO_TARGET_MOUNT -- systemctl enable serial-getty@ttyS4.service\"" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
            echo "    - \"curtin in-target --target=$ISO_TARGET_MOUNT -- systemctl start serial-getty@ttyS4.service\"" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
          fi
          echo "    - \"curtin in-target --target=$ISO_TARGET_MOUNT -- update-grub\"" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
          if [ "$DO_INSTALL_ISO_NETWORK_UPDATES" = "true" ]; then
            if [ "$DO_INSTALL_ISO_UPDATE" = "true" ] || [ "$DO_INSTALL_ISO_DIST_UPGRADE" = "true" ]; then
              echo "    - \"curtin in-target --target=$ISO_TARGET_MOUNT -- apt update\"" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
            fi
            if [ "$DO_INSTALL_ISO_UPGRADE" = "true" ]; then
              echo "    - \"curtin in-target --target=$ISO_TARGET_MOUNT -- apt upgrade -y\"" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
            fi
            if [ "$DO_INSTALL_ISO_DIST_UPGRADE" = "true" ]; then
              echo "    - \"curtin in-target --target=$ISO_TARGET_MOUNT -- apt dist-upgrade -y\"" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
            fi
            if [ "$DO_INSTALL_ISO_PACKAGES" = "true" ]; then
              echo "    - \"curtin in-target --target=$ISO_TARGET_MOUNT -- apt install -y $ISO_INSTALL_PACKAGES\"" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
            fi
            if [ "$ISO_MAJOR_REL" = "22" ]; then
              if [ "$DO_ISO_APT_NEWS" = "false" ]; then
                echo "    - \"curtin in-target --target=$ISO_TARGET_MOUNT -- pro config set apt_news=false\"" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
              fi
            fi
          fi
          echo "  version: 1" >> "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
          print_file "$CONFIG_DIR/$ISO_VOLMGR/$ISO_DEVICE/user-data"
        fi
      fi
    done
  done
}

# Check if KVM VM exists

check_kvm_vm_exists () {
  KVM_TEST=$(sudo virsh list --all |awk '{ print $2 }' |grep "^$VM_NAME")
  if [ "$KVM_TEST" = "$VM_NAME" ]; then
    warning_message "KVM VM $VM_NAME exists"
    VM_EXISTS="true"
  fi
}

# Create a KVM VM for testing an ISO

create_kvm_vm () {
  VIRT_DIR="/var/lib/libvirt"
  QEMU_DIR="$VIRT_DIR/qemu"
  NVRAM_DIR="$QEMU_DIR/nvram"
  IMAGE_DIR="$VIRT_DIR/images"
  NVRAM_FILE="$NVRAM_DIR/${VM_NAME}_VARS.fd"
  VM_DISK="$IMAGE_DIR/$VM_NAME.qcow2"
  BIOS_FILE="/usr/share/OVMF/OVMF_CODE.fd"
  VARS_FILE="/usr/share/OVMF/OVMF_VARS.fd"
  if ! [ -f "$BIOS_FILE" ]; then
    BIOS_FILE="/usr/share/edk2/x64/OVMF_CODE.fd"
    VARS_FILE="/usr/share/edk2/x64/OVMF_VARS.fd"
  fi
  if ! [ -f "$BIOS_FILE" ]; then
    TEMP_VERBOSE_MODE="true"
    warning_message "Could not find BIOS file"
    exit
  fi
  information_message "Creating VM disk $VM_DISK"
  execution_message "sudo qemu-img create -f qcow2 $VM_DISK $VM_SIZE"
  if [ "$TEST_MODE" = "false" ]; then
    sudo qemu-img create -f qcow2 "$VM_DISK" "$VM_SIZE"
  fi
  information_message "Generating VM config $XML_FILE"
  XML_FILE="/tmp/$VM_NAME.xml"
  echo "<domain type='kvm'>" > "$XML_FILE"
  echo "  <name>$VM_NAME</name>" >> "$XML_FILE"
  echo "  <metadata>" >> "$XML_FILE"
  echo "    <libosinfo:libosinfo xmlns:libosinfo=\"http://libosinfo.org/xmlns/libvirt/domain/1.0\">" >> "$XML_FILE"
  echo "      <libosinfo:os id=\"http://ubuntu.com/ubuntu/22.04\"/>" >> "$XML_FILE"
  echo "    </libosinfo:libosinfo>" >> "$XML_FILE"
  echo "  </metadata>" >> "$XML_FILE"
  echo "  <memory unit='KiB'>$VM_RAM</memory>" >> "$XML_FILE"
  echo "  <currentMemory unit='KiB'>$VM_RAM</currentMemory>" >> "$XML_FILE"
  echo "  <vcpu placement='static'>$VM_CPUS</vcpu>" >> "$XML_FILE"
  if [ "$ISO_BOOT_TYPE" = "bios" ]; then
    echo "  <os>" >> "$XML_FILE"
    echo "    <type arch='x86_64' machine='pc-q35-8.1'>hvm</type>" >> "$XML_FILE"
  else
    echo "  <os firmware='efi'>" >> "$XML_FILE"
    echo "    <type arch='x86_64' machine='pc-q35-8.1'>hvm</type>" >> "$XML_FILE"
    echo "    <firmware>" >> "$XML_FILE"
    echo "      <feature enabled='no' name='enrolled-keys'/>" >> "$XML_FILE"
    echo "      <feature enabled='no' name='secure-boot'/>" >> "$XML_FILE"
    echo "    </firmware>" >> "$XML_FILE"
    echo "    <loader readonly='yes' type='pflash'>$BIOS_FILE</loader>" >> "$XML_FILE"
    echo "    <nvram template='$VARS_FILE'>$NVRAM_FILE</nvram>" >> "$XML_FILE"
    echo "    <bootmenu enable='yes'/>" >> "$XML_FILE"
  fi
  echo "  </os>" >> "$XML_FILE"
  echo "  <features>" >> "$XML_FILE"
  echo "    <acpi/>" >> "$XML_FILE"
  echo "    <apic/>" >> "$XML_FILE"
  echo "    <vmport state='off'/>" >> "$XML_FILE"
  echo "  </features>" >> "$XML_FILE"
  echo "  <cpu mode='host-passthrough' check='none' migratable='on'/>" >> "$XML_FILE"
  echo "  <clock offset='utc'>" >> "$XML_FILE"
  echo "    <timer name='rtc' tickpolicy='catchup'/>" >> "$XML_FILE"
  echo "    <timer name='pit' tickpolicy='delay'/>" >> "$XML_FILE"
  echo "    <timer name='hpet' present='no'/>" >> "$XML_FILE"
  echo "  </clock>" >> "$XML_FILE"
  echo "  <on_poweroff>destroy</on_poweroff>" >> "$XML_FILE"
  echo "  <on_reboot>restart</on_reboot>" >> "$XML_FILE"
  echo "  <on_crash>destroy</on_crash>" >> "$XML_FILE"
  echo "  <pm>" >> "$XML_FILE"
  echo "    <suspend-to-mem enabled='no'/>" >> "$XML_FILE"
  echo "    <suspend-to-disk enabled='no'/>" >> "$XML_FILE"
  echo "  </pm>" >> "$XML_FILE"
  echo "  <devices>" >> "$XML_FILE"
  echo "    <emulator>/usr/bin/qemu-system-x86_64</emulator>" >> "$XML_FILE"
  echo "    <disk type='file' device='disk'>" >> "$XML_FILE"
  echo "      <driver name='qemu' type='qcow2' discard='unmap'/>" >> "$XML_FILE"
  echo "      <source file='$VM_DISK'/>" >> "$XML_FILE"
  echo "      <target dev='vda' bus='virtio'/>" >> "$XML_FILE"
  echo "      <boot order='2'/>" >> "$XML_FILE"
  echo "      <address type='pci' domain='0x0000' bus='0x04' slot='0x00' function='0x0'/>" >> "$XML_FILE"
  echo "    </disk>" >> "$XML_FILE"
  echo "    <disk type='file' device='cdrom'>" >> "$XML_FILE"
  echo "      <driver name='qemu' type='raw'/>" >> "$XML_FILE"
  echo "      <source file='$VM_ISO'/>" >> "$XML_FILE"
  echo "      <target dev='sda' bus='sata'/>" >> "$XML_FILE"
  echo "      <readonly/>" >> "$XML_FILE"
  echo "      <boot order='1'/>" >> "$XML_FILE"
  echo "      <address type='drive' controller='0' bus='0' target='0' unit='0'/>" >> "$XML_FILE"
  echo "    </disk>" >> "$XML_FILE"
  echo "    <controller type='usb' index='0' model='qemu-xhci' ports='15'>" >> "$XML_FILE"
  echo "      <address type='pci' domain='0x0000' bus='0x02' slot='0x00' function='0x0'/>" >> "$XML_FILE"
  echo "    </controller>" >> "$XML_FILE"
  echo "    <controller type='pci' index='0' model='pcie-root'/>" >> "$XML_FILE"
  echo "    <controller type='pci' index='1' model='pcie-root-port'>" >> "$XML_FILE"
  echo "      <model name='pcie-root-port'/>" >> "$XML_FILE"
  echo "      <target chassis='1' port='0x10'/>" >> "$XML_FILE"
  echo "      <address type='pci' domain='0x0000' bus='0x00' slot='0x02' function='0x0' multifunction='on'/>" >> "$XML_FILE"
  echo "    </controller>" >> "$XML_FILE"
  echo "    <controller type='pci' index='2' model='pcie-root-port'>" >> "$XML_FILE"
  echo "      <model name='pcie-root-port'/>" >> "$XML_FILE"
  echo "      <target chassis='2' port='0x11'/>" >> "$XML_FILE"
  echo "      <address type='pci' domain='0x0000' bus='0x00' slot='0x02' function='0x1'/>" >> "$XML_FILE"
  echo "    </controller>" >> "$XML_FILE"
  echo "    <controller type='pci' index='3' model='pcie-root-port'>" >> "$XML_FILE"
  echo "      <model name='pcie-root-port'/>" >> "$XML_FILE"
  echo "      <target chassis='3' port='0x12'/>" >> "$XML_FILE"
  echo "      <address type='pci' domain='0x0000' bus='0x00' slot='0x02' function='0x2'/>" >> "$XML_FILE"
  echo "    </controller>" >> "$XML_FILE"
  echo "    <controller type='pci' index='4' model='pcie-root-port'>" >> "$XML_FILE"
  echo "      <model name='pcie-root-port'/>" >> "$XML_FILE"
  echo "      <target chassis='4' port='0x13'/>" >> "$XML_FILE"
  echo "      <address type='pci' domain='0x0000' bus='0x00' slot='0x02' function='0x3'/>" >> "$XML_FILE"
  echo "    </controller>" >> "$XML_FILE"
  echo "    <controller type='pci' index='5' model='pcie-root-port'>" >> "$XML_FILE"
  echo "      <model name='pcie-root-port'/>" >> "$XML_FILE"
  echo "      <target chassis='5' port='0x14'/>" >> "$XML_FILE"
  echo "      <address type='pci' domain='0x0000' bus='0x00' slot='0x02' function='0x4'/>" >> "$XML_FILE"
  echo "    </controller>" >> "$XML_FILE"
  echo "    <controller type='pci' index='6' model='pcie-root-port'>" >> "$XML_FILE"
  echo "      <model name='pcie-root-port'/>" >> "$XML_FILE"
  echo "      <target chassis='6' port='0x15'/>" >> "$XML_FILE"
  echo "      <address type='pci' domain='0x0000' bus='0x00' slot='0x02' function='0x5'/>" >> "$XML_FILE"
  echo "    </controller>" >> "$XML_FILE"
  echo "    <controller type='pci' index='7' model='pcie-root-port'>" >> "$XML_FILE"
  echo "      <model name='pcie-root-port'/>" >> "$XML_FILE"
  echo "      <target chassis='7' port='0x16'/>" >> "$XML_FILE"
  echo "      <address type='pci' domain='0x0000' bus='0x00' slot='0x02' function='0x6'/>" >> "$XML_FILE"
  echo "    </controller>" >> "$XML_FILE"
  echo "    <controller type='pci' index='8' model='pcie-root-port'>" >> "$XML_FILE"
  echo "      <model name='pcie-root-port'/>" >> "$XML_FILE"
  echo "      <target chassis='8' port='0x17'/>" >> "$XML_FILE"
  echo "      <address type='pci' domain='0x0000' bus='0x00' slot='0x02' function='0x7'/>" >> "$XML_FILE"
  echo "    </controller>" >> "$XML_FILE"
  echo "    <controller type='pci' index='9' model='pcie-root-port'>" >> "$XML_FILE"
  echo "      <model name='pcie-root-port'/>" >> "$XML_FILE"
  echo "      <target chassis='9' port='0x18'/>" >> "$XML_FILE"
  echo "      <address type='pci' domain='0x0000' bus='0x00' slot='0x03' function='0x0' multifunction='on'/>" >> "$XML_FILE"
  echo "    </controller>" >> "$XML_FILE"
  echo "    <controller type='pci' index='10' model='pcie-root-port'>" >> "$XML_FILE"
  echo "      <model name='pcie-root-port'/>" >> "$XML_FILE"
  echo "      <target chassis='10' port='0x19'/>" >> "$XML_FILE"
  echo "      <address type='pci' domain='0x0000' bus='0x00' slot='0x03' function='0x1'/>" >> "$XML_FILE"
  echo "    </controller>" >> "$XML_FILE"
  echo "    <controller type='pci' index='11' model='pcie-root-port'>" >> "$XML_FILE"
  echo "      <model name='pcie-root-port'/>" >> "$XML_FILE"
  echo "      <target chassis='11' port='0x1a'/>" >> "$XML_FILE"
  echo "      <address type='pci' domain='0x0000' bus='0x00' slot='0x03' function='0x2'/>" >> "$XML_FILE"
  echo "    </controller>" >> "$XML_FILE"
  echo "    <controller type='pci' index='12' model='pcie-root-port'>" >> "$XML_FILE"
  echo "      <model name='pcie-root-port'/>" >> "$XML_FILE"
  echo "      <target chassis='12' port='0x1b'/>" >> "$XML_FILE"
  echo "      <address type='pci' domain='0x0000' bus='0x00' slot='0x03' function='0x3'/>" >> "$XML_FILE"
  echo "    </controller>" >> "$XML_FILE"
  echo "    <controller type='pci' index='13' model='pcie-root-port'>" >> "$XML_FILE"
  echo "      <model name='pcie-root-port'/>" >> "$XML_FILE"
  echo "      <target chassis='13' port='0x1c'/>" >> "$XML_FILE"
  echo "      <address type='pci' domain='0x0000' bus='0x00' slot='0x03' function='0x4'/>" >> "$XML_FILE"
  echo "    </controller>" >> "$XML_FILE"
  echo "    <controller type='pci' index='14' model='pcie-root-port'>" >> "$XML_FILE"
  echo "      <model name='pcie-root-port'/>" >> "$XML_FILE"
  echo "      <target chassis='14' port='0x1d'/>" >> "$XML_FILE"
  echo "      <address type='pci' domain='0x0000' bus='0x00' slot='0x03' function='0x5'/>" >> "$XML_FILE"
  echo "    </controller>" >> "$XML_FILE"
  echo "    <controller type='sata' index='0'>" >> "$XML_FILE"
  echo "      <address type='pci' domain='0x0000' bus='0x00' slot='0x1f' function='0x2'/>" >> "$XML_FILE"
  echo "    </controller>" >> "$XML_FILE"
  echo "    <controller type='virtio-serial' index='0'>" >> "$XML_FILE"
  echo "      <address type='pci' domain='0x0000' bus='0x03' slot='0x00' function='0x0'/>" >> "$XML_FILE"
  echo "    </controller>" >> "$XML_FILE"
  echo "    <interface type='network'>" >> "$XML_FILE"
  echo "      <mac address='52:54:00:2e:6c:5b'/>" >> "$XML_FILE"
  echo "      <source network='default'/>" >> "$XML_FILE"
  echo "      <model type='virtio'/>" >> "$XML_FILE"
  echo "      <address type='pci' domain='0x0000' bus='0x01' slot='0x00' function='0x0'/>" >> "$XML_FILE"
  echo "    </interface>" >> "$XML_FILE"
  echo "    <serial type='pty'>" >> "$XML_FILE"
  echo "      <target type='isa-serial' port='0'>" >> "$XML_FILE"
  echo "        <model name='isa-serial'/>" >> "$XML_FILE"
  echo "      </target>" >> "$XML_FILE"
  echo "    </serial>" >> "$XML_FILE"
  echo "    <console type='pty'>" >> "$XML_FILE"
  echo "      <target type='serial' port='0'/>" >> "$XML_FILE"
  echo "    </console>" >> "$XML_FILE"
  echo "    <channel type='unix'>" >> "$XML_FILE"
  echo "      <target type='virtio' name='org.qemu.guest_agent.0'/>" >> "$XML_FILE"
  echo "      <address type='virtio-serial' controller='0' bus='0' port='1'/>" >> "$XML_FILE"
  echo "    </channel>" >> "$XML_FILE"
  echo "    <channel type='spicevmc'>" >> "$XML_FILE"
  echo "      <target type='virtio' name='com.redhat.spice.0'/>" >> "$XML_FILE"
  echo "      <address type='virtio-serial' controller='0' bus='0' port='2'/>" >> "$XML_FILE"
  echo "    </channel>" >> "$XML_FILE"
  echo "    <input type='tablet' bus='usb'>" >> "$XML_FILE"
  echo "      <address type='usb' bus='0' port='1'/>" >> "$XML_FILE"
  echo "    </input>" >> "$XML_FILE"
  echo "    <input type='mouse' bus='ps2'/>" >> "$XML_FILE"
  echo "    <input type='keyboard' bus='ps2'/>" >> "$XML_FILE"
  echo "    <graphics type='spice' autoport='yes'>" >> "$XML_FILE"
  echo "      <listen type='address'/>" >> "$XML_FILE"
  echo "      <image compression='off'/>" >> "$XML_FILE"
  echo "    </graphics>" >> "$XML_FILE"
  echo "    <sound model='ich9'>" >> "$XML_FILE"
  echo "      <address type='pci' domain='0x0000' bus='0x00' slot='0x1b' function='0x0'/>" >> "$XML_FILE"
  echo "    </sound>" >> "$XML_FILE"
  echo "    <audio id='1' type='spice'/>" >> "$XML_FILE"
  echo "    <video>" >> "$XML_FILE"
  echo "      <model type='qxl' ram='65536' vram='65536' vgamem='16384' heads='1' primary='yes'/>" >> "$XML_FILE"
  echo "      <address type='pci' domain='0x0000' bus='0x00' slot='0x01' function='0x0'/>" >> "$XML_FILE"
  echo "    </video>" >> "$XML_FILE"
  echo "    <redirdev bus='usb' type='spicevmc'>" >> "$XML_FILE"
  echo "      <address type='usb' bus='0' port='2'/>" >> "$XML_FILE"
  echo "    </redirdev>" >> "$XML_FILE"
  echo "    <redirdev bus='usb' type='spicevmc'>" >> "$XML_FILE"
  echo "      <address type='usb' bus='0' port='3'/>" >> "$XML_FILE"
  echo "    </redirdev>" >> "$XML_FILE"
  echo "    <watchdog model='itco' action='reset'/>" >> "$XML_FILE"
  echo "    <memballoon model='virtio'>" >> "$XML_FILE"
  echo "      <address type='pci' domain='0x0000' bus='0x05' slot='0x00' function='0x0'/>" >> "$XML_FILE"
  echo "    </memballoon>" >> "$XML_FILE"
  echo "    <rng model='virtio'>" >> "$XML_FILE"
  echo "      <backend model='random'>/dev/urandom</backend>" >> "$XML_FILE"
  echo "      <address type='pci' domain='0x0000' bus='0x06' slot='0x00' function='0x0'/>" >> "$XML_FILE"
  echo "    </rng>" >> "$XML_FILE"
  echo "  </devices>" >> "$XML_FILE"
  echo "</domain>" >> "$XML_FILE"
  information_message "Importing VM config $XML_FILE"
  execution_message "sudo virsh define $XML_FILE"
  if [ "$TEST_MODE" = "false" ]; then
    sudo virsh define "$XML_FILE"
  fi
  verbose_message "To start the VM and connect to console run the following command:" TEXT
  verbose_message "" TEXT
  verbose_message "sudo virsh start $VM_NAME ; sudo virsh console $VM_NAME" TEXT
}

# Function: delete_kvm_vm
#
# Delete a KVM VM

delete_kvm_vm () {
  information_message "Stopping KVM VM $VM_NAME"
  execute_command "sudo virsh shutdown $VM_NAME"
  information_message "Deleting VM $VM_NAME"
  execute_command "sudo virsh undefine $VM_NAME --nvram"
}

# Function: delete_vm
# 
# Delete a VM

delete_vm () {
  if [ "$VM_TYPE" = "kvm" ]; then
    check_kvm_vm_exists
    if [ "$VM_EXISTS" = "true" ]; then
      delete_kvm_vm
    else
      information_message "KVM VM $VM_NAME does not exist"
    fi
  fi
}

# Function: create_vm
#
# Create a VM for testing an ISO

create_vm () {
  if [ "$VM_ISO" = "" ]; then
    if ! [ "$OUTPUT_FILE" = "" ]; then
      VM_ISO="$OUTPUT_FILE"
    fi
  fi
  if [ "$VM_TYPE" = "kvm" ]; then
    check_kvm_vm_exists
    if [ "$VM_EXISTS" = "false" ]; then
      create_kvm_vm
    else
      information_message "KVM VM $VM_NAME already exists"
    fi
  fi
}

# Function: process_options
#
# Process option switch

process_options () {
  if [[ "$OPTIONS" =~ "scp" ]]; then
    DO_SCP_HEADER="true"
  fi
  if [[ "$OPTIONS" =~ "confdef" ]] || [[ "$OPTIONS" =~ "confnew" ]]; then
    if [[ "$OPTIONS" =~ "confdef" ]]; then
      ISO_DPKG_CONF="--force-confdef"
    fi
    if [[ "$OPTIONS" =~ "confnew" ]]; then
      ISO_DPKG_CONF="--force-confnew"
    fi
  else
    ISO_DPKG_CONF="$DEFAULT_ISO_DPKG_CONF"
  fi
  if [[ "$OPTIONS" =~ "overwrite" ]]; then
    ISO_DPKG_OVERWRITE="--force-overwrite"
  else
    ISO_DPKG_OVERWRITE="$DEFAULT_ISO_DPKG_OVERWRITE"
  fi
  if [[ "$OPTIONS" =~ "depends" ]]; then
    ISO_DPKG_DEPENDS="--force-depends"
  else
    ISO_DPKG_DEPENDS="$DEFAULT_ISO_DPKG_DEPENDS"
  fi
  if [[ "$OPTIONS" =~ "latest" ]]; then
    DO_CHECK_ISO="true"
  fi
  if [[ "$OPTIONS" =~ "noserial" ]]; then
    DO_SERIAL="false"
  fi
  if [[ "$OPTIONS" =~ "nomultipath" ]]; then
    if [ "$ISO_BLOCKLIST" = "" ]; then
      ISO_BLOCKLIST="md_multipath"
    else
      ISO_BLOCKLIST="$ISO_BLOCKLIST,md_multipath"
    fi
  fi
  if [[ "$OPTIONS" =~ "cluster" ]]; then
    DEFAULT_ISO_INSTALL_PACKAGES="$DEFAULT_ISO_INSTALL_PACKAGES pcs pacemaker cockpit cockpit-machines resource-agents-extra resource-agents-common resource-agents-base glusterfs-server"
  fi
  if [[ "$OPTIONS" =~ "kvm" ]]; then
    DEFAULT_ISO_INSTALL_PACKAGES="$DEFAULT_ISO_INSTALL_PACKAGES cpu-checker qemu-kvm libvirt-daemon-system libvirt-clients bridge-utils virt-manager cloud-image-utils"
  fi
  if [[ "$OPTIONS" =~ "sshkey" ]]; then
    DO_ISO_SSH_KEY="true"
  fi
  if [[ "$OPTIONS" =~ "biosdevname" ]]; then
    ISO_USE_BIOSDEVNAME="true"
  else
    ISO_USE_BIOSDEVNAME="false"
  fi
  if [[ "$OPTIONS" =~ "nounmount" ]]; then
    DO_NO_UNMOUNT_ISO="true";
  else
    DO_NO_UNMOUNT_ISO="false";
  fi
  if [[ "$OPTIONS" =~ "testmode" ]]; then
    TEST_MODE="true";
  else
    TEST_MODE="false";
  fi
  if [[ "$OPTIONS" =~ "efi" ]]; then
    ISO_BOOT_TYPE="efi";
  fi
  if [[ "$OPTIONS" =~ "bios" ]]; then
    ISO_BOOT_TYPE="bios";
  fi
  if [[ "$OPTIONS" =~ "verbose" ]]; then
    VERBOSE_MODE="true";
  else
    VERBOSE_MODE="false";
  fi
  if [[ "$OPTIONS" =~ "autoupgrades" ]]; then
    DO_ISO_AUTO_UPGRADES="true";
  else
    DO_ISO_AUTO_UPGRADES="false";
  fi
  if [[ "$OPTIONS" =~ "interactive" ]]; then
    INTERACTIVE_MODE="true";
  else
    INTERACTIVE_MODE="false";
  fi
  if [[ "$OPTIONS" =~ "aptnews" ]]; then
    DO_ISO_APT_NEWS="true";
  else
    DO_ISO_APT_NEWS="false";
  fi
}

# Function: process_actions
#
# Process action switch

process_actions () {
  case $ACTION in
    "help"|"printhelp")
      print_help
      ;;
    "usage"|"printusage")
      print_usage
      ;;
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
    "createautoinstall")
      DO_PREPARE_AUTOINSTALL_ISO_ONLY="true"
      ;;
    "runchrootscript")
      DO_EXECUTE_ISO_CHROOT_SCRIPT="true"
      ;;
    "createiso")
      DO_CHECK_WORK_DIR="true"
      DO_INSTALL_REQUIRED_PACKAGES="true"
      DO_EXECUTE_ISO_CHROOT_SCRIPT="true"
      DO_CREATE_AUTOINSTALL_ISO_FULL="true"
      ;;
    "createisoandsquashfs")
      DO_ISO_SQUASHFS_UPDATE="true"
      DO_CHECK_WORK_DIR="true"
      DO_INSTALL_REQUIRED_PACKAGES="true"
      DO_EXECUTE_ISO_CHROOT_SCRIPT="true"
      DO_CREATE_AUTOINSTALL_ISO_FULL="true"
     ;;
    "createdockeriso")
      DO_DOCKER="true"
      DO_CHECK_DOCKER="true"
      DO_CHECK_WORK_DIR="true"
      DO_INSTALL_REQUIRED_PACKAGES="true"
      DO_EXECUTE_ISO_CHROOT_SCRIPT="true"
      DO_CREATE_AUTOINSTALL_ISO_FULL="true"
      ;;
    "createdockerisoandsquashfs")
      DO_ISO_SQUASHFS_UPDATE="true"
      DO_DOCKER="true"
      DO_CHECK_DOCKER="true"
      DO_CHECK_WORK_DIR="true"
      DO_INSTALL_REQUIRED_PACKAGES="true"
      DO_EXECUTE_ISO_CHROOT_SCRIPT="true"
      DO_CREATE_AUTOINSTALL_ISO_FULL="true"
      ;;
    'createkvmvm')
      VM_TYPE="kvm"
      DO_INSTALL_REQUIRED_PACKAGES="true"
      DO_CREATE_VM="true"
      ;;
    'deletekvmvm')
      VM_TYPE="kvm"
      DO_INSTALL_REQUIRED_PACKAGES="true"
      DO_DELETE_VM="true"
      ;;
    'createvm')
      DO_INSTALL_REQUIRED_PACKAGES="true"
      DO_CREATE_VM="true"
      ;;
    'deletevm')
      DO_INSTALL_REQUIRED_PACKAGES="true"
      DO_DELETE_VM="true"
      ;;
    "queryiso")
      DO_ISO_QUERY="true"
      ;;
    "unmount")
      DO_UMOUNT_ISO="true"
      ;;
    "oldinstaller")
      DO_OLD_INSTALLER="true"
      ;;
    "listallisos"|"listisos")
      DO_LIST_ISOS="true"
      ;;
    *)
      handle_output "Action: $ACTION is not a valid action"
      exit
      ;;
  esac
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
}

# Function: print_env
# 
# Print environment

print_env () {
  handle_output "# Setting Variables" TEXT
  handle_output "# Release:                   [ISO_RELEASE]                    $ISO_RELEASE" TEXT
  handle_output "# Codename:                  [ISO_CODENAME]                   $ISO_CODENAME" TEXT
  handle_output "# Architecture:              [ISO_ARCH]                       $ISO_ARCH" TEXT
  handle_output "# Work directory:            [WORK_DIR]                       $WORK_DIR" TEXT
  if [ "$DO_DOCKER" = "true" ]; then
    handle_output "# Previous Work directory:   [WORK_DIR]                       $WORK_DIR" TEXT
  fi
  if [ "$DO_OLD_INSTALLER" = "true" ]; then
    handle_output "# Old Work directory:        [OLD_WORK_DIR]                   $OLD_WORK_DIR" TEXT
    handle_output "# Old ISO input file:        [OLD_INPUT_FILE]                 $OLD_INPUT_FILE" TEXT
    handle_output "# Old ISO URL:               [OLD_ISO_URL]                    $OLD_ISO_URL" TEXT
  fi
  handle_output "# ISO URL:                   [ISO_URL]                        $ISO_URL" TEXT
  handle_output "# ISO input file:            [INPUT_FILE]                     $INPUT_FILE" TEXT
  handle_output "# Required packages:         [REQUIRED_PACKAGES]              $REQUIRED_PACKAGES" TEXT
  handle_output "# ISO output file:           [OUTPUT_FILE]                    $OUTPUT_FILE" TEXT
  handle_output "# SCP command:               [SCP_COMMAND]                    $MY_USERNAME@$MY_IP:$OUTPUT_FILE" TEXT
  handle_output "# ISO Release:               [ISO_RELEASE]                    $ISO_RELEASE" TEXT
  handle_output "# ISO Build:                 [ISO_BUILD_TYPE]                 $ISO_BUILD_TYPE" TEXT
  handle_output "# ISO Volume ID:             [ISO_VOLID]                      $ISO_VOLID" TEXT
  handle_output "# ISO mount directory:       [ISO_MOUNT_DIR]                  $ISO_MOUNT_DIR" TEXT
  if [ "$DO_OLD_INSTALLER" = "true" ]; then
    handle_output "# Old ISO mount directory:   [OLD_ISO_MOUNT_DIR]              $OLD_ISO_MOUNT_DIR" TEXT
    handle_output "# Old install squashfs file: [OLD_INSTALL_SQUASHFS_FILE]      $OLD_INSTALL_SQUASHFS_FILE" TEXT
  fi
  handle_output "# ISO squashfs file:         [ISO_SQUASHFS_FILE]              $ISO_SQUASHFS_FILE" TEXT
  handle_output "# Check latest ISO:          [DO_CHECK_ISO]                   $DO_CHECK_ISO" TEXT
  handle_output "# Hostname:                  [ISO_HOSTNAME]                   $ISO_HOSTNAME" TEXT
  handle_output "# Username:                  [ISO_USERNAME]                   $ISO_USERNAME" TEXT
  handle_output "# Realname:                  [ISO_REALNAME]                   $ISO_REALNAME" TEXT
  handle_output "# Password:                  [ISO_PASSWORD]                   $ISO_PASSWORD" TEXT
  handle_output "# Password Hash:             [ISO_PASSWORD_CRYPT]             $ISO_PASSWORD_CRYPT" TEXT
  if [ "$DO_ISO_SSH_KEY" =  "true" ]; then
    handle_output "# SSH Key file:              [ISO_SSH_KEY_FILE]               $ISO_SSH_KEY_FILE" TEXT
    handle_output "# SSH Key:                   [ISO_SSH_KEY]                    $ISO_SSH_KEY" TEXT
  fi
  handle_output "# Timezone:                  [ISO_TIMEZONE]                   $ISO_TIMEZONE" TEXT
  if [ -n "$ISO_SSH_KEY_FILE" ]; then
    handle_output "# SSH Key file:              [ISO_SSH_KEY_FILE]               $ISO_SSH_KEY_FILE" TEXT
  fi
  handle_output "# NIC:                       [ISO_NIC]                        $ISO_NIC" TEXT
  handle_output "# DHCP:                      [ISO_DHCP]                       $ISO_DHCP" TEXT
  if [ "$ISO_DHCP" = "false" ]; then
    handle_output "# IP:                        [ISO_IP/ISO_CIDR]                $ISO_IP/$ISO_CIDR" TEXT
    handle_output "# Gateway:                   [ISO_GATEWAY]                    $ISO_GATEWAY" TEXT
    handle_output "# Nameservers:               [ISO_DNS]                        $ISO_DNS" TEXT
  fi
  handle_output "# Kernel:                    [ISO_KERNEL]                     $ISO_KERNEL" TEXT
  handle_output "# Kernel arguments:          [ISO_KERNEL_ARGS]                $ISO_KERNEL_ARGS" TEXT
  handle_output "# Block kernel modules:      [ISO_BLOCKLIST]                  $ISO_BLOCKLIST" TEXT
  handle_output "# Allow kernel modules:      [ISO_ALLOWLIST]                  $ISO_ALLOWLIST" TEXT
  handle_output "# Keyboard Layout:           [ISO_LAYOUT]                     $ISO_LAYOUT" TEXT
  handle_output "# Locale:                    [ISO_LOCALE]                     $ISO_LOCALE" TEXT
  handle_output "# LC_ALL:                    [ISO_LC_ALL]                     $ISO_LC_ALL" TEXT
  handle_output "# Root disk(s):              [ISO_DEVICES]                    $ISO_DEVICES" TEXT
  handle_output "# Volme Manager(s):          [ISO_VOLMGRS]                    $ISO_VOLMGRS" TEXT
  handle_output "# GRUB Menu:                 [ISO_GRUB_MENU]                  $ISO_GRUB_MENU" TEXT
  handle_output "# GRUB Timeout:              [ISO_GRUB_TIMEOUT]               $ISO_GRUB_TIMEOUT" TEXT
  handle_output "# AI Directory:              [ISO_AUTOINSTALL_DIR]            $ISO_AUTOINSTALL_DIR" TEXT
  handle_output "# Install mount:             [ISO_INSTALL_MOUNT]              $ISO_INSTALL_MOUNT" TEXT
  handle_output "# Install target:            [ISO_TARGET_MOUNT]               $ISO_TARGET_MOUNT" TEXT
  handle_output "# Recreate squashfs:         [DO_ISO_SQUASHFS_UPDATE]         $DO_ISO_SQUASHFS_UPDATE" TEXT
  handle_output "# Squashfs packages:         [ISO_CHROOT_PACKAGES]            $ISO_CHROOT_PACKAGES" TEXT
  handle_output "# Additional packages:       [ISO_INSTALL_PACKAGES            $ISO_INSTALL_PACKAGES" TEXT
  handle_output "# Network updates:           [DO_INSTALL_ISO_NETWORK_UPDATES  $DO_INSTALL_ISO_NETWORK_UPDATES" TEXT
  handle_output "# Install packages:          [DO_INSTALL_ISO_PACKAGES         $DO_INSTALL_ISO_PACKAGES" TEXT
  handle_output "# Install updates:           [DO_INSTALL_ISO_UPDATE           $DO_INSTALL_ISO_UPDATE" TEXT
  handle_output "# Install upgrades:          [DO_INSTALL_ISO_UPGRADE          $DO_INSTALL_ISO_UPGRADE" TEXT
  handle_output "# Dist upgrades:             [DO_INSTALL_ISO_DIST_UPGRADE     $DO_INSTALL_ISO_DIST_UPGRADE" TEXT
  handle_output "# Swap size:                 [ISO_SWAPSIZE                    $ISO_SWAPSIZE" TEXT
  if [ "$DO_CREATE_EXPORT" = "true" ] || [ "$DO_CREATE_ANSIBLE" = "true" ]; then
    handle_output "# Bootserver IP:             [BOOT_SERVER_IP                  $BOOT_SERVER_IP" TEXT
    handle_output "# Bootserver file:           [BOOT_SERVER_FILE                $BOOT_SERVER_FILE" TEXT
  fi
  if [ "$DO_CREATE_ANSIBLE" = "true" ] ; then
    handle_output "# BMC IP:                    [BMC_IP                          $BMC_IP" TEXT
    handle_output "# BMC Username:              [BMC_USERNAME                    $BMC_USERNAME" TEXT
    handle_output "# BMC Password:              [BMC_PASSWORD                    $BMC_PASSWORD" TEXT
  fi
  handle_output "# Serial Port:               [ISO_SERIAL_PORT0                $ISO_SERIAL_PORT0" TEXT
  handle_output "# Serial Port:               [ISO_SERIAL_PORT1                $ISO_SERIAL_PORT1" TEXT
  handle_output "# Serial Port Address:       [ISO_SERIAL_PORT_ADDRESS0        $ISO_SERIAL_PORT_ADDRESS0" TEXT
  handle_output "# Serial Port Address:       [ISO_SERIAL_PORT_ADDRESS1        $ISO_SERIAL_PORT_ADDRESS1" TEXT
  handle_output "# Serial Port Speed:         [ISO_SERIAL_PORT_SPEED0          $ISO_SERIAL_PORT_SPEED0" TEXT
  handle_output "# Serial Port Speed:         [ISO_SERIAL_PORT_SPEED1          $ISO_SERIAL_PORT_SPEED1" TEXT
  handle_output "# Use biosdevnames:          [ISO_USE_BIOSDEVNAME             $ISO_USE_BIOSDEVNAME" TEXT
  if [ "$DO_PRINT_ENV" = "true" ] || [ "$INTERACTIVE_MODE" = "true" ]; then
    TEMP_VERBOSE_MODE="false"
  fi
  if [ "$DO_PRINT_ENV" = "true" ]; then
    exit
  fi
}

# Function: process_post_install
#
# Process postinstall switch

process_post_install () {
  if [[ "$ISO_POSTINSTALL" =~ "dist" ]]; then
    DO_INSTALL_ISO_NETWORK_UPDATES="true"
    DO_INSTALL_ISO_DIST_UPGRADE="true"
  fi
  if [[ "$ISO_POSTINSTALL" =~ "packages" ]]; then
    DO_INSTALL_ISO_NETWORK_UPDATES="true"
    DO_INSTALL_ISO_PACKAGES="true"
  fi
  if [[ "$ISO_POSTINSTALL" =~ "updates" ]]; then
    DO_INSTALL_ISO_NETWORK_UPDATES="true"
    DO_INSTALL_ISO_UPDATE="true"
    DO_INSTALL_ISO_UPGRADE="true"
  fi
  if [[ "$ISO_POSTINSTALL" =~ "autoupgrades" ]]; then
    DO_ISO_AUTO_UPGRADES="true"
  fi
  if [[ "$ISO_POSTINSTALL" =~ "all" ]]; then
    DO_INSTALL_ISO_NETWORK_UPDATES="true"
    DO_INSTALL_ISO_UPDATE="true"
    DO_INSTALL_ISO_UPGRADE="true"
    DO_INSTALL_ISO_DIST_UPGRADE="true"
    DO_INSTALL_ISO_PACKAGES="true"
  fi
}

# Function: update_required_packages
#
# Update required packages

update_required_packages () {
  if [ "$OS_NAME" = "Darwin" ]; then
    if ! [[ "$ACTION" =~ "docker" ]]; then
      REQUIRED_PACKAGES="p7zip lftp wget xorriso ansible squashfs"
    fi
  fi
}

# Function: process_switches
#
# Process switches

process_switches () {
  if [ "$DO_CUSTOM_AUTO_INSTALL" = "true" ]; then
    if [ ! -f "$AUTO_INSTALL_FILE" ]; then
      echo "File $AUTO_INSTALL_FILE does not exist"
      exit
    fi
  fi
  if [ "$ZFS_FILESYSTEMS" = "" ]; then
    ZFS_FILESYSTEMS="$DEFAULT_ZFS_FILESYSTEMS"
  fi
  if [ "$ISO_SEARCH" = "" ]; then
    ISO_SEARCH="$DEFAULT_ISO_SEARCH"
  fi
  if [ "$ISO_BLOCKLIST" = "" ]; then
    ISO_BLOCKLIST="$DEFAULT_ISO_BLOCKLIST"
  fi
  if [ "$ISO_ALLOWLIST" = "" ]; then
    ISO_ALLOWLIST="$DEFAULT_ISO_ALLOWLIST"
  fi
  if [ "$ISO_COUNTRY" = "" ]; then
    ISO_COUNTRY="$DEFAULT_ISO_COUNTRY"
  fi
  if [[ "$ISO_SERIAL_PORT0" =~ "," ]]; then
      ISO_SERIAL_PORT0=$(echo "$ISO_SERIAL_PORT0" |cut -f1 -d,)
      ISO_SERIAL_PORT1=$(echo "$ISO_SERIAL_PORT1" |cut -f2 -d,)
  else
    if [ "$ISO_SERIAL_PORT0" = "" ]; then
      ISO_SERIAL_PORT0="$DEFAULT_ISO_SERIAL_PORT0"
      ISO_SERIAL_PORT1="$DEFAULT_ISO_SERIAL_PORT1"
    fi
  fi
  if [[ "$ISO_SERIAL_PORT_ADDRESS0" =~ "," ]]; then
    ISO_SERIAL_PORT_ADDRESS0=$(echo "$ISO_SERIAL_PORT_ADDRESS0" |cut -f1 -d,)
    ISO_SERIAL_PORT_ADDRESS1=$(echo "$ISO_SERIAL_PORT_ADDRESS1" |cut -f2 -d,)
  else
    if [ "$ISO_SERIAL_PORT_ADDRESS0" = "" ]; then
      ISO_SERIAL_PORT_ADDRESS0="$DEFAULT_ISO_SERIAL_PORT_ADDRESS0"
      ISO_SERIAL_PORT_ADDRESS1="$DEFAULT_ISO_SERIAL_PORT_ADDRESS1"
    fi
  fi
  if [ "$ISO_SERIAL_PORT_SPEED0" = "" ]; then
    ISO_SERIAL_PORT_SPEED0=$(echo "$DEFAULT_ISO_SERIAL_PORT_SPEED0" |cut -f1 -d,)
    ISO_SERIAL_PORT_SPEED1=$(echo "$DEFAULT_ISO_SERIAL_PORT_SPEED1" |cut -f2 -d,)
  else
    if [ "$ISO_SERIAL_PORT_SPEED0" = "" ]; then
      ISO_SERIAL_PORT_SPEED0="$DEFAULT_ISO_SERIAL_PORT_SPEED0"
      ISO_SERIAL_PORT_SPEED1="$DEFAULT_ISO_SERIAL_PORT_SPEED1"
    fi
  fi
  if [ "$ISO_ARCH" = "" ]; then
    ISO_ARCH="$DEFAULT_ISO_ARCH"
    DOCKER_ARCH="$DEFAULT_DOCKER_ARCH"
  else
    DOCKER_ARCH="$ISO_ARCH"
  fi
  if [ "$ISO_BOOT_TYPE" = "" ]; then
    ISO_BOOT_TYPE="$DEFAULT_ISO_BOOT_TYPE"
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
  if [ "$ISO_RELEASE" = "" ]; then
    ISO_RELEASE="$DEFAULT_ISO_RELEASE"
  else
    case "$ISO_RELEASE" in
      "22.04")
        ISO_RELEASE="$CURRENT_ISO_RELEASE_2204"
        ;;
      "20.04")
        ISO_RELEASE="$CURRENT_ISO_RELEASE_2004"
        ;;
      "18.04")
        ISO_RELEASE="$CURRENT_ISO_RELEASE_1804"
        ;;
      "16.04")
        ISO_RELEASE="$CURRENT_ISO_RELEASE_1604"
        ;;
      "14.04")
        ISO_RELEASE="$CURRENT_ISO_RELEASE_1404"
        ;;
    esac
  fi
  if [ "$OLD_ISO_RELEASE" = "" ]; then
    OLD_ISO_RELEASE="$CURRENT_OLD_ISO_RELEASE"
  fi
  ISO_MAJOR_REL=$(echo "$ISO_RELEASE" |cut -f1 -d.)
  ISO_MINOR_REL=$(echo "$ISO_RELEASE" |cut -f2 -d.)
  if [ "$ISO_CODENAME" = "" ]; then
    get_code_name
  fi
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
    ISO_CHROOT_PACKAGES="$DEFAULT_ISO_INSTALL_PACKAGES"
  fi
  if [ "$ISO_INSTALL_PACKAGES" = "" ]; then
    ISO_INSTALL_PACKAGES="$DEFAULT_ISO_INSTALL_PACKAGES"
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
  if [ "$ISO_BOOT_TYPE" = "bios" ]; then
    if [[ "$OPTIONS" =~ "fs" ]]; then
      DEFAULT_ISO_VOLMGRS="lvm zfs xfs btrfs"
    else
      DEFAULT_ISO_VOLMGRS="lvm"
    fi
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
    if [ "$DO_CREATE_VM" = "true" ]; then
      ISO_KERNEL="$DEFAULT_VM_TYPE"
    else
      ISO_KERNEL="$DEFAULT_ISO_KERNEL"
    fi
  fi
  if [[ "$ACTION" =~ "iso" ]]; then
    if [ "$CODENAME" = "" ]; then
      get_code_name
    fi
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
  if [ "$ISO_INSTALL_MOUNT" = "" ]; then
    ISO_INSTALL_MOUNT="$DEFAULT_ISO_INSTALL_MOUNT"
  fi
  if [ "$ISO_TARGET_MOUNT" = "" ]; then
    ISO_TARGET_MOUNT="$DEFAULT_ISO_TARGET_MOUNT"
  fi
  if [ "$ISO_AUTOINSTALL_DIR" = "" ]; then
    ISO_AUTOINSTALL_DIR="$DEFAULT_ISO_AUTOINSTALL_DIR"
  fi
  if [ "$ISO_OS_NAME" = "" ]; then
    ISO_OS_NAME="$DEFAULT_ISO_OS_NAME"
  fi
  if [ "$WORK_DIR" = "" ]; then
    if [ "$DO_DAILY_ISO" = "true" ]; then
      WORK_DIR="$HOME/$SCRIPT_NAME/$ISO_OS_NAME/$ISO_CODENAME"
      DOCKER_WORK_DIR="/root/$SCRIPT_NAME/$ISO_OS_NAME/$ISO_CODENAME"
    else
      WORK_DIR="$HOME/$SCRIPT_NAME/$ISO_OS_NAME/$ISO_RELEASE"
      DOCKER_WORK_DIR="/root/$SCRIPT_NAME/$ISO_OS_NAME/$ISO_RELEASE"
    fi
  else
    if [ "$DO_DAILY_ISO" = "true" ]; then
      WORK_DIR="$HOME/$SCRIPT_NAME/$ISO_OS_NAME/$ISO_CODENAME"
      DOCKER_WORK_DIR="/root/$SCRIPT_NAME/$ISO_OS_NAME/$ISO_CODENAME"
    fi
  fi
  if [ "$ISO_BUILD_TYPE" = "" ]; then
    ISO_BUILD_TYPE="$DEFAULT_ISO_BUILD_TYPE"
  fi
  if [ "$ISO_VOLID" = "" ]; then
    case $ISO_BUILD_TYPE in
      "daily-desktop"|"desktop")
        ISO_VOLID="$ISO_OS_NAME $ISO_RELEASE Desktop"
        ;;
      *)
        ISO_VOLID="$ISO_OS_NAME $ISO_RELEASE Server"
        ;;
    esac
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
          OUTPUT_FILE="$WORK_DIR/files/$ISO_CODENAME-live-server-$ISO_ARCH-$ISO_BOOT_TYPE-autoinstall.iso"
          BOOT_SERVER_FILE="$OUTPUT_FILE"
          ;;
        "daily-desktop")
          INPUT_FILE="$WORK_DIR/files/$ISO_CODENAME-desktop-$ISO_ARCH.iso"
          OUTPUT_FILE="$WORK_DIR/files/$ISO_CODENAME-desktop-$ISO_ARCH-$ISO_BOOT_TYPE-autoinstall.iso"
          BOOT_SERVER_FILE="$OUTPUT_FILE"
          ;;
       "desktop")
          INPUT_FILE="$WORK_DIR/files/ubuntu-$ISO_RELEASE-desktop-$ISO_ARCH.iso"
          OUTPUT_FILE="$WORK_DIR/files/ubuntu-$ISO_RELEASE-desktop-$ISO_ARCH-$ISO_BOOT_TYPE-autoinstall.iso"
          BOOT_SERVER_FILE="$OUTPUT_FILE"
          ;;
        *)
          INPUT_FILE="$WORK_DIR/files/ubuntu-$ISO_RELEASE-live-server-$ISO_ARCH.iso"
          OUTPUT_FILE="$WORK_DIR/files/ubuntu-$ISO_RELEASE-live-server-$ISO_ARCH-$ISO_BOOT_TYPE-autoinstall.iso"
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
  if [ "$ISO_USE_BIOSDEVNAME" = "true" ]; then
    ISO_KERNEL_ARGS="$ISO_KERNEL_ARGS net.ifnames=0 biosdevname=0"
  fi
  if [ "$OLD_INPUT_FILE" = "" ]; then
    OLD_INPUT_FILE="$DEFAULT_OLD_INPUT_FILE"
  fi
}

# Function: update_output_file_name
#
# Update output file name based on switched and options

update_output_file_name () {
  if ! [ "$ISO_HOSTNAME" = "$DEFAULT_ISO_HOSTNAME" ]; then
    TEMP_DIR_NAME=$( dirname "$OUTPUT_FILE" )
    TEMP_FILE_NAME=$( basename "$OUTPUT_FILE" .iso )
    OUTPUT_FILE="$TEMP_DIR_NAME/$TEMP_FILE_NAME-$ISO_HOSTNAME.iso"
  fi
  if ! [ "$ISO_NIC" = "$DEFAULT_ISO_NIC" ]; then
    TEMP_DIR_NAME=$( dirname "$OUTPUT_FILE" )
    TEMP_FILE_NAME=$( basename "$OUTPUT_FILE" .iso )
    OUTPUT_FILE="$TEMP_DIR_NAME/$TEMP_FILE_NAME-$ISO_NIC.iso"
  fi
  if [ "$ISO_DHCP" = "false" ]; then
    if ! [ "$ISO_IP" = "$DEFAULT_ISO_IP" ]; then
      TEMP_DIR_NAME=$( dirname "$OUTPUT_FILE" )
      TEMP_FILE_NAME=$( basename "$OUTPUT_FILE" .iso )
      OUTPUT_FILE="$TEMP_DIR_NAME/$TEMP_FILE_NAME-$ISO_IP.iso"
    fi
    if ! [ "$ISO_GATEWAY" = "$DEFAULT_ISO_GATEWAY" ]; then
      TEMP_DIR_NAME=$( dirname "$OUTPUT_FILE" )
      TEMP_FILE_NAME=$( basename "$OUTPUT_FILE" .iso )
      OUTPUT_FILE="$TEMP_DIR_NAME/$TEMP_FILE_NAME-$ISO_GATEWAY.iso"
    fi
    if ! [ "$ISO_DNS" = "$DEFAULT_ISO_DNS" ]; then
      TEMP_DIR_NAME=$( dirname "$OUTPUT_FILE" )
      TEMP_FILE_NAME=$( basename "$OUTPUT_FILE" .iso )
      OUTPUT_FILE="$TEMP_DIR_NAME/$TEMP_FILE_NAME-$ISO_DNS.iso"
    fi
  fi
  if ! [ "$ISO_USERNAME" = "$DEFAULT_ISO_USERNAME" ]; then
    TEMP_DIR_NAME=$( dirname "$OUTPUT_FILE" )
    TEMP_FILE_NAME=$( basename "$OUTPUT_FILE" .iso )
    OUTPUT_FILE="$TEMP_DIR_NAME/$TEMP_FILE_NAME-$ISO_USERNAME.iso"
  fi
  if ! [ "$ISO_DEVICES" = "$DEFAULT_ISO_DEVICES" ]; then
    TEMP_DIR_NAME=$( dirname "$OUTPUT_FILE" )
    TEMP_FILE_NAME=$( basename "$OUTPUT_FILE" .iso )
    OUTPUT_FILE="$TEMP_DIR_NAME/$TEMP_FILE_NAME-$ISO_DEVICES.iso"
  fi
  if ! [ "$ISO_PREFIX" = "" ]; then
    TEMP_DIR_NAME=$( dirname "$OUTPUT_FILE" )
    TEMP_FILE_NAME=$( basename "$OUTPUT_FILE" .iso )
    OUTPUT_FILE="$TEMP_DIR_NAME/$ISO_PREFIX-$TEMP_FILE_NAME.iso"
  fi
  if ! [ "$ISO_SUFFIX" = "" ]; then
    TEMP_DIR_NAME=$( dirname "$OUTPUT_FILE" )
    TEMP_FILE_NAME=$( basename "$OUTPUT_FILE" .iso )
    OUTPUT_FILE="$TEMP_DIR_NAME/$TEMP_FILE_NAME-$ISO_SUFFIX.iso"
  fi
  if [[ "$OPTIONS" =~ "cluster" ]]; then
    TEMP_DIR_NAME=$( dirname "$OUTPUT_FILE" )
    TEMP_FILE_NAME=$( basename "$OUTPUT_FILE" .iso )
    OUTPUT_FILE="$TEMP_DIR_NAME/$TEMP_FILE_NAME-cluster.iso"
  fi
  if [[ "$OPTIONS" =~ "kvm" ]]; then
    TEMP_DIR_NAME=$( dirname "$OUTPUT_FILE" )
    TEMP_FILE_NAME=$( basename "$OUTPUT_FILE" .iso )
    OUTPUT_FILE="$TEMP_DIR_NAME/$TEMP_FILE_NAME-kvm.iso"
  fi
  if [[ "$OPTIONS" =~ "biosdevname" ]]; then
    TEMP_DIR_NAME=$( dirname "$OUTPUT_FILE" )
    TEMP_FILE_NAME=$( basename "$OUTPUT_FILE" .iso )
    OUTPUT_FILE="$TEMP_DIR_NAME/$TEMP_FILE_NAME-biosdevname.iso"
  fi
  if [ "$ISO_DHCP" = "true" ]; then
    TEMP_DIR_NAME=$( dirname "$OUTPUT_FILE" )
    TEMP_FILE_NAME=$( basename "$OUTPUT_FILE" .iso )
    OUTPUT_FILE="$TEMP_DIR_NAME/$TEMP_FILE_NAME-dhcp.iso"
  fi
  if [ "$DO_CREATE_VM" = "true" ]; then
    if [ "$VM_TYPE" = "kvm" ]; then
      REQUIRED_PACKAGES="$REQUIRED_PACKAGES qemu-full virt-manager virt-viewer dnsmasq bridge-utils libguestfs ebtables vde2 openbsd-netcat cloud-image-utils libosinfo"
    fi
  fi
  if [ "$VM_TYPE" = "" ]; then
    VM_TYPE="$DEFAULT_VM_TYPE"
  fi
  if [ "$VM_NIC" = "" ]; then
    VM_NIC="$DEFAULT_VM_NIC"
  fi
  if [ "$VM_SIZE" = "" ]; then
    VM_SIZE="$DEFAULT_VM_SIZE"
  fi
  if [ "$VM_CPUS" = "" ]; then
    VM_CPUS="$DEFAULT_VM_CPUS"
  fi
  if [[ "$ACTION" =~ "vm" ]]; then
    if [[ "$ACTION" =~ "create" ]]; then
      if [ "$VM_RAM" = "" ]; then
        VM_RAM="$DEFAULT_VM_RAM"
      else
        if [[ "$VM_RAM" =~ "G" ]] || [[ "$VM_RAM" =~ "g" ]]; then
          VM_RAM=$(echo "$VM_RAM" |sed "s/[G,g]//g")
          VM_RAM=$(echo "$VM_RAM*1024*1024" |bc -l)
        fi
        if [ "$VM_RAM" -lt 1024000 ]; then
          warning_message "Insufficient RAM specified for VM"
          exit
        fi
      fi
    fi
    if [ "$VM_NAME" = "" ]; then
      VM_NAME="$SCRIPT_NAME-ubuntu-$ISO_RELEASE-$ISO_BOOT_TYPE"
    fi
    if [[ "$ACTION" =~ "create" ]]; then
      if ! [ "$VM_ISO" = "" ]; then
        if ! [ -f "$VM_ISO" ]; then
          warning_message "ISO $VM_ISO does not exist"
          exit
        fi
      fi
    fi
  fi
  if [ "$DO_SERIAL" = "true" ]; then
    ISO_KERNEL_ARGS="$ISO_KERNEL_ARGS console=$ISO_SERIAL_PORT0,$ISO_SERIAL_PORT_SPEED0"
    if ! [ "$ISO_SERIAL_PORT1" = "" ]; then
      ISO_KERNEL_ARGS="$ISO_KERNEL_ARGS console=$ISO_SERIAL_PORT1,$ISO_SERIAL_PORT_SPEED1"
    fi
  fi
  if [ "$OLD_INSTALL_SQUASHFS_FILE" = "" ]; then
    OLD_INSTALL_SQUASHFS_FILE="$DEFAULT_OLD_INSTALL_SQUASHFS_FILE"
  fi
  if [ "$OLD_WORK_DIR" = "" ]; then
    OLD_WORK_DIR="$DEFAULT_OLD_WORK_DIR"
  fi
}

# Function: get_interactive_input
#
# Get values for script interactively

get_interactive_input () {
  if [ "$DO_CREATE_EXPORT" = "true" ] || [ "$DO_CREATE_ANSIBLE" = "true" ]; then
    if [ "$DO_CREATE_EXPORT" = "true" ] || [ "$DO_CREATE_ANSIBLE" = "true" ]; then
      # Get bootserver IP
      read -r -p "Enter Bootserver IP [$BOOT_SERVER_IP]: " NEW_BOOT_SERVER_IP
      BOOT_SERVER_IP=${NEW_BOOT_SERVER_IP:-$BOOT_SERVER_IP}
      # Get bootserver file
      read -r -p "Enter Bootserver file [$BOOT_SERVER_FILE]: " NEW_BOOT_SERVER_FILE
      BOOT_SERVER_FILE=${NEW_BOOT_SERVER_FILE:-$BOOT_SERVER_FILE}
    fi
    if [ "$DO_CREATE_ANSIBLE" = "true" ]; then
      # Get BMC IP
      read -r -p "Enter BMC/iDRAC IP [$BMC_IP]: " NEW_BMC_IP
      BMC_IP=${NEW_BMC_IP:-$BMC_IP}
      # Get BMC Username
      read -r -p "Enter BMC/iDRAC Username [$BMC_USERNAME]: " NEW_BMC_USERNAME
      BMC_USERNAME=${NEW_BMC_USERNAME:-$BMC_USERNAME}
      # Get BMC Password
      read -r -p "Enter BMC/iDRAC Password [$BMC_PASSWORD]: " NEW_BMC_PASSWORD
      BMC_PASSWORD=${NEW_BMC_PASSWORD:-$BMC_PASSWORD}
    fi
  else
    # Get release
    read -r -p "Enter Release [$ISO_RELEASE]: " NEW_ISO_RELEASE
    ISO_RELEASE=${NEW_ISO_RELEASE:-$ISO_RELEASE}
    # Get codename
    read -r -p "Enter Codename [$ISO_CODENAME: " NEW_ISO_CODENAME
    ISO_CODENAME=${NEW_ISO_CODENAME:-$ISO_CODENAME}
    # Get Architecture
    read -r -p "Architecture [$ISO_ARCH]: "
    ISO_ARCH=${NEW_ISO_ARCH:-$ISO_ARCH}
    # Get Work directory
    read -r -p "Enter Work directory [$WORK_DIR]: " NEW_WORK_DIR
    WORK_DIR=${NEW_WORK_DIR:-$WORK_DIR}
    # Get ISO input file
    read -r -p "Enter ISO input file [$INPUT_FILE]: " NEW_INPUT_FILE
    INPUT_FILE=${NEW_INPUT_FILE:-$INPUT_FILE}
    # Get output file
    read -r -p "Enter ISO output file [$OUTPUT_FILE]: " NEW_OUTPUT_FILE
    OUTPUT_FILE=${NEW_OUTPUT_FILE:-$OUTPUT_FILE}
    # Get ISO URL
    read -r -p "Enter ISO URL [$ISO_URL]: " NEW_ISO_URL
    ISO_URL=${NEW_ISO_URL:-$ISO_URL}
    # Get ISO Volume ID
    read -r -p "Enter ISO Volume ID [$ISO_VOLID]: " NEW_ISO_VOLID
    ISO_VOLID=${NEW_ISO_VOLID:-$ISO_VOLID}
    # Get Hostname
    read -r -p "Enter Hostname[$ISO_HOSTNAME]: " NEW_ISO_HOSTNAME
    ISO_HOSTNAME=${NEW_ISO_HOSTNAME:-$ISO_HOSTNAME}
    # Get Username
    read -r -p "Enter Username [$ISO_USERNAME]: " NEW_ISO_USERNAME
    ISO_USERNAME=${NEW_ISO_USERNAME:-$ISO_USERNAME}
    # Get User Real NAme
    read -r -p "Enter User Realname [$ISO_REALNAME]: " NEW_ISO_REALNAME
    ISO_REALNAME=${NEW_ISO_REALNAME:-$ISO_REALNAME}
    # Get Password
    read -r -s -p "Enter password [$ISO_PASSWORD]: " NEW_ISO_PASSWORD
    ISO_PASSWORD=${NEW_ISO_PASSWORD:-$ISO_PASSWORD}
    # Get wether to allow SSH Password
    read -r -s -p "Allow SSH access with password [$ISO_ALLOW_PASSWORD]: " NEW_ISO_ALLOW_PASSWORD
    ISO_ALLOW_PASSWORD=${NEW_ISO_ALLOW_PASSWORD:-$ISO_ALLOW_PASSWORD}
    # Get Timezone
    read -r -p "Enter Timezone: " NEW_ISO_TIMEZONE
    ISO_TIMEZONE=${NEW_ISO_TIMEZONE:-$ISO_TIMEZONE}
    # Get NIC
    read -r -p "Enter NIC [$ISO_NIC]: " NEW_ISO_NIC
    ISO_NIC=${NEW_ISO_NIC:-$ISO_NIC}
    # Get DHCP
    read -r -p "Use DHCP? [$ISO_DHCP]: " NEW_ISO_DHCP
    ISO_DHCP=${NEW_ISO_DHCP:-$ISO_DHCP}
    # Get Static IP information if no DHCP
    if [ "$ISO_DHCP" = "false" ]; then
      # Get IP
      read -r -p "Enter IP [$ISO_IP]: " NEW_ISO_IP
      ISO_IP=${NEW_ISO_IP:-$ISO_IP}
      # Get CIDR
      read -r -p "Enter CIDR [$ISO_CIDR]: " NEW_ISO_CIDR
      ISO_CIDR=${NEW_ISO_CIDR:-$ISO_CIDR}
      # Get Geteway
      read -r -p "Enter Gateway [$ISO_GATEWAY]: " NEW_ISO_GATEWAY
      ISO_GATEWAY=${NEW_ISO_GATEWAY:-$ISO_GATEWAY}
      # Get DNS
      read -r -p "Enter DNS [$ISO_DNS]: " NEW_ISO_DNS
      ISO_DNS=${NEW_ISO_DNS:-$ISO_DNS}
    fi
    # Get Kernel
    read -r -p "Enter Kernel [$ISO_KERNEL]: " NEW_ISO_KERNEL
    ISO_KERNEL=${NEW_ISO_KERNEL:-$ISO_KERNEL}
    # Get Kernel Arguments
    read -r -p "Enter Kernel Arguments [$ISO_KERNEL_ARGS]: " NEW_ISO_KERNEL_ARGS
    ISO_KERNEL_ARGS=${NEW_ISO_KERNEL_ARGS:-$ISO_KERNEL_ARGS}
    # Get Keyboard Layout
    read -r -p "Enter IP [$ISO_LAYOUT]: " NEW_ISO_LAYOUT
    ISO_LAYOUT=${NEW_ISO_LAYOUT:-$ISO_LAYOUT}
    # Get Locale
    read -r -p "Enter IP [$ISO_LOCALE]: " NEW_ISO_LOCALE
    ISO_LOCALE=${NEW_ISO_LOCALE:-$ISO_LOCALE}
    # Get LC _ALL
    read -r -p "Enter LC_ALL [$ISO_LC_ALL]: " NEW_ISO_LC_ALL
    ISO_LC_ALL=${NEW_ISO_LC_ALL:-$ISO_LC_ALL}
    # Get Root Disk(s)
    read -r -p "Enter Root Disk(s) [$ISO_DEVICES]: " NEW_ISO_DEVICES
    ISO_DEVICES=${NEW_ISO_DEVICES:-$ISO_DEVICES}
    # Get Volume Managers
    read -r -p "Enter Volume Manager(s) [$ISO_VOLMGRS]: " NEW_ISO_VOLMGRS
    ISO_VOLMGRS=${NEW_ISO_VOLMGRS:-$ISO_VOLMGRS}
    # Get Default Grub Menu selection
    read -r -p "Enter Default Grub Menu [$ISO_GRUB_MENU]: " NEW_ISO_GRUB_MENU
    ISO_GRUB_MENU=${NEW_ISO_GRUB_MENU:-$ISO_GRUB_MENU}
    # Get Grub Timeout
    read -r -p "Enter Grub Timeout [$ISO_GRUB_TIMEOUT]: " NEW_ISO_GRUB_TIMEOUT
    ISO_GRUB_TIMEOUT=${NEW_ISO_GRUB_TIMEOUT:-$ISO_GRUB_TIMEOUT}
    # Get Autoinstall directory
    read -r -p "Enter Auttoinstall Directory [$ISO_AUTOINSTALL_DIR]: " NEW_ISO_AUTOINSTALL_DIR
    ISO_AUTOINSTALL_DIR=${NEW_ISO_AUTOINSTALL_DIR:-$ISO_AUTOINSTALL_DIR}
    # Get Install Mount
    read -r -p "Enter Install Mount [$ISO_INSTALL_MOUNT]: " NEW_ISO_INSTALL_MOUNT
    ISO_INSTALL_MOUNT=${NEW_ISO_INSTALL_MOUNT:-$ISO_INSTALL_MOUNT}
    # Get Install Target
    read -r -p "Enter Install Target [$ISO_TARGET_MOUNT]: " NEW_ISO_TARGET_MOUNT
    ISO_TARGET_MOUNT=${NEW_ISO_TARGET_MOUNT:-$ISO_TARGET_MOUNT}
    # Get whether to do squashfs
    read -r -p "Recreate squashfs? [$DO_ISO_SQUASHFS_UPDATE]: " NEW_DO_ISO_SQUASHFS_UPDATE
    DO_ISO_SQUASHFS_UPDATE=${NEW_DO_ISO_SQUASHFS_UPDATE:-$DO_ISO_SQUASHFS_UPDATE}
    if  [ "$DO_ISO_SQUASHFS_UPDATE" = "true" ]; then
      # Get squashfs packages
      read -r -p "Enter Squashfs Packages [$ISO_CHROOT_PACKAGES]: " NEW_ISO_CHROOT_PACKAGES
      ISO_CHROOT_PACKAGES=${NEW_ISO_CHROOT_PACKAGES:-$ISO_CHROOT_PACKAGES}
    fi
    # Get whether to install packages as part of install
    read -r -p "Install additional packages [$DO_INSTALL_ISO_PACKAGES]: " NEW_DO_INSTALL_ISO_PACKAGES
    DO_INSTALL_ISO_PACKAGES=${NEW_DO_INSTALL_ISO_PACKAGES:-$DO_INSTALL_ISO_PACKAGES}
    if [ "$DO_INSTALL_ISO_PACKAGES" = "true" ]; then
      # Get IP
      read -r -p "Enter Additional Packages to install[$ISO_INSTALL_PACKAGES]: " NEW_ISO_INSTALL_PACKAGES
      ISO_INSTALL_PACKAGES=${NEW_ISO_INSTALL_PACKAGES:-$ISO_INSTALL_PACKAGES}
    fi
    # Get wether to install network updates
    read -r -p "Install Network Updates? [$DO_INSTALL_ISO_NETWORK_UPDATES]: " NEW_DO_INSTALL_ISO_NETWORK_UPDATES
    DO_INSTALL_ISO_NETWORK_UPDATES=${NEW_DO_INSTALL_ISO_NETWORK_UPDATES:-$DO_INSTALL_ISO_NETWORK_UPDATES}
    # Get whether to install updates
    if [ "$DO_INSTALL_ISO_NETWORK_UPDATES" = "true" ]; then
      read -r -p "Install updates? [$DO_INSTALL_ISO_UPDATE]: " NEW_DO_INSTALL_ISO_UPDATE
      DO_INSTALL_ISO_UPDATE=${NEW_DO_INSTALL_ISO_UPDATE:-$DO_INSTALL_ISO_UPDATE}
      if [ "$DO_INSTALL_ISO_UPDATE" = "true" ]; then
        # Get wether to install upgrades
        read -r -p "Upgrade packages? [$DO_INSTALL_ISO_UPGRADE]: " NEW_DO_INSTALL_ISO_UPGRADE
        DO_INSTALL_ISO_UPGRADE=${NEW_DO_INSTALL_ISO_UPGRADE:-$DO_INSTALL_ISO_UPGRADE}
        # Get whether to do a dist-updrage
        read -r -p "Install Distribution Upgrade if available (e.g. 20.04.4 -> 20.04.5)? [$DO_INSTALL_ISO_DIST_UPGRADE]: " NEW_DO_INSTALL_ISO_DIST_UPGRADE
        DO_INSTALL_ISO_DIST_UPGRADE=${NEW_DO_INSTALL_ISO_DIST_UPGRADE:-$DO_INSTALL_ISO_DIST_UPGRADE}
      fi
    fi
    # Get swap size
    read -r -p "Enter Swap Size [$ISO_SWAPSIZE]: " NEW_ISO_SWAPSIZE
    ISO_SWAPSIZE=${NEW_ISO_SWAPSIZE:-$ISO_SWAPSIZE}
    # Determine wether we use an SSH key
    read -r -p "Use SSH keys? [$DO_ISO_SSH_KEY]: " NEW_DO_ISO_SSH_KEY
    DO_ISO_SSH_KEY=${NEW_DO_ISO_SSH_KEY:-$DO_ISO_SSH_KEY}
    if [ "$DO_ISO_SSH_KEY" = "true" ]; then
      # Determine wether we use an SSH key
      read -r -p "SSH keys file [$ISO_SSH_KEY_FILE]: " NEW_ISO_SSH_KEY_FILE
      ISO_SSH_KEY_FILE=${NEW_ISO_SSH_KEY_FILE:-$ISO_SSH_KEY_FILE}
    fi
    # Get wether to install drivers
    read -r -p "Install Drivers? [$DO_INSTALL_ISO_DRIVERS]: " NEW_INSTALL_ISO_DRIVERS
    DO_INSTALL_ISO_DRIVERS=${NEW_INSTALL_ISO_DRIVERS:-$DO_INSTALL_ISO_DRIVERS}
    # Get Serial Port 0
    read -r -p "Serial Port? [$ISO_SERIAL_PORT0]: " NEW_ISO_SERIAL_PORT0
    ISO_SERIAL_PORT0=${NEW_ISO_SERIAL_PORT0:-$ISO_SERIAL_PORT0}
    # Get Serial Port 1
    read -r -p "Serial Port? [$ISO_SERIAL_PORT1]: " NEW_ISO_SERIAL_PORT1
    ISO_SERIAL_PORT1=${NEW_ISO_SERIAL_PORT1:-$ISO_SERIAL_PORT1}
    # Get Serial Port Address 0
    read -r -p "Serial Port Address? [$ISO_SERIAL_PORT_ADDRESS0]: " NEW_ISO_SERIAL_PORT_ADDRESS0
    ISO_SERIAL_PORT_ADDRESS0=${NEW_ISO_SERIAL_PORT_ADDRESS0:-$ISO_SERIAL_PORT_ADDRESS0}
    # Get Serial Port Address 1
    read -r -p "Serial Port Address? [$ISO_SERIAL_PORT_ADDRESS1]: " NEW_ISO_SERIAL_PORT_ADDRESS1
    ISO_SERIAL_PORT_ADDRESS1=${NEW_ISO_SERIAL_PORT_ADDRESS1:-$ISO_SERIAL_PORT_ADDRESS1}
    # Get Serial Port Speed 0
    read -r -p "Serial Port Speed? [$ISO_SERIAL_PORT_SPEED0]: " NEW_ISO_SERIAL_PORT_SPEED0
    ISO_SERIAL_PORT_SPEED0=${NEW_ISO_SERIAL_PORT_SPEED0:-$ISO_SERIAL_PORT_SPEED0}
    # Get Serial Port Speed 1
    read -r -p "Serial Port Speed? [$ISO_SERIAL_PORT_SPEED1]: " NEW_ISO_SERIAL_PORT_SPEED1
    ISO_SERIAL_PORT_SPEED1=${NEW_ISO_SERIAL_PORT_SPEED1:-$ISO_SERIAL_PORT_SPEED1}
  fi
}

update_iso_url () {
  BASE_INPUT_FILE=$( basename "$INPUT_FILE" )
  case $ISO_BUILD_TYPE in
    "daily-live"|"daily-live-server")
      if [ "$ISO_RELEASE" = "$CURRENT_ISO_DEV_RELEASE" ] || [ "$ISO_CODENAME" = "$CURRENT_ISO_CODENAME" ]; then
        ISO_URL="https://cdimage.ubuntu.com/ubuntu-server/daily-live/current/$ISO_CODENAME-live-server-$ISO_ARCH.iso"
      else
        ISO_URL="https://cdimage.ubuntu.com/ubuntu-server/$ISO_CODENAME/daily-live/current/$BASE_INPUT_FILE"
      fi
      NEW_DIR="$ISO_OS_NAME/$ISO_CODENAME"
     ;;
    "daily-desktop")
      if [ "$ISO_RELEASE" = "$CURRENT_ISO_DEV_RELEASE" ] || [ "$ISO_CODENAME" = "$CURRENT_ISO_CODENAME" ]; then
        ISO_URL="https://cdimage.ubuntu.com/daily-live/current/$BASE_INPUT_FILE"
      else
        ISO_URL="https://cdimage.ubuntu.com/$ISO_CODENAME/daily-live/current/$BASE_INPUT_FILE"
      fi
      NEW_DIR="$ISO_OS_NAME/$ISO_CODENAME"
      ;;
    "desktop")
      ISO_URL="https://releases.ubuntu.com/$ISO_RELEASE/$BASE_INPUT_FILE"
      NEW_DIR="$ISO_OS_NAME/$ISO_RELEASE"
      ;;
    *)
      if [ "$ISO_ARCH" = "amd64" ]; then
        URL_RELEASE=$( echo "$ISO_RELEASE" |awk -F. '{print $1"."$2}' )
        ISO_URL="https://releases.ubuntu.com/$URL_RELEASE/$BASE_INPUT_FILE"
      else
        ISO_URL="https://cdimage.ubuntu.com/releases/$ISO_RELEASE/release/$BASE_INPUT_FILE"
      fi
      NEW_DIR="$ISO_OS_NAME/$ISO_RELEASE"
      ;;
  esac
  if [ "$OLD_ISO_URL" = "" ]; then
    OLD_ISO_URL="$DEFAULT_OLD_ISO_URL"
  fi
}

# Function: handle_bios
#
# Handle BIOS and EFI options

handle_bios () {
  if [[ "$ISO_BOOT_TYPE" =~ "efi" ]]; then
    ISO_INSTALL_PACKAGES="$ISO_INSTALL_PACKAGES grub-efi"
    ISO_CHROOT_PACKAGES="$ISO_CHROOT_PACKAGES grub-efi"
  fi
  if [[ "$ISO_BOOT_TYPE" =~ "bios" ]]; then
    ISO_INSTALL_PACKAGES="$ISO_INSTALL_PACKAGES grub-pc"
    ISO_CHROOT_PACKAGES="$ISO_CHROOT_PACKAGES grub-pc"
  fi
}

# Function: get_ssh_key
#
# Get SSH key if option set

get_ssh_key () {
  if [ "$DO_ISO_SSH_KEY" = "true" ]; then
    if ! [ -f "$ISO_SSH_KEY_FILE" ]; then
      warning_message "SSH Key file ($ISO_SSH_KEY_FILE) does not exist"
    else
      ISO_SSH_KEY=$(<"$ISO_SSH_KEY_FILE")
    fi
  fi
}

# Function: handle_ubuntu_pro
#
# Handle Ubuntu Pro Apt News etc

handle_ubuntu_pro () {
  if [ "$ISO_REALNAME" = "Ubuntu" ]; then
    if [ "$ISO_MAJOR_REL" -ge 22 ]; then
      ISO_INSTALL_PACKAGES="$ISO_INSTALL_PACKAGES ubuntu-advantage-tools"
      ISO_CHROOT_PACKAGES="$ISO_CHROOT_PACKAGES ubuntu-advantage-tools"
    fi
  fi
}

# Function: Handle command line arguments

if [ "$SCRIPT_ARGS" = "" ]; then
  print_help
fi

while test $# -gt 0
do
  case $1 in
    -0|--oldrelease)
      OLD_ISO_RELEASE="$2"
      shift 2
      ;;
    -1|--country)
      ISO_COUNTRY="$2"
      shift 2
      ;;
    -2|--isourl)
      ISO_URL="$2"
      shift 2
      ;;
    -3|--prefix)
      ISO_PREFIX="$2"
      shift 2
      ;;
    -4|--suffix)
      ISO_SUFFIX="$2"
      shift 2
      ;;
    -5|--block)
      ISO_BLOCKLIST="$2"
      shift 2
      ;;
    -6|--allow)
      ISO_ALLOWLIST="$2"
      shift 2
      ;;
    -7|--oldisourl)
      OLD_ISO_URL="$2"
      shift 2
      ;;
    -8|--oldinputfile)
      OLD_INPUT_FILE="$2"
      shift 2
      ;;
    -9|--search)
      ISO_SEARCH="$2"
      shift 2
      ;;
    -A|--codename|--distro)
      ISO_CODENAME="$2"
      shift 2
      ;;
    -a|--action)
      ACTION="$2"
      shift 2
      ;;
    -B|--layout|--vmsize)
      ISO_LAYOUT="$2"
      VM_SIZE=$2
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
      DO_ISO_SSH_KEY="true"
      shift 2
      ;;
    -D|--dns)
      ISO_DNS="$2"
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
      ISO_DHCP="false"
      ;;
    -g|--grubmenu|--vmname)
      ISO_GRUB_MENU="$2"
      VM_NAME="$2"
      shift 2
      ;;
    -H|--hostname)
      ISO_HOSTNAME="$2"
      shift 2
      ;;
    -h|--help)
      print_help
      ;;
    -I|--ip)
      ISO_IP="$2"
      shift 2
      ISO_DHCP="false"
      ;;
    -i|--inputiso|--vmiso)
      INPUT_FILE="$2"
      VM_ISO="$2"
      shift 2
      ;;
    -J|--grubfile)
      ISO_GRUB_FILE="$2"
      shift 2
      ;;
    -j|--autoinstalldir)
      ISO_AUTOINSTALL_DIR="$2"
      shift 2
      ;;
    -K|--kernel|--vmtype)
      ISO_KERNEL="$2"
      VM_TYPE="$2"
      shift 2
      ;;
    -k|--kernelargs|--vmcpus)
      ISO_KERNEL_ARGS="$2"
      VM_CPUS="$2"
      shift 2
      ;;
    -L|--release)
      ISO_RELEASE="$2"
      shift 2
      case $ISO_RELEASE in
        "$CURRENT_ISO_DEV_RELEASE")
          if [ "$ISO_BUILD_TYPE" = "" ]; then
            ISO_BUILD_TYPE="daily-live"
            DO_DAILY_ISO="true"
          fi
          ;;
      esac
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
    -N|--bootserverfile)
      BOOT_SERVER_FILE="$2"
      DO_CUSTOM_BOOT_SERVER_FILE="true"
      shift 2
      ;;
    -n|--nic|--vmnic)
      ISO_NIC="$2"
      VM_NIC="$2"
      shift 2
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
      ISO_BUILD_TYPE="$2"
      case "$ISO_BUILD_TYPE" in
        "daily")
          DO_DAILY_ISO="true"
          ;;
      esac
      shift 2
      ;;
    -q|--arch)
      ISO_ARCH="$2"
      shift 2
      ISO_ARCH=$( echo "$ISO_ARCH" |sed "s/aarch64/arm64/g" |sed "s/x86_64/amd64/g" |sed "s/x86/amd64/g" )
      ;;
    -R|--realname)
      ISO_REALNAME="$2"
      shift 2
      ;;
    -r|--serialportspeed)
      ISO_SERIAL_PORT_SPEED0="$2"
      shift 2
      ;;
    -S|--swapsize|--vmram)
      ISO_SWAPSIZE="$2"
      VM_RAM="$2"
      shift 2
      ;;
    -s|--squashfsfile)
      ISO_SQUASHFS_FILE="$2"
      shift 2
      ;;
    -T|--timezone)
      ISO_TIMEZONE="$2"
      shift 2
      ;;
    -t|--serialportaddress)
      ISO_SERIAL_PORT_ADDRESS0="$2"
      shift 2
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
    -v|--serialport)
      ISO_SERIAL_PORT0="$2"
      shift 2
      ;;
    -W|--workdir)
      WORK_DIR="$2"
      shift 2
      ;;
    -w|--preworkdir)
      PRE_WORK_DIR="$2"
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
    -Z|--options)
      OPTIONS="$2";
      shift 2
      ;;
    -z|--volumemanager)
      ISO_VOLMGR="$2"
      shift 2
      ;;
    --zfsfilesystems)
      ZFS_FILESYSTEMS="$2"
      shift 2
      ;;
    --autoinstall)
      DO_CUSTOM_AUTO_INSTALL="true"
      AUTO_INSTALL_FILE="$2"
      shift 2
      ;;
    --)
      shift
      break
      ;;
    *)
      print_help
      ;;
  esac
done

# Setup functions

set_defaults
reset_defaults
set_default_flags
set_default_os_name
set_default_arch
set_default_release
set_default_codename
set_default_old_url
set_default_docker_arch
set_default_dirs
process_switches
reset_default_dirs
set_default_files
reset_default_files
process_options
process_actions
process_post_install
update_required_packages
update_output_file_name
update_iso_url
handle_bios
handle_ubuntu_pro

# Output variables

if [ "$DO_PRINT_ENV" = "true" ] || [ "$INTERACTIVE_MODE" = "true" ]; then
  TEMP_VERBOSE_MODE="true"
fi

get_ssh_key
get_my_ip
get_password_crypt "$ISO_PASSWORD"
print_env

# If run in interactive mode ask for values for required parameters
# Set any unset values to defaults

if [ "$INTERACTIVE_MODE" = "true" ]; then
  get_interactive_input
fi

# Handle specific functions

if [ "$DO_DOCKER" = "true" ] || [ "$DO_CHECK_DOCKER" = "true" ]; then
  create_docker_iso
fi
if [ "$DO_DELETE_VM" = "true" ]; then
  delete_vm
  exit
fi
if [ "$DO_CREATE_VM" = "true" ]; then
  get_info_from_iso
  install_required_packages
  create_vm
  exit
fi
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
  if [ "$DO_OLD_INSTALLER" = "true" ]; then
    check_old_work_dir
  fi
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
  if [ "$DO_PREPARE_AUTOINSTALL_ISO_ONLY" = "true" ]; then
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
if [ "$DO_LIST_ISOS" = "true" ]; then
  list_isos
  exit
fi

if [ "$DO_PRINT_HELP" = "true" ]; then
  print_help
fi
