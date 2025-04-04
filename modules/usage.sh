#!/usr/bin/env bash

# shellcheck disable=SC2129
# shellcheck disable=SC2154

# Function: print_usage
#
# Print script usage information

print_actions () {
  cat <<-actions_usage

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
actions_usage
}

print_options () {
  cat <<-options_usage

options
-------

cluster:                Install cluster related packages (pcs, gluster, etc)  (default: ${options['clusterpackages']})
kvm:                    Install KVM related packages (virt-manager, cloud-image-utils, etc) (default: ${options['kvmpackages']})
sshkey:                 Add SSH key from ~/.ssh if present (default ${options['sshkey']})
biosdevname:            Enable biosdevname kernel parameters (default: ${options['biosdevname']})
nounmount:              Don't unmount filesystems (useful for troubleshooting) (default: ${options['nounmount']})
testmode:               Don't execute commands (useful for testing and generating a script) (default: ${options['testmode']})
efi:                    Create UEFI based ISO
bios:                   Create BIOS based ISO
verbose:                Verbose output (default: ${options['verbose']})
interactive:            Interactively ask questions (default: ${options['interactivemode']})
autoupgrades:           Allow autoupgrades
hwekernel:              Don't install HWE kernel packages (Ubuntu) (default: ${options['hwekernel']})
nohwekernel:            Don't install HWE kernel packages
multipath:              Don't load multipath kernel module (default: ${options['multipath']})
nomultipath:            Don't load multipath kernel module
plaintextpassword:      Use plaintext password (default: ${options['plaintextpassword']})
mediacheck:             Do media check (default: ${options['mediacheck']})
nolockroot:             Don't lock root account
noactivate:             Don't activate network
noipv4:                 Disable IPv4
noipv6:                 Disable IPv6
plaintext:              Plain text password
staticip:               Use static IP
dhcp:                   Use DHCP
nochroot:               Don't run chroot script (default: ${options['chroot']})
chroot:                 Run chroot script
refreshinstaller:       Refresh installer (default: ${options['refreshinstaller']})
norefreshinstaller:     Don't refresh installer
nvme:                   Additional NVMe config (default: ${options['nvme']})
nonvme:                 No additional NVMe config
geoip:                  Use Geo IP (default: ${options['geoip']})
nogeoip:                Don't use Geo IP
reorderuefi:            Reorder UEFI devices on reboot (default: ${options['reorderuefi']})
noreorderuefi:          Don't reorder UEFI devices on reboot
compression:            Compress filesystem(s) if supported (default: ${options['compression']})
nocompression:          Don't compress filesystem(s)
strict:                 Enable -eu shell options (useful for debuging) (default: ${options['strict']})
nostrict:               Disable -eu shell options
debug:                  Enable -x shell option (useful for debuging)   (default: ${options['debug']})
nodebug:                Disable -x shell option
options_usage
}

print_postinstall () {
  cat <<-postinstall_usage

postinstall
-----------

distupgrade:            Do distribution upgrade as part of install process
packages:               Install packages as part of install process
updates:                Do updates as part of install process
upgrades:               Do upgrades as part of install process
all:                    Do all updates as part of install process
postinstall_usage
}

print_examples () {
  cat <<-examples

Examples
--------

Create an ISO with a static IP configuration:

${0##*/} --action createiso --options verbose --ip 192.168.1.211 --cidr 24 --dns 8.8.8.8 --gateway 192.168.1.254
examples
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
