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
    DO_REFRESH_INSTALLER="true"
  fi
  if [[ "$ISO_OPTIONS" =~ "norefreshinstaller" ]]; then
    DO_REFRESH_INSTALLER="false"
  fi
  if [[ "$ISO_OPTIONS" =~ "debug" ]]; then
    DO_DEBUG="true"
  fi
  if [[ "$ISO_OPTIONS" =~ "nodebug" ]]; then
    DO_DEBUG="false"
  fi
  if [[ "$ISO_OPTIONS" =~ "strict" ]]; then
    DO_STRICT="true"
  fi
  if [[ "$ISO_OPTIONS" =~ "nostrict" ]]; then
    DO_STRICT="false"
  fi
  if [[ "$ISO_OPTIONS" =~ "compress" ]]; then
    DO_ISO_COMPRESSION="true"
  fi
  if [[ "$ISO_OPTIONS" =~ "nocompress" ]]; then
    DO_ISO_COMPRESSION="false"
  fi
  if [[ "$ISO_OPTIONS" =~ "nvme" ]]; then
    DO_NVME="true"
  fi
  if [[ "$ISO_OPTIONS" =~ "nonvme" ]]; then
    DO_NVME="false"
  fi
  if [[ "$ISO_OPTIONS" =~ "chroot" ]]; then
    DO_CHROOT="true"
  fi
  if [[ "$ISO_OPTIONS" =~ "nochroot" ]]; then
    DO_CHROOT="false"
  fi
  if [[ "$ISO_OPTIONS" =~ "geoip" ]]; then
    DO_GEOIP="true"
  fi
  if [[ "$ISO_OPTIONS" =~ "nogeoip" ]]; then
    DO_GEOIP="false"
  fi
  if [[ "$ISO_OPTIONS" =~ "reorderuefi" ]]; then
    DO_REORDER_UEFI="true"
  fi
  if [[ "$ISO_OPTIONS" =~ "noreorderuefi" ]]; then
    DO_REORDER_UEFI="false"
  fi
  if [[ "$ISO_OPTIONS" =~ "nosecure" ]]; then
    DO_SECURE_BOOT="false"
  fi
  if [[ "$ISO_OPTIONS" =~ "noiso" ]]; then
    DO_CREATE_ISO="false"
  fi
  if [[ "$ISO_OPTIONS" =~ "firstboot" ]]; then
    DO_ISO_FIRSTBOOT="enabled"
  fi
  if [[ "$ISO_OPTIONS" =~ "quiet" ]]; then
    DO_KS_QUIET="true"
  fi
  if [[ "$ISO_OPTIONS" =~ "text" ]]; then
    DO_KS_TEXT="true"
  fi
  if [[ "$ISO_OPTIONS" =~ "user" ]]; then
    DO_INSTALL_USER="true"
  fi
  if [[ "$ISO_OPTIONS" =~ "static" ]]; then
    ISO_BOOT_PROTO="static"
    DO_ISO_DHCP="false"
  fi
  if [[ "$ISO_OPTIONS" =~ "dhcp" ]]; then
    ISO_BOOT_PROTO="dhcp"
    DO_ISO_DHCP="true"
  fi
  if [[ "$ISO_OPTIONS" =~ "mediacheck" ]]; then
    DO_MEDIA_CHECK="true"
  fi
  if [[ "$ISO_OPTIONS" =~ "ks" ]] || [[ "$ISO_OPTIONS" =~ "kick" ]]; then
    if [ "$ISO_ACTION" = "test" ]; then
      DO_KS_TEST="true"
    fi
  fi
  if [[ "$ISO_OPTIONS" =~ "nolockroot" ]]; then
    DO_LOCK_ROOT="false"
  fi
  if [[ "$ISO_OPTIONS" =~ "nodefroute" ]]; then
    DO_DEFROUTE="true"
  fi
  if [[ "$ISO_OPTIONS" =~ "noactivate" ]]; then
    DO_ACTIVATE="false"
  fi
  if [[ "$ISO_OPTIONS" =~ "hwekernel" ]]; then
    DO_HWE_KERNEL="true"
  fi
  if [[ "$ISO_OPTIONS" =~ "nohwekernel" ]]; then
    DO_HWE_KERNEL="false"
  fi
  if [[ "$ISO_OPTIONS" =~ "noipv4" ]]; then
    DO_IPV4="false"
  fi
  if [[ "$ISO_OPTIONS" =~ "noipv6" ]]; then
    DO_IPV6="false"
  fi
  if [[ "$ISO_OPTIONS" =~ "plaintext" ]]; then
    DO_PLAIN_TEXT_PASSWORD="true"
  else
    DO_PLAIN_TEXT_PASSWORD="false"
  fi
  if [[ "$ISO_OPTIONS" =~ "searchdrivers" ]]; then
    DO_ISO_SEARCH_DRIVERS="true"
  fi
  if [[ "$ISO_OPTIONS" =~ "preservesourceslist" ]]; then
    DO_ISO_PRESERVE_SOURCES="true"
  fi
  if [[ "$ISO_OPTIONS" =~ "scp" ]]; then
    DO_SCP_HEADER="true"
  fi
  if [[ "$ISO_OPTIONS" =~ "confdef" ]] || [[ "$ISO_OPTIONS" =~ "confnew" ]]; then
    if [[ "$ISO_OPTIONS" =~ "confdef" ]]; then
      ISO_DPKG_CONF="--force-confdef"
    fi
    if [[ "$ISO_OPTIONS" =~ "confnew" ]]; then
      ISO_DPKG_CONF="--force-confnew"
    fi
  else
    ISO_DPKG_CONF="$DEFAULT_ISO_DPKG_CONF"
  fi
  if [[ "$ISO_OPTIONS" =~ "overwrite" ]]; then
    ISO_DPKG_OVERWRITE="--force-overwrite"
  else
    ISO_DPKG_OVERWRITE="$DEFAULT_ISO_DPKG_OVERWRITE"
  fi
  if [[ "$ISO_OPTIONS" =~ "depends" ]]; then
    ISO_DPKG_DEPENDS="--force-depends"
  else
    ISO_DPKG_DEPENDS="$DEFAULT_ISO_DPKG_DEPENDS"
  fi
  if [[ "$ISO_OPTIONS" =~ "latest" ]]; then
    DO_CHECK_ISO="true"
  fi
  if [[ "$ISO_OPTIONS" =~ "noserial" ]]; then
    DO_SERIAL="false"
  fi
  if [[ "$ISO_OPTIONS" =~ "nomultipath" ]]; then
    DO_NO_MULTIPATH="true"
    if [ "$ISO_BLOCKLIST" = "" ]; then
      ISO_BLOCKLIST="md_multipath"
    else
      ISO_BLOCKLIST="$ISO_BLOCKLIST,md_multipath"
    fi
  fi
  if [[ "$ISO_OPTIONS" =~ "cluster" ]]; then
    DO_CLUSTER_PACKAGES="true"
    DEFAULT_ISO_PACKAGES="$DEFAULT_ISO_PACKAGES pcs pacemaker cockpit cockpit-machines resource-agents-extra resource-agents-common resource-agents-base glusterfs-server"
  fi
  if [[ "$ISO_OPTIONS" =~ "kvm" ]]; then
    DO_CLUSTER_PACKAGES="true"
    DEFAULT_ISO_PACKAGES="$DEFAULT_ISO_PACKAGES cpu-checker qemu-kvm libvirt-daemon-system libvirt-clients bridge-utils virt-manager cloud-image-utils"
  fi
  if [[ "$ISO_OPTIONS" =~ "sshkey" ]]; then
    DO_ISO_SSHKEY="true"
  fi
  if [[ "$ISO_OPTIONS" =~ "nosshkey" ]]; then
    DO_ISO_SSHKEY="false"
  fi
  if [[ "$ISO_OPTIONS" =~ "biosdevname" ]]; then
    ISO_USE_BIOSDEVNAME="true"
  else
    ISO_USE_BIOSDEVNAME="false"
  fi
  if [[ "$ISO_OPTIONS" =~ "nounmount" ]]; then
    DO_NO_UNMOUNT_ISO="true";
  else
    DO_NO_UNMOUNT_ISO="false";
  fi
  if [[ "$ISO_OPTIONS" =~ "testmode" ]]; then
    TEST_MODE="true";
  else
    TEST_MODE="false";
  fi
  if [[ "$ISO_OPTIONS" =~ "efi" ]]; then
    ISO_BOOT_TYPE="efi";
  fi
  if [[ "$ISO_OPTIONS" =~ "bios" ]]; then
    ISO_BOOT_TYPE="bios";
  fi
  if [[ "$ISO_OPTIONS" =~ "verbose" ]]; then
    VERBOSE_MODE="true";
  else
    VERBOSE_MODE="false";
  fi
  if [[ "$ISO_OPTIONS" =~ "autoupgrades" ]]; then
    DO_ISO_AUTO_UPGRADES="true";
  else
    DO_ISO_AUTO_UPGRADES="false";
  fi
  if [[ "$ISO_OPTIONS" =~ "interactive" ]]; then
    INTERACTIVE_MODE="true";
  else
    INTERACTIVE_MODE="false";
  fi
  if [[ "$ISO_OPTIONS" =~ "aptnews" ]]; then
    DO_ISO_APT_NEWS="true";
  else
    DO_ISO_APT_NEWS="false";
  fi
  if [ "$DO_DEBUG" = "true" ]; then
    set -x
  fi
  if [ "$DO_STRICT" = "true" ]; then
    set -eu
  fi
  if [[ "$ISO_OPTIONS" =~ "early" ]]; then
    DO_ISO_EARLY_PACKAGES="true"
  fi
  if [[ "$ISO_OPTIONS" =~ "late" ]]; then
    DO_ISO_LATE_PACKAGES="false"
  fi
}

# Function: get_release_info
#
# Get release information

get_release_info () {
  if [ ! "$ISO_RELEASE" = "" ]; then
    NO_DOTS=$( echo "$ISO_RELEASE" | sed "s/[^.]//g" | awk '{ print length }' )
    set -- $(echo "$ISO_RELEASE" | awk 'BEGIN { FS="[:\t.]"; } {print $1, $2, $3 }' )
    ISO_MAJOR_RELEASE="$1"
    ISO_MINOR_RELEASE="$2"
    if [ "$NO_DOTS" = "2" ]; then
      ISO_DOT_RELEASE="$3"
    else
      ISO_DOT_RELEASE=""
    fi
  fi
}
