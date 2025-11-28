#!/usr/bin/env bash

# shellcheck disable=SC2004
# shellcheck disable=SC2034
# shellcheck disable=SC2129
# shellcheck disable=SC2154

# Function: get_switches
#
# Get list of switches

get_switches () {
  if [ "${#switches[@]}" -lt 2 ]; then 
    if [ -f "/.dockerenv" ]; then
      input_file="${iso['workdir']}/files/${script['bin']}"
    else
      input_file="${script['file']}"
    fi
    switchstart="false"
    while read -r line; do
      switch_name=""
      if [[ "${line}" =~ -- ]]; then
        switchstart="true"
      fi
      if [[ "${line}" =~ esac ]] || [[ "${line}" =~ \* ]]; then
        switchstart="false"
      fi
      if [ "${switchstart}" = "true" ]; then
        if [[ "${line}" =~ -- ]] && [[ "${line}" =~ [a-z] ]]; then
          if [[ "${line}" =~ \| ]]; then
            switch_name=$( echo "${line}" |cut -f1 -d "|" )
          else
            switch_name=$( echo "${line}" |cut -f1 -d ")" )
          fi
          switch_name="${switch_name//--/}"
          switch_name="${switch_name// /}"
          if [ ! "${switch_name}" = "" ]; then
            switches+=("${switch_name}")
          fi
        fi
      fi
    done < "${input_file}"
  fi
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
  get_switches
  for switch_name in "${switches[@]}"; do
    if [ "${iso[${switch_name}]}" = "" ]; then
      case "${switch_name}" in
        arch)
          iso['arch']="${defaults['arch']}"
          iso['dockerarch']="${defaults['dockerarch']}"
          ;;
        build)
          update_iso_build
          ;;
        codename)
          get_code_name
          ;;
        serialport)
          iso['serialport']="${defaults['serialport']}"
          iso['serialporta']="${defaults['serialporta']}"
          iso['serialportb']="${defaults['serialportb']}"
          ;;
        serialportaddress)
          iso['serialportaddress']="${defaults['serialportaddress']}"
          iso['serialportaddressa']="${defaults['serialportaddressa']}"
          iso['serialportaddressb']="${defaults['serialportaddressb']}"
          ;;
        serialportspeed)
          iso['serialportspeed']="${defaults['serialportspeed']}"
          iso['serialportspeeda']="${defaults['serialportspeeda']}"
          iso['serialportspeedb']="${defaults['serialportspeedb']}"
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
        build)
          update_iso_build
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
  if [ "${iso['workdir']}" = "${defaults['workdir']}" ] || [ "${iso['workdir']}" = "" ]; then
    iso['workdir']="$HOME/Documents/${script['name']}/${iso['osname']}/${iso['build']}/${iso['release']}"
  fi
  if [ "${iso['inputci']}" = "${defaults['inputci']}" ]; then
    get_input_ci
  fi
  if [ "${iso['outputci']}" = "${defaults['outputci']}" ]; then
    get_output_ci
  fi
  if [ "${iso['dockerworkdir']}" = "${defaults['dockerworkdir']}" ] || [ "${iso['dockerworkdir']}" = "" ]; then
    iso['dockerworkdir']="/root/${script['name']}/${iso['osname']}/${iso['build']}/${iso['release']}"
  fi
  if [ "${iso['outputfile']}" = "${defaults['outputfile']}" ]; then
    build_name=${iso['build']//\/-}
    iso['outputfile']="${iso['workdir']}/files/${iso['osname']}-${iso['release']}-${build_name}-${iso['arch']}-${iso['boottype']}-autoinstall.iso"
  fi
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
  if [ "${iso['volid']}" = "" ] || [[ ! "${iso['volid']}" =~ ${iso['release']} ]]; then
    case ${iso['build']} in
      *desktop*)
        iso['volid']="${iso['releasename']} ${iso['release']} ${iso['arch']} Desktop"
        ;;
      *)
        iso['volid']="${iso['releasename']} ${iso['release']} ${iso['arch']} Server"
        ;;
    esac
  fi
  if [ "${options['query']}" = "true" ]; then
    get_info_from_iso
  else
    if [ "${options['bootserverfile']}" = "false" ]; then
      update_iso_url
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
  if [ "${options['serial']}" = "true" ]; then
    if [[ ! "${iso['kernelargs']}" =~ ${iso['kernelserialargs']} ]]; then
      iso['kernelargs']="${iso['kernelargs']} ${iso['kernelserialargs']}"
    fi
  fi
  if [ ! "${iso['ip']}" = "" ] || [ ! "${iso['grubip']}" = "" ]; then 
    options['dhcp']="false"
  fi
  update_output_file_name
}
