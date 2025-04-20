#!/usr/bin/env bash

# shellcheck disable=SC2034
# shellcheck disable=SC2129
# shellcheck disable=SC2154

# Function: get_switches
#
# Get list of switches

get_switches () {
  switchstart="false"
  while read line; do
    if [[ "${line}" =~ switchstart ]]; then
      switchstart="true"
    fi
    if [[ "${line}" =~ switchend ]] || [[ "${line}" =~ \* ]]; then
      switchstart="false"
    fi
    if [ "${switchstart}" = "true" ]; then
      if [[ "${line}" =~ -- ]] && [[ "${line}" =~ [a-z] ]]; then
        if [[ "${line}" =~ \| ]]; then
          switch_name=$( echo "${line}" |cut -f1 -d "|" )
        else
          switch_name=$( echo "${line}" |cut -f1 -d ")" )
        fi
        switch_name=$( echo "${switch_name}" |sed "s/\-\-//g" )
        switch_name=$( echo "${switch_name}" |sed "s/ //g" )
        switches+=(${switch_name})
      fi
    fi
  done < "${script['file']}"
}

# Function: list_switches
#
# Print a list of switches

list_switches () {
  for switch_name in "${switches[@]}"; do
    echo "${switch_name}"
  done
}

# Function: process_switches
#
# Process switches

process_switches () {
  for switch_name in "${!defaults[@]}"; do
    if [ "${iso[${switch_name}]}" = "" ]; then
      case "${switch_name}" in
        arch)
          iso['arch']="${defaults['arch']}"
          iso['dockerarch']="${defaults['dockerarch']}"
          ;;
        cidr)
          if [ ! "${iso['netmask']}" = "" ]; then
            get_cidr_from_netmask "${iso['netmask']}"
          fi
          ;;
        codename)
          get_code_name
          ;;
        ip)
          iso['bootproto']="dhcp"
          options['dhcp']="true"
          ;;
        netmask)
          if [ ! "${iso['cidr']}" = "" ]; then
            get_netmask_from_cidr "${iso['cidr']}"
          fi
          ;;
        *)
          iso[${switch_name}]="${defaults[${switch_name}]}"
          ;;
      esac
    else
      case "${switch_name}" in
        arch)
          iso['dockerarch']="${iso['arch']}"
          ;; 
        boottype)
          if [ "${iso['boottype']}" = "bios" ]; then
            if [[ "${iso['options']}" =~ "fs" ]]; then
              defaults['volumemanager']="lvm zfs xfs btrfs"
            else
              defaults['volumemanager']="lvm"
            fi
          fi
          ;;
        cidr)
          if [ "${iso['netmask']}" = "" ]; then
            get_netmask_from_cidr "${iso['cidr']}"
          fi
          ;;
        ip)
          options['dhcp']="false"
          iso['bootproto']="static"
          ;;
        netmask)
          if [ "${iso['cidr']}" = "" ]; then
            get_cidr_from_netmask "${iso['netmask']}"
          fi
          ;;
        vgname)
          if [ "${iso['pvname']}" = "" ]; then
            iso['pvname']="${iso['vgname']}}-pv"
          fi
          if [ "${iso['lvname']}" = "" ]; then
            iso['lvname']="${iso['vgname']}}-lv"
          fi
          ;;
        "release")
          iso['majorrelease']=$( echo "${iso['release']}" |cut -f1 -d. )
          iso['minorrelease']=$( echo "${iso['release']}" |cut -f2 -d. )
          iso['dotrelease']=$( echo "${iso['release']}" |cut -f3 -d. )
          if [ "${iso['osname']}" = "ubuntu" ]; then
            if [ "${options['dotrelease']}" = "" ]; then
              get_current_release
            fi
          else
            if [ "${iso['osname']}" = "rocky" ]; then
              case "${iso['release']}" in
                "9")
                  iso['release']="${current['release9']}"
                  ;;
                *)
                  iso['release']="${current['release']}"
                  ;;
              esac
            fi
          fi
          ;;
        "serialport")
          if [[ "${iso['serialport']}" =~ , ]]; then
            iso['serialporta']=$(echo "${iso['serialporta']}" |cut -f1 -d,)
            iso['serialportb']=$(echo "${iso['serialportb']}" |cut -f2 -d,)
          else
            iso['serialporta']="${iso['serialport']}"
            iso['serialportb']="${defaults['serialportb']}"
          fi
          ;;
        "serialportaddress")
          if [[ "${iso['serialportaddress']}" =~ , ]]; then
            iso['serialportaddressa']=$(echo "${iso['serialportaddressa']}" |cut -f1 -d,)
            iso['serialportaddressb']=$(echo "${iso['serialportaddressb']}" |cut -f2 -d,)
          else
            iso['serialportaddressa']="${iso['serialportaddress']}"
            iso['serialportaddressb']="${defaults['serialportaddressb']}"
          fi
          ;;
        "serialportspeed")
          if [[ "${iso['serialportspeeda']}" =~ , ]]; then
            iso['serialportspeeda']=$(echo "${defaults['serialportspeeda']}" |cut -f1 -d,)
            iso['serialportspeedb']=$(echo "${defaults['serialportspeedb']}" |cut -f2 -d,)
          else
            iso['serialportspeeda']="${iso['serialportspeed']}"
            iso['serialportspeedb']="${defaults['serialportspeedb']}"
          fi
          ;;
        "volumemanager")
          if [[ "${iso['volumemanager']}" =~ fs ]] || [[ "${iso['volumemanager']}" =~ custom ]]; then
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
          ;;
      esac
    fi
  done
  if [ "${options['autoinstall']}" = "true" ]; then
    if [ ! -f "${iso['autoinstallfile']}" ]; then
      echo "File ${iso['autoinstallfile']} does not exist"
      exit
    fi
  fi
  if [ "${options['autoinstall']}" = "true" ]; then
    defaults['volumemanager']="custom ${defaults['volumemanager']}"
  fi
  reset_volmgrs
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
  iso['workdir']="$HOME/${script['name']}/${iso['osname']}/${iso['build']}/${iso['release']}"
  docker['workdir']="/root/${script['name']}/${iso['osname']}/${iso['build']}/${iso['release']}"
  if [ "${iso['volid']}" = "" ]; then
    case ${iso['build']} in
      "daily-desktop"|"desktop")
        iso['volid']="${iso['releasename']} ${iso['release']} Desktop"
        ;;
      *)
        iso['volid']="${iso['releasename']} ${iso['release']} Server"
        ;;
    esac
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
            if [ "${iso['release']}" = "${current['betarelease']}" ]; then
              iso['inputfile']="${iso['workdir']}/files/${iso['osname']}-${iso['release']}-beta-desktop-${iso['arch']}.iso"
              iso['outputfile']="${iso['workdir']}/files/${iso['osname']}-${iso['release']}-beta-desktop-${iso['arch']}-${iso['boottype']}-autoinstall.iso"
              iso['bootserverfile']="${iso['outputfile']}"
            else
              iso['inputfile']="${iso['workdir']}/files/${iso['osname']}-${iso['release']}-desktop-${iso['arch']}.iso"
              iso['outputfile']="${iso['workdir']}/files/${iso['osname']}-${iso['release']}-desktop-${iso['arch']}-${iso['boottype']}-autoinstall.iso"
              iso['bootserverfile']="${iso['outputfile']}"
            fi
            ;;
          *)
            if [ "${iso['release']}" = "${current['betarelease']}" ]; then
              iso['inputfile']="${iso['workdir']}/files/${iso['osname']}-${iso['release']}-beta-live-server-${iso['arch']}.iso"
              iso['outputfile']="${iso['workdir']}/files/${iso['osname']}-${iso['release']}-beta-live-server-${iso['arch']}-${iso['boottype']}-autoinstall.iso"
              iso['bootserverfile']="${iso['outputfile']}"
            else
              iso['inputfile']="${iso['workdir']}/files/${iso['osname']}-${iso['release']}-live-server-${iso['arch']}.iso"
              iso['outputfile']="${iso['workdir']}/files/${iso['osname']}-${iso['release']}-live-server-${iso['arch']}-${iso['boottype']}-autoinstall.iso"
              iso['bootserverfile']="${iso['outputfile']}"
            fi
            ;;
        esac
      else
        case ${iso['build']} in
          *)
            iso['inputfile']="${iso['workdir']}/files/${iso['releasename']}-${iso['release']}-${iso['arch']}-${iso['build']}.iso"
            iso['outputfile']="${iso['workdir']}/files/${iso['releasename']}-${iso['release']}-${iso['arch']}-${iso['boottype']}-${iso['build']}-kickstart.iso"
            iso['inputci']="${iso['workdir']}/files/ubuntu-${iso['release']}-server-cloudimg-${iso['arch']}.img"
            iso['outputci']="${iso['workdir']}/files/ubuntu-${iso['release']}-server-cloudimg-${iso['arch']}.img"
            iso['bootserverfile']="${iso['outputfile']}"
          ;;
        esac
      fi
    fi
  fi
  if [ "${options['biosdevname']}" = "true" ]; then
    iso['kernelargs']="${iso['kernelargs']} net.ifnames=0 biosdevname=0"
  fi
  if [ "${options['verbose']}" = "true" ]; then
    for param_name in "${!iso[@]}"; do
      handle_output "Parameter ${param_name} is set to ${iso[${param_name}]}" "TEXT"
    done
  fi
}
