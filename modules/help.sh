#!/usr/bin/env bash

# shellcheck disable=SC2129
# shellcheck disable=SC2034

# Function: print_cli_help
#
# Print script help information

print_cli_help () {
  cat <<-HELP

  Usage: ${0##*/} [OPTIONS...]

  --action(s)             Action to perform (e.g. createiso, justiso, runchrootscript, checkdocker, installrequired)
  --allow                 Load additional kernel modules(s)
  --allowpassword         Allow password access via SSH (default: $DEFAULT_ISO_ALLOWPASSWORD)
  --allowservice          Allow Services (default: $DEFAULT_ISO_ALLOWSERVICE)
  --arch                  Architecture (default: $DEFAULT_ISO_ARCH)
  --autoinstalldir        Directory where autoinstall config files are stored on ISO
  --block                 Block kernel module(s)
  --bmcip                 BMC/iDRAC IP (default: $DEFAULT_ISO_BMCIP)
  --bmcpassword           BMC/iDRAC password (default: $DEFAULT_ISO_BMCPASSWORD)
  --bmcusername           BMC/iDRAC User (default: $DEFAULT_ISO_BMCUSERNAME)
  --bootdisk              Boot Disk devices (default: $DEFAULT_ISO_DISK)
  --bootloader            Boot Loader Location (default: $DEFAULT_ISO_BOOTLOADER)
  --bootserverfile        Boot sever file (default: $DEFAULT_ISO_BOOTSERVERFILE_BASE)
  --bootserverip          NFS/Bootserver IP
  --bootsize              Boot partition size (default: $DEFAULT_ISO_BOOTSIZE)
  --build                 Type of ISO to build (default: $DEFAULT_ISO_BUILDTYPE)
  --chrootpackages        List of packages to add to ISO (default: $DEFAULT_ISO_PACKAGES)
  --cidr                  CIDR (default: $DEFAULT_ISO_CIDR)
  --codename|--disto      Linux release codename or distribution
  --compression           Compression algorithm (default: $DEFAULT_ISO_COMPRESSION)
  --country               Country (used for sources.list mirror - default: $DEFAULT_ISO_COUNTRY)
  --debug                 Set debug flag (set -x)
  --delete                Remove previously created files (default: $DO_ISO_FORCEMODE)
  --disableservice        Disable Service (default: $DEFAULT_ISO_DISABLESERVICE)
  --diskserial            Disk Serial
  --diskwwn               Disk WWN
  --dns                   DNS Server (ddefault: $DEFAULT_ISO_DNS)
  --enableservice         Enable Service (default: $DEFAULT_ISO_ENABLESERVICE)
  --fallback              Installation fallback (default: $DEFAULT_ISO_FALLBACK)
  --firewall              Firewall (default: $DEFAULT_ISO_FIREWALL)
  --firstoption           First menu option (default: $DEFAULT_ISO_OPTION)
  --gateway               Gateway (default $DEFAULT_ISO_GATEWAY)
  --gecos                 GECOS Field Entry (default: $DEFAULT_ISO_DISABLESERVICE)
  --groupts               Groups (default: $DEFAULT_ISO_GROUPS)
  --grubfile              GRUB file
  --grubmenu              Set default grub menu (default: $DEFAULT_ISO_GRUBMENU)
  --grubtimeout           Grub timeout (default: $DEFAULT_ISO_GRUBTIMEOUT)
  --help                  Help/Usage Information
  --hostname              Hostname (default: $DEFAULT_ISO_HOSTNAME)
  --inputiso|--vmiso      Input/base ISO file
  --inputci|--vmci        Input/base Cloud Image file
  --installmode           Install Mode (default: $DEFAULT_ISO_INSTALLMODE)
  --installmount          Where the install mounts the CD during install (default: $DEFAULT_ISO_INSTALLMOUNT)
  --installpassword       Temporary install password for remote access during install (default: $DEFAULT_ISO_INSTALLPASSWORD)
  --installsource         Install Source (default: $DEFAULT_ISO_INSTALLSOURCE)
  --installtarget         Where the install mounts the target filesystem (default: $DEFAULT_ISO_TARGETMOUNT)
  --installuser           Temporary install username for remote access during install (default: $DEFAULT_ISO_INSTALLUSERNAME)
  --ip                    IP Address (default: $DEFAULT_ISO_IP)
  --isolinux              External isolinux file to import
  --isopackages           List of packages to install (default: $DEFAULT_ISO_PACKAGES)
  --isourl                Specify ISO URL
  --isovolid              ISO Volume ID
  --kernel                Kernel (default: $DEFAULT_ISO_KERNEL)
  --kernelargs            Kernel arguments (default: $DEFAULT_ISO_KERNELARGS)
  --layout|--vmsize       Layout or VM disk size (default: $DEFAULT_ISO_LAYOUT/$DEFAULT_VM_SIZE)
  --lcall                 LC_ALL (default: $DEFAULT_ISO_LCALL)
  --locale                LANGUAGE (default: $DEFAULT_ISO_LOCALE)
  --lvname                LVM Logical Volume Name (default: $DEFAULT_ISO_LVNAME)
  --netmask               Netmask (default: $DEFAULT_ISO_NETMASK)
  --nic|--vmnic           Network device (default: $DEFAULT_ISO_NIC/$DEFAULT_VM_NIC)
  --oeminstall            OEM Install Type (default: $DEFAULT_ISO_OEMINSTALL)
  --oldinputfile          Old release ISO (used with --oldrelease)
  --oldisourl             Old release ISO URL (used with --oldrelease)
  --oldrelease            Old release (used for copying file from an older release ISO)
  --onboot                Enable Network on Boot (default: $DEFAULT_ISO_ONBOOT)
  --options               Options (e.g. nounmount, testmode, bios, uefi, verbose, interactive)
  --outputci              Output Cloud Image file (default: $DEFAULT_ISO_OUTPUTCI_BASE)
  --outputiso             Output ISO file (default: $DEFAULT_ISO_OUTPUTFILE_BASE)
  --password              Password (default: $DEFAULT_ISO_PASSWORD)
  --passwordalgorithm     Password Algorithm (default: $DEFAULT_ISO_PASSWORDALGORITHM)
  --pesize                PE size (default: $DEFAULT_ISO_PESIZE)
  --postinstall           Postinstall action (e.g. installpackages, upgrade, distupgrade, installdrivers, all, autoupgrades)
  --prefix                Prefix to add to ISO name
  --preworkdir            Docker work directory (used internally)
  --pvname                LVM Pysical Volume Name (default: $DEFAULT_ISO_LVNAME)
  --realname              Realname (default $DEFAULT_ISO_REALNAME)
  --release               LSB release (default: $DEFAULT_ISO_RELEASE)
  --rootsize              Root partition size (default: $DEFAULT_ISO_ROOTSIZE)
  --search                Search output for value (eg --action listallisos --search efi)
  --selinux               SELinux Mode (default: $DEFAULT_ISO_SELINUX)
  --serialport            Serial Port (default: $DEFAULT_ISO_SERIALPORT0,$DEFAULT_ISO_SERIAL_PORT1)
  --serialportaddress     Serial Port Address (default: $DEFAULT_ISO_SERIALPORTADDRESS0,$DEFAULT_ISO_SERIAL_PORT_ADDRESS1)
  --serialportspeed       Serial Port Speed (default: $DEFAULT_ISO_SERIALPORTSPEED0,$DEFAULT_ISO_SERIAL_PORT_SPEED1)
  --sourceid              Source ID (default: $DEFAULT_ISO_SOURCEID)
  --squashfsfile          Squashfs file (default: $DEFAULT_ISO_SQUASHFSFILE_BASE)
  --sshkeyfile            SSH key file to use as SSH key (default: $MASKED_DEFAULT_ISO_SSHKEYFILE)
  --suffix                Suffix to add to ISO name
  --swapsize|--vmram      Swap or VM memory size (default $DEFAULT_ISO_SWAPSIZE/$DEFAULT_VM_RAM)
  --timezone              Timezone (default: $DEFAULT_ISO_TIMEZONE)
  --updates               Updates to install (default: $DEFAULT_ISO_UPDATES)
  --userdata              Use a custom user-data file (default: generate automatically)
  --username              Username (default: $DEFAULT_ISO_USERNAME)
  --version               Display Script Version
  --vgname                LVM Volume Group Name (default: $DEFAULT_ISO_VGNAME)
  --vmcpus                No ov VM CPUs (default: $DEFAULT_VM_CPUS)
  --vmname                Set VM name (default: $DEFAULT_VM_NAME)
  --vmtype                VM type (default: $DEFAULT_VM_TYPE)
  --volumemanager         Volume Managers (default: $DEFAULT_ISO_VOLMGRS)
  --workdir               Work directory (default: $DEFAULT_ISO_WORKDIR)
  --zfsfilesystems        ZFS filesystems (default: $DEFAULT_ISO_ZFSFILESYSTEMS)
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
