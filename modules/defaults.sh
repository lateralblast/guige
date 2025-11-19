#!/usr/bin/env bash

# shellcheck disable=SC2034
# shellcheck disable=SC2116
# shellcheck disable=SC2129
# shellcheck disable=SC2154

# Function: set_current_defaults
#
# Set current defaults 

set_current_defaults () {
  current['arch']="amd64"
  current['codename']="jammy"
  current['devrelease']="26.04"
  current['betarelease']=""
  current['dockerubunturelease']="25.04"
  current['oldrelease']="23.04"
  current['osname']="ubuntu"
  current['release']="24.04.2"
  current['release1404']="14.04.6"
  current['release1604']="16.04.7"
  current['release1804']="18.04.6"
  current['release2004']="20.04.6"
  current['release2204']="22.04.5"
  current['release2210']="22.10"
  current['release2304']="23.04"
  current['release2310']="23.10.1"
  current['release2404']="24.04.2"
  current['release2410']="24.10"
  current['release2504']="25.04"
  current['release2510']="25.10"
}

# Function: set_default_defaults
#
# Set default defaults

set_default_defaults () {
  defaults['allowlist']=""
  defaults['allowpassword']="false"
  defaults['allowservice']="ssh"
  defaults['arch']=$( uname -m |sed "s/aarch64/arm64/g" |sed "s/x86_64/amd64/g" |sed "s/x86/amd64/g" )
  defaults['bmcip']=""
  defaults['bmcpassword']="calvin"
  defaults['bmcport']="443"
  defaults['bmcusername']="root"
  defaults['blocklist']=""
  defaults['bootloader']="mbr"
  defaults['bootproto']="dhcp"
  defaults['bootsize']="2048"
  defaults['boottype']="efi"
  defaults['bridge']="br0"
  defaults['build']="server"
  defaults['chrootpackages']="sudo zfsutils-linux zfs-initramfs xfsprogs btrfs-progs net-tools curl lftp wget sudo file rsync dialog setserial ansible apt-utils whois squashfs-tools duperemove jq btrfs-compsize iproute2"
  defaults['cidr']="24"
  defaults['cidrs']=""
  defaults['compression']="lzo"
  defaults['codename']="jammy"
  defaults['country']="us"
  defaults['cpus']="2"
  defaults['disableservice']="cupsd"
  defaults['disk']="first-disk"
  defaults['diskfile']=""
  defaults['diskname']="boot"
  defaults['diskserial']="first-serial"
  defaults['disksize']="20G"
  defaults['diskwwn']="first-wwn"
  defaults['dns']="8.8.8.8"
  defaults['dnsoptions']="edns0 trust-ad"
  defaults['nameserver']="8.8.8.8"
  defaults['dockerarch']="amd64 arm64"
  defaults['dpkgconf']="--force-confnew"
  defaults['dpkgdepends']="--force-depends"
  defaults['dpkgoverwrite']="--force-overwrite"
  defaults['enableservice']="sshd"
  defaults['fallback']="continue-anyway"
  defaults['firewall']="enabled"
  defaults['firstoption']="zfs"
  defaults['gateway']="192.168.1.254"
  defaults['gecos']="Administrator"
  defaults['groups']="adm,cdrom,dip,plugdev,lxd,sudo"
#  defaults['groups']="dialout,kvm,libvirt,qemu,wheel"
  defaults['grubmenu']="0"
  defaults['grubtimeout']="10"
  defaults['hostname']="ubuntu"
  defaults['installmode']="text"
  defaults['installpassword']="install"
  defaults['installsource']="cdrom"
  defaults['installusername']="install"
  defaults['ip']=""
  defaults['ips']=""
  defaults['kernel']="linux-generic"
  defaults['kernelargs']="console=tty0 console=vt0"
  defaults['kernelserialargs']="console=ttyS0,115200 console=ttyS1,115200"
  defaults['layout']="us"
  defaults['lcall']="en_US"
  defaults['locale']="en_US.UTF-8"
  defaults['maskedsshkeyfile']="$HOME/.ssh/id_rsa.pub"
  defaults['name']="${script['name']}"
  defaults['netmask']=""
  defaults['nic']="first-nic"
  defaults['nics']=""
  defaults['oeminstall']="auto"
  defaults['oldrelease']="23.04"
  defaults['onboot']="on"
  defaults['packages']="sudo zfsutils-linux zfs-initramfs xfsprogs btrfs-progs net-tools curl lftp wget sudo file rsync dialog setserial ansible apt-utils whois squashfs-tools duperemove jq btrfs-compsize iproute2 ipcalc"
  defaults['password']="ubuntu"
  defaults['passwordalgorithm']="sha512"
  defaults['pesize']="32768"
  defaults['ram']="2048000"
  defaults['realname']="Ubuntu"
  defaults['releasename']="Ubuntu"
  defaults['release']="${current['release']}"
  defaults['majorrelease']=$( echo "${defaults['release']}" |cut -f1 -d. )
  defaults['minorrelease']=$( echo "${defaults['release']}" |cut -f2 -d. )
  defaults['dotrelease']=$( echo "${defaults['release']}" |cut -f3 -d. )
  defaults['rootsize']="-1"
  defaults['search']=""
  defaults['searchdomain']="."
  defaults['selinux']="enforcing"
  defaults['serialport']="ttyS0,ttyS1"
  defaults['serialporta']="ttyS0"
  defaults['serialportaddress']="0x02f8,0x03f8"
  defaults['serialportaddressa']="0x02f8"
  defaults['serialportspeed']="115200,115200"
  defaults['serialportspeeda']="115200"
  defaults['serialportb']="ttyS1"
  defaults['serialportaddressb']="0x03f8"
  defaults['serialportspeedb']="115200"
  defaults['shell']="/bin/bash"
  defaults['sourceid']="ubuntu-server"
  defaults['sshkey']=""
  defaults['sshkeyfile']="$HOME/.ssh/id_rsa.pub"
  defaults['sudoers']="ALL=(ALL) NOPASSWD: ALL"
  defaults['swap']=""
  defaults['swapsize']="2G"
  defaults['timezone']="Australia/Melbourne"
  defaults['type']="kvm"
  defaults['updates']="security"
  defaults['username']="ubuntu"
  defaults['vgbase']="ubuntu"
  defaults['vgname']="${defaults['vgbase']}-vg"
  defaults['lvname']="${defaults['vgbase']}-lv"
  defaults['pvname']="${defaults['vgbase']}-pv"
  defaults['volumemanager']="zfs auto ext4 xfs btrfs"
  defaults['zfsfilesystems']="/var /var/lib /var/lib/AccountsService /var/lib/apt /var/lib/dpkg /var/lib/NetworkManager /srv /usr /usr/local /var/games /var/log /var/mail /var/snap /var/spool /var/www"
  defaults['zfsroot']="zfsroot"
  if [ "${os['name']}" = "Linux" ]; then
    defaults['requiredpackages']="binwalk casper genisoimage live-boot live-boot-initramfs-tools p7zip-full lftp wget xorriso whois squashfs-tools sudo file rsync net-tools nfs-kernel-server ansible dialog apt-utils jq ipcalc"
  else
    defaults['requiredpackages']="binwalk p7zip lftp wget xorriso whois file rsync net-tools ansible dialog jq ipcalc"
  fi
  defaults['requireddockerpackages']="binwalk casper genisoimage live-boot live-boot-initramfs-tools p7zip-full lftp wget xorriso whois squashfs-tools sudo file rsync net-tools nfs-kernel-server ansible dialog apt-utils jq ipcalc iproute2"
}

# Function: set_defaults
#
# Set defaults

set_defaults () {
  temp['verbose']="false"
  set_options_defaults
  set_current_defaults
  set_default_defaults
  set_iso_defaults
  iso['name']=""
  iso['exists']="false"
  if [ "${os['name']}" = "Linux" ]; then
    iso['requiredkvmpackages']="libvirt-clients libvirt-daemon-system libguestfs-tools qemu-kvm virt-manager"
  else
    iso['requiredkvmpackages']="libvirt-glib libvirt qemu qemu-kvm virt-manager"
  fi
  set_default_cidr
}

# Function: reset_defaults
#
# Reset defaults

reset_defaults () {
  get_ssh_key
  get_release_info
  if [[ "${iso['build']}" =~ "desktop" ]]; then
    options['chroot']="false"
  fi
  if [ "${iso['osname']}" = "" ]; then
    iso['osname']="${defaults['osname']}"
  fi
  if [[ "${iso['osname']}" =~ "ubuntu" ]]; then
    defaults['requiredpackages']="iproute2 ${defaults['requiredpackages']}"
    if [ "${iso['release']}" = "${current['betarelease']}" ]; then
      if [ "${iso['arch']}" = "" ]; then
        iso_arch="${defaults['arch']}"
      else
        iso_arch="${iso['arch']}"
      fi
      defaults['inputfilebase']="ubuntu-${iso['release']}-beta-${iso_build}-${iso_arch}.iso"
      defaults['inputfile']="${defaults['workdir']}/${defaults['inputfilebase']}"
    fi
  fi
  if [[ "${iso['osname']}" =~ "rocky" ]]; then
    defaults['volumemanager']="auto ext4 xfs btrfs"
    defaults['arch']="x86_64"
    current['release']="9.3"
    defaults['osname']="rocky"
    defaults['hostname']="rocky"
    defaults['releasename']="Rocky"
    defaults['username']="rocky"
    defaults['password']="rocky"
    defaults['build']="dvd"
    defaults['swapsize']="2048"
    defaults['workdir']="$HOME/Documents/${script['name']}/${defaults['osname']}/${defaults['build']}/${defaults['release']}"
    defaults['oldmountdir']="${defaults['workdir']}/isomount"
    defaults['inputfile']="${defaults['workdir']}/${defaults['releasename']}-${defaults['release']}-${defaults['arch']}-dvd.iso"
    defaults['inputfilebase']=$( basename "${defaults['inputfile']}" )
    defaults['outputfilebase']=$( basename "${defaults['outputfile']}" )
    defaults['url']="https://download.rockylinux.org/pub/rocky/${defaults['majorrelease']}/isos/${defaults['arch']}/${defaults['inputfilebase']}"
    defaults['packages']="net-tools curl lftp wget sudo file rsync dialog setserial whois squashfs-tools jq"
    defaults['requiredpackages']="apt-utils ${defaults['requiredpackages']}"
  fi
  if [[ "${iso['action']}" =~ "ci" ]]; then
    defaults['release']=$( echo "${defaults['release']}" |awk -F"." '{ print $1"."$2 }' )
    defaults['workdir']="$HOME/Documents/${script['name']}/${defaults['osname']}/${defaults['release']}"
    defaults['inputci']="${defaults['workdir']}/files/ubuntu-${defaults['release']}-server-cloudimg-${defaults['arch']}.img"
    defaults['inputcibase']=$( basename "${defaults['inputci']}" )
    defaults['outputci']="${defaults['workdir']}/files/ubuntu-${defaults['release']}-server-cloudimg-${defaults['arch']}-${defaults['boottype']}-autoinstall.img"
    defaults['outputcibase']=$( basename "${defaults['outputci']}" )
  fi
  if [[ "${iso['build']}" =~ "server" ]]; then
    options['unpacksquashfs']="true"
    if [[ "${iso['volumemanager']}" =~ "zfs" ]]; then
      options['earlypackages']="true"
      options['latepackages']="true"
    fi
  fi
}

# Function: set_default_os['name']}
#
# Set default OS name

set_default_osname () {
  if [ -f "/usr/bin/lsb_release" ]; then
    lsb_release=$( lsb_release -s -d )
    if [[ "${lsb_release}" =~ Ubuntu ]]; then
      defaults['osname']=$( lsb_release -d |awk '{print $2}' |tr '[:upper:]' '[:lower:]' )
    else
      defaults['osname']="${current['osname']}"
      if [[ "${lsb_release}" =~ "Arch" ]] || [[ "${lsb_release}" =~ "Endeavour" ]]; then
        iso['requiredpackages']="p7zip lftp wget xorriso whois squashfs-tools sudo file rsync ansible dialog"
      fi
    fi
  else
    defaults['osname']="${current['osname']}"
  fi
}

# Function: set_default_arch
#
# Set default zrchitecture

set_default_arch () {
  if [ -f "/usr/bin/uname" ]; then
    if [ "${os['name']}" = "Linux" ]; then
      if [ "$( command -v ifconfig )" ]; then
        defaults['bootserverip']=$( ifconfig | grep "inet " | grep -v "127.0.0.1" |head -1 |awk '{print $2}' )
      else
        defaults['bootserverip']=$( ip addr | grep "inet " | grep -v "127.0.0.1" |head -1 |awk '{print $2}' |cut -f1 -d/ )
      fi
      if [ "${iso['osname']}" = "rocky" ]; then
        defaults['arch']=$( uname -m)
      else
        defaults['arch']=$( uname -m | sed "s/aarch64/arm64/g" |sed "s/x86_64/amd64/g" )
        if [ "${defaults['arch']}" = "x86_64" ] || [ "${defaults['arch']}" = "amd64" ]; then
          defaults['arch']="amd64"
        fi
        if [ "${defaults['arch']}" = "aarch64" ] || [ "${defaults['arch']}" = "arm64" ]; then
          defaults['arch']="arm64"
        fi
      fi
    else
      if [ "$( command -v ifconfig )" ]; then
        defaults['bootserverip']=$( ifconfig | grep "inet " | grep -v "127.0.0.1" |head -1 |awk '{print $2}' )
      else
        defaults['bootserverip']=$( ip add | grep "inet " | grep -v "127.0.0.1" |head -1 |awk '{print $2}' |cut -f1 -d/ )
      fi
    fi
  else
    defaults['arch']="${current['arch']}"
    defaults['bootserverip']=$( ifconfig | grep "inet " | grep -v "127.0.0.1" |head -1 |awk '{print $2}' )
  fi
}

# Function: set_default_release
#
# Set default release

set_default_release () {
  if [ -f "/usr/bin/lsb_release" ]; then
    if [ "${os['distro']}" = "Ubuntu" ]; then
      distro_info=$( lsb_release -ds )
      if [[ "${distro_info}" =~ development ]]; then
        defaults['release']=$( lsb_release -sr )
      else
        defaults['release']=$( lsb_release -ds |awk '{print $2}' )
      fi
    else
      defaults['release']="${current['release']}"
    fi
  else
    defaults['release']="${current['release']}"
  fi
  defaults['oldrelease']="${current['oldrelease']}"
}

# Funtion: set_default_codename
#
# Set default codename

set_default_codename () {
  if [ -f "/usr/bin/lsb_release" ]; then
    if [ "${os['name']}" = "Ubuntu" ]; then
      defaults['codename']=$( lsb_release -cs 2> /dev/null)
    else
      defaults['codename']="${current['codename']}"
    fi
  else
    defaults['codename']="${current['codename']}"
  fi
}

# Function: set_default_old_url
#
# Set default old ISO URL

set_default_old_url () {
  defaults['oldurl']="https://old-releases.ubuntu.com/releases/${defaults['oldrelease']}/ubuntu-${defaults['oldrelease']}-live-server-${defaults['arch']}.iso"
}

# Function: set_defaults['dockerarch']}
#
# Set default arches for Docker

set_default_docker_arch () {
  if [ "${os['name']}" = "Darwin" ]; then
    if [ "${os['arch']}" = "arm64" ]; then
      defaults['dockerarch']="amd64 arm64"
    else
      defaults['dockerarch']="amd64"
    fi
  else
    defaults['dockerarch']="amd64"
  fi
}

# Function: set_default_dirs
#
# Set default work directories

set_default_dirs () {
  defaults['workdir']="$HOME/Documents/${script['name']}/${defaults['osname']}/${defaults['build']}/${defaults['release']}"
  defaults['dockerworkdir']="/root/${script['name']}/${defaults['osname']}/${defaults['build']}/${defaults['release']}"
  defaults['oldworkdir']="$HOME/Documents/${script['name']}/${defaults['osname']}/${defaults['build']}/${defaults['oldrelease']}"
  defaults['maskedworkdir']="$HOME/Documents/${script['name']}/${defaults['osname']}/${defaults['build']}/${defaults['release']}"
  defaults['oldmountdir']="${defaults['workdir']}/isomount"
  defaults['oldmountdir']="${defaults['oldworkdir']}/isomount"
  defaults['autoinstalldir']="autoinstall"
  defaults['targetmount']="/target"
  defaults['installmount']="/cdrom"
}

# Function: reset_default_dirs
#
# Update Default work directories

reset_default_dirs () {
  iso['mountdir']="${iso['workdir']}/isomount"
  old['mountdir']="${old['workdir']}/isomount"
  iso['newdir']="${iso['workdir']}/isonew"
  iso['sourcedir']="${iso['workdir']}/source-files"
}

# Function: set_default_files
#
# Set default file names/locations

set_default_files () {
  defaults['inputfile']="${defaults['workdir']}/files/ubuntu-${defaults['release']}-live-server-${defaults['arch']}.iso"
  defaults['inputci']="${defaults['workdir']}/files/ubuntu-${defaults['release']}-server-cloudimg-${defaults['arch']}.img"
  defaults['oldinputfile']="${defaults['oldworkdir']}/files/ubuntu-${defaults['oldrelease']}-live-server-${defaults['arch']}.iso"
  defaults['outputfile']="${defaults['workdir']}/files/ubuntu-${defaults['release']}-live-server-${defaults['arch']}-${defaults['boottype']}-autoinstall.iso"
  defaults['outputci']="${defaults['workdir']}/files/ubuntu-${defaults['release']}-server-cloudimg-${defaults['arch']}-${defaults['boottype']}-autoinstall.img"
  defaults['bootserverfile']="${defaults['outputfile']}"
  defaults['squashfsfile']="${defaults['oldmountdir']}/casper/ubuntu-server-minimal.squashfs"
  defaults['oldinstallsquashfsfile']="${defaults['oldmountdir']}/casper/ubuntu-server-minimal.ubuntu-server.installer.squashfs"
  defaults['grubfile']="${defaults['workdir']}/grub.cfg"
  defaults['volid']="${defaults['releasename']} ${defaults['release']} Server"
  defaults['inputfilebase']=$( basename "${defaults['inputfile']}" )
  defaults['inputcibase']=$( basename "${defaults['inputci']}" )
  defaults['outputfilebase']=$( basename "${defaults['outputfile']}" )
  defaults['outputcibase']=$( basename "${defaults['outputci']}" )
  defaults['bootserverfilebase']=$(basename "${defaults['bootserverfile']}")
  defaults['squashfsfilebase']=$( basename "${defaults['squashfsfile']}" )
  defaults['grubfilebase']=$( basename "${defaults['grubfile']}" )
}

# Function: reset_default_files
#
# Update default files

reset_default_files () {
  if [[ ! "${iso['volid']}" =~ ${iso['arch']} ]]; then
    iso['volid']="${iso['volid']} ${iso['arch']}"
  fi
  iso['grubfile']="${iso['workdir']}/grub.cfg"
  if [[ "${iso['build']}" =~ desktop ]]; then
    iso['squashfsfile']="${iso['mountdir']}/casper/minimal.squashfs"
    iso['newsquashfsfile']="${iso['sourcedir']}/casper/minimal.squashfs"
  else
    if [ "${iso['majorrelease']}" -ge 22 ]; then
      iso['squashfsfile']="${iso['mountdir']}/casper/ubuntu-server-minimal.squashfs"
      iso['newsquashfsfile']="${iso['sourcedir']}/casper/ubuntu-server-minimal.squashfs"
    else
      iso['squashfsfile']="${iso['mountdir']}/casper/filesystem.squashfs"
      iso['newsquashfsfile']="${iso['sourcedir']}/casper/filesystem.squashfs"
    fi
  fi
}

# Function: reset_volmgrs
#
# Update order of volmgrs based on --firstoption switch

reset_volmgrs () {
  if [ ! "${iso['firstoption']}" = "" ]; then
    temp_volmgrs=$(echo "${iso['volumemanager']}" |sed "s/${iso['firstoption']}//g" |sed "s/^ //g" |sed "s/ $//g" )
    iso['volumemanager']="${iso['firstoption']} ${temp_volmgrs}"
  fi
}

# Function: set_default_cidr
#
# Set default CIDR

set_default_cidr () {
  bin_test=$( command -v ipcalc | grep -c ipcalc )
  if [ "${os['name']}" = "Darwin" ]; then
    if [ ! "${bin_test}" = "0" ]; then
      defaults['interface']=$( route -n get default |grep interface |awk '{print $2}' )
      defaults['netmask']=$( ifconfig "${defaults['interface']}" |grep mask |awk '{print $4}' )
      defaults['cidr']=$( ipcalc "1.1.1.1" "${defaults['netmask']}" | grep ^Netmask |awk '{print $4}' )
      if [[ "${defaults['netmask']}" =~ "0x" ]]; then
        defaults_cidr="${defaults['cidr']}"
        octets=$( eval echo '$(((defaults_cidr<<32)-1<<32-$defaults_cidr>>'{3..0}'*8&255))' )
        defaults['netmask']=$( echo "${octets// /.}" )
      fi
    else
      warning_message "Tool ipcalc not found"
      defaults['cidr']="24"
    fi
  else
    if [ -f "/usr/sbin/ip" ]; then
      defaults['interface']=$( ip -4 route show default |grep -v linkdown|awk '{ print $5 }' )
      defaults['cidr']=$( ip r |grep link |grep "${defaults['interface']}" |awk '{print $1}' |cut -f2 -d/ |head -1 )
    else
      defaults['interface']=$( netstat -rn |grep "^0.0.0.0" |awk '{print $8}' )
      defaults['cidr']=""
    fi
    if [[ "${defaults['cidr']}" =~ . ]] || [ "${defaults['cidr']}" = "" ]; then
      if [ ! "${bin_test}" = "0" ]; then
        if [ ! -f "/usr/sbin/route" ]; then
          install_package "iproute2"
        fi
        defaults['netmask']=$( route -n |awk '{print $3}' |grep "^255" )
        defaults['cidr']=$( ipcalc "1.1.1.1" "${defaults['netmask']}" | grep ^Netmask |awk '{print $4}' )
      else
        warning_message "Tool ipcalc not found"
        defaults['cidr']="24"
      fi
    fi
  fi
}

# Function: get_cidr_from_netmask
#
# Get CIDR from netmask

get_cidr_from_netmask () {
  local x=${1##*255.}
  set -- 0^^^128^192^224^240^248^252^254^ "$(( (${#1}" - "${#x})*2 ))" "${x%%.*}"
  x="${1%%"$3"*}"
  iso['cidr']=$( eval echo "$(( $2 + (${#x}/4) ))")
}


# Function:: get_netmask_from_cidr
#
# Get netmask from CIDR

get_netmask_from_cidr () {
  octets=$( eval echo '$(((1<<32)-1<<32-$1>>'{3..0}'*8&255))' )
  iso['netmask']=$( echo "${octets// /.}" )
}
