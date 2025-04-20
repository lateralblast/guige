#!/usr/bin/env bash

# shellcheck disable=SC2034
# shellcheck disable=SC2046
# shellcheck disable=SC2129
# shellcheck disable=SC2154

# Function: process_options
#
# Process option switch

process_options () {
  iso['dpkgconf']="${defaults['dpkgconf']}"
  iso['dpkgdepends']="${defaults['dpkgdepends']}"
  if [[ "${iso['options']}" =~ , ]]; then
    option_names=$( echo "${iso['options']}" | sed "s/,/ /g" )
  else
    option_names="${iso['options']}"
  fi
  for option_name in ${option_names}; do
    options[${option_name}]="true"
    case "${option_name}" in
      firstboot)
        options['firstboot']="enabled"
        ;;
      static)
        iso['bootproto']="static"
        options['dhcp']="false"
        ;;
      dhcp)
        iso['bootproto']="dhcp"
        options['dhcp']="true"
        ;;
      confdef)
        iso['dpkgconf']="--force-confdef"
        ;;
      confnew)
        iso['dpkgconf']="--force-confnew"
        ;;
      overwrite)
        iso['dpkgoverwrite']="--force-overwrite"
        ;;
      depends)
        iso['dpkgdepends']="--force-depends"
        ;;
      nomultipath)
        iso['blocklist']="md_multipath"
        if [ "${iso['blocklist']}" = "" ]; then
          iso['blocklist']="md_multipath"
        else
          iso['blocklist']="${iso['blocklist']},md_multipath"
        fi
        ;;
      cluster)
        options['clusterpackages']="true"
        defaults['packages']="${defaults['packages']} pcs pacemaker cockpit cockpit-iso['machine']}s resource-agents-extra resource-agents-common resource-agents-base glusterfs-server"
        ;;
      kvm)
        options['clusterpackages']="true"
        defaults['packages']="${defaults['packages']} cpu-checker qemu-kvm libvirt-daemon-system libvirt-clients bridge-utils virt-manager cloud-image-utils"
        ;;
      efi)
        iso['boottype']="efi";
        ;;
      bios)
        iso['boottype']="bios";
        ;;
      debug)
        set -x
        ;;
      strict)
        set -eu
        ;;
      *)
        if [[ "${option_name}" =~ ^no ]]; then
          inverse_name="${option_name:2}"
          options[${inverse_name}]="false"
          options[${option_name}]="true"
        else
          inverse_name="no${option_name}"
          options[${inverse_name}]="false"
          options[${option_name}]="true"
        fi
        ;;
    esac
  done
  if [[ "${iso['volumemanager']}" =~ fs ]]; then
    options['earlypackages']="true"
    options['latepackages']="true"
  fi
  if [ "${options['verbose']}" = "true" ]; then
    for option_name in "${!options[@]}"; do
      handle_output "Option ${option_name} is set to ${options[${option_name}]}" "TEXT"
    done
  fi
  if [ "${options['grubparseall']}" = "true" ]; then
    for param in ${iso['grubparams']}; do
      grub_param="grub${param}"
      if [ "${iso[${grub_param}]}" = "" ]; then
        iso[${grub_param}]="${iso[${param}]}"
      fi
    done
  fi
}

# Function: get_release_info
#
# Get release information

get_release_info () {
  if [ "${iso['release']}" = "" ]; then
    iso['release']="${defaults['release']}"
  fi
  if [ ! "${iso['release']}" = "" ]; then
    num_dots=$( echo "${iso['release']}" | sed "s/[^.]//g" | awk '{ print length }' )
    set -- $(echo "${iso['release']}" | awk 'BEGIN { FS="[:\t.]"; } {print $1, $2, $3 }' )
    iso['majorrelease']="$1"
    iso['minorrelease']="$2"
    if [ "${num_dots}" = "2" ]; then
      options['dotrelease']="$3"
    else
      options['dotrelease']=""
    fi
  fi
}
