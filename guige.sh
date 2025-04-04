#!/usr/bin/env bash

# Name:         guige (Generic Ubuntu/Unix ISO Generation Engine)
# Version:      3.2.4
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
declare -a option_flags
declare -a action_flags

script['args']="$*"
script['file']="$0"
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


# Handle verbose and debug early so it's enabled early

if [[ "$*" =~ "verbose" ]]; then
  options['verbose']="true"
  if [ ! -f "/.dockerenv" ]; then
    set -eu
  fi
else
  options['verbose']="false"
fi

if [[ "$*" =~ "debug" ]]; then
  options['verbose']="true"
  set -x
else
  options['verbose']="false"
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

while test $# -gt 0
do
  case "$1" in
    --action|--actions)
      iso['action']="$2"
      shift 2
      ;;
    --allow|--allowlist)
      iso['allowlist']="$2"
      shift 2
      ;;
    --allowpassword|--allow-password)
      iso['allowpassword']="true"
      shift
      ;;
    --allowservice|--allowservices|--service|--services)
      iso['allowservice']="$2"
      shift 2
      ;;
    --arch)
      iso['arch']="$2"
      shift 2
      iso['arch']=$( echo "${iso['arch']}" |sed "s/aarch64/arm64/g" |sed "s/x86_64/amd64/g" |sed "s/x86/amd64/g" )
      ;;
    --autoinstalldir|--aidir)
      iso['autoinstalldir']="$2"
      shift 2
      ;;
    --block|--blocklist)
      iso['blocklist']="$2"
      shift 2
      ;;
    --bmcip)
      iso['bmcip']="$2"
      shift 2
      ;;
    ----bmcpass|--bmcpassword)
      iso['bmcpassword']="$2"
      shift 2
      ;;
    --bmcuser|--bmcusername)
      iso['bmcusername']="$2"
      shift 2
      ;;
    --bootdisk|--disk|--installdisk|--firstdisk)
      iso['disk']="$2"
      shift 2
      ;;
    --bootloader)
      iso['bootloader']="$2"
      shift 2
      ;;
    --bootserverfile)
      iso['bootserverfile']="$2"
      options['bootserverfile']="true"
      shift 2
      ;;
    --bootserverip)
      iso['bootserverip']="$2"
      shift 2
      ;;
    --bootsize)
      iso['bootsize']="$2"
      shift 2
      ;;
    --build|--buildtype)
      iso['build']="$2"
      case "${iso['build']}" in
        "daily")
          options['daily']="true"
          ;;
      esac
      shift 2
      ;;
    --chrootpackages)
      iso['chrootpackages']="$2"
      shift 2
      ;;
    --cidr)
      iso['cidr']="$2"
      shift 2
      ;;
    --codename|--distro)
      iso['codename']="$2"
      shift 2
      ;;
    --compression)
      iso['compression']="$2"
      options['compression']="true"
      shift 2
      ;;
    --country)
      iso['country']="$2"
      shift 2
      ;;
    --debug)
      set -x
      shift
      ;;
    --iso['delete']})
      iso['delete']="$2"
      shift 2
      ;;
    --disableservice|--disable)
      iso['disableservice']="$2"
      shift 2
      ;;
    --diskserial)
      iso['diskserial']="$2"
      shift 2
      ;;
    --diskwwn)
      iso['diskwwn']="$2"
      shift 2
      ;;
    --dns|--nameserver)
      iso['dns']="$2"
      shift 2
      ;;
    --enableservice|--enable)
      iso['enableservice']="$2"
      shift 2
      ;;
    --fallback)
      iso['fallback']="$2"
      shift 2
      ;;
    --firewall)
      iso['firewall']="$2"
      shift 2
      ;;
    --firstoption|--first-option)
      iso['firstoption']="$2"
      shift 2
      ;;
    --gateway)
      iso['gateway']="$2"
      shift 2
      options['dhcp']="false"
      ;;
    --gecos)
      iso['gecos']="$2"
      shift 2
      ;;
    --groups)
      iso['groups']="$2"
      shift 2
      ;;
    --grub|--grubfile)
      options['grubfile']="true"
      iso['grubfile']="$2"
      shift 2
      ;;
    --grubmenu)
      iso['grubmenu']="$2"
      shift 2
      ;;
    --grubtimeout|--grub-timeout)
      iso['grubtimeout']="$2"
      shift 2
      ;;
    -h|--help)
      print_help ""
      ;;
    --hostname)
      iso['hostname']="$2"
      shift 2
      ;;
    --inputiso|--vmiso)
      iso['inputfile']="$2"
      vm['inputfile']="$2"
      shift 2
      ;;
    --inputci|--vmci)
      iso['inputci']="$2"
      shift 2
      ;;
    --installmode|--install-mode)
      iso['installmode']="$2"
      shift 2
      ;;
    --installmount)
      iso['installmount']="$2"
      shift 2
      ;;
    --installpassword|--install-password|--installpass|--install-pass)
      iso['installpassword']="$2"
      shift 2
      ;;
    --installsource|--install-source)
      iso['installsource']="$2"
      shift 2
      ;;
    --installtarget)
      iso['targetmount']="$2"
      shift 2
      ;;
    --installuser|--install-user)
      iso['installusername']="$2"
      shift 2
      ;;
    --ip)
      iso['ip']="$2"
      shift 2
      options['dhcp']="false"
      ;;
    --isolinux|--isolinuxfile)
      options['isolinuxfile']="true"
      iso['isolinuxfile']="$2"
      shift 2
      ;;
    --isopackages|--packages)
      iso['packages']="$2"
      shift 2
      ;;
    --isourl|--url)
      iso['url']="$2"
      shift 2
      ;;
    --isovolid|--volid)
      iso['volid']="$2"
      shift 2
      ;;
    --isokernel|--kernel)
      iso['kernel']="$2"
      shift 2
      ;;
    --isokernelargs|--kernelargs)
      iso['kernel']}ARGS="$2"
      shift 2
      ;;
    --layout|--vmsize)
      iso['layout']="$2"
      vm['size']=$2
      shift 2
      ;;
    --lcall)
      iso['lcall']="$2"
      shift 2
      ;;
    --locale)
      iso['locale']="$2"
      shift 2
      ;;
    --lvname)
      iso['lvname']="$2"
      shift 2
      ;;
    --netmask)
      iso['netmask']="$2"
      shift 2
      ;;
    --nic|--vmnic|--installnic|--bootnic|--firstnic)
      iso['nic']="$2"
      vm['nic']="$2"
      shift 2
      ;;
    --oeminstall)
      iso['oeminstall']="$2"
      shift 2
      ;;
    --oldinputfile)
      old['inputfile']="$2"
      shift 2
      ;;
    --oldisourl)
      old['url']="$2"
      shift 2
      ;;
    --oldrelease)
      old['release']="$2"
      shift 2
      ;;
    --onboot)
      iso['onboot']="$2"
      shift 2
      ;;
    --option|--options)
      iso['options']="$2";
      shift 2
      ;;
    --outputiso)
      iso['outputfile']="$2"
      shift 2
      ;;
    --outputci)
      iso['outputci']="$2"
      shift 2
      ;;
    --password)
      iso['password']="$2"
      shift 2
      ;;
    --passalgo|--passwordalgorithm|--password-algorithm)
      iso['passwordalgorithm']="$2"
      shift 2
      ;;
    --pesize)
      iso['pesize']="$2"
      shift 2
      ;;
    --postinstall)
      iso['postinstall']="$2"
      shift 2
      ;;
    --prefix)
      iso['prefix']="$2"
      shift 2
      ;;
    --preworkdir)
      iso['preworkdir']="$2"
      shift 2
      ;;
    --pvname)
      iso['pvname']="$2"
      shift 2
      ;;
    --realname)
      iso['realname']="$2"
      shift 2
      ;;
    --release)
      iso['release']="$2"
      shift 2
      case ${iso['release']} in
        "${current['devrelease']}")
          if [ "${iso['build']}" = "" ]; then
            iso['build']="daily-live"
            options['daily']="true"
          fi
          ;;
      esac
      get_release_info
      get_code_name
      get_build_type
      ;;
    --rootsize)
      iso['rootsize']="$2"
      shift 2
      ;;
    --search)
      iso['search']="$2"
      shift 2
      ;;
    --selinux)
      iso['selinux']="$2"
      shift 2
      ;;
    --serialport)
      iso['serialporta']="$2"
      shift 2
      ;;
    --serialportaddress)
      iso['serialportaddressa']="$2"
      shift 2
      ;;
    --serialportspeed)
      iso['serialportspeeda']="$2"
      shift 2
      ;;
    --sourceid)
      iso['sourceid']="$2"
      shift 2
      ;;
    --squashfsfile)
      iso['squashfsfile']="$2"
      shift 2
      ;;
    --sshkey)
      iso['sshkey']="$2"
      options['sshkey']="true"
      shift 2
      ;;
    --sshkeyfile)
      iso['sshkeyfile']="$2"
      options['sshkey']="true"
      shift 2
      ;;
    --suffix)
      iso['suffix']="$2"
      shift 2
      ;;
    --iso['swapsize']}|--vmram)
      iso['swapsize']="$2"
      VM_RAM="$2"
      shift 2
      ;;
    --timezone)
      iso['timezone']="$2"
      shift 2
      ;;
    --updates)
      iso['updates']="$2"
      shift 2
      ;;
    --userdata|--autoinstall|--kickstart)
      options['autoinstall']="true"
      iso['volumemanager']="custom"
      iso['autoinstallfile']="$2"
      shift 2
      ;;
    --user|--username)
      iso['username']="$2"
      shift 2
      ;;
    --usage)
      print_usage "$2"
      exit
      ;;
    -V|--version)
      echo "${script['version']}"
      shift
      exit
      ;;
    --vgname)
      iso['vgname']="$2"
      shift 2
      ;;
    --vmcpus)
      vm['cpus']="$2"
      shift 2
      ;;
    --vmname)
      vm['name']="$2"
      shift 2
      ;;
    --vmtype)
      vm['type']="$2"
      shift 2
      ;;
    --volumemanager|--volumemanagers|--volmgr|--volmgrs)
      iso['volumemanager']="$2"
      shift 2
      ;;
    --workdir)
      iso['workdir']="$2"
      shift 2
      ;;
    --zfs|--zfs_filesystems)
      options['zfs_filesystems']="true"
      iso['zfs_filesystems']="$2"
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
  install_required_packages "${options['requiredpackages']}"
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
