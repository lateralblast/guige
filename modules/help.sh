#!/usr/bin/env bash

# shellcheck disable=SC2129
# shellcheck disable=SC2034

# Function: print_cli_help
#
# Print script help information

print_cli_help () {
  cat <<-HELP

  Usage: ${0##*/} [OPTIONS...]

  --action                Action to perform (e.g. createiso, justiso, runchrootscript, checkdocker, installrequired)
  --allow                 Load additional kernel modules(s)
  --allowpassword         Allow password access via SSH (default: $DEFAULT_ISO_ALLOW_PASSWORD)
  --allowservice          Allow Services (default: $DEFAULT_ISO_ALLOW_SERVICE)
  --arch                  Architecture (default: $DEFAULT_ISO_ARCH)
  --autoinstalldir        Directory where autoinstall config files are stored on ISO
  --block                 Block kernel module(s)
  --bmcip                 BMC/iDRAC IP (default: $DEFAULT_BMC_IP)
  --bmcpassword           BMC/iDRAC password (default: $DEFAULT_BMC_PASSWORD)
  --bmcusername           BMC/iDRAC User (default: $DEFAULT_BMC_USERNAME)
  --bootdisk              Boot Disk devices (default: $DEFAULT_ISO_DISK)
  --bootloader            Boot Loader Location (default: $DEFAULT_ISO_BOOT_LOADER_LOCATION)
  --bootserverfile        Boot sever file (default: $DEFAULT_BOOT_SERVER_FILE_BASE)
  --bootserverip          NFS/Bootserver IP
  --bootsize              Boot partition size (default: $DEFAULT_ISO_BOOT_SIZE)
  --build                 Type of ISO to build (default: $DEFAULT_ISO_BUILD_TYPE)
  --chrootpackages        List of packages to add to ISO (default: $DEFAULT_ISO_INSTALL_PACKAGES)
  --cidr                  CIDR (default: $DEFAULT_ISO_CIDR)
  --codename|--disto      Linux release codename or distribution
  --compression           Compression algorithm (default: $DEFAULT_ISO_COMPRESSION)
  --country               Country (used for sources.list mirror - default: $DEFAULT_ISO_COUNTRY)
  --debug                 Set debug flag (set -x)
  --delete                Remove previously created files (default: $FORCE_MODE)
  --disableservice        Disable Service (default: $DEFAULT_ISO_DISABLE_SERVICE)
  --diskserial            Disk Serial
  --diskwwn               Disk WWN
  --dns                   DNS Server (ddefault: $DEFAULT_ISO_DNS)
  --enableservice         Enable Service (default: $DEFAULT_ISO_ENABLE_SERVICE)
  --fallback              Installation fallback (default: $DEFAULT_ISO_FALLBACK)
  --firewall              Firewall (default: $DEFAULT_ISO_FIREWALL)
  --firstoption           First menu option (default: $DEFAULT_ISO_OPTION)
  --gateway               Gateway (default $DEFAULT_ISO_GATEWAY)
  --gecos                 GECOS Field Entry (default: $DEFAULT_ISO_DISABLE_SERVICE)
  --groupts               Groups (default: $DEFAULT_ISO_GROUPS)
  --grubfile              GRUB file
  --grubmenu              Set default grub menu (default: $DEFAULT_ISO_GRUB_MENU)
  --grubtimeout           Grub timeout (default: $DEFAULT_ISO_GRUB_TIMEOUT)
  --help                  Help/Usage Information
  --hostname              Hostname (default: $DEFAULT_ISO_HOSTNAME)
  --inputiso|--vmiso      Input/base ISO file
  --installmode           Install Mode (default: $DEFAULT_ISO_INSTALL_MODE)
  --installmount          Where the install mounts the CD during install (default: $DEFAULT_ISO_INSTALL_MOUNT)
  --installpassword       Temporary install password for remote access during install (default: $DEFAULT_ISO_INSTALL_PASSWORD)
  --installsource         Install Source (default: $DEFAULT_ISO_INSTALL_SOURCE)
  --installtarget         Where the install mounts the target filesystem (default: $DEFAULT_ISO_TARGET_MOUNT)
  --installuser           Temporary install username for remote access during install (default: $DEFAULT_ISO_INSTALL_USERNAME)
  --ip                    IP Address (default: $DEFAULT_ISO_IP)
  --isolinux              External isolinux file to import
  --isopackages           List of packages to install (default: $DEFAULT_ISO_INSTALL_PACKAGES)
  --isourl                Specify ISO URL
  --isovolid              ISO Volume ID
  --kernel                Kernel (default: $DEFAULT_ISO_KERNEL)
  --kernelargs            Kernel arguments (default: $DEFAULT_ISO_KERNEL_ARGS)
  --layout|--vmsize       Layout or VM disk size (default: $DEFAULT_ISO_LAYOUT/$DEFAULT_VM_SIZE)
  --lcall                 LC_ALL (default: $DEFAULT_ISO_LC_ALL)
  --locale                LANGUAGE (default: $DEFAULT_ISO_LOCALE)
  --lvname                Volume Group Name (default: $DEFAULT_ISO_LV_NAME)
  --nic|--vmnic           Network device (default: $DEFAULT_ISO_NIC/$DEFAULT_VM_NIC)
  --oeminstall            OEM Install Type (default: $DEFAULT_ISO_OEM_INSTALL)
  --oldinputfile          Old release ISO (used with --oldrelease)
  --oldisourl             Old release ISO URL (used with --oldrelease)
  --oldrelease            Old release (used for copying file from an older release ISO)
  --onboot                Enable Network on Boot (default: $DEFAULT_ISO_ONBOOT)
  --options               Options (e.g. nounmount, testmode, bios, uefi, verbose, interactive)
  --outputiso             Output ISO file (default: $DEFAULT_OUTPUT_FILE_BASE)
  --password              Password (default: $DEFAULT_ISO_PASSWORD)
  --passwordalgorithm     Password Algorithm (default: $DEFAULT_ISO_PASSWORD_ALGORITHM)
  --pesize                PE size (default: $DEFAULT_ISO_PE_SIZE)
  --postinstall           Postinstall action (e.g. installpackages, upgrade, distupgrade, installdrivers, all, autoupgrades)
  --prefix                Prefix to add to ISO name
  --preworkdir            Docker work directory (used internally)
  --realname              Realname (default $DEFAULT_ISO_REALNAME)
  --release               LSB release (default: $DEFAULT_ISO_RELEASE)
  --rootsize              Root partition size (default: $DEFAULT_ISO_ROOT_SIZE)
  --search                Search output for value (eg --action listallisos --search efi)
  --selinux               SELinux Mode (default: $DEFAULT_ISO_SELINUX)
  --serialport            Serial Port (default: $DEFAULT_ISO_SERIAL_PORT0,$DEFAULT_ISO_SERIAL_PORT1)
  --serialportaddress     Serial Port Address (default: $DEFAULT_ISO_SERIAL_PORT_ADDRESS0,$DEFAULT_ISO_SERIAL_PORT_ADDRESS1)
  --serialportspeed       Serial Port Speed (default: $DEFAULT_ISO_SERIAL_PORT_SPEED0,$DEFAULT_ISO_SERIAL_PORT_SPEED1)
  --sourceid              Source ID (default: $DEFAULT_ISO_SOURCE_ID)
  --squashfsfile          Squashfs file (default: $DEFAULT_ISO_SQUASHFS_FILE_BASE)
  --sshkeyfile            SSH key file to use as SSH key (default: $MASKED_DEFAULT_ISO_SSH_KEY_FILE)
  --suffix                Suffix to add to ISO name
  --swapsize|--vmram      Swap or VM memory size (default $DEFAULT_ISO_SWAP_SIZE/$DEFAULT_VM_RAM)
  --timezone              Timezone (default: $DEFAULT_ISO_TIMEZONE)
  --updates               Updates to install (default: $DEFAULT_ISO_UPDATES)
  --userdata              Use a custom user-data file (default: generate automatically)
  --username              Username (default: $DEFAULT_ISO_USERNAME)
  --version               Display Script Version
  --vgname                Volume Group Name (default: $DEFAULT_ISO_VG_NAME)
  --vmcpus                No ov VM CPUs (default: $DEFAULT_VM_CPUS)
  --vmname                Set VM name (default: $DEFAULT_VM_NAME)
  --vmtype                VM type (default: $DEFAULT_VM_TYPE)
  --volumemanager         Volume Managers (default: $DEFAULT_ISO_VOLMGRS)
  --workdir               Work directory (default: $DEFAULT_WORK_DIR)
  --zfsfilesystems        ZFS filesystems (default: $DEFAULT_ZFS_FILESYSTEMS)
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
