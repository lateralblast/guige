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
    -H|--hostname             Hostname (default: $DEFAULT_ISO_HOSTNAME)
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
      |--userdata:            Use a custom user-data file (default: generate automatically)
      |--oeminstall:          OEM Install Type (default $DEFAULT_ISO_OEM_INSTALL)
      |--sourceid:            Source ID ($DEFAULT_ISO_SOURCE_ID) 
      |--installmode:         Install Mode ($DEFAULT_ISO_INSTALL_MODE)
      |--passwordalgorithm:   Password Algorithm ($DEFAULT_ISO_PASSWORD_ALGORITHM)
      |--bootloader:          Boot Loader Location ($DEFAULT_ISO_BOOT_LOADER_LOCATION)
      |--selinux:             SELinux Mode ($DEFAULT_ISO_SELINUX)
      |--firewall:            Firewall ($DEFAULT_ISO_FIREWALL)
      |--allow:               Allow Services ($DEFAULT_ISO_ALLOW_SERVICE)
      |--onboot:              Enable Network on Boot ($DEFAULT_ISO_ONBOOT)
      |--enableservice        Enable Service ($DEFAULT_ISO_ENABLE_SERVICE)
      |--disableservice       Disable Service ($DEFAULT_ISO_DISABLE_SERVICE)
      |--gecos                GECOS Field Entry ($DEFAULT_ISO_DISABLE_SERVICE)
      |--installsource        Install Source ($DEFAULT_ISO_INSTALL_SOURCE)
HELP
  exit
}
