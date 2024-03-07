#!/usr/bin/env bash

# Name:         guige (Generic Ubuntu/Unix ISO Generation Engine)
# Version:      2.1.0
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
MODULE_PATH="$START_PATH/modules"

# Load modules

if [ -d "$MODULE_PATH" ]; then
  for MODULE in $( ls "$MODULE_PATH"/*.sh ); do
    if [[ "$SCRIPT_ARGS" =~ "verbose" ]]; then
      echo "Loading Module: $MODULE"
    fi
    . $MODULE
  done
fi

exit

# Function: Handle command line arguments

if [ "$SCRIPT_ARGS" = "" ]; then
  print_help
fi

set_defaults
set_default_flags

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
      ISO_OS_NAME="$2"
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
    -D|--dns|--nameserver)
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
    --userdata|--autoinstall|--kickstart)
      DO_CUSTOM_AUTO_INSTALL="true"
      AUTO_INSTALL_FILE="$2"
      shift 2
      ;;
    --oeminstall)
      ISO_OEM_INSTALL="$2"
      shift 2
      ;;
    --sourceid)
      ISO_SOURCE_ID="$2"
      shift 2
      ;;
    --installmode)
      ISO_INSTALL_MODE="$2"
      shift 2
      ;;
    --passwordalgorithm)
      ISO_PASSWORD_ALGORITHM="$2"
      shift 2
      ;;
    --bootloader)
      ISO_BOOT_LOADER_LOCATION="$2"
      shift 2
      ;;
    --selinux)
      ISO_SELINUX="$2"
      shift 2
      ;;
    --firewall)
      ISO_FIREWALL="$2"
      shift 2
      ;;
    --allow)
      ISO_ALLOW_SERVICE="$2"
      shift 2
      ;;
    --onboot)
      ISO_ONBOOT="$2"
      shift 2
      ;;
    --gecos)
      ISO_GECOS="$2"
      shift 2
      ;;
    --groups)
      ISO_GROUPS="$2"
      shift 2
      ;;
    --installsource)
      ISO_INSTALL_SOURCE="$2"
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
reset_defaults
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
update_iso_packages
update_output_file_name
update_iso_url
handle_bios
handle_ubuntu_pro
copy_custom_user_data

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

if [ "$DO_LIST_VM" = "true" ]; then
  list_vm
  exit
fi

if [ "$DO_DOCKER" = "true" ] || [ "$DO_CHECK_DOCKER" = "true" ]; then
  create_docker_iso
fi
if [ "$DO_DELETE_VM" = "true" ]; then
  delete_vm
  exit
fi
if [ "$DO_CREATE_VM" = "true" ]; then
  get_info_from_iso
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
  if [ "$ACTION" = "getiso" ]; then
    exit
  fi
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
  prepare_iso
  create_iso
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
    prepare_iso
  fi
  if [ "$DO_CREATE_AUTOINSTALL_ISO_ONLY" = "true" ]; then
    DO_PRINT_HELP="false"
    prepare_iso
    create_iso
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
