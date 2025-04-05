#!/usr/bin/env bash

# shellcheck disable=SC2034
# shellcheck disable=SC2046
# shellcheck disable=SC2129
# shellcheck disable=SC2154

# Function: process_options
#
# Process option switch

process_options () {
  if [[ "${iso['options']}" =~ "zfs" ]]; then
    options_ZFS="true"
  fi
  if [[ "${iso['options']}" =~ "nozfs" ]]; then
    options_ZFS="false"
  fi
  if [[ "${iso['options']}" =~ "zfsf" ]]; then
    options['zfs_filesystems']="true"
  fi
  if [[ "${iso['options']}" =~ "nozfsf" ]]; then
    options['zfs_filesystems']="false"
  fi
  if [[ "${iso['options']}" =~ "refreshinstaller" ]]; then
    options['refreshinstaller']="true"
  fi
  if [[ "${iso['options']}" =~ "norefreshinstaller" ]]; then
    options['refreshinstaller']="false"
  fi
  if [[ "${iso['options']}" =~ "debug" ]]; then
    options['debug']="true"
  fi
  if [[ "${iso['options']}" =~ "nodebug" ]]; then
    options['debug']="false"
  fi
  if [[ "${iso['options']}" =~ "strict" ]]; then
    options['strict']="true"
  fi
  if [[ "${iso['options']}" =~ "nostrict" ]]; then
    options['strict']="false"
  fi
  if [[ "${iso['options']}" =~ "compress" ]]; then
    options['compression']="true"
  fi
  if [[ "${iso['options']}" =~ "nocompress" ]]; then
    options['compression']="false"
  fi
  if [[ "${iso['options']}" =~ "nvme" ]]; then
    options['nvme']="true"
  fi
  if [[ "${iso['options']}" =~ "nonvme" ]]; then
    options['nvme']="false"
  fi
  if [[ "${iso['options']}" =~ "chroot" ]]; then
    options['chroot']="true"
  fi
  if [[ "${iso['options']}" =~ "nochroot" ]]; then
    options['chroot']="false"
  fi
  if [[ "${iso['options']}" =~ "geoip" ]]; then
    options['geoip']="true"
  fi
  if [[ "${iso['options']}" =~ "nogeoip" ]]; then
    options['geoip']="false"
  fi
  if [[ "${iso['options']}" =~ "reorderuefi" ]]; then
    options['reorderuefi']="true"
  fi
  if [[ "${iso['options']}" =~ "noreorderuefi" ]]; then
    options['reorderuefi']="false"
  fi
  if [[ "${iso['options']}" =~ "nosecure" ]]; then
    options['secureboot']="false"
  fi
  if [[ "${iso['options']}" =~ "noiso" ]]; then
    options['createiso']="false"
  fi
  if [[ "${iso['options']}" =~ "firstboot" ]]; then
    options['firstboot']="enabled"
  fi
  if [[ "${iso['options']}" =~ "quiet" ]]; then
    options['ksquiet']="true"
  fi
  if [[ "${iso['options']}" =~ "text" ]]; then
    options['kstext']="true"
  fi
  if [[ "${iso['options']}" =~ "user" ]]; then
    options['installuser']="true"
  fi
  if [[ "${iso['options']}" =~ "static" ]]; then
    iso['bootproto']="static"
    options['dhcp']="false"
  fi
  if [[ "${iso['options']}" =~ "dhcp" ]]; then
    iso['bootproto']="dhcp"
    options['dhcp']="true"
  fi
  if [[ "${iso['options']}" =~ "mediacheck" ]]; then
    options['mediacheck']="true"
  fi
  if [[ "${iso['options']}" =~ "ks" ]] || [[ "${iso['options']}" =~ "kick" ]]; then
    if [ "${iso['action']}" = "test" ]; then
      options['kstest']="true"
    fi
  fi
  if [[ "${iso['options']}" =~ "nolockroot" ]]; then
    options['lockroot']="false"
  fi
  if [[ "${iso['options']}" =~ "nodef" ]]; then
    options['defaultroute']="true"
  fi
  if [[ "${iso['options']}" =~ "noactivate" ]]; then
    options['activate']="false"
  fi
  if [[ "${iso['options']}" =~ "hwekernel" ]]; then
    options['hwekernel']="true"
  fi
  if [[ "${iso['options']}" =~ "nohwekernel" ]]; then
    options['hwekernel']="false"
  fi
  if [[ "${iso['options']}" =~ "noipv4" ]]; then
    options['ipv4']="false"
  fi
  if [[ "${iso['options']}" =~ "noipv6" ]]; then
    options['ipv6']="false"
  fi
  if [[ "${iso['options']}" =~ "plaintext" ]]; then
    options['plaintextpassword']="true"
  else
    options['plaintextpassword']="false"
  fi
  if [[ "${iso['options']}" =~ "searchdrivers" ]]; then
    options['searchdrivers']="true"
  fi
  if [[ "${iso['options']}" =~ "preservesourceslist" ]]; then
    options['preservesources']="true"
  fi
  if [[ "${iso['options']}" =~ "scp" ]]; then
    options['scpheader']="true"
  fi
  if [[ "${iso['options']}" =~ "confdef" ]] || [[ "${iso['options']}" =~ "confnew" ]]; then
    if [[ "${iso['options']}" =~ "confdef" ]]; then
      iso['dpkgconf']="--force-confdef"
    fi
    if [[ "${iso['options']}" =~ "confnew" ]]; then
      iso['dpkgconf']="--force-confnew"
    fi
  else
    iso['dpkgconf']="${defaults['dpkgconf']}"
  fi
  if [[ "${iso['options']}" =~ "overwrite" ]]; then
    iso['dpkgoverwrite']="--force-overwrite"
  else
    iso['dpkgoverwrite']="${defaults['dpkgoverwrite']}"
  fi
  if [[ "${iso['options']}" =~ "depends" ]]; then
    iso['dpkgdepends']="--force-depends"
  else
    iso['dpkgdepends']="${defaults['dpkgdepends']}"
  fi
  if [[ "${iso['options']}" =~ "latest" ]]; then
    options['latest']="true"
  fi
  if [[ "${iso['options']}" =~ "noserial" ]]; then
    options['serial']="false"
  fi
  if [[ "${iso['options']}" =~ "nomultipath" ]]; then
    options['nomultipath']="true"
    if [ "${iso['blocklist']}" = "" ]; then
      iso['blocklist']="md_multipath"
    else
      iso['blocklist']="${iso['blocklist']},md_multipath"
    fi
  fi
  if [[ "${iso['options']}" =~ "cluster" ]]; then
    options['clusterpackages']="true"
    defaults['packages']="${defaults['packages']} pcs pacemaker cockpit cockpit-iso['machine']}s resource-agents-extra resource-agents-common resource-agents-base glusterfs-server"
  fi
  if [[ "${iso['options']}" =~ "kvm" ]]; then
    options['clusterpackages']="true"
    defaults['packages']="${defaults['packages']} cpu-checker qemu-kvm libvirt-daemon-system libvirt-clients bridge-utils virt-manager cloud-image-utils"
  fi
  if [[ "${iso['options']}" =~ "sshkey" ]]; then
    options['sshkey']="true"
  fi
  if [[ "${iso['options']}" =~ "nosshkey" ]]; then
    options['sshkey']="false"
  fi
  if [[ "${iso['options']}" =~ "biosdevname" ]]; then
    options_BIOSDEVNAME="true"
  else
    options_BIOSDEVNAME="false"
  fi
  if [[ "${iso['options']}" =~ "nounmount" ]]; then
    options['nounmount']="true";
  else
    options['nounmount']="false";
  fi
  if [[ "${iso['options']}" =~ "testmode" ]]; then
    options['testmode']="true";
  else
    options['testmode']="false";
  fi
  if [[ "${iso['options']}" =~ "efi" ]]; then
    iso['boottype']="efi";
  fi
  if [[ "${iso['options']}" =~ "bios" ]]; then
    iso['boottype']="bios";
  fi
  if [[ "${iso['options']}" =~ "verbose" ]]; then
    options['verbose']="true";
  else
    options['verbose']="false";
  fi
  if [[ "${iso['options']}" =~ "autoupgrades" ]]; then
    options['autoupgrade']="true";
  else
    options['autoupgrade']="false";
  fi
  if [[ "${iso['options']}" =~ "interactive" ]]; then
    options['interactivemode']="true";
  else
    options['interactivemode']="false";
  fi
  if [[ "${iso['options']}" =~ "aptnews" ]]; then
    options['aptnews']="true";
  else
    options['aptnews']="false";
  fi
  if [ "${options['debug']}" = "true" ]; then
    set -x
  fi
  if [ "${options['strict']}" = "true" ]; then
    set -eu
  fi
  if [[ "${iso['options']}" =~ "early" ]]; then
    options['earlypackages']="true"
  fi
  if [[ "${iso['options']}" =~ "late" ]]; then
    options['latepackages']="false"
  fi
}

# Function: get_release_info
#
# Get release information

get_release_info () {
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
