#!/usr/bin/env bash

# shellcheck disable=SC2129
# shellcheck disable=SC2034
# shellcheck disable=SC2154

# Function: process_switches
#
# Process switches

process_switches () {
  if [ "${iso['compression']}" = "" ]; then
    iso['compression']="${defaults['compression']}"
  fi
  if [ "${iso['diskserial']}" = "" ]; then
    iso['diskserial']="${defaults['diskserial']}"
  fi
  if [ "${iso['diskwwn']}" = "" ]; then
    iso['diskwwn']="${defaults['diskwwn']}"
  fi
  if [ "${iso['updates']}" = "" ]; then
    iso['updates']="${defaults['updates']}"
  fi
  if [ "${iso['fallback']}" = "" ]; then
    iso['fallback']="${defaults['fallback']}"
  fi
  if [ "${iso['vgname']}" = "" ]; then
    iso['vgname']="${defaults['vgname']}"
  else
    if [ "${iso['pvname']}" = "" ]; then
      iso['pvname']="${iso['vgname']}}-pv"
    fi
    if [ "${iso['lvname']}" = "" ]; then
      iso['lvname']="${iso['vgname']}}-lv"
    fi
  fi
  if [ "${iso['pvname']}" = "" ]; then
    iso['pvname']="${defaults['pvname']}"
  fi
  if [ "${iso['lvname']}" = "" ]; then
    iso['lvname']="${defaults['lvname']}"
  fi
  if [ "${iso['diskname']}" = "" ]; then
    iso['diskname']="${defaults['diskname']}"
  fi
  if [ "${iso['installusername']}" = "" ]; then
    iso['installusername']="${defaults['installusername']}"
  fi
  if [ "${iso['installpassword']}" = "" ]; then
    iso['installpassword']="${defaults['installpassword']}"
  fi
  if [ "${iso['pesize']}" = "" ]; then
    iso['pesize']="${defaults['pesize']}"
  fi
  if [ "${iso['bootsize']}" = "" ]; then
    iso['bootsize']="${defaults['bootsize']}"
  fi
  if [ "${iso['rootsize']}" = "" ]; then
    iso['rootsize']="${defaults['rootsize']}"
  fi
  if [ "${iso['selinux']}" = "" ]; then
    iso['selinux']="${defaults['selinux']}"
  fi
  if [ "${iso['installsource']}" = "" ]; then
    iso['installsource']="${defaults['installsource']}"
  fi
  if [ "${iso['groups']}" = "" ]; then
    iso['groups']="${defaults['groups']}"
  fi
  if [ "${iso['gecos']}" = "" ]; then
    iso['gecos']="${defaults['gecos']}"
  fi
  if [ "${iso['enableservice']}" = "" ]; then
    iso['enableservice']="${defaults['enableservice']}"
  fi
  if [ "${iso['disableservice']}" = "" ]; then
    iso['disableservice']="${defaults['disableservice']}"
  fi
  if [ "${iso['onboot']}" = "" ]; then
    iso['onboot']="${defaults['onboot']}"
  fi
  if [ "${iso['allowservice']}" = "" ]; then
    iso['allowservice']="${defaults['allowservice']}"
  fi
  if [ "${iso['firewall']}" = "" ]; then
    iso['firewall']="${defaults['firewall']}"
  fi
  if [ "${iso['selinux']}" = "" ]; then
    iso['selinux']="${defaults['selinux']}"
  fi
  if [ "${iso['bootloader']}" = "" ]; then
    iso['bootloader']="${defaults['bootloader']}"
  fi
  if [ "${iso['passwordalgorithm']}" = "" ]; then
    iso['passwordalgorithm']="${defaults['passwordalgorithm']}"
  fi
  if [ "${iso['installmode']}" = "" ]; then
    iso['installmode']="${defaults['installmode']}"
  fi
  if [ "${options['autoinstall']}" = "true" ]; then
    if [ ! -f "${iso['autoinstallfile']}" ]; then
      if [ ! -f "/.dockerenv" ]; then
        echo "File ${iso['autoinstallfile']} does not exist"
        exit
      fi
    fi
  fi
  if [ "${iso['sourceid']}" = "" ]; then
    iso['sourceid']="${defaults['sourceid']}"
  fi
  if [ "${iso['oeminstall']}" = "" ]; then
    iso['oeminstall']="${defaults['oeminstall']}"
  fi
  if [ "${iso['zfs_filesystems']}" = "" ]; then
    iso['zfs_filesystems']="${defaults['zfs_filesystems']}"
  fi
  if [ "${iso['search']}" = "" ]; then
    iso['search']="${defaults['search']}"
  fi
  if [ "${iso['blocklist']}" = "" ]; then
    iso['blocklist']="${defaults['blocklist']}"
  fi
  if [ "${iso['allowlist']}" = "" ]; then
    iso['allowlist']="${defaults['allowlist']}"
  fi
  if [ "${iso['country']}" = "" ]; then
    iso['country']="${defaults['country']}"
  fi
  if [[ "${iso['serialporta']}" =~ "," ]]; then
      iso['serialporta']=$(echo "${iso['serialporta']}" |cut -f1 -d,)
      iso['serailportb']=$(echo "${iso['serailportb']}" |cut -f2 -d,)
  else
    if [ "${iso['serialporta']}" = "" ]; then
      iso['serialporta']="${defaults['serialporta']}"
      iso['serailportb']="${defaults['serialportb']}"
    fi
  fi
  if [[ "${iso['serialportaddressa']}" =~ "," ]]; then
    iso['serialportaddressa']=$(echo "${iso['serialportaddressa']}" |cut -f1 -d,)
    iso['serialportaddressb']=$(echo "${iso['serialportaddressb']}" |cut -f2 -d,)
  else
    if [ "${iso['serialportaddressa']}" = "" ]; then
      iso['serialportaddressa']="${defaults['serialportaddressa']}"
      iso['serialportaddressb']="${defaults['serialaddressb']}"
    fi
  fi
  if [ "${iso['serialportspeeda']}" = "" ]; then
    iso['serialportspeeda']=$(echo "${defaults['serialportspeeda']}" |cut -f1 -d,)
    iso['serialportspeedb']=$(echo "${defaults['serialportspeedb']}" |cut -f2 -d,)
  else
    if [ "${iso['serialportspeeda']}" = "" ]; then
      iso['serialportspeeda']="${defaults['serialportspeeda']}"
      iso['serialportspeedb']="${defaults['serialportspeedb']}"
    fi
  fi
  if [ "${iso['arch']}" = "" ]; then
    iso['arch']="${defaults['arch']}"
    iso['dockerarch']="${defaults['dockerarch']}"
  else
    iso['dockerarch']="${iso['arch']}"
  fi
  if [ "${iso['boottype']}" = "" ]; then
    iso['boottype']="${defaults['boottype']}"
  fi
  if [ "${iso['sshkeyfile']}" = "" ]; then
    iso['sshkeyfile']="${defaults['sshkeyfile']}"
  else
    iso['sshkey']="${defaults['sshkey']}"
  fi
  if [ "${iso['bootserverip']}" = "" ]; then
    iso['bootserverip']="${defaults['bootserverip']}"
  fi
  if [ "${iso['bootserverfile']}" = "" ]; then
    iso['bootserverfile']="${defaults['bootserverfile']}"
  fi
  if [ "${iso['bmcusername']}" = "" ]; then
    iso['bmcusername']="${defaults['bmcusername']}"
  fi
  if [ "${iso['bmcpassword']}" = "" ]; then
    iso['bmcpassword']="${defaults['bmcpassword']}"
  fi
  if [ "${iso['bmcip']}" = "" ]; then
    iso['bmcip']="${defaults['bmcip']}"
  fi
  if [ "${iso['cidr']}" = "" ]; then
    iso['cidr']="${defaults['cidr']}"
  fi
  if [ "${iso['codename']}" = "" ]; then
    iso['codename']="${defaults['codename']}"
  fi
  if [ "${iso['osname']}" = "" ]; then
    iso['osname']="${defaults['osname']}"
  fi
  if [ "${iso['release']}" = "" ]; then
    iso['release']="${defaults['release']}"
  else
    iso['minorrelease']=$( echo "${iso['release']}" |cut -f2 -d. )
    options['dotrelease']=$( echo "${iso['release']}" |cut -f3 -d. )
    if [ "${iso['osname']}" = "ubuntu" ]; then
      if [ "${options['dotrelease']}" = "" ]; then
        get_current_release
      fi
    else
      if [ "${iso['osname']}" = "rocky" ]; then
        case "${iso['release']}" in
          "9")
            iso['release']="${current['release']}_9"
            ;;
          *)
            iso['release']="${current['release']}"
            ;;
        esac
      fi
    fi
  fi
  if [ "${old['release']}" = "" ]; then
    old['release']="${current['oldrelease']}"
  fi
  get_release_info
  if [ "${iso['codename']}" = "" ]; then
    get_code_name
  fi
  if [ "${iso['username']}" = "" ]; then
    iso['username']="${defaults['username']}"
  fi
  if [ "${iso['realname']}" = "" ]; then
    iso['realname']="${defaults['realname']}"
  fi
  if [ "${iso['hostname']}" = "" ]; then
    iso['hostname']="${defaults['hostname']}"
  fi
  if [ "${iso['gateway']}" = "" ]; then
    iso['gateway']="${defaults['gateway']}"
  fi
  if [ "${iso['dns']}" = "" ]; then
    iso['dns']="${defaults['dns']}"
  fi
  if [ "${iso['ip']}" = "" ]; then
    iso['bootproto']="dhcp"
    options['dhcp']="true"
  else
    options['dhcp']="false"
    iso['bootproto']="static"
  fi
  if [ "${iso['allowpassword']}" = "" ]; then
    iso['allowpassword']="${defaults['allowpassword']}"
  fi
  if [ "${iso['password']}" = "" ]; then
    iso['password']="${defaults['password']}"
  fi
  if [ "${iso['chrootpackages']}" = "" ]; then
    iso['chrootpackages']="${defaults['packages']}"
  fi
  if [ "${iso['packages']}" = "" ]; then
    iso['packages']="${defaults['packages']}"
  fi
  if [ "${iso['timezone']}" = "" ]; then
    iso['timezone']="${defaults['timezone']}"
  fi
  if [ "${iso['outputfile']}" = "" ]; then
    iso['outputfile']="${defaults['outputfile']}"
  fi
  if [ "${iso['outputci']}" = "" ]; then
    iso['outputci']="${defaults['outputci']}"
  fi
  if [ "${iso['nic']}" = "" ]; then
    iso['nic']="${defaults['nic']}"
  fi
  if [ "${iso['swapsize']}" = "" ]; then
    iso['swapsize']="${defaults['swapsize']}"
  fi
  if [ "${iso['disk']}" = "" ]; then
    iso['disk']="${defaults['disk']}"
  fi
  if [ "${iso['boottype']}" = "bios" ]; then
    if [[ "${iso['options']}" =~ "fs" ]]; then
      defaults['volumemanager']="lvm zfs xfs btrfs"
    else
      defaults['volumemanager']="lvm"
    fi
  fi
  if [ "${options['autoinstall']}" = "true" ]; then
    defaults['volumemanager']="custom ${defaults['volumemanager']}"
  fi
  reset_volmgrs
  if [ "${iso['grubmenu']}" = "" ]; then
    iso['grubmenu']="${defaults['grubmenu']}"
  fi
  if [ "${iso['grubtimeout']}" = "" ]; then
    iso['grubtimeout']="${defaults['grubtimeout']}"
  fi
  if [ "${iso['kernelargs']}" = "" ]; then
    iso['kernelargs']="${defaults['kernelargs']}"
  fi
  if [ "${iso['kernel']}" = "" ]; then
    if [ "${options['createisovm']}" = "true" ]; then
      iso['kernel']="${defaults['vmtype']}"
    else
      iso['kernel']="${defaults['kernel']}"
    fi
  fi
  if [[ "${iso['action']}" =~ "iso" ]]; then
    if [ "${iso['codename']}" = "" ]; then
      get_code_name
    fi
  fi
  if [ "${iso['locale']}" = "" ]; then
    iso['locale']="${defaults['locale']}"
  fi
  if [ "${iso['lcall']}" = "" ]; then
    iso['lcall']="${defaults['lcall']}"
  fi
  if [ "${iso['layout']}" = "" ]; then
    iso['layout']="${defaults['layout']}"
  fi
  if [ "${iso['installmount']}" = "" ]; then
    iso['installmount']="${defaults['installmount']}"
  fi
  if [ "${iso['targetmount']}" = "" ]; then
    iso['targetmount']="${defaults['targetmount']}"
  fi
  if [ "${iso['autoinstalldir']}" = "" ]; then
    iso['autoinstalldir']="${defaults['autoinstalldir']}"
  fi
  if [ "${iso['build']}" = "" ]; then
    iso['build']="${defaults['build']}"
  fi
  iso['workdir']="$HOME/${script['name']}/${iso['osname']}/${iso['build']}/${iso['release']}"
  docker['workdir']="/root/${script['name']}/${iso['osname']}/${iso['build']}/${iso['release']}"
  if [ "${iso['volid']}" = "" ]; then
    case ${iso['build']} in
      "daily-desktop"|"desktop")
        iso['volid']="${iso['realname']} ${iso['release']} Desktop"
        ;;
      *)
        iso['volid']="${iso['realname']} ${iso['release']} Server"
        ;;
    esac
  fi
  if [ "${iso['inputfile']}" = "" ]; then
    iso['inputfile']="${defaults['inputfile']}"
  fi
  if [ "${iso['inputci']}" = "" ]; then
    iso['inputci']="${defaults['inputci']}"
  fi
  if [ "${options['query']}" = "true" ]; then
    get_info_from_iso
  else
    if [ "${options['bootserverfile']}" = "false" ]; then
      if [ "${iso['osname']}" = "ubuntu" ]; then
        case ${iso['build']} in
          "daily-live"|"daily-live-server")
            iso['inputfile']="${iso['workdir']}/files/${iso['codename']}-live-server-${iso['arch']}.iso"
            iso['outputfile']="${iso['workdir']}/files/${iso['codename']}-live-server-${iso['arch']}-${iso['boottype']}-autoinstall.iso"
            iso['inputci']="${iso['workdir']}/files/${iso['codename']}-server-cloudimg-${iso['arch']}.img"
            iso['outputci']="${iso['workdir']}/files/${iso['codename']}-server-cloudimg-${iso['arch']}.img"
            iso['bootserverfile']="${iso['outputfile']}"
            ;;
          "daily-desktop")
            iso['inputfile']="${iso['workdir']}/files/${iso['codename']}-desktop-${iso['arch']}.iso"
            iso['outputfile']="${iso['workdir']}/files/${iso['codename']}-desktop-${iso['arch']}-${iso['boottype']}-autoinstall.iso"
            iso['bootserverfile']="${iso['outputfile']}"
            ;;
         "desktop")
            iso['inputfile']="${iso['workdir']}/files/${iso['osname']}-${iso['release']}-desktop-${iso['arch']}.iso"
            iso['outputfile']="${iso['workdir']}/files/${iso['osname']}-${iso['release']}-desktop-${iso['arch']}-${iso['boottype']}-autoinstall.iso"
            iso['bootserverfile']="${iso['outputfile']}"
            ;;
          *)
            iso['inputfile']="${iso['workdir']}/files/${iso['osname']}-${iso['release']}-live-server-${iso['arch']}.iso"
            iso['outputfile']="${iso['workdir']}/files/${iso['osname']}-${iso['release']}-live-server-${iso['arch']}-${iso['boottype']}-autoinstall.iso"
            iso['bootserverfile']="${iso['outputfile']}"
            ;;
        esac
      else
        case ${iso['build']} in
          *)
            iso['inputfile']="${iso['workdir']}/files/${iso['realname']}-${iso['release']}-${iso['arch']}-${iso['build']}.iso"
            iso['outputfile']="${iso['workdir']}/files/${iso['realname']}-${iso['release']}-${iso['arch']}-${iso['boottype']}-${iso['build']}-kickstart.iso"
            iso['inputci']="${iso['workdir']}/files/ubuntu-${iso['release']}-server-cloudimg-${iso['arch']}.img"
            iso['outputci']="${iso['workdir']}/files/ubuntu-${iso['release']}-server-cloudimg-${iso['arch']}.img"
            iso['bootserverfile']="${iso['outputfile']}"
          ;;
        esac
      fi
    fi
  fi
  if [ "${iso['squashfsfile']}" = "" ]; then
    iso['squashfsfile']="${defaults['squashfsfile']}"
  fi
  if [ "${iso['grubfile']}" = "" ]; then
    iso['grubfile']="${defaults['grubfile']}"
  fi
  if [ "${options['biosdevname']}" = "true" ]; then
    iso['kernelargs']="${iso['kernelargs']} net.ifnames=0 biosdevname=0"
  fi
  if [ "${old['inputfile']}" = "" ]; then
    old['inputfile']="${defaults['oldinputfile']}"
  fi
  if [ "${vm['ram']}" = "" ]; then
    vm['ram']="${defaults['vmram']}"
  fi
  if [ ! "${iso['netmask']}" = "" ]; then
    if [ "${iso['cidr']}" = "" ]; then
      get_cidr_from_netmask "${iso['netmask']}"
    fi
  fi
  if [ ! "${iso['cidr']}" = "" ]; then
    if [ "${iso['netmask']}" = "" ]; then
      get_netmask_from_cidr "${iso['cidr']}"
    fi
  fi
  if [ "${iso['volumemanager']}" = "" ]; then
    iso['volumemanager']="${defaults['volumemanager']}"
  fi
  if [[ "${iso['volumemanager']}" =~ "fs" ]] || [[ "${iso['volumemanager']}" =~ "custom" ]]; then
    options['chroot']="true"
    options['unpacksquashfs']="true"
    options['earlypackages']="true"
    options['latepackages']="true"
  else
    options['chroot']="false"
    options['unpacksquashfs']="false"
    options['earlypackages']="false"
    options['latepackages']="false"
  fi
}
