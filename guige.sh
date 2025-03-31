#!/usr/bin/env bash

# Name:         guige (Generic Ubuntu/Unix ISO Generation Engine)
# Version:      3.1.4
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
OS_USER=$( whoami )
OS_GROUP=$( id -gn )

# Handle verbose and debug early so it's enabled early

if [[ "$*" =~ "verbose" ]]; then
  DO_VERBOSE="true"
  set -eu
else
  DO_VERBOSE="false"
fi

if [[ "$*" =~ "debug" ]]; then
  DO_VERBOSE="true"
  set -x
else
  DO_VERBOSE="false"
fi

# Check if we are running inside docker

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
set_default_os_name
set_default_release
set_default_dirs
set_default_files
set_default_flags

# Function: Handle command line arguments

if [ "$SCRIPT_ARGS" = "" ]; then
  print_help
fi

while test $# -gt 0
do
  case $1 in
    --action|--actions)
      ISO_ACTION="$2"
      shift 2
      ;;
    --allow)
      ISO_ALLOWLIST="$2"
      shift 2
      ;;
    --allowpassword|--allow-password)
      ISO_ALLOWPASSWORD="true"
      shift
      ;;
    --allowservice|--service)
      ISO_ALLOWSERVICE="$2"
      shift 2
      ;;
    --arch)
      ISO_ARCH="$2"
      shift 2
      ISO_ARCH=$( echo "$ISO_ARCH" |sed "s/aarch64/arm64/g" |sed "s/x86_64/amd64/g" |sed "s/x86/amd64/g" )
      ;;
    --autoinstalldir|--aidir)
      ISO_AUTOINSTALLDIR="$2"
      shift 2
      ;;
    --block)
      ISO_BLOCKLIST="$2"
      shift 2
      ;;
    --bmcip)
      ISO_BMCIP="$2"
      shift 2
      ;;
    ----bmcpass|--bmcpassword)
      ISO_BMCPASSWORD="$2"
      shift 2
      ;;
    --bmcuser|--bmcusername)
      ISO_BMCUSERNAME="$2"
      shift 2
      ;;
    --bootdisk|--disk|--installdisk|--firstdisk)
      ISO_DISK="$2"
      shift 2
      ;;
    --bootloader)
      ISO_BOOTLOADER="$2"
      shift 2
      ;;
    --bootserverfile)
      ISO_BOOTSERVERFILE="$2"
      DO_ISO_BOOTSERVERFILE="true"
      shift 2
      ;;
    --bootserverip)
      ISO_BOOTSERVERIP="$2"
      shift 2
      ;;
    --bootsize)
      ISO_BOOTSIZE="$2"
      shift 2
      ;;
    --build|--buildtype)
      ISO_BUILDTYPE="$2"
      case "$ISO_BUILDTYPE" in
        "daily")
          DO_ISO_DAILY="true"
          ;;
      esac
      shift 2
      ;;
    --chrootpackages)
      ISO_CHROOTPACKAGES="$2"
      shift 2
      ;;
    --cidr)
      ISO_CIDR="$2"
      shift 2
      ;;
    --codename|--distro)
      ISO_CODENAME="$2"
      shift 2
      ;;
    --compression)
      ISO_COMPRESSION="$2"
      DO_ISO_COMPRESSION="true"
      shift 2
      ;;
    --country)
      ISO_COUNTRY="$2"
      shift 2
      ;;
    --debug)
      set -x
      shift
      ;;
    --delete)
      DELETE="$2"
      shift 2
      ;;
    --disableservice|--disable)
      ISO_DISABLESERVICE="$2"
      shift 2
      ;;
    --diskserial)
      ="$2"
      shift 2
      ;;
    --diskwwn)
      ISO_DISK_WWN="$2"
      shift 2
      ;;
    --dns|--nameserver)
      ISO_DNS="$2"
      shift 2
      ;;
    --enableservice|--enable)
      ISO_ENABLESERVICE="$2"
      shift 2
      ;;
    --fallback)
      ISO_FALLBACK="$2"
      shift 2
      ;;
    --firewall)
      ISO_FIREWALL="$2"
      shift 2
      ;;
    --firstoption|--first-option)
      ISO_OPTION="$2"
      shift 2
      ;;
    --gateway)
      ISO_GATEWAY="$2"
      shift 2
      DO_ISO_DHCP="false"
      ;;
    --gecos)
      ISO_GECOS="$2"
      shift 2
      ;;
    --groups)
      ISO_GROUPS="$2"
      shift 2
      ;;
    --grub|--grubfile)
      DO_ISO_GRUBFILE="true"
      ISO_GRUBFILE="$2"
      shift 2
      ;;
    --grubmenu)
      ISO_GRUBMENU="$2"
      shift 2
      ;;
    --grubtimeout|--grub-timeout)
      ISO_GRUBTIMEOUT="$2"
      shift 2
      ;;
    -h|--help)
      print_help ""
      ;;
    --hostname)
      ISO_HOSTNAME="$2"
      shift 2
      ;;
    --inputiso|--vmiso)
      ISO_INPUTFILE="$2"
      VM_ISO="$2"
      shift 2
      ;;
    --inputci|--vmci)
      ISO_INPUTCI="$2"
      shift 2
      ;;
    --installmode|--install-mode)
      ISO_INSTALLMODE="$2"
      shift 2
      ;;
    --installmount)
      ISO_INSTALLMOUNT="$2"
      shift 2
      ;;
    --installpassword|--install-password|--installpass|--install-pass)
      ISO_INSTALLPASSWORD="$2"
      shift 2
      ;;
    --installsource|--install-source)
      ISO_INSTALLSOURCE="$2"
      shift 2
      ;;
    --installtarget)
      ISO_TARGETMOUNT="$2"
      shift 2
      ;;
    --installuser|--install-user)
      ISO_INSTALLUSERNAME="$2"
      shift 2
      ;;
    --ip)
      ISO_IP="$2"
      shift 2
      DO_ISO_DHCP="false"
      ;;
    --isolinux|--isolinuxfile)
      DO_ISO_ISOLINUXFILE="true"
      ISO_ISOLINUXFILE="$2"
      shift 2
      ;;
    --isopackages|--packages)
      ISO_PACKAGES="$2"
      shift 2
      ;;
    --isourl|--url)
      ISO_URL="$2"
      shift 2
      ;;
    --isovolid|--volid)
      ISO_VOLID="$2"
      shift 2
      ;;
    --isokernel|--kernel)
      ISO_KERNEL="$2"
      shift 2
      ;;
    --isokernelargs|--kernelargs)
      ISO_KERNELARGS="$2"
      shift 2
      ;;
    --layout|--vmsize)
      ISO_LAYOUT="$2"
      VM_SIZE=$2
      shift 2
      ;;
    --lcall)
      ISO_LCALL="$2"
      shift 2
      ;;
    --locale)
      ISO_LOCALE="$2"
      shift 2
      ;;
    --lvname)
      ISO_LVNAME="$2"
      shift 2
      ;;
    --netmask)
      ISO_NETMASK="$2"
      shift 2
      ;;
    --nic|--vmnic|--installnic|--bootnic|--firstnic)
      ISO_NIC="$2"
      VM_NIC="$2"
      shift 2
      ;;
    --oeminstall)
      ISO_OEMINSTALL="$2"
      shift 2
      ;;
    --oldinputfile)
      OLD_ISO_INPUTFILE="$2"
      shift 2
      ;;
    --oldisourl)
      OLD_ISO_URL="$2"
      shift 2
      ;;
    --oldrelease)
      OLD_ISO_RELEASE="$2"
      shift 2
      ;;
    --onboot)
      ISO_ONBOOT="$2"
      shift 2
      ;;
    --option|--options)
      ISO_OPTIONS="$2";
      shift 2
      ;;
    --outputiso)
      ISO_OUTPUTFILE="$2"
      shift 2
      ;;
    --outputci)
      ISO_OUTPUTCI="$2"
      shift 2
      ;;
    --password)
      ISO_PASSWORD="$2"
      shift 2
      ;;
    --passalgo|--passwordalgorithm|--password-algorithm)
      ISO_PASSWORDALGORITHM="$2"
      shift 2
      ;;
    --pesize)
      ISO_PESIZE="$2"
      shift 2
      ;;
    --postinstall)
      ISO_POSTINSTALL="$2"
      shift 2
      ;;
    --prefix)
      ISO_PREFIX="$2"
      shift 2
      ;;
    --preworkdir)
      ISO_PREWORKDIR="$2"
      shift 2
      ;;
    --pvname)
      ISO_PVNAME="$2"
      shift 2
      ;;
    --realname)
      ISO_REALNAME="$2"
      shift 2
      ;;
    --release)
      ISO_RELEASE="$2"
      shift 2
      case $ISO_RELEASE in
        "$CURRENT_ISO_DEVRELEASE")
          if [ "$ISO_BUILDTYPE" = "" ]; then
            ISO_BUILDTYPE="daily-live"
            DO_ISO_DAILY="true"
          fi
          ;;
      esac
      get_release_info
      get_code_name
      get_build_type
      ;;
    --rootsize)
      ISO_ROOTSIZE="$2"
      shift 2
      ;;
    --search)
      ISO_SEARCH="$2"
      shift 2
      ;;
    --selinux)
      ISO_SELINUX="$2"
      shift 2
      ;;
    --serialport)
      ISO_SERIALPORT0="$2"
      shift 2
      ;;
    --serialportaddress)
      ISO_SERIALPORTADDRESS0="$2"
      shift 2
      ;;
    --serialportspeed)
      ISO_SERIALPORTSPEED0="$2"
      shift 2
      ;;
    --sourceid)
      ISO_SOURCEID="$2"
      shift 2
      ;;
    --squashfsfile)
      ISO_SQUASHFSFILE="$2"
      shift 2
      ;;
    --sshkey)
      ISO_SSHKEY="$2"
      DO_ISO_SSHKEY="true"
      shift 2
      ;;
    --sshkeyfile)
      ISO_SSHKEYFILE="$2"
      DO_ISO_SSHKEY="true"
      shift 2
      ;;
    --suffix)
      ISO_SUFFIX="$2"
      shift 2
      ;;
    --swapsize|--vmram)
      ISO_SWAPSIZE="$2"
      VM_RAM="$2"
      shift 2
      ;;
    --timezone)
      ISO_TIMEZONE="$2"
      shift 2
      ;;
    --updates)
      ISO_UPDATES="$2"
      shift 2
      ;;
    --userdata|--autoinstall|--kickstart)
      DO_ISO_AUTOINSTALL="true"
      ISO_VOLMGRS="custom"
      ISO_AUTOINSTALLFILE="$2"
      shift 2
      ;;
    --user|--username)
      ISO_USERNAME="$2"
      shift 2
      ;;
    --usage)
      print_usage "$2"
      exit
      ;;
    -V|--version)
      echo "$SCRIPT_VERSION"
      shift
      exit
      ;;
    --vgname)
      ISO_VGNAME="$2"
      shift 2
      ;;
    --vmcpus)
      VM_CPUS="$2"
      shift 2
      ;;
    --vmname)
      VM_NAME="$2"
      shift 2
      ;;
    --vmtype)
      VM_TYPE="$2"
      shift 2
      ;;
    --volumemanager|--volumemanagers|--volmgr|--volmgrs)
      ISO_VOLMGRS="$2"
      shift 2
      ;;
    --workdir)
      ISO_WORKDIR="$2"
      shift 2
      ;;
    --zfs|--zfsfilesystems)
      DO_ISO_ZFSFILESYSTEMS="true"
      ISO_ZFSFILESYSTEMS="$2"
      shift 2
      ;;
    --)
      shift
      break
      ;;
    *)
      print_help ""
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
update_ISO_PACKAGES
update_output_file_name
update_iso_url
update_ci_url
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
  ISO_INSTALLPASSWORD_CRYPT=$( get_password_crypt "$ISO_INSTALLPASSWORD" )
fi
print_env

# If run in interactive mode ask for values for required parameters
# Set any unset values to defaults

if [ "$INTERACTIVE_MODE" = "true" ]; then
  get_interactive_input
fi

# Do test outputs

if [ "$ISO_ACTION" = "test" ]; then
  check_ISO_WORKDIR
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
if [ "$DO_CREATE_ISO_VM" = "true" ]; then
  get_info_from_iso
  create_iso_vm
  exit
fi
if [ "$DO_CREATE_CI_VM" = "true" ]; then
  create_ci_vm
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
if [ "$DO_CHECK_ISO_WORKDIR" = "true" ]; then
  DO_PRINT_HELP="false"
  check_ISO_WORKDIR
  if [ "$DO_OLD_INSTALLER" = "true" ]; then
    check_old_ISO_WORKDIR
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
  if [ "$ISO_ACTION" = "getiso" ]; then
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
  if [ "$DO_UNMOUNT_ISO" = "true" ]; then
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
