#!/usr/bin/env bash

# shellcheck disable=SC2004
# shellcheck disable=SC2034
# shellcheck disable=SC2046
# shellcheck disable=SC2129
# shellcheck disable=SC2154

# Function: set_options_defaults
#
# Set options defaults

set_options_defaults () {
  options['activate']="true"                  # option - Active network
  options['aptnews']="false"                  # option - Enable apt news
  options['autoinstall']="false"              # option - Enable autoinstall
  options['autoupgrade']="false"              # option - Enable auto upgrade
  options['biosdevname']="false"              # option - Use biosdevname
  options['bootserverfile']="false"           # option - Enable bootserver file
  options['bridge']="false"                   # option - Enable bridge
  options['checkci']="false"                  # option - Check cloud-init
  options['checkdocker']="false"              # option - Check docker
  options['checkworkdir']="false"             # option - Check work directory
  options['chroot']="true"                    # option - Do chroot
  options['clean']="false"                    # option - Clean up old files
  options['clusterpackages']="false"          # option - Enable cluster packages
  options['compression']="true"               # option - Enable compression
  options['createautoinstall']="false"        # option - Create autoinstall files
  options['createansible']="false"            # option - Create ansible
  options['createexport']="false"             # option - Create export
  options['createisovm']="false"              # option - Create ISO based VM
  options['checkracadm']="false"              # option - Create racadm config
  options['createcivm']="false"               # option - Create cloud-init base VM
  options['createiso']="true"                 # option - Create ISO
  options['createvm']="false"                 # option - Create VM
  options['daily']="false"                    # option - Build daily ISO
  options['debug']="false"                    # option - Enable debug flag
  options['defaultroute']="true"              # option - Enable default route
  options['deletecivm']="false"               # option - Delete cloud-init based VM
  options['deleteisovm']="false"              # option - Delete ISO base VM
  options['deletevm']="false"                 # option - Delete VM
  options['dhcp']="true"                      # option - Enable DHCP
  options['distupgrade']="false"              # option - Enable dist-upgrade
  options['docker']="false"                   # option - Use docker
  options['earlypackages']="false"            # option - Enable early packages
  options['executeracadm']="false"            # option - Execute racadm cofngi
  options['firstboot']="disabled"             # option - Enable first boot
  options['force']="false"                    # option - Force actions
  options['forceall']="false"                 # option - Force all actions
  options['fulliso']="false"                  # option - Perfom all ISO functions
  options['geoip']="true"                     # option - Enable GeoIP
  options['getiso']="false"                   # option - Get ISO
  options['grubfile']="false"                 # option - Create GRUB file
  options['grubparse']="false"                # option - Enable GRUB parser
  options['grubparseall']="false"             # option - Enable all GRUB parsers
  options['help']="true"                      # option - Enable help
  options['hwekernel']="true"                 # option - Enable HWE kernel
  options['installcodecs']="false"            # option - Install codecs
  options['installdrivers']="false"           # option - Install drivers
  options['installpackages']="false"          # option - Install packages
  options['installrequiredpackages']="false"  # option - Install required packages
  options['installserver']="false"            # option - Install server
  options['installuser']="false"              # option - Enable install user
  options['interactivemode']="false"          # option - Run in interactive mode
  options['ipv4']="true"                      # option - Emable IPv4
  options['ipv6']="true"                      # option - Enable IPv6
  options['isolinuxfile']="false"             # option - Create isolinux file
  options['justiso']="false"                  # option - Create ISO only
  options['ksquiet']="false"                  # option - Enable Kickstart quiet mode
  options['kstest']="false"                   # option - Perform Kickstart validation
  options['kstext']="false"                   # option - Enable kickstart text mode
  options['kvmpackages']="false"              # option - Enable KVM packages
  options['latepackages']="false"             # option - Enable late packages
  options['latest']="false"                   # option - Enable latest
  options['listisos']="false"                 # option - List ISOS
  options['listvms']="false"                  # option - List VMs
  options['lockpassword']="false"             # option - Lock password
  options['lockroot']="true"                  # option - Lock root
  options['mediacheck']="false"               # option - Enable media check
  options['multipath']="false"                # option - Enable multipath
  options['networkupdates']="false"           # option - Enable network based updates
  options['nomultipath']="false"              # option - Enable no multipath
  options['nounmount']="false"                # option - Do not unmount ISOs etc after creating ISO
  options['nvme']="false"                     # option - Enable NVMe
  options['oldinstaller']="false"             # option - Enable old installer
  options['packageupdates']="false"           # option - Enable package updates
  options['packageupgrades']="false"          # option - Enable package upgrades
  options['plaintextpassword']="false"        # option - Enable plain text passwords
  options['preservesources']="false"          # option - Preserve sources  
  options['printdockerconfig']="false"        # option - Print Docker config
  options['printdockerenv']="false"           # option - Print Docker environment 
  options['printenv']="false"                 # option - Print environment
  options['query']="false"                    # option - Enable query
  options['refreshinstaller']="false"         # option - Refresh installer
  options['reorderuefi']="false"              # option - Re-order UEFI
  options['runchrootscript']="false"          # option - Run chroot script
  options['scpheader']="false"                # option - Enable SCP header
  options['searchdrivers']="false"            # option - Enable search drivers
  options['secureboot']="true"                # option - Enable secure boot
  options['serial']="true"                    # option - Enable serial
  options['sshkey']="true"                    # option - Enable SSH key
  options['strict']="false"                   # option - Enable strict mode
  options['testmode']="false"                 # option - Enable test mode
  options['unmount']="true"                   # option - Unmount ISO etc after creating ISO
  options['unpacksquashfs']="true"            # option - Unpack squashfs
  options['updatesquashfs']="false"           # option - Update squashfs
  options['verbose']="false"                  # option - Enable verbose mode
  options['zfs']="false"                      # option - Enable ZFS
  options['zfsfilesystems']="false"           # option - Enable XFS datasets
}

# Function: process_options
#
# Process option switch

process_options () {
  iso['dpkgconf']="${defaults['dpkgconf']}"
  iso['dpkgdepends']="${defaults['dpkgdepends']}"
  if [[ "${iso['options']}" =~ , ]]; then
    option_names="${iso['options']//,/ }"
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
  update_output_file_name
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
