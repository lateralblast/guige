#!/usr/bin/env bash

# shellcheck disable=SC2129
# shellcheck disable=SC2034

# Function: print_cli_help
#
# Print script help information

print_cli_help () {
  cat <<-HELP

  Usage: ${0##*/} [OPTIONS...]
  
    --oldrelease            Old release (used for copying file from an older release ISO)
    --debug                 Set debug flag (set -x)
    --country               Country (used for sources.list mirror - default: $DEFAULT_ISO_COUNTRY)
    --isourl                Specify ISO URL
    --prefix                Prefix to add to ISO name
    --suffix                Suffix to add to ISO name
    --block                 Block kernel module(s)
    --allow                 Load additional kernel modules(s)
    --oldisourl             Old release ISO URL (used with --oldrelease)
    --oldinputfile          Old release ISO (used with --oldrelease)
    --search                Search output for value (eg --action listallisos --search efi)
    --codename|--disto      Linux release codename or distribution
    --action:               Action to perform (e.g. createiso, justiso, runchrootscript, checkdocker, installrequired)
    --layout|--vmsize:      Layout or VM disk size (default: $DEFAULT_ISO_LAYOUT/$DEFAULT_VM_SIZE)
    --bootserverip:         NFS/Bootserver IP
    --cidr:                 CIDR (default: $DEFAULT_ISO_CIDR)
    --sshkeyfile:           SSH key file to use as SSH key (default: $MASKED_DEFAULT_ISO_SSH_KEY_FILE)
    --dns:                  DNS Server (ddefault: $DEFAULT_ISO_DNS)
    --bootdisk:             Boot Disk devices (default: $DEFAULT_ISO_DISK)
    --firstoption:          First menu option (default: $DEFAULT_ISO_OPTION)
    --locale:               LANGUAGE (default: $DEFAULT_ISO_LOCALE)
    --lcall:                LC_ALL (default: $DEFAULT_ISO_LC_ALL)
    --bmcusername:          BMC/iDRAC User (default: $DEFAULT_BMC_USERNAME)
    --delete:               Remove previously created files (default: $FORCE_MODE)
    --fallback:             Installation fallback (default: $DEFAULT_ISO_FALLBACK)
    --gateway:              Gateway (default $DEFAULT_ISO_GATEWAY)
    --grubmenu:             Set default grub menu (default: $DEFAULT_ISO_GRUB_MENU)
    --vmname:               Set VM name (default: $DEFAULT_VM_NAME)
    --hostname              Hostname (default: $DEFAULT_ISO_HOSTNAME)
    --help                  Help/Usage Information
    --ip:                   IP Address (default: $DEFAULT_ISO_IP)
    --inputiso|--vmiso:     Input/base ISO file
    --grubfile              GRUB file
    --autoinstalldir        Directory where autoinstall config files are stored on ISO
    --kernel:               Kernel (default: $DEFAULT_ISO_KERNEL)
    --vmtype:               VM type (default: $DEFAULT_VM_TYPE)
    --kernelargs:           Kernel arguments (default: $DEFAULT_ISO_KERNEL_ARGS)
    --vmcpus:               No ov VM CPUs (default: $DEFAULT_VM_CPUS)
    --release:              LSB release (default: $DEFAULT_ISO_RELEASE)
    --bmcip:                BMC/iDRAC IP (default: $DEFAULT_BMC_IP)
    --installtarget:        Where the install mounts the target filesystem (default: $DEFAULT_ISO_TARGET_MOUNT)
    --installmount:         Where the install mounts the CD during install (default: $DEFAULT_ISO_INSTALL_MOUNT)
    --bootserverfile        Boot sever file (default: $DEFAULT_BOOT_SERVER_FILE_BASE)
    --nic|--vmnic:          Network device (default: $DEFAULT_ISO_NIC/$DEFAULT_VM_NIC)
    --isopackages:          List of packages to install (default: $DEFAULT_ISO_INSTALL_PACKAGES)
    --outputiso:            Output ISO file (default: $DEFAULT_OUTPUT_FILE_BASE)
    --password:             Password (default: $DEFAULT_ISO_PASSWORD)
    --chrootpackages:       List of packages to add to ISO (default: $DEFAULT_ISO_INSTALL_PACKAGES)
    --build:                Type of ISO to build (default: $DEFAULT_ISO_BUILD_TYPE)
    --arch:                 Architecture (default: $DEFAULT_ISO_ARCH)
    --realname:             Realname (default $DEFAULT_ISO_REALNAME)
    --diskwwn:              Disk WWN
    --diskserial:           Disk Serial
    --serialportspeed:      Serial Port Speed (default: $DEFAULT_ISO_SERIAL_PORT_SPEED0,$DEFAULT_ISO_SERIAL_PORT_SPEED1)
    --swapsize|--vmram:     Swap or VM memory size (default $DEFAULT_ISO_SWAP_SIZE/$DEFAULT_VM_RAM)
    --squashfsfile:         Squashfs file (default: $DEFAULT_ISO_SQUASHFS_FILE_BASE)
    --timezone:             Timezone (default: $DEFAULT_ISO_TIMEZONE)
    --serialportaddress:    Serial Port Address (default: $DEFAULT_ISO_SERIAL_PORT_ADDRESS0,$DEFAULT_ISO_SERIAL_PORT_ADDRESS1)
    --username:             Username (default: $DEFAULT_ISO_USERNAME)
    --postinstall:          Postinstall action (e.g. installpackages, upgrade, distupgrade, installdrivers, all, autoupgrades)
    --version               Display Script Version
    --serialport:           Serial Port (default: $DEFAULT_ISO_SERIAL_PORT0,$DEFAULT_ISO_SERIAL_PORT1)
    --workdir:              Work directory
    --preworkdir:           Docker work directory (used internally)
    --isovolid:             ISO Volume ID
    --grubtimeout:          Grub timeout (default: $DEFAULT_ISO_GRUB_TIMEOUT)
    --allowpassword         Allow password access via SSH (default: $DEFAULT_ISO_ALLOW_PASSWORD)
    --bmcpassword:          BMC/iDRAC password (default: $DEFAULT_BMC_PASSWORD)
    --options:              Options (e.g. nounmount, testmode, bios, uefi, verbose, interactive)
    --volumemanager:        Volume Managers (default: $DEFAULT_ISO_VOLMGRS)
    --zfsfilesystems:       ZFS filesystems (default: $DEFAULT_ZFS_FILESYSTEMS)
    --userdata:             Use a custom user-data file (default: generate automatically)
    --oeminstall:           OEM Install Type (default: $DEFAULT_ISO_OEM_INSTALL)
    --sourceid:             Source ID (default: $DEFAULT_ISO_SOURCE_ID) 
    --installmode:          Install Mode (default: $DEFAULT_ISO_INSTALL_MODE)
    --passwordalgorithm:    Password Algorithm (default: $DEFAULT_ISO_PASSWORD_ALGORITHM)
    --bootloader:           Boot Loader Location (default: $DEFAULT_ISO_BOOT_LOADER_LOCATION)
    --selinux:              SELinux Mode (default: $DEFAULT_ISO_SELINUX)
    --firewall:             Firewall (default: $DEFAULT_ISO_FIREWALL)
    --allow:                Allow Services (default: $DEFAULT_ISO_ALLOW_SERVICE)
    --onboot:               Enable Network on Boot (default: $DEFAULT_ISO_ONBOOT)
    --enableservice         Enable Service (default: $DEFAULT_ISO_ENABLE_SERVICE)
    --disableservice        Disable Service (default: $DEFAULT_ISO_DISABLE_SERVICE)
    --gecos                 GECOS Field Entry (default: $DEFAULT_ISO_DISABLE_SERVICE)
    --installsource         Install Source (default: $DEFAULT_ISO_INSTALL_SOURCE)
    --bootsize              Boot partition size (default: $DEFAULT_ISO_BOOT_SIZE)
    --rootsize              Root partition size (default: $DEFAULT_ISO_ROOT_SIZE)
    --compression           Compression algorithm (default: $DEFAULT_ISO_COMPRESSION)
    --installuser           Temporary install username for remote access during install (default: $DEFAULT_ISO_INSTALL_USERNAME)
    --installpassword       Temporary install password for remote access during install (default: $DEFAULT_ISO_INSTALL_PASSWORD)
    --pesize                PE size (default: $DEFAULT_ISO_PE_SIZE)
    --vgname                Volume Group Name (default: $DEFAULT_ISO_VG_NAME)
    --lvname                Volume Group Name (default: $DEFAULT_ISO_LV_NAME)
HELP
  exit
}

# Function: print_help
#
# Print help

print_help () {
  case "$1" in
    "cli")
      print_cli_help
      ;;
    "actions")
      print_actions
      exit
      ;;
    "options")
      print_options
      exit
      ;;
    "postinstall")
      print_postinstall
      exit
      ;;
    "examples")
      print_examples
      exit
      ;;
    *)
      print_cli_help
      ;;
  esac
}
