#!/usr/bin/env bash

# Name:         guige (Generic Ubuntu/Unix ISO Generation Engine)
# Version:      4.6.3
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

# Check bash version

[[ "${BASH_VERSINFO[0]}" -lt 4 ]] && echo "Requires bash version >=4" >&2 && exit 1

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

declare -a switches
declare -a actions_list
declare -a options_list

script['args']="$*"
script['file']="$0"
script['file']=$( realpath "${script['file']}" )
script['name']="guige"
script['path']=$( pwd )
script['bin']=$( basename "$0" |sed "s/^\.\///g")
script['dir']=$( dirname "$0" )
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

regex='--version$|--help|-V$|-h$|--usage'
if [[ ! "${script['args']}" =~ $regex ]]; then
  set_defaults
  set_default_osname
  set_default_release
  set_default_dirs
  set_default_files
fi

# Function: do_exit
#
# Selective exit (don't exit when we're running in dryrun mode)

do_exit () {
  if [ "${options['dryrun']}" = "false" ]; then
    exit
  fi
}

# Function: Handle command line arguments

if [ "${script['args']}" = "" ]; then
  print_help
fi

while test $# -gt 0
do
  case "$1" in
    --action*)
      # Action to perform
      check_value "$1" "$2"
      actions_list+=("$2")
      shift 2
      ;;
    --allowpassword)
      # Allow password access via SSH
      iso['allowpassword']="true"
      shift
      ;;
    --allowservice)
      # Allow Services
      check_value "$1" "$2"
      iso['allowservice']="$2"
      shift 2
      ;;
    --arch)
      # Architacture
      check_value "$1" "$2"
      iso['arch']="$2"
      shift 2
      iso['arch']=$( echo "${iso['arch']}" |sed "s/aarch64/arm64/g" |sed "s/x86_64/amd64/g" |sed "s/x86/amd64/g" )
      ;;
    --autoinstalldir)
      # Directory where autoinstall config files are stored on ISO
      check_value "$1" "$2"
      iso['autoinstalldir']="$2"
      shift 2
      ;;
    --bios)
      # BIOS boot type
      options_list+=(bios)
      shift
      ;;
    --blacklist)
      # Block kernel module(s)
      check_value "$1" "$2"
      iso['blacklist']="$2"
      shift 2
      ;;
    --bmcip|--idracip)
      # BMC/iDRAC IP
      check_value "$1" "$2"
      iso['bmcip']="$2"
      shift 2
      ;;
    --bmcpassword|--idracpassword)
      # BMC/iDRAC password
      check_value "$1" "$2"
      iso['bmcpassword']="$2"
      shift 2
      ;;
    --bmcusername|--idracusername)
      # BMC/iDRAC User
      check_value "$1" "$2"
      iso['bmcusername']="$2"
      shift 2
      ;;
    --bootloader)
      # Boot Loader Location
      check_value "$1" "$2"
      iso['bootloader']="$2"
      shift 2
      ;;
    --bootserverfile)
      # Boot sever file
      check_value "$1" "$2"
      iso['bootserverfile']="$2"
      options['bootserverfile']="true"
      shift 2
      ;;
    --bootserverip)
      # Bootserver IP
      check_value "$1" "$2"
      iso['bootserverip']="$2"
      shift 2
      ;;
    --bootserverproto*)
      # Bootserver Protocol 
      check_value "$1" "$2"
      iso['bootserverprotocol']="$2"
      shift 2
      ;;
    --bootsize)
      # Boot partition size
      check_value "$1" "$2"
      iso['bootsize']="$2"
      shift 2
      ;;
    --boottype)
      # Boot type
      check_value "$1" "$2"
      iso['boottype']="$2"
      shift 2
      ;;
    --build)
      # Type of ISO to build
      check_value "$1" "$2"
      iso['build']="$2"
      case "${iso['build']}" in
        "daily")
          options['daily']="true"
          ;;
      esac
      shift 2
      ;;
    --builddockerconfig)
      # Build Docker config
      actions_list+=(builddockerconfig)
      shift
      ;;
    --bridge)
      # Bridge name
      check_value "$1" "$2"
      iso['bridge']="$2"
      options['bridge']="true"
      shift 2
      ;;
    --bridges)
      # Bridge names
      check_value "$1" "$2"
      iso['bridges']="$2"
      options['bridge']="true"
      shift 2
      ;;
    --checkdocker)
      # Check Docker
      actions_list+=(checkdocker)
      shift
      ;;
    --checkracadm)
      # Check RACadm
      actions_list+=(checkracadm)
      shift
      ;;
    --checkshellcheck)
      # Shellcheck script
      actions_list+=(checkshellcheck)
      shift
      ;;
    --checkworkdir)
      # Check work directories
      actions_list+=(checkworkdir)
      shift
      ;;
    --chrootpackages)
      # List of packages to add to ISO
      check_value "$1" "$2"
      iso['chrootpackages']="$2"
      shift 2
      ;;
    --cidr)
      # CIDR
      check_value "$1" "$2"
      iso['cidr']="$2"
      shift 2
      ;;
    --cidrs)
      # CIDRs
      check_value "$1" "$2"
      iso['cidrs']="$2"
      shift 2
      ;;
    --codename)
      # Release codename
      check_value "$1" "$2"
      iso['codename']="$2"
      shift 2
      ;;
    --compression)
      # Compression algorithm
      check_value "$1" "$2"
      iso['compression']="$2"
      options['compression']="true"
      shift 2
      ;;
    --confdef)
      # Force confdef
      options_list+=(confdef)
      shift
      ;;
    --confnew)
      # Force confnew
      options_list+=(confnew)
      shift
      ;;
    --country)
      # Country
      check_value "$1" "$2"
      iso['country']="$2"
      shift 2
      ;;
    --cpus)
      # Number of CPUs
      check_value "$1" "$2"
      iso['cpus']="$2"
      shift 2
      ;;
    --createansible)
      # Create ansible
      actions_list+=(createansible)
      shift
      ;;
    --createautoinstall)
      # Create autoinstall
      actions_list+=(createautoinstall)
      shift
      ;;
    --createcivm)
      # Create cloud-init based VM
      actions_list+=(createcivm)
      shift
      ;;
    --createdockeriso)
      # Create ISO using docker
      actions_list+=(createdockeriso)
      shift
      ;;
    --createdockerisoandsquashfs)
      # Create ISO and update squashfs using docker
      actions_list+=(createdockerisoandsquashfs)
      shift
      ;;
    --createexport)
      # Create export
      actions_list+=(createexport)
      shift
      ;;
    --createiso|--fullsiso)
      # Create ISO
      actions_list+=(createiso)
      shift
      ;;
    --createisoandsquashfs)
      # Create ISO and update squashfs
      actions_list+=(createisoandsquashfs)
      shift
      ;;
    --createisovm)
      # Create ISO based VM
      actions_list+=(createisovm)
      shift
      ;;
    --debug)
      # Set debug flag (set -x)
      set -x
      shift
      ;;
    --delete)
      # Remove previously created files
      check_value "$1" "$2"
      iso['delete']="$2"
      shift 2
      ;;
    --deletecivm)
      # Delete cloud-init based VM
      actions_list+=(deletecivm)
      shift
      ;;
    --deleteisovm)
      # Delete ISO based VM
      actions_list+=(deleteisovm)
      shift
      ;;
    --depends)
      # Force depends
      options_list+=(depends)
      shift
      ;;
    --dhcp)
      # DHCP network configuration
      options_list+=(dhcp)
      shift
      ;;
    --disableservice)
      # Disable service(s)
      check_value "$1" "$2"
      iso['disableservice']="$2"
      shift 2
      ;;
    --disk)
      # Boot Disk devices
      check_value "$1" "$2"
      iso['disk']="$2"
      shift 2
      ;;
    --diskfile)
      # Disk file
      check_value "$1" "$2"
      iso['diskfile']="$2"
      shift 2
      ;;
    --diskserial)
      # Disk serial
      check_value "$1" "$2"
      iso['diskserial']="$2"
      shift 2
      ;;
    --disksize)
      # Disk size
      check_value "$1" "$2"
      iso['diskize']="$2"
      shift 2
      ;;
    --diskwwn)
      # Disk WWN
      check_value "$1" "$2"
      iso['diskwwn']="$2"
      shift 2
      ;;
    --dns)
      # DNS server IP
      check_value "$1" "$2"
      iso['dns']="$2"
      shift 2
      ;;
    --dnsoptions)
      # DNS Options
      check_value "$1" "$2"
      iso['dnsoptions']="$2"
      shift 2
      ;;
    --dockerworkdir)
      # Disk WWN
      check_value "$1" "$2"
      iso['dockerworkdir']="$2"
      shift 2
      ;;
    --efi)
      # EFI boot type
      options_list+=(efi)
      shift
      ;;
    --enableservice)
      # Enable service(s)
      check_value "$1" "$2"
      iso['enableservice']="$2"
      shift 2
      ;;
    --fallback)
      # Installation fallback 
      check_value "$1" "$2"
      iso['fallback']="$2"
      shift 2
      ;;
    --firewall)
      # Firewall
      check_value "$1" "$2"
      iso['firewall']="$2"
      shift 2
      ;;
    --firstboot)
      # Enable firstboot
      options['firstboot']="enabled"
      shift
      ;;
    --firstoption)
      # First menu option (e.g. grub menu)
      check_value "$1" "$2"
      iso['firstoption']="$2"
      shift 2
      ;;
    --gateway)
      # Gateway IP
      check_value "$1" "$2"
      iso['gateway']="$2"
      shift 2
      options['dhcp']="false"
      ;;
    --gecos)
      # User GECOS field
      check_value "$1" "$2"
      iso['gecos']="$2"
      shift 2
      ;;
    --getiso)
      # Get ISO
      actions_list+=(getiso)
      shift
      ;;
    --groups)
      # Groups to add user to
      check_value "$1" "$2"
      iso['groups']="$2"
      shift 2
      ;;
    --grubfile)
      # Import grub file
      check_value "$1" "$2"
      options['grubfile']="true"
      iso['grubfile']="$2"
      shift 2
      ;;
    --grubmenu)
      # Import grub menu
      check_value "$1" "$2"
      iso['grubmenu']="$2"
      shift 2
      ;;
    --grubtimeout)
      # Grub timeout
      check_value "$1" "$2"
      iso['grubtimeout']="$2"
      shift 2
      ;;
    --grubparseall)
      # Parse grub for all parameters
      options['grubparse']="true"
      options['grubparseall']="true"
      shift
      ;;
    --grubcidr)
      # Pass CIDR to config from grub boot command
      check_value "$1" "$2"
      iso['grubcidr']="$2"
      iso['cidr']="$2"
      options['grubparse']="true"
      shift 2
      ;;
    --grubdisk)
      # Pass disk to config from grub boot command
      check_value "$1" "$2"
      iso['grubdisk']="$2"
      iso['disk']="$2"
      options['grubparse']="true"
      shift 2
      ;;
    --grubdns)
      # Pass nameserver to config from grub boot command
      check_value "$1" "$2"
      iso['grubdns']="$2"
      iso['dns']="$2"
      options['grubparse']="true"
      shift 2
      ;;
    --grubgateway)
      # Pass gateway to config from grub boot command
      check_value "$1" "$2"
      iso['grubgateway']="$2"
      iso['gateway']="$2"
      options['grubparse']="true"
      shift 2
      ;;
    --grubhostname)
      # Pass hostname to config from grub boot command
      check_value "$1" "$2"
      iso['grubhostname']="$2"
      iso['hostname']="$2"
      options['grubparse']="true"
      shift 2
      ;;
    --grubip)
      # Pass IP to config from grub boot command
      check_value "$1" "$2"
      iso['grubip']="$2"
      iso['ip']="$2"
      options['dhcp']="false"
      options['grubparse']="true"
      shift 2
      ;;
    --grubkernel)
      # Pass kernel package to config from grub boot command
      check_value "$1" "$2"
      iso['grubkernel']="$2"
      iso['kernel']="$2"
      options['grubparse']="true"
      shift 2
      ;;
    --grublocale)
      # Pass locale to config from grub boot command
      check_value "$1" "$2"
      iso['grublocale']="$2"
      iso['locale']="$2"
      options['grubparse']="true"
      shift 2
      ;;
    --grublayout)
      # Pass keyboard layout to config from grub boot command
      check_value "$1" "$2"
      iso['grublayout']="$2"
      iso['layout']="$2"
      options['grubparse']="true"
      shift 2
      ;;
    --grubnic)
      # Pass NIC to config from grub boot command
      check_value "$1" "$2"
      iso['grubnic']="$2"
      iso['nic']="$2"
      options['grubparse']="true"
      shift 2
      ;;
    --grubpassword)
      # Pass password to config from grub boot command
      check_value "$1" "$2"
      iso['grubpassword']="$2"
      iso['password']="$2"
      options['grubparse']="true"
      shift 2
      ;;
    --grubrealname)
      # Pass realname to config from grub boot command
      check_value "$1" "$2"
      iso['grubrealname']="$2"
      iso['realname']="$2"
      options['grubparse']="true"
      shift 2
      ;;
    --grubusername)
      # Pass username to config from grub boot command
      check_value "$1" "$2"
      iso['grubusername']="$2"
      iso['username']="$2"
      options['grubparse']="true"
      shift 2
      ;;
    --help|-h|--printhelp)
      # Print help
      print_help "cli"
      shift
      ;;
    --hostname)
      # Hostname
      check_value "$1" "$2"
      iso['hostname']="$2"
      shift 2
      ;;
    --inputci|--vmci)
      # Import Cloud Image
      check_value "$1" "$2"
      iso['inputci']="$2"
      shift 2
      ;;
    --inputfile)
      # Import ISO/file
      check_value "$1" "$2"
      iso['inputfile']="$2"
      shift 2
      ;;
    --installmode)
      # Install mode
      check_value "$1" "$2"
      iso['installmode']="$2"
      shift 2
      ;;
    --installmount)
      # Where the install mounts the CD during install
      check_value "$1" "$2"
      iso['installmount']="$2"
      shift 2
      ;;
    --installpassword)
      check_value "$1" "$2"
      iso['installpassword']="$2"
      # Temporary install password for remote access during install
      shift 2
      ;;
    --installreq*|--checkreq*)
      # Install/Check required packages
      actions_list+=(installrequiredpackages)
      shift
      ;;
    --installsource)
      # Install source
      check_value "$1" "$2"
      iso['installsource']="$2"
      shift 2
      ;;
    --installusername)
      # Install user
      check_value "$1" "$2"
      iso['installusername']="$2"
      shift 2
      ;;
    --ip)
      # IP addresses
      check_value "$1" "$2"
      iso['ip']="$2"
      shift 2
      options['dhcp']="false"
      ;;
    --ips)
      # IP address
      check_value "$1" "$2"
      iso['ips']="$2"
      shift 2
      options['dhcp']="false"
      ;;
    --isolinuxfile)
      # Import isolinux file
      check_value "$1" "$2"
      options['isolinuxfile']="true"
      iso['isolinuxfile']="$2"
      shift 2
      ;;
    --kernel)
      # Kernel to install
      check_value "$1" "$2"
      iso['kernel']="$2"
      shift 2
      ;;
    --kernelargs)
      # Kernel arguments
      check_value "$1" "$2"
      iso['kernelargs']="$2"
      shift 2
      ;;
    --kernelserialargs)
      # Kernel serial arguments
      check_value "$1" "$2"
      iso['kernelserialargs']="$2"
      shift 2
      ;;
    --kvm)
      # Install KVM packages
      options_list+=(kvm)
      shift
      ;;
    --vmiso|--kvmiso)
      # KVM/VM Import ISO/file
      check_value "$1" "$2"
      iso['vmiso']="$2"
      shift 2
      ;;
    --volid)
      # ISO Volume ID
      check_value "$1" "$2"
      iso['volid']="$2"
      shift 2
      ;;
    --layout)
      # Keyboard layout
      check_value "$1" "$2"
      iso['layout']=$2
      shift 2
      ;;
    --lcall)
      # LC_ALL
      check_value "$1" "$2"
      iso['lcall']="$2"
      shift 2
      ;;
    --listalliso*|--listiso*)
      # List ISOs
      actions_list+=(listisos)
      shift
      ;;
    --listswitches)
      # List switches
      actions_list+=(listswitches)
      shift
      ;;
    --listvm)
      # List VMs
      actions_list+=(listvm)
      shift
      ;;
    --locale)
      # Local
      check_value "$1" "$2"
      iso['locale']="$2"
      shift 2
      ;;
    --lvname)
      # Logical Volume Name
      check_value "$1" "$2"
      iso['lvname']="$2"
      shift 2
      ;;
    --name)
      # VM name
      check_value "$1" "$2"
      iso['name']="$2"
      shift 2
      ;;
    --netmask)
      # Netmask
      check_value "$1" "$2"
      iso['netmask']="$2"
      shift 2
      ;;
    --nic)
      # NIC to use for installation
      check_value "$1" "$2"
      iso['nic']="$2"
      shift 2
      ;;
    --nics)
      # NICs to use for installation
      check_value "$1" "$2"
      iso['nics']="$2"
      shift 2
      ;;
    --oeminstall)
      # OEM Install
      check_value "$1" "$2"
      iso['oeminstall']="$2"
      shift 2
      ;;
    --oldinstaller)
      # Use old installer
      options['oldinstaller']="true"
      shift
      ;;
    --oldinputfile)
      # Old release ISO
      check_value "$1" "$2"
      old['inputfile']="$2"
      shift 2
      ;;
    --oldisourl)
      # Old ISO URL
      check_value "$1" "$2"
      old['url']="$2"
      shift 2
      ;;
    --oldrelease)
      # Old release
      check_value "$1" "$2"
      old['release']="$2"
      shift 2
      ;;
    --onboot)
      # Enable network on boot
      check_value "$1" "$2"
      iso['onboot']="$2"
      shift 2
      ;;
    --option*)
      # Options (e.g. verbose)
      check_value "$1" "$2"
      options_list+=("$2")
      shift 2
      ;;
    --outputci)
      # Output CI file
      check_value "$1" "$2"
      iso['outputci']="$2"
      shift 2
      ;;
    --outputfile)
      # Output ISO file
      check_value "$1" "$2"
      iso['outputfile']="$2"
      shift 2
      ;;
    --overwrite)
      # Force overwrite
      options_list+=(overwrite)
      shift
      ;;
    --packages)
      # Additional packages to install
      check_value "$1" "$2"
      iso['packages']="$2"
      shift 2
      ;;
    --password)
      # Password
      check_value "$1" "$2"
      iso['password']="$2"
      shift 2
      ;;
    --passwordalgorithm)
      # Password Algorithm
      check_value "$1" "$2"
      iso['passwordalgorithm']="$2"
      shift 2
      ;;
    --pesize)
      # PE size
      check_value "$1" "$2"
      iso['pesize']="$2"
      shift 2
      ;;
    --postinstall)
      # Import post install script
      check_value "$1" "$2"
      iso['postinstall']="$2"
      shift 2
      ;;
    --prefix)
      # Output file name prefix
      check_value "$1" "$2"
      iso['prefix']="$2"
      shift 2
      ;;
    --preworkdir)
      # Docker work directory
      check_value "$1" "$2"
      iso['preworkdir']="$2"
      shift 2
      ;;
    --printdockerconfig)
      # Print Docker config
      actions_list+=(printdockerconfig)
      shift
      ;;
    --printenv)
      # Print environment variables
      actions_list+=(printenv)
      shift
      ;;
    --pvname)
      # Physical Volume Name
      check_value "$1" "$2"
      iso['pvname']="$2"
      shift 2
      ;;
    --ram)
      # RAM size
      check_value "$1" "$2"
      iso['ram']="$2"
      shift 2
      ;;
    --realname)
      # User real name field
      check_value "$1" "$2"
      iso['realname']="$2"
      shift 2
      ;;
    --release)
      # OS release
      check_value "$1" "$2"
      iso['release']="$2"
      shift 2
      get_release_info
      get_code_name
      get_build_type
      ;;
    --releasename)
      # OS releasename
      check_value "$1" "$2"
      iso['releasename']="$2"
      shift 2
      ;; 
    --requiredpackages)
      # Required Packages
      check_value "$1" "$2"
      options['installrequiredpackages']="true"
      iso['requiredpackages']="$2"
      shift 2
      ;; 
    --requireddockerpackages)
      # Required Packages
      check_value "$1" "$2"
      iso['requireddockerpackages']="$2"
      shift 2
      ;; 
    --rootsize)
      # Root volume size
      check_value "$1" "$2"
      iso['rootsize']="$2"
      shift 2
      ;;
    --search)
      # Search output for value
      check_value "$1" "$2"
      iso['search']="$2"
      shift 2
      ;;
    --searchdomain)
      # Search domain
      check_value "$1" "$2"
      iso['searchdomain']="$2"
      shift 2
      ;;
    --selinux)
      # SELinux Mode
      check_value "$1" "$2"
      iso['selinux']="$2"
      shift 2
      ;;
    --serialport)
      # Serial port
      check_value "$1" "$2"
      iso['serialport']="$2"
      shift 2
      ;;
    --serialportaddress)
      # Serial port address
      check_value "$1" "$2"
      iso['serialportaddress']="$2"
      shift 2
      ;;
    --serialportspeed)
      # Serial port speed
      check_value "$1" "$2"
      iso['serialportspeed']="$2"
      shift 2
      ;;
    --shell)
      # User shell
      check_value "$1" "$2"
      iso['shell']="$2"
      shift 2
      ;;
    --sourceid)
      # Source ID
      check_value "$1" "$2"
      iso['sourceid']="$2"
      shift 2
      ;;
    --squashfsfile)
      # Squashfs file
      check_value "$1" "$2"
      iso['squashfsfile']="$2"
      shift 2
      ;;
    --sshkey)
      # SSH key
      check_value "$1" "$2"
      iso['sshkey']="$2"
      options['sshkey']="true"
      shift 2
      ;;
    --sshkeyfile)
      # SSH key file
      check_value "$1" "$2"
      iso['sshkeyfile']="$2"
      options['sshkey']="true"
      shift 2
      ;;
    --static)
      # Static IP configuration
      options_list+=(static)
      shift
      ;;
    --strict)
      # Enable strict mode
      set -eu
      shift
      ;;
    --sudoers)
      # Sudoers entry
      check_value "$1" "$2"
      iso['sudoers']="$2"
      shift 2
      ;;
    --suffix)
      # Output file name suffix
      check_value "$1" "$2"
      iso['suffix']="$2"
      shift 2
      ;;
    --swap)
      # Swap device 
      check_value "$1" "$2"
      iso['swap']="$2"
      shift 2
      ;;
    --swapsize)
      # Swap size
      check_value "$1" "$2"
      iso['swapsize']="$2"
      shift 2
      ;;
    --targetmount)
      # Install target
      check_value "$1" "$2"
      iso['targetmount']="$2"
      shift 2
      ;;
    --test)
      # Run in test mode
      options_list+=(test)
      shift
      ;;
    --timezone)
      # Timezone
      check_value "$1" "$2"
      iso['timezone']="$2"
      shift 2
      ;;
    --type)
      # VM type
      check_value "$1" "$2"
      iso['type']="$2"
      shift 2
      ;;
    --updates)
      # Updates to install
      check_value "$1" "$2"
      iso['updates']="$2"
      shift 2
      ;;
    --autoinstallfile)
      # Import autoinstall config file
      check_value "$1" "$2"
      options['autoinstall']="true"
      iso['volumemanager']="custom"
      iso['autoinstallfile']="$2"
      shift 2
      ;;
    --username)
      # Username
      check_value "$1" "$2"
      iso['username']="$2"
      shift 2
      ;;
    --usage)
      # Usage information
      check_value "$1" "$2"
      print_info "$2"
      shift 2
      exit
      ;;
    --url)
      # ISO URL
      check_value "$1" "$2"
      iso['url']="$2"
      shift 2
      ;;
    --verbose)
      # Verbose output
      options_list+=(verbose)
      shift
      ;;
    --version|-V)
      # Display version
      echo "${script['version']}"
      shift
      exit
      ;;
    --vfio)
      # VM type
      check_value "$1" "$2"
      iso['vfio']="$2"
      options['vfio']="true"
      shift 2
      ;;
    --vgname)
      # Volume Group Name
      check_value "$1" "$2"
      iso['vgname']="$2"
      shift 2
      ;;
    --volumemanager)
      # Volumemanager(s)
      check_value "$1" "$2"
      iso['volumemanager']="$2"
      shift 2
      ;;
    --whitelist)
      # Allow/load additional kernel modules(s)
      check_value "$1" "$2"
      iso['whitelist']="$2"
      shift 2
      ;;
    --workdir)
      # Work directory
      check_value "$1" "$2"
      iso['workdir']="$2"
      shift 2
      ;;
    --zfsfilesystems)
      # Additional ZFS filesystems
      check_value "$1" "$2"
      options['zfsfilesystems']="true"
      iso['zfsfilesystems']="$2"
      shift 2
      ;;
    --zfsroot)
      # ZFS root name
      check_value "$1" "$2"
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
update_iso_url

# Process options

if [ -n "${options_list[*]}" ]; then
  for option_list in "${options_list[@]}"; do
    if [[ "${option_list}" =~ , ]]; then
      IFS="," read -r -a option_array <<< "${option_list[*]}"
      for option_item in "${option_array[@]}"; do
        process_options "${option_item}"
      done
    else
      process_options "${option_list}"
    fi
  done
fi

reset_defaults

# Process actions

if [ -n "${actions_list[*]}" ]; then
  for action_list in "${actions_list[@]}"; do
    if [[ "${action_list}" =~ , ]]; then
      IFS="," read -r -a action_array <<< "${action_list[*]}"
      for action_item in "${action_array[@]}"; do
        process_actions "${action_item}"
      done
    else
      process_actions "${action_list}"
    fi
  done
fi

process_post_install
update_required_packages
install_required_packages
update_iso_packages
update_output_file_name
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

if [ "${options['test']}" = "true" ]; then
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
