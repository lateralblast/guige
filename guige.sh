#!/usr/bin/env bash

# Name:         guige (Generic Ubuntu/Unix ISO Generation Engine)
# Version:      2.5.4
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
# shellcheck disable=SC2034
# shellcheck disable=SC2045
# shellcheck disable=SC1090

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
OS_GROUP=$(groups |awk '{ print $2 }')

if [ -f /.dockerenv ]; then
  START_PATH=$( dirname "$0" )
  MODULE_PATH="$START_PATH/modules"
else
  MODULE_PATH="$START_PATH/modules"
fi

# Load modules

if [ -d "$MODULE_PATH" ]; then
  for MODULE in $( ls "$MODULE_PATH"/*.sh ); do
    if [[ "$SCRIPT_ARGS" =~ "verbose" ]]; then
      echo "Loading Module: $MODULE"
    fi
    . "$MODULE"
  done
fi

set_defaults
set_default_flags

# Function: Handle command line arguments

if [ "$SCRIPT_ARGS" = "" ]; then
  print_help
fi

while test $# -gt 0
do
  if [ "$1" = "-h" ]; then
    print_help "$2"
    exit
  fi
  if [ "$2" = "" ]; then
    PATTERN="[version|help|usage]"
    if ! [[ $1 =~ $PATTERN ]]; then
      warning_message "No $1 specified"
      exit
    fi
  fi
  case $1 in
    --oldrelease)
      OLD_ISO_RELEASE="$2"
      shift 2
      ;;
    --country)
      ISO_COUNTRY="$2"
      shift 2
      ;;
    --isourl)
      ISO_URL="$2"
      shift 2
      ;;
    --prefix)
      ISO_PREFIX="$2"
      shift 2
      ;;
    --suffix)
      ISO_SUFFIX="$2"
      shift 2
      ;;
    --block)
      ISO_BLOCKLIST="$2"
      shift 2
      ;;
    --allow)
      ISO_ALLOWLIST="$2"
      shift 2
      ;;
    --oldisourl)
      OLD_ISO_URL="$2"
      shift 2
      ;;
    --oldinputfile)
      OLD_INPUT_FILE="$2"
      shift 2
      ;;
    --search)
      ISO_SEARCH="$2"
      shift 2
      ;;
    --codename|--distro)
      ISO_OS_NAME="$2"
      shift 2
      ;;
    --action)
      ACTION="$2"
      shift 2
      ;;
    --layout|--vmsize)
      ISO_LAYOUT="$2"
      VM_SIZE=$2
      shift 2
      ;;
    --bootserverip)
      BOOT_SERVER_IP="$2"
      shift 2
      ;;
    --cidr)
      ISO_CIDR="$2"
      shift 2
      ;;
    --sshkeyfile)
      ISO_SSH_KEY_FILE="$2"
      DO_ISO_SSH_KEY="true"
      shift 2
      ;;
    --dns|--nameserver)
      ISO_DNS="$2"
      shift 2
      ;;
    --bootdisk|--disk|--installdisk|--firstdisk)
      ISO_DISK+="$2"
      shift 2
      ;;
    --locale)
      ISO_LOCALE="$2"
      shift 2
      ;;
    --lcall)
      ISO_LC_ALL="$2"
      shift 2
      ;;
    --bmcusername)
      BMC_USERNAME="$2"
      shift 2
      ;;
    --delete)
      DELETE="$2"
      shift 2
      ;;
    --fallback)
      ISO_FALLBACK="$2"
      shift 2
      ;;
    --gateway)
      ISO_GATEWAY="$2"
      shift 2
      DO_DHCP="false"
      ;;
    --grubmenu|--vmname)
      ISO_GRUB_MENU="$2"
      VM_NAME="$2"
      shift 2
      ;;
    --hostname)
      ISO_HOSTNAME="$2"
      shift 2
      ;;
    --help)
      print_help
      ;;
    --ip)
      ISO_IP="$2"
      shift 2
      DO_DHCP="false"
      ;;
    --inputiso|--vmiso)
      INPUT_FILE="$2"
      VM_ISO="$2"
      shift 2
      ;;
    --grubfile)
      ISO_GRUB_FILE="$2"
      shift 2
      ;;
    --autoinstalldir)
      ISO_AUTOINSTALL_DIR="$2"
      shift 2
      ;;
    --kernel|--vmtype)
      ISO_KERNEL="$2"
      VM_TYPE="$2"
      shift 2
      ;;
    --kernelargs|--vmcpus)
      ISO_KERNEL_ARGS="$2"
      VM_CPUS="$2"
      shift 2
      ;;
    --release)
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
      get_release_info
      get_code_name
      get_build_type
      ;;
    --bmcip)
      BMC_IP="$2"
      shift 2
      ;;
    --installtarget)
      ISO_TARGET_MOUNT="$2"
      shift 2
      ;;
    --installmount)
      ISO_INSTALL_MOUNT="$2"
      shift 2
      ;;
    --bootserverfile)
      BOOT_SERVER_FILE="$2"
      DO_CUSTOM_BOOT_SERVER_FILE="true"
      shift 2
      ;;
    --nic|--vmnic|--installnic|--bootnic|--firstnic)
      ISO_NIC="$2"
      VM_NIC="$2"
      shift 2
      ;;
    --isopackages)
      ISO_INSTALL_PACKAGES="$2"
      shift 2
      ;;
    --outputiso)
      OUTPUT_FILE="$2"
      shift 2
      ;;
    --password)
      ISO_PASSWORD="$2"
      shift 2
      ;;
    --chrootpackages)
      ISO_CHROOT_PACKAGES="$2"
      shift 2
      ;;
    --build)
      ISO_BUILD_TYPE="$2"
      case "$ISO_BUILD_TYPE" in
        "daily")
          DO_DAILY_ISO="true"
          ;;
      esac
      shift 2
      ;;
    --arch)
      ISO_ARCH="$2"
      shift 2
      ISO_ARCH=$( echo "$ISO_ARCH" |sed "s/aarch64/arm64/g" |sed "s/x86_64/amd64/g" |sed "s/x86/amd64/g" )
      ;;
    --realname)
      ISO_REALNAME="$2"
      shift 2
      ;;
    --diskserial)
      ISO_DISK_SERIAL="$2"
      shift 2
      ;;
    --diskwwn)
      ISO_DISK_WWN="$2"
      shift 2
      ;;
    --serialportspeed)
      ISO_SERIAL_PORT_SPEED0="$2"
      shift 2
      ;;
    --swapsize|--vmram)
      ISO_SWAP_SIZE="$2"
      VM_RAM="$2"
      shift 2
      ;;
    --squashfsfile)
      ISO_SQUASHFS_FILE="$2"
      shift 2
      ;;
    --timezone)
      ISO_TIMEZONE="$2"
      shift 2
      ;;
    --serialportaddress)
      ISO_SERIAL_PORT_ADDRESS0="$2"
      shift 2
      ;;
    --username)
      ISO_USERNAME="$2"
      shift 2
      ;;
    --postinstall)
      ISO_POSTINSTALL="$2"
      shift 2
      ;;
    --version)
      echo "$SCRIPT_VERSION"
      shift
      exit
      ;;
    --serialport)
      ISO_SERIAL_PORT0="$2"
      shift 2
      ;;
    --workdir)
      WORK_DIR="$2"
      shift 2
      ;;
    --preworkdir)
      PRE_WORK_DIR="$2"
      shift 2
      ;;
    --isovolid)
      ISO_VOLID="$2"
      shift 2
      ;;
    --grubtimeout|--grub-timeout)
      ISO_GRUB_TIMEOUT="$2"
      shift 2
      ;;
    --allowpassword|--allow-password)
      ISO_ALLOW_PASSWORD="true"
      shift
      ;;
    --bmcpassword)
      BMC_PASSWORD="$2"
      shift 2
      ;;
    --options)
      OPTIONS="$2";
      shift 2
      ;;
    --volumemanager|--volumemanagers|--volmgr|--volmgrs)
      ISO_VOLMGRS="$2"
      shift 2
      ;;
    --zfsfilesystems)
      ZFS_FILESYSTEMS="$2"
      shift 2
      ;;
    --userdata|--autoinstall|--kickstart)
      DO_CUSTOM_AUTO_INSTALL="true"
      ISO_VOLMGRS="custom"
      AUTO_INSTALL_FILE="$2"
      shift 2
      ;;
    --isolinux)
      DO_CUSTOM_ISOLINUX="true"
      ISOLINUX_FILE="$2"
      shift 2
      ;;
    --grub)
      DO_CUSTOM_GRUB="true"
      GRUB_FILE="$2"
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
    --installmode|--install-mode)
      ISO_INSTALL_MODE="$2"
      shift 2
      ;;
    --passwordalgorithm|--password-algorithm)
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
    --installsource|--install-source)
      ISO_INSTALL_SOURCE="$2"
      shift 2
      ;;
    --bootsize)
      ISO_BOOT_SIZE="$2"
      shift 2
      ;;
    --rootsize)
      ISO_ROOT_SIZE="$2"
      shift 2
      ;;
    --pesize)
      ISO_PE_SIZE="$2"
      shift 2
      ;;
    --vgname)
      ISO_VG_NAME="$2"
      shift 2
      ;;
    --lvname)
      ISO_LV_NAME="$2"
      shift 2
      ;;
    --installuser|--install-user)
      ISO_INSTALL_USERNAME="$2"
      shift 2
      ;;
    --installpassword|--install-password|--installpass|--install-pass)
      ISO_INSTALL_PASSWORD="$2"
      shift 2
      ;;
    --updates)
      ISO_UPDATES="$2"
      shift 2
      ;;
    --usage)
      print_usage "$2"
      exit
      ;;
    --)
      shift
      break
      ;;
    *)
      print_help "$2"
      exit
      ;;
  esac
done

# Setup functions
set_default_os_name
set_default_arch
set_default_release
set_default_codename
set_default_old_url
set_default_docker_arch
set_default_dirs
reset_defaults
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
get_iso_type

# Output variables

if [ "$DO_PRINT_ENV" = "true" ] || [ "$INTERACTIVE_MODE" = "true" ]; then
  TEMP_VERBOSE_MODE="true"
fi

get_ssh_key
get_my_ip
ISO_PASSWORD_CRYPT=$( get_password_crypt "$ISO_PASSWORD" )
if [ "$DO_INSTALL_USER" = "true" ]; then
  ISO_INSTALL_PASSWORD_CRYPT=$( get_password_crypt "$ISO_INSTALL_PASSWORD" )
fi
print_env

# If run in interactive mode ask for values for required parameters
# Set any unset values to defaults

if [ "$INTERACTIVE_MODE" = "true" ]; then
  get_interactive_input
fi

# Do test outputs

if [ "$ACTION" = "test" ]; then
  check_work_dir
  if [ "$DO_KS_TEST" = "true" ]; then
    prepare_kickstart_files
    exit
  fi
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
  install_required_packages "$REQUIRED_PACKAGES"
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
