#!/usr/bin/env bash

# shellcheck disable=SC2129

# Function: print_usage
#
# Print script usage information

print_actions () {
  cat <<-ISO_ACTIONS

actions
-------

checkracadm:            Check RACADM requirements are installed
runracadm:              Run racadm to deploy image
createexport:           Create export for image (e.g. NFS)
createansible:          Create ansible stanza
runansible:             Run ansible stanza
printenv:               Prints environment
checkdocker:            Check docker config
checkdirs:              Check work directories
getiso:                 Download ISO
justiso:                Just perform the ISO creation steps rather than all steps
checkrequired:          Check required packages
installrequired:        Install required packages
createautoinstall:      Just create autoinstall files
runchrootscript:        Just run chroot script
createiso:              Create ISO
createisoandsquashfs:   Create ISO and squashfs
dockeriso:              Use Docker to create ISO
dockerisoandsquashfs:   Use Docker to create ISO
queryiso:               Query ISO for information
listalliso:             List all ISOs
listiso:                List ISOs
createkvmvm:            Create KVM VM
deletekvmvm:            Delete KVM VM
ISO_ACTIONS
}

print_options () {
  cat <<-ISO_OPTIONS

options
-------

cluster:                Install cluster related packages (pcs, gluster, etc)  (default: $DO_ISO_CLUSTERPACKAGES)
kvm:                    Install KVM related packages (virt-manager, cloud-image-utils, etc) (default: $DO_KVM_PACKAGES)
sshkey:                 Add SSH key from ~/.ssh if present (default $DO_ISO_SSHKEY)
biosdevname:            Enable biosdevname kernel parameters (default: $ISO_BIOSDEVNAME)
nounmount:              Don't unmount filesystems (useful for troubleshooting) (default: $DO_ISO_NOUNMOUNT)
testmode:               Don't execute commands (useful for testing and generating a script) (default: $DO_ISO_TESTMODE)
efi:                    Create UEFI based ISO
bios:                   Create BIOS based ISO
verbose:                Verbose output (default: $DO_ISO_VERBOSEMODE)
interactive:            Interactively ask questions (default: $DO_ISO_INTERACTIVEMODE)
autoupgrades:           Allow autoupgrades
hwekernel:              Don't install HWE kernel packages (Ubuntu) (default: $DO_ISO_HWEKERNEL)
nohwekernel:            Don't install HWE kernel packages
multipath:              Don't load multipath kernel module (default: $DO_MULTIPATH)
nomultipath:            Don't load multipath kernel module
plaintextpassword:      Use plaintext password (default: $DO_ISO_PLAINTEXTPASSWORD)
mediacheck:             Do media check (default: $DO_ISO_MEDIACHECK)
nolockroot:             Don't lock root account
noactivate:             Don't activate network
noipv4:                 Disable IPv4
noipv6:                 Disable IPv6
plaintext:              Plain text password
staticip:               Use static IP
dhcp:                   Use DHCP
nochroot:               Don't run chroot script (default: $DO_ISO_CHROOT)
chroot:                 Run chroot script
refreshinstaller:       Refresh installer (default: $DO_ISO_REFRESHINSTALLER)
norefreshinstaller:     Don't refresh installer
nvme:                   Additional NVMe config (default: $DO_ISO_NVME)
nonvme:                 No additional NVMe config
geoip:                  Use Geo IP (default: $DO_ISO_GEOIP)
nogeoip:                Don't use Geo IP
reorderuefi:            Reorder UEFI devices on reboot (default: $DO_ISO_REORDERUEFI)
noreorderuefi:          Don't reorder UEFI devices on reboot
compression:            Compress filesystem(s) if supported (default: $DO_ISO_COMPRESSION)
nocompression:          Don't compress filesystem(s)
strict:                 Enable -eu shell options (useful for debuging) (default: $DO_ISO_STRICT)
nostrict:               Disable -eu shell options
debug:                  Enable -x shell option (useful for debuging)   (default: $DO_ISO_DEBUG)
nodebug:                Disable -x shell option
ISO_OPTIONS
}

print_postinstall () {
  cat <<-ISO_POSTINSTALL

postinstall
-----------

distupgrade:            Do distribution upgrade as part of install process
packages:               Install packages as part of install process
updates:                Do updates as part of install process
upgrades:               Do upgrades as part of install process
all:                    Do all updates as part of install process
ISO_POSTINSTALL
}

print_examples () {
  cat <<-ISO_EXAMPLES

Examples
--------

Create an ISO with a static IP configuration:

${0##*/} --action createiso --options verbose --ip 192.168.1.211 --cidr 24 --dns 8.8.8.8 --gateway 192.168.1.254
ISO_EXAMPLES
}


# Function: print_all_usage
#
# Print script usage information

print_all_usage () {
  print_actions
  print_options
  print_postinstall
  print_examples
}

# Function: print_usage
#
# Print script usage information

print_usage () {
  case "$1" in
    "actions")
      print_actions
      exit
      ;;
    "options")
      print_options
      exit
      ;;
    "postinstall")
      print_postinstall
      exit
      ;;
    "examples")
      print_examples
      exit
      ;;
    *)
      print_all_usage
      exit
      ;;
  esac
}
