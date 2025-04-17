#!/usr/bin/env bash

# Name:         guige (Generic Ubuntu/Unix ISO Generation Engine)
# Version:      3.7.3
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

# shellcheck disable=SC1090
# shellcheck disable=SC2034
# shellcheck disable=SC2045
# shellcheck disable=SC2129

# Create arrays for options and actions

declare -A os
declare -A vm
declare -A new 
declare -A old
declare -A iso
declare -A temp
declare -A script
declare -A docker
declare -A options
declare -A current
declare -A defaults

script['args']="$*"
script['file']="$0"
script['file']=$( realpath "${script['file']}" )
script['name']="guige"
script['path']=$( pwd )
script['bin']=$( basename "$0" |sed "s/^\.\///g")
script['file']="${script['path']}/${script['bin']}"
script['version']=$( grep '^# Version' < "$0" | awk '{print $3}' )
os['name']=$( uname )
os['arch']=$( uname -m |sed "s/aarch64/arm64/g" |sed "s/x86_64/amd64/g")
os['user']=$( whoami )
os['group']=$( id -gn )
if [ -f "/usr/bin/lsb_release" ]; then
  os['distro']=$( lsb_release -is )
else
  os['distro']="${os['name']}"
fi

# Run shellcheck

check_shellcheck () {
  bin_test=$( command -v shellcheck | grep -c shellcheck )
  if [ ! "$bin_test" = "0" ]; then
    shellcheck "${script['file']}"
  fi
  if [ -d "${script['modules']}" ]; then
    for module in $( ls "${script['modules']}"/*.sh ); do
      if [[ "${script['args']}" =~ "verbose" ]]; then
        echo "Loading Module: ${module}"
      fi
      shellcheck "${module}"
    done
  fi
}

# Handle verbose and debug early so it's enabled early

if [[ "$*" =~ "verbose" ]]; then
  options['verbose']="true"
else
  options['verbose']="false"
fi

if [[ "$*" =~ "debug" ]]; then
  options['verbose']="true"
  set -x
  if [ ! -f "/.dockerenv" ]; then
    set -eu
  fi
fi

# Check if we are running inside docker

if [ -f /.dockerenv ]; then
  script['path']=$( dirname "$0" )
  script['modules']="${script['path']}/modules"
else
  script['modules']="${script['path']}/modules"
fi

# Load modules

if [ -d "${script['modules']}" ]; then
  for module in $( ls "${script['modules']}"/*.sh ); do
    if [[ "${script['args']}" =~ "verbose" ]]; then
      echo "Loading Module: ${module}"
    fi
    . "${module}"
  done
fi

set_defaults
set_default_osname
set_default_release
set_default_dirs
set_default_files
set_default_flags

# Function: Handle command line arguments

if [ "${script['args']}" = "" ]; then
  print_help
fi

# switchstart

while test $# -gt 0
do
  case "$1" in
    --action|--actions)
      # Action to perform
      iso['action']="$2"
      shift 2
      ;;
    --allowlist|--allow)
      # Allow/load additional kernel modules(s)
      iso['allowlist']="$2"
      shift 2
      ;;
    --allowpassword|--allow-password)
      # Allow password access via SSH
      iso['allowpassword']="true"
      shift
      ;;
    --allowservice|--allowservices|--service|--services)
      # Allow Services
      iso['allowservice']="$2"
      shift 2
      ;;
    --arch)
      # Architacture
      iso['arch']="$2"
      shift 2
      iso['arch']=$( echo "${iso['arch']}" |sed "s/aarch64/arm64/g" |sed "s/x86_64/amd64/g" |sed "s/x86/amd64/g" )
      ;;
    --autoinstalldir|--aidir)
      # Directory where autoinstall config files are stored on ISO
      iso['autoinstalldir']="$2"
      shift 2
      ;;
    --blocklist|--block)
      # Block kernel module(s)
      iso['blocklist']="$2"
      shift 2
      ;;
    --bmcip)
      # BMC/iDRAC IP
      iso['bmcip']="$2"
      shift 2
      ;;
    --bmcpassword|--bmcpass)
      # BMC/iDRAC password
      iso['bmcpassword']="$2"
      shift 2
      ;;
    --bmcusername|--bmcuser)
      # BMC/iDRAC User
      iso['bmcusername']="$2"
      shift 2
      ;;
    --disk|--bootdisk|--installdisk|--firstdisk)
      # Boot Disk devices
      iso['disk']="$2"
      shift 2
      ;;
    --bootloader)
      # Boot Loader Location
      iso['bootloader']="$2"
      shift 2
      ;;
    --bootserverfile)
      # Boot sever file
      iso['bootserverfile']="$2"
      options['bootserverfile']="true"
      shift 2
      ;;
    --bootserverip)
      # NFS/Bootserver IP
      iso['bootserverip']="$2"
      shift 2
      ;;
    --bootsize)
      # Boot partition size
      iso['bootsize']="$2"
      shift 2
      ;;
    --build|--buildtype)
      # Type of ISO to build
      iso['build']="$2"
      case "${iso['build']}" in
        "daily")
          options['daily']="true"
          ;;
      esac
      shift 2
      ;;
    --chrootpackages)
      # List of packages to add to ISO
      iso['chrootpackages']="$2"
      shift 2
      ;;
    --cidr)
      # CIDR
      iso['cidr']="$2"
      shift 2
      ;;
    --codename|--distro)
      # Linux release codename or distribution
      iso['codename']="$2"
      shift 2
      ;;
    --compression)
      # Compression algorithm
      iso['compression']="$2"
      options['compression']="true"
      shift 2
      ;;
    --country)
      # Country
      iso['country']="$2"
      shift 2
      ;;
    --debug)
      # Set debug flag (set -x)
      set -x
      shift
      ;;
    --delete)
      # Remove previously created files
      iso['delete']="$2"
      shift 2
      ;;
    --disableservice|--disableservices|--disable)
      # Disable service(s)
      iso['disableservice']="$2"
      shift 2
      ;;
    --diskfile)
      # Disk file
      iso['diskfile']="$2"
      shift 2
      ;;
    --diskserial)
      # Disk serial
      iso['diskserial']="$2"
      shift 2
      ;;
    --disksize)
      # Disk size
      iso['diskize']="$2"
      shift 2
      ;;
    --diskwwn)
      # Disk WWN
      iso['diskwwn']="$2"
      shift 2
      ;;
    --dns|--nameserver)
      # DNS server IP
      iso['dns']="$2"
      shift 2
      ;;
    --enableservice|--enableservices|--enable)
      # Enable service(s)
      iso['enableservice']="$2"
      shift 2
      ;;
    --fallback)
      # Installation fallback 
      iso['fallback']="$2"
      shift 2
      ;;
    --firewall)
      # Firewall
      iso['firewall']="$2"
      shift 2
      ;;
    --firstoption|--first-option)
      # First menu option (e.g. grub menu)
      iso['firstoption']="$2"
      shift 2
      ;;
    --gateway)
      # Gateway IP
      iso['gateway']="$2"
      shift 2
      options['dhcp']="false"
      ;;
    --gecos)
      # User GECOS field
      iso['gecos']="$2"
      shift 2
      ;;
    --groups)
      # Groups to add user to
      iso['groups']="$2"
      shift 2
      ;;
    --grubfile|--grub)
      # Import grub file
      options['grubfile']="true"
      iso['grubfile']="$2"
      shift 2
      ;;
    --grubmenu)
      # Import grub menu
      iso['grubmenu']="$2"
      shift 2
      ;;
    --grubtimeout|--grub-timeout)
      # Grub timeout
      iso['grubtimeout']="$2"
      shift 2
      ;;
    --help|-h)
      # Print help
      print_help "cli"
      ;;
    --hostname)
      # Hostname
      iso['hostname']="$2"
      shift 2
      ;;
    --inputci|--vmci)
      # Import Cloud Image
      iso['inputci']="$2"
      shift 2
      ;;
    --inputfile|--inputiso|--vmiso)
      # Import ISO
      iso['inputfile']="$2"
      shift 2
      ;;
    --installmode|--install-mode)
      # Install mode
      iso['installmode']="$2"
      shift 2
      ;;
    --installmount)
      # Where the install mounts the CD during install
      iso['installmount']="$2"
      shift 2
      ;;
    --installpassword|--install-password|--installpass|--install-pass)
      iso['installpassword']="$2"
      # Temporary install password for remote access during install
      shift 2
      ;;
    --installsource|--install-source)
      # Install source
      iso['installsource']="$2"
      shift 2
      ;;
    --targetmount|--installtarget)
      # Install target
      iso['targetmount']="$2"
      shift 2
      ;;
    --installusername|--installuser|--install-user)
      # Install user
      iso['installusername']="$2"
      shift 2
      ;;
    --ip)
      # IP address
      iso['ip']="$2"
      shift 2
      options['dhcp']="false"
      ;;
    --kernel|--isokernel)
      # Kernel to install
      iso['kernel']="$2"
      shift 2
      ;;
    --isokernelargs|--kernelargs)
      # Kernel arguments
      iso['kernelargs']="$2"
      shift 2
      ;;
    --isolinuxfile|--isolinux)
      # Import isolinux file
      options['isolinuxfile']="true"
      iso['isolinuxfile']="$2"
      shift 2
      ;;
    --packages|--isopackages)
      # Additional packages to install
      iso['packages']="$2"
      shift 2
      ;;
    --url|--isourl)
      # ISO URL
      iso['url']="$2"
      shift 2
      ;;
    --volid|--isovolid)
      # ISO Volume ID
      iso['volid']="$2"
      shift 2
      ;;
    --layout)
      # Keyboard layout
      iso['layout']=$2
      shift 2
      ;;
    --lcall)
      # LC_ALL
      iso['lcall']="$2"
      shift 2
      ;;
    --locale)
      # Local
      iso['locale']="$2"
      shift 2
      ;;
    --lvname)
      # Logical Volume Name
      iso['lvname']="$2"
      shift 2
      ;;
    --netmask)
      # Netmask
      iso['netmask']="$2"
      shift 2
      ;;
    --nic|--vmnic|--installnic|--bootnic|--firstnic)
      # NIC to use for installation
      iso['nic']="$2"
      shift 2
      ;;
    --oeminstall)
      # OEM Install
      iso['oeminstall']="$2"
      shift 2
      ;;
    --oldinputfile)
      # Old release ISO
      old['inputfile']="$2"
      shift 2
      ;;
    --oldisourl)
      # Old ISO URL
      old['url']="$2"
      shift 2
      ;;
    --oldrelease)
      # Old release
      old['release']="$2"
      shift 2
      ;;
    --onboot)
      # Enable network on boot
      iso['onboot']="$2"
      shift 2
      ;;
    --options|--option)
      # Options (e.g. verbose)
      iso['options']="$2";
      shift 2
      ;;
    --outputci)
      # Output CI file
      iso['outputci']="$2"
      shift 2
      ;;
    --outputfile|--outputiso)
      # Output ISO file
      iso['outputfile']="$2"
      shift 2
      ;;
    --password)
      # Password
      iso['password']="$2"
      shift 2
      ;;
    --passwordalgorithm|--password-algorithm|--passalgo|--algoritm)
      # Password Algorithm
      iso['passwordalgorithm']="$2"
      shift 2
      ;;
    --pesize)
      # PE size
      iso['pesize']="$2"
      shift 2
      ;;
    --postinstall)
      # Import post install script
      iso['postinstall']="$2"
      shift 2
      ;;
    --prefix)
      # Output file name prefix
      iso['prefix']="$2"
      shift 2
      ;;
    --preworkdir)
      # Docker work directory
      iso['preworkdir']="$2"
      shift 2
      ;;
    --pvname)
      # Physical Volume Name
      iso['pvname']="$2"
      shift 2
      ;;
    --ram|--vmram)
      # RAM size
      iso['ram']="$2"
      shift 2
      ;;
    --realname)
      # User real name field
      iso['realname']="$2"
      shift 2
      ;;
    --release)
      # OS release
      iso['release']="$2"
      shift 2
      get_release_info
      get_code_name
      get_build_type
      ;;
    --rootsize)
      # Root volume size
      iso['rootsize']="$2"
      shift 2
      ;;
    --search)
      # Search output for value
      iso['search']="$2"
      shift 2
      ;;
    --selinux)
      # SELinux Mode
      iso['selinux']="$2"
      shift 2
      ;;
    --serialport)
      # Serial port
      iso['serialport']="$2"
      shift 2
      ;;
    --serialportaddress)
      # Serial port address
      iso['serialportaddress']="$2"
      shift 2
      ;;
    --serialportspeed)
      # Serial port speed
      iso['serialportspeed']="$2"
      shift 2
      ;;
    --sourceid)
      # Source ID
      iso['sourceid']="$2"
      shift 2
      ;;
    --squashfsfile)
      # Squashfs file
      iso['squashfsfile']="$2"
      shift 2
      ;;
    --sshkey)
      # SSH key
      iso['sshkey']="$2"
      options['sshkey']="true"
      shift 2
      ;;
    --sshkeyfile)
      # SSH key file
      iso['sshkeyfile']="$2"
      options['sshkey']="true"
      shift 2
      ;;
    --suffix)
      # Output file name suffix
      iso['suffix']="$2"
      shift 2
      ;;
    --swap|--vmswap)
      # Swap device 
      iso['swap']="$2"
      shift 2
      ;;
    --swapsize|--vmswapsize)
      # Swap size
      iso['swapsize']="$2"
      shift 2
      ;;
    --timezone)
      # Timezone
      iso['timezone']="$2"
      shift 2
      ;;
    --updates)
      # Updates to install
      iso['updates']="$2"
      shift 2
      ;;
    --autoinstallfile|--userdata|--autoinstall|--kickstart)
      # Import autoinstall config file
      options['autoinstall']="true"
      iso['volumemanager']="custom"
      iso['autoinstallfile']="$2"
      shift 2
      ;;
    --username|--user)
      # Username
      iso['username']="$2"
      shift 2
      ;;
    --usage)
      # Usage information
      print_usage "$2"
      exit
      ;;
    --version|-V)
      # Display version
      echo "${script['version']}"
      shift
      exit
      ;;
    --vgname)
      # Volume Group Name
      iso['vgname']="$2"
      shift 2
      ;;
    --vmcpus|--cpus)
      # Number of CPUs
      iso['cpus']="$2"
      shift 2
      ;;
    --vmname|--name)
      # VM name
      iso['name']="$2"
      shift 2
      ;;
    --vmtype|--type)
      # VM type
      iso['type']="$2"
      shift 2
      ;;
    --volumemanager|--volumemanagers|--volmgr|--volmgrs)
      # Volumemanager(s)
      iso['volumemanager']="$2"
      shift 2
      ;;
    --workdir)
      # Work directory
      iso['workdir']="$2"
      shift 2
      ;;
    --zfsfilesystems|--zfs)
      # Additional ZFS filesystems
      options['zfsfilesystems']="true"
      iso['zfsfilesystems']="$2"
      shift 2
      ;;
    --zfsroot)
      # ZFS root name
      options['zfsroot']="$2"
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

# switchend

# Setup functions
set_default_osname
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
update_ci_url
handle_bios
handle_ubuntu_pro
copy_custom_user_data
get_iso_type

# Output variables

if [ "${options['printenv']}" = "true" ] || [ "${options['interactivemode']}" = "true" ]; then
  temp['verbose']="true"
fi

get_ssh_key
get_os_ip
iso['passwordcrypt']=$( get_password_crypt "${iso['password']}" )
if [ "${options['installuser']}" = "true" ]; then
  iso['installpasswordcrypt']=$( get_password_crypt "${iso['installpassword']}" )
fi
print_env

# If run in interactive mode ask for values for required parameters
# Set any unset values to defaults

if [ "${options['interactivemode']}" = "true" ]; then
  get_interactive_input
fi

# Do test outputs

if [ "${iso['action']}" = "test" ]; then
  check_workdir
  if [ "${options['kstest']}" = "true" ]; then
    prepare_kickstart_files
    exit
  fi
fi

# Handle specific functions

if [ "${options['listvms']}" = "true" ]; then
  list_vm
  exit
fi

if [ "${options['docker']}" = "true" ] || [ "${options['checkdocker']}" = "true" ]; then
  create_docker_iso
fi
if [ "${options['deletevm']}" = "true" ]; then
  delete_vm
  exit
fi
if [ "${options['createisovm']}" = "true" ]; then
  get_info_from_iso
  create_iso_vm
  exit
fi
if [ "${options['createcivm']}" = "true" ]; then
  create_ci_vm
  exit
fi
if [ "${options['checkracadm']}" = "true" ]; then
  check_racadm
  exit
fi
if [ "${options['executeracadm']}" = "true" ]; then
  check_racadm
  execute_racadm
  exit
fi
if [ "${options['checkworkdir']}" = "true" ]; then
  options['help']="false"
  check_workdir
  if [ "${options['oldinstaller']}" = "true" ]; then
    check_old_workdir
  fi
fi
if [ "${options['installrequiredpackages']}" = "true" ]; then
  options['help']="false"
  install_required_packages "${iso['requiredpackages']}"
fi
if [ "${options['createexport']}" = "true" ]; then
  create_export
fi
if [ "${options['createansible']}" = "true" ]; then
  check_ansible
  create_ansible
fi
if [ "${options['installserver']}" = "true" ]; then
  install_server
fi
if [ "${options['getiso']}" = "true" ]; then
  options['help']="false"
  get_base_iso
  if [ "${iso['action']}" = "getiso" ]; then
    exit
  fi
fi
if [ "${options['fulliso']}" = "true" ]; then
  options['help']="false"
  unmount_iso
  unmount_squashfs
  mount_iso
  copy_iso
  copy_squashfs
  create_chroot_script
  execute_chroot_script
  if [ "${options['updatesquashfs']}" = "true" ]; then
    update_iso_squashfs
  fi
  prepare_iso
  create_iso
  if ! [ "${options['nounmount']}" = "true" ]; then
    unmount_iso
    unmount_squashfs
  fi
else
  if [ "${options['runchrootscript']}" = "true" ]; then
    options['help']="false"
    mount_iso
    execute_chroot_script
  fi
  if [ "${options['createautoinstall']}" = "true" ]; then
    options['help']="false"
    prepare_iso
  fi
  if [ "${options['justiso']}" = "true" ]; then
    options['help']="false"
    prepare_iso
    create_iso
  fi
  if [ "${options['unmount']}" = "true" ]; then
    options['help']="false"
    unmount_iso
    unmount_squashfs
  fi
fi
if [ "${options['listisos']}" = "true" ]; then
  list_isos
  exit
fi

if [ "${options['help']}" = "true" ]; then
  print_help
fi
