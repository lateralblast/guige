#!/usr/bin/env bash

# shellcheck disable=SC2034
# shellcheck disable=SC2116
# shellcheck disable=SC2129
# shellcheck disable=SC2154

# Function: set_defaults
#
# Set defaults

set_defaults () {
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
  current['release']="24.04.2"
  current['osname']="ubuntu"
  defaults['release']="${current['release']}"
  defaults['majorrelease']=$( echo "${defaults['release']}" |cut -f1 -d. )
  defaults['minorrelease']=$( echo "${defaults['release']}" |cut -f2 -d. )
  defaults['dotrelease']=$( echo "${defaults['release']}" |cut -f3 -d. )
  defaults['oldrelease']="23.04"
  current['oldrelease']="23.04"
  current['devrelease']="25.04"
  current['dockerubunturelease']="24.04"
  defaults['codename']="jammy"
  current['codename']="jammy"
  current['arch']="amd64"
  defaults['arch']=$( uname -m |sed "s/aarch64/arm64/g" |sed "s/x86_64/amd64/g" |sed "s/x86/amd64/g" )
  defaults['installsource']="cdrom"
  defaults['sourceid']="ubuntu-server"
  defaults['fallback']="continue-anyway"
  defaults['hostname']="ubuntu"
  defaults['realname']="Ubuntu"
  defaults['username']="ubuntu"
  defaults['timezone']="Australia/Melbourne"
  defaults['password']="ubuntu"
  defaults['kernel']="linux-generic"
  defaults['nic']="first-nic"
  defaults['ip']="192.168.1.2"
  defaults['dns']="8.8.8.8"
  defaults['cidr']="24"
  defaults['blocklist']=""
  defaults['allowlist']=""
  defaults['gateway']="192.168.1.254"
  defaults['swapsize']="2G"
  defaults['disk']="first-disk"
  defaults['volumemanager']="zfs auto ext4 xfs btrfs"
  defaults['grubmenu']="0"
  defaults['grubtimeout']="10"
  defaults['locale']="en_US.UTF-8"
  defaults['lcall']="en_US"
  defaults['layout']="us"
  defaults['country']="us"
  defaults['updates']="security"
  defaults['build']="live-server"
  defaults['boottype']="efi"
  defaults['serialporta']="ttyS0"
  defaults['serialportaddressa']="0x03f8"
  defaults['serialportspeeda']="115200"
  defaults['serialportb']="ttyS1"
  defaults['serialaddressb']="0x02f8"
  defaults['serialportspeedb']="115200"
  defaults['installmode']="text"
  defaults['packages']="zfsutils-linux zfs-initramfs xfsprogs btrfs-progs net-tools curl lftp wget sudo file rsync dialog setserial ansible apt-utils whois squashfs-tools duperemove jq btrfs-compsize iproute2"
  options['requiredpackages']="binwalk casper genisoimage live-boot live-boot-initramfs-tools p7zip-full lftp wget xorriso whois squashfs-tools sudo file rsync net-tools nfs-kernel-server ansible dialog apt-utils jq"
  defaults['dockerarch']="amd64 arm64"
  defaults['sshkeyfile']="$HOME/.ssh/id_rsa.pub"
  defaults['maskedsshkeyfile']="$HOME/.ssh/id_rsa.pub"
  defaults['sshkey']=""
  defaults['allowpassword']="false"
  defaults['bmcusername']="root"
  defaults['bmcpassword']="calvin"
  defaults['bmcip']="192.168.1.3"
  defaults['kernelargs']="console=tty0 console=vt0"
  defaults['search']=""
  defaults['selinux']="enforcing"
  defaults['onboot']="on"
  defaults['enableservice']="sshd"
  defaults['disableservice']="cupsd"
  defaults['dpkgconf']="--force-confnew"
  defaults['dpkgoverwrite']="--force-overwrite"
  defaults['dpkgdepends']="--force-depends"
  defaults['vmtype']="kvm"
  defaults['vmram']="2048000"
  defaults['vmcpus']="2"
  defaults['vmsize']="20G"
  defaults['vmnic']="default"
  defaults['gecos']="Administrator"
  defaults['groups']="dialout,kvm,libvirt,qemu,wheel"
  defaults['bootproto']="dhcp"
  defaults['allowservice']="ssh"
  defaults['firewall']="enabled"
  defaults['passwordalgorithm']="sha512"
  defaults['bootloader']="mbr"
  defaults['oeminstall']="auto"
  defaults['zfsfilesystems']="/var /var/lib /var/lib/AccountsService /var/lib/apt /var/lib/dpkg /var/lib/NetworkManager /srv /usr /usr/local /var/games /var/log /var/mail /var/snap /var/spool /var/www"
  defaults['bootsize']="2048"
  defaults['rootsize']="-1"
  defaults['pesize']="32768"
  defaults['installusername']="install"
  defaults['installpassword']="install"
  defaults['vgbase']="ubuntu"
  defaults['vgname']="${defaults['vgbase']}-vg"
  defaults['lvname']="${defaults['vgbase']}-lv"
  defaults['pvname']="${defaults['vgbase']}-pv"
  defaults['diskname']="boot"
  defaults['diskserial']="first-serial"
  defaults['diskwwn']="first-wwn"
  defaults['compression']="lzo"
  defaults['firstoption']="btrfs"
  defaults['netmask']=""
  vm['exists']="false"
  options['testmode']="false"
  options['force']="false"
  options['forceall']="false"
  options['verbose']="false"
  temp['verbose']="false"
  options['interactivemode']="false"
  options['biosdevname']="false"
  iso['prefix']=""
  iso['suffix']=""
  iso['sshkey']=""
  iso['vgname']=""
  iso['lvname']=""
  iso['pvname']=""
  iso['diskname']=""
  options['bmcport']="443"
  iso['bmcexposeduration']="180"
  vm['name']=""
  iso['xmlfile']=""
  iso['majorrelease']=""
  iso['minorrelease']=""
  options['dotrelease']=""
  iso['netmask']=""
  iso['postinstall']="none"
  options['brewdir']=""
  options['bindir']=""
  iso['virtdir']=""
  defaults['vmname']="${script['name']}"
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
  if [[ "${iso['osname']}" =~ "rocky" ]]; then
    defaults['volumemanager']="auto ext4 xfs btrfs"
    defaults['arch']="x86_64"
    current['release']="9.3"
    defaults['osname']="rocky"
    defaults['hostname']="rocky"
    defaults['realname']="Rocky"
    defaults['username']="rocky"
    defaults['password']="rocky"
    defaults['build']="dvd"
    defaults['swapsize']="2048"
    defaults['workdir']="$HOME/${script['name']}/${defaults['osname']}/${defaults['build']}/${defaults['release']}"
    defaults['oldmountdir']="${defaults['workdir']}/isomount"
    defaults['inputfile']="${defaults['workdir']}/${defaults['realname']}-${defaults['release']}-${defaults['arch']}-dvd.iso"
    defaults['inputfilebase']=$( basename "${defaults['inputfile']}" )
    defaults['outputfilebase']=$( basename "${defaults['outputfile']}" )
    defaults['url']="https://download.rockylinux.org/pub/rocky/${defaults['majorrelease']}/isos/${defaults['arch']}/${defaults['inputfilebase']}"
    defaults['packages']="net-tools curl lftp wget sudo file rsync dialog setserial whois squashfs-tools jq"
    options['requiredpackages']="apt-utils ${options['requiredpackages']}"
  fi
  if [[ "${iso['action']}" =~ "ci" ]]; then
    defaults['release']=$( echo "${defaults['release']}" |awk -F"." '{ print $1"."$2 }' )
    defaults['workdir']="$HOME/${script['name']}/${defaults['osname']}/${defaults['release']}"
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

# Function: set_default_flags
#
# Set default flags

set_default_flags () {
  options['zfs']="false"
  options['ipv4']="true"
  options['ipv6']="true"
  options['nomultipath']="false"
  options['kvmpackages']="false"
  options['hwekernel']="true"
  options['clusterpackages']="false"
  options['daily']="false"
  options['checkdocker']="false"
  options['latest']="false"
  options['checkci']="false"
  options['createcivm']="false"
  options['deletecivm']="false"
  options['createisovm']="false"
  options['deleteisovm']="false"
  options['listvms']="false"
  options['oldinstaller']="false"
  options['bootserverfile']="false"
  options['installrequiredpackages']="false"
  options['networkupdates']="false"
  options['installpackages']="false"
  options['installdrivers']="false"
  options['installcodecs']="false"
  options['autoupgrade']="false"
  options['aptnews']="false"
  options['getiso']="false"
  options['checkworkdir']="false"
  options['createautoinstall']="false"
  options['fulliso']="false"
  options['justiso']="false"
  options['runchrootscript']="false"
  options['help']="true"
  options['unmount']="true"
  options['nounmount']="false"
  options['packageupdates']="false"
  options['packageupgrades']="false"
  options['distupgrade']="false"
  options['updatesquashfs']="false"
  options['query']="false"
  options['docker']="false"
  options['printenv']="false"
  options['installserver']="false"
  options['createexport']="false"
  options['createansible']="false"
  options['checkracadm']="false"
  options['executeracadm']="false"
  options['listisos']="false"
  options['scpheader']="false"
  options['serial']="true"
  options['autoinstall']="false"
  options['searchdrivers']="false"
  options['preservesources']="false"
  options['plaintextpassword']="false"
  options['activate']="true"
  options['defaultroute']="true"
  options['lockroot']="true"
  options['kstest']="false"
  options['mediacheck']="false"
  options['installuser']="false"
  options['sshkey']="true"
  options['firstboot']="disabled"
  options['secureboot']="true"
  options['isolinuxfile']="false"
  options['grubfile']="false"
  options['ksquiet']="false"
  options['kstext']="false"
  options['zfsfilesystems']="false"
  options['createiso']="true"
  options['reorderuefi']="false"
  options['deletevm']="false"
  options['dhcp']="true"
  options['geoip']="true"
  options['chroot']="true"
  options['nvme']="false"
  options['compression']="true"
  options['refreshinstaller']="false"
  options['earlypackages']="false"
  options['latepackages']="false"
  options['multipath']="false"
  options['debug']="false"
  options['strict']="false"
}

# Function: set_default_os['name']}
#
# Set default OS name

set_default_osname () {
  if [ -f "/usr/bin/lsb_release" ]; then
    iso['release']=$( lsb_release -s -a )
    if [[ "${iso['release']}" =~ "Ubuntu" ]]; then
      defaults['osname']=$( lsb_release -d |awk '{print $2}' |tr '[:upper:]' '[:lower:]' )
    else
      defaults['osname']="${current['osname']}"
      if [[ "${iso['release']}" =~ "Arch" ]] || [[ "${iso['release']}" =~ "Endeavour" ]]; then
        options['requiredpackages']="p7zip lftp wget xorriso whois squashfs-tools sudo file rsync ansible dialog"
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
      defaults['release']=$( lsb_release -ds |awk '{print $2}' )
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
  defaults['workdir']="$HOME/${script['name']}/${defaults['osname']}/${defaults['build']}/${defaults['release']}"
  defaults['oldworkdir']="$HOME/${script['name']}/${defaults['osname']}/${defaults['build']}/${defaults['oldrelease']}"
  defaults['maskedworkdir']="$HOME/${script['name']}/${defaults['osname']}/${defaults['build']}/${defaults['release']}"
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
  defaults['volid']="${defaults['realname']} ${defaults['release']} Server"
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
  iso['volid']="${iso['volid']} ${iso['arch']}"
  iso['grubfile']="${iso['workdir']}/grub.cfg"
  if [[ "${iso['build']}" =~ "desktop" ]]; then
    iso['squashfsfile']="${iso['mountdir']}/casper/minimal.squashfs"
    iso['newsquashfsfile']="${iso['sourcedir']}/casper/minimal.squashfs"
  else
    if [ "${iso['majorrelease']}" -ge "22" ]; then
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
      verbose_message "Tool ipcalc not found" "warn"
      defaults['cidr']="24"
    fi
  else
    defaults['interface']=$( ip -4 route show default |grep -v linkdown|awk '{ print $5 }' )
    defaults['cidr']=$( ip r |grep link |grep "${defaults['interface']}" |awk '{print $1}' |cut -f2 -d/ |head -1 )
    if [[ "${defaults['cidr']}" =~ . ]] || [ "${defaults['cidr']}" = "" ]; then
      if [ ! "${bin_test}" = "0" ]; then
        defaults['netmask']=$( route -n |awk '{print $3}' |grep "^255" )
        defaults['cidr']=$( ipcalc "1.1.1.1" "${defaults['netmask']}" | grep ^Netmask |awk '{print $4}' )
      else
        verbose_message "Tool ipcalc not found" "warn"
        defaults['cidr']="24"
      fi
    fi
  fi
  defaults['vmbridge']="${defaults['interface']}"
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
