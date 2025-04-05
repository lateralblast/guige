#!/usr/bin/env bash

# shellcheck disable=SC2034
# shellcheck disable=SC2129
# shellcheck disable=SC2154

# Function: print_cli_help
#
# Print script help information

print_cli_help () {
  cat <<-help

  Usage: ${0##*/} [OPTIONS...]

  --action(s)             Action to perform (e.g. createiso, justiso, runchrootscript, checkdocker, installrequired)
  --allow                 Load additional kernel modules(s)
  --allowpassword         Allow password access via SSH (default: ${defaults['allowpassword']})
  --allowservice          Allow Services (default: ${defaults['allowservice']})
  --arch                  Architecture (default: ${defaults['arch']})
  --autoinstalldir        Directory where autoinstall config files are stored on ISO
  --block                 Block kernel module(s)
  --bmcip                 BMC/iDRAC IP (default: ${defaults['bmcip']})
  --bmcpassword           BMC/iDRAC password (default: ${defaults['bmcpassword']})
  --bmcusername           BMC/iDRAC User (default: ${defaults['bmcusername']})
  --bootdisk              Boot Disk devices (default: ${defaults['disk']})
  --bootloader            Boot Loader Location (default: ${defaults['bootloader']})
  --bootserverfile        Boot sever file (default: ${defaults['bootserverfile']}_BASE)
  --bootserverip          NFS/Bootserver IP
  --bootsize              Boot partition size (default: ${defaults['bootsize']})
  --build                 Type of ISO to build (default: ${defaults['build']})
  --chrootpackages        List of packages to add to ISO (default: ${defaults['packages']})
  --cidr                  CIDR (default: ${defaults['cidr']})
  --codename|--disto      Linux release codename or distribution
  --compression           Compression algorithm (default: ${defaults['compression']})
  --country               Country (used for sources.list mirror - default: ${defaults['country']})
  --debug                 Set debug flag (set -x)
  --delete                Remove previously created files (default: ${options['force']})
  --disableservice        Disable Service (default: ${defaults['disableservice']})
  --diskserial            Disk Serial
  --diskwwn               Disk WWN
  --dns                   DNS Server (ddefault: ${defaults['dns']})
  --enableservice         Enable Service (default: ${defaults['enableservice']})
  --fallback              Installation fallback (default: ${defaults['fallback']})
  --firewall              Firewall (default: ${defaults['firewall']})
  --firstoption           First menu option (default: ${defaults['firstoption']})
  --gateway               Gateway (default ${defaults['gateway']})
  --gecos                 GECOS Field Entry (default: ${defaults['disableservice']})
  --groupts               Groups (default: ${defaults['groups']})
  --grubfile              GRUB file
  --grubmenu              Set default grub menu (default: ${defaults['grubmenu']})
  --grubtimeout           Grub timeout (default: ${defaults['grubtimeout']})
  --help                  Help/Usage Information
  --hostname              Hostname (default: ${defaults['hostname']})
  --inputiso|--vmiso      Input/base ISO file
  --inputci|--vmci        Input/base Cloud Image file
  --installmode           Install Mode (default: ${defaults['installmode']})
  --installmount          Where the install mounts the CD during install (default: ${defaults['installmount']})
  --installpassword       Temporary install password for remote access during install (default: ${defaults['installpassword']})
  --installsource         Install Source (default: ${defaults['installsource']})
  --installtarget         Where the install mounts the target filesystem (default: ${defaults['targetmount']})
  --installuser           Temporary install username for remote access during install (default: ${defaults['installusername']})
  --ip                    IP Address (default: ${defaults['ip']})
  --isolinux              External isolinux file to import
  --isopackages           List of packages to install (default: ${defaults['packages']})
  --isourl                Specify ISO URL
  --isovolid              ISO Volume ID
  --kernel                Kernel (default: ${defaults['kernel']})
  --kernelargs            Kernel arguments (default: ${defaults['kernel']}ARGS)
  --layout|--vmsize       Layout or VM disk size (default: ${defaults['layout']}/${defaults['vmsize']})
  --lcall                 LC_ALL (default: ${defaults['lcall']})
  --locale                LANGUAGE (default: ${defaults['locale']})
  --lvname                LVM Logical Volume Name (default: ${defaults['lvname']})
  --netmask               Netmask (default: ${defaults['netmask']})
  --nic|--vmnic           Network device (default: ${defaults['nic']}/${defaults['vmnic']})
  --oeminstall            OEM Install Type (default: ${defaults['oeminstall']})
  --oldinputfile          Old release ISO (used with --oldrelease)
  --oldisourl             Old release ISO URL (used with --oldrelease)
  --oldrelease            Old release (used for copying file from an older release ISO)
  --onboot                Enable Network on Boot (default: ${defaults['onboot']})
  --options               Options (e.g. nounmount, testmode, bios, uefi, verbose, interactive)
  --outputci              Output Cloud Image file (default: ${defaults['outputcibase']})
  --outputiso             Output ISO file (default: ${defaults['outputfilebase']})
  --password              Password (default: ${defaults['password']})
  --passwordalgorithm     Password Algorithm (default: ${defaults['passwordalgorithm']})
  --pesize                PE size (default: ${defaults['pesize']})
  --postinstall           Postinstall action (e.g. installpackages, upgrade, distupgrade, installdrivers, all, autoupgrades)
  --prefix                Prefix to add to ISO name
  --preworkdir            Docker work directory (used internally)
  --pvname                LVM Pysical Volume Name (default: ${defaults['lvname']})
  --realname              Realname (default ${defaults['realname']})
  --release               LSB release (default: ${defaults['release']})
  --rootsize              Root partition size (default: ${defaults['rootsize']})
  --search                Search output for value (eg --action listallisos --search efi)
  --selinux               SELinux Mode (default: ${defaults['selinux']})
  --serialport            Serial Port (default: ${defaults['serialporta']},${defaults['serialportb']})
  --serialportaddress     Serial Port Address (default: ${defaults['serialportaddressa']},${defaults['serialaddressb']})
  --serialportspeed       Serial Port Speed (default: ${defaults['serialportspeeda']},${defaults['serialportspeedb']})
  --sourceid              Source ID (default: ${defaults['sourceid']})
  --squashfsfile          Squashfs file (default: ${defaults['squashfsfile']}_BASE)
  --sshkeyfile            SSH key file to use as SSH key (default: ${defaults['maskedsshkeyfile']})
  --suffix                Suffix to add to ISO name
  --swapsize|--vmram      Swap or VM memory size (default ${defaults['swapsize']}/${defaults['vmram']})
  --timezone              Timezone (default: ${defaults['timezone']})
  --updates               Updates to install (default: ${defaults['updates']})
  --userdata              Use a custom user-data file (default: generate automatically)
  --username              Username (default: ${defaults['username']})
  --version               Display Script Version
  --vgname                LVM Volume Group Name (default: ${defaults['vgname']})
  --vmcpus                No ov VM CPUs (default: ${defaults['vmcpus']})
  --vmname                Set VM name (default: ${defaults['vmname']})
  --vmtype                VM type (default: ${defaults['vmtype']})
  --volumemanager         Volume Managers (default: ${defaults['volumemanager']})
  --workdir               Work directory (default: ${defaults['workdir']})
  --zfsfilesystems        ZFS filesystems (default: ${defaults['zfs_filesystems']})
help
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
