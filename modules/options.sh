#!/usr/bin/env bash

# shellcheck disable=SC2129
# shellcheck disable=SC2034

# Function: process_options
#
# Process option switch

process_options () {
  if [[ "$ISO_OPTIONS" =~ "zfs" ]]; then
    DO_ISO_ZFS="true"
  fi
  if [[ "$ISO_OPTIONS" =~ "nozfs" ]]; then
    DO_ISO_ZFS="false"
  fi
  if [[ "$ISO_OPTIONS" =~ "zfsf" ]]; then
    DO_ISO_ZFSFILESYSTEMS="true"
  fi
  if [[ "$ISO_OPTIONS" =~ "nozfsf" ]]; then
    DO_ISO_ZFSFILESYSTEMS="false"
  fi
  if [[ "$ISO_OPTIONS" =~ "refreshinstaller" ]]; then
    DO_ISO_REFRESHINSTALLER="true"
  fi
  if [[ "$ISO_OPTIONS" =~ "norefreshinstaller" ]]; then
    DO_ISO_REFRESHINSTALLER="false"
  fi
  if [[ "$ISO_OPTIONS" =~ "debug" ]]; then
    DO_ISO_DEBUG="true"
  fi
  if [[ "$ISO_OPTIONS" =~ "nodebug" ]]; then
    DO_ISO_DEBUG="false"
  fi
  if [[ "$ISO_OPTIONS" =~ "strict" ]]; then
    DO_ISO_STRICT="true"
  fi
  if [[ "$ISO_OPTIONS" =~ "nostrict" ]]; then
    DO_ISO_STRICT="false"
  fi
  if [[ "$ISO_OPTIONS" =~ "compress" ]]; then
    DO_ISO_COMPRESSION="true"
  fi
  if [[ "$ISO_OPTIONS" =~ "nocompress" ]]; then
    DO_ISO_COMPRESSION="false"
  fi
  if [[ "$ISO_OPTIONS" =~ "nvme" ]]; then
    DO_ISO_NVME="true"
  fi
  if [[ "$ISO_OPTIONS" =~ "nonvme" ]]; then
    DO_ISO_NVME="false"
  fi
  if [[ "$ISO_OPTIONS" =~ "chroot" ]]; then
    DO_ISO_CHROOT="true"
  fi
  if [[ "$ISO_OPTIONS" =~ "nochroot" ]]; then
    DO_ISO_CHROOT="false"
  fi
  if [[ "$ISO_OPTIONS" =~ "geoip" ]]; then
    DO_ISO_GEOIP="true"
  fi
  if [[ "$ISO_OPTIONS" =~ "nogeoip" ]]; then
    DO_ISO_GEOIP="false"
  fi
  if [[ "$ISO_OPTIONS" =~ "reorderuefi" ]]; then
    DO_ISO_REORDERUEFI="true"
  fi
  if [[ "$ISO_OPTIONS" =~ "noreorderuefi" ]]; then
    DO_ISO_REORDERUEFI="false"
  fi
  if [[ "$ISO_OPTIONS" =~ "nosecure" ]]; then
    DO_ISO_SECUREBOOT="false"
  fi
  if [[ "$ISO_OPTIONS" =~ "noiso" ]]; then
    DO_ISO_CREATEISO="false"
  fi
  if [[ "$ISO_OPTIONS" =~ "firstboot" ]]; then
    DO_ISO_FIRSTBOOT="enabled"
  fi
  if [[ "$ISO_OPTIONS" =~ "quiet" ]]; then
    DO_ISO_KSQUIET="true"
  fi
  if [[ "$ISO_OPTIONS" =~ "text" ]]; then
    DO_ISO_KSTEXT="true"
  fi
  if [[ "$ISO_OPTIONS" =~ "user" ]]; then
    DO_ISO_INSTALLUSER="true"
  fi
  if [[ "$ISO_OPTIONS" =~ "static" ]]; then
    ISO_BOOTPROTO="static"
    DO_ISO_DHCP="false"
  fi
  if [[ "$ISO_OPTIONS" =~ "dhcp" ]]; then
    ISO_BOOTPROTO="dhcp"
    DO_ISO_DHCP="true"
  fi
  if [[ "$ISO_OPTIONS" =~ "mediacheck" ]]; then
    DO_ISO_MEDIACHECK="true"
  fi
  if [[ "$ISO_OPTIONS" =~ "ks" ]] || [[ "$ISO_OPTIONS" =~ "kick" ]]; then
    if [ "$ISO_ACTION" = "test" ]; then
      DO_ISO_KSTEST="true"
    fi
  fi
  if [[ "$ISO_OPTIONS" =~ "nolockroot" ]]; then
    DO_ISO_LOCKROOT="false"
  fi
  if [[ "$ISO_OPTIONS" =~ "nodef" ]]; then
    DO_ISO_DEFAULTROUTE="true"
  fi
  if [[ "$ISO_OPTIONS" =~ "noactivate" ]]; then
    DO_ISO_ACTIVATE="false"
  fi
  if [[ "$ISO_OPTIONS" =~ "hwekernel" ]]; then
    DO_ISO_HWEKERNEL="true"
  fi
  if [[ "$ISO_OPTIONS" =~ "nohwekernel" ]]; then
    DO_ISO_HWEKERNEL="false"
  fi
  if [[ "$ISO_OPTIONS" =~ "noipv4" ]]; then
    DO_ISO_IPV4="false"
  fi
  if [[ "$ISO_OPTIONS" =~ "noipv6" ]]; then
    DO_ISO_IPV6="false"
  fi
  if [[ "$ISO_OPTIONS" =~ "plaintext" ]]; then
    DO_ISO_PLAINTEXTPASSWORD="true"
  else
    DO_ISO_PLAINTEXTPASSWORD="false"
  fi
  if [[ "$ISO_OPTIONS" =~ "searchdrivers" ]]; then
    DO_ISO_SEARCHDRIVERS="true"
  fi
  if [[ "$ISO_OPTIONS" =~ "preservesourceslist" ]]; then
    DO_ISO_PRESERVESOURCES="true"
  fi
  if [[ "$ISO_OPTIONS" =~ "scp" ]]; then
    DO_ISO_SCPHEADER="true"
  fi
  if [[ "$ISO_OPTIONS" =~ "confdef" ]] || [[ "$ISO_OPTIONS" =~ "confnew" ]]; then
    if [[ "$ISO_OPTIONS" =~ "confdef" ]]; then
      ISO_ISO_DPKGCONF="--force-confdef"
    fi
    if [[ "$ISO_OPTIONS" =~ "confnew" ]]; then
      ISO_ISO_DPKGCONF="--force-confnew"
    fi
  else
    ISO_ISO_DPKGCONF="$DEFAULT_ISO_ISO_DPKGCONF"
  fi
  if [[ "$ISO_OPTIONS" =~ "overwrite" ]]; then
    ISO_DPKGOVERWRITE="--force-overwrite"
  else
    ISO_DPKGOVERWRITE="$DEFAULT_ISO_DPKGOVERWRITE"
  fi
  if [[ "$ISO_OPTIONS" =~ "depends" ]]; then
    ISO_DPKGDEPENDS="--force-depends"
  else
    ISO_DPKGDEPENDS="$DEFAULT_ISO_DPKGDEPENDS"
  fi
  if [[ "$ISO_OPTIONS" =~ "latest" ]]; then
    DO_ISO_LATEST="true"
  fi
  if [[ "$ISO_OPTIONS" =~ "noserial" ]]; then
    DO_ISO_SERIAL="false"
  fi
  if [[ "$ISO_OPTIONS" =~ "nomultipath" ]]; then
    DO_ISO_NOMULTIPATH="true"
    if [ "$ISO_BLOCKLIST" = "" ]; then
      ISO_BLOCKLIST="md_multipath"
    else
      ISO_BLOCKLIST="$ISO_BLOCKLIST,md_multipath"
    fi
  fi
  if [[ "$ISO_OPTIONS" =~ "cluster" ]]; then
    DO_ISO_CLUSTERPACKAGES="true"
    DEFAULT_ISO_PACKAGES="$DEFAULT_ISO_PACKAGES pcs pacemaker cockpit cockpit-machines resource-agents-extra resource-agents-common resource-agents-base glusterfs-server"
  fi
  if [[ "$ISO_OPTIONS" =~ "kvm" ]]; then
    DO_ISO_CLUSTERPACKAGES="true"
    DEFAULT_ISO_PACKAGES="$DEFAULT_ISO_PACKAGES cpu-checker qemu-kvm libvirt-daemon-system libvirt-clients bridge-utils virt-manager cloud-image-utils"
  fi
  if [[ "$ISO_OPTIONS" =~ "sshkey" ]]; then
    DO_ISO_SSHKEY="true"
  fi
  if [[ "$ISO_OPTIONS" =~ "nosshkey" ]]; then
    DO_ISO_SSHKEY="false"
  fi
  if [[ "$ISO_OPTIONS" =~ "biosdevname" ]]; then
    DO_ISO_BIOSDEVNAME="true"
  else
    DO_ISO_BIOSDEVNAME="false"
  fi
  if [[ "$ISO_OPTIONS" =~ "nounmount" ]]; then
    DO_ISO_NOUNMOUNT="true";
  else
    DO_ISO_NOUNMOUNT="false";
  fi
  if [[ "$ISO_OPTIONS" =~ "testmode" ]]; then
    DO_ISO_TESTMODE="true";
  else
    DO_ISO_TESTMODE="false";
  fi
  if [[ "$ISO_OPTIONS" =~ "efi" ]]; then
    ISO_BOOTTYPE="efi";
  fi
  if [[ "$ISO_OPTIONS" =~ "bios" ]]; then
    ISO_BOOTTYPE="bios";
  fi
  if [[ "$ISO_OPTIONS" =~ "verbose" ]]; then
    DO_ISO_VERBOSEMODE="true";
  else
    DO_ISO_VERBOSEMODE="false";
  fi
  if [[ "$ISO_OPTIONS" =~ "autoupgrades" ]]; then
    DO_ISO_AUTOUPGRADES="true";
  else
    DO_ISO_AUTOUPGRADES="false";
  fi
  if [[ "$ISO_OPTIONS" =~ "interactive" ]]; then
    DO_ISO_INTERACTIVEMODE="true";
  else
    DO_ISO_INTERACTIVEMODE="false";
  fi
  if [[ "$ISO_OPTIONS" =~ "aptnews" ]]; then
    DO_ISO_APTNEWS="true";
  else
    DO_ISO_APTNEWS="false";
  fi
  if [ "$DO_ISO_DEBUG" = "true" ]; then
    set -x
  fi
  if [ "$DO_ISO_STRICT" = "true" ]; then
    set -eu
  fi
  if [[ "$ISO_OPTIONS" =~ "early" ]]; then
    DO_ISO_EARLYPACKAGES="true"
  fi
  if [[ "$ISO_OPTIONS" =~ "late" ]]; then
    DO_ISO_LATEPACKAGES="false"
  fi
}

# Function: get_release_info
#
# Get release information

get_release_info () {
  if [ ! "$ISO_RELEASE" = "" ]; then
    NO_DOTS=$( echo "$ISO_RELEASE" | sed "s/[^.]//g" | awk '{ print length }' )
    set -- $(echo "$ISO_RELEASE" | awk 'BEGIN { FS="[:\t.]"; } {print $1, $2, $3 }' )
    ISO_MAJORRELEASE="$1"
    ISO_MINORRELEASE="$2"
    if [ "$NO_DOTS" = "2" ]; then
      ISO_DOTRELEASE="$3"
    else
      ISO_DOTRELEASE=""
    fi
  fi
}
