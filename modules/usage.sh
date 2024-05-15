#!/usr/bin/env bash

# shellcheck disable=SC2129

# Function: print_usage
#
# Print script usage information

print_actions () {
  cat <<-ACTIONS

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
ACTIONS
}

print_options () {
  cat <<-OPTIONS

  options
  -------

  cluster                 Install cluster related packages (pcs, gluster, etc)  (default: $DO_CLUSTER_PACKAGES)
  kvm                     Install KVM related packages (virt-manager, cloud-image-utils, etc) (deffault: $DO_KVM_PACKAGES)
  sshkey                  Add SSH key from ~/.ssh if present (default $DO_ISO_SSH_KEY)
  biosdevname:            Enable biosdevname kernel parameters (default: $ISO_USE_BIOSDEVNAME)
  nounmount:              Don't unmount filesystems (useful for troubleshooting) (default: $DO_NO_UNMOUNT_ISO)
  testmode:               Don't execute commands (useful for testing and generating a script) (deafault: $TEST_MODE)
  efi:                    Create UEFI based ISO
  bios:                   Create BIOS based ISO
  verbose:                Verbose output (default: $VERBOSE_MODE)
  interactive:            Interactively ask questions (default: $INTERACTIVE_MODE)
  autoupgrades:           Allow autoupgrades
  nohwekernel:            Don't install HWE kernel packages (Ubuntu) (deafault: $DO_NO_HWE_KERNEL)
  nomultipath:            Don't load multipath kernel module (default: $DO_NO_MULTIPATH)
  plaintextpassword:      Use plaintext password (default: $DO_PLAIN_TEXT_PASSWORD)
  mediacheck              Do media check (default: $DO_MEDIA_CHECK)
  nolockroot              Don't lock root account
  noactivate              Don't activate network
  noipv4                  Disable IPv4
  noipv6                  Disable IPv6
  plaintext               Plain text password
  nohwekernel             Don't install HWE kernel package
  staticip                Use static IP
  dhcp                    Use DHCP
  nochroot                Don't run chroot script
  chroot                  Run chroot script
OPTIONS
}

print_postinstall () {
  cat <<-POSTINSTALL

  postinstall
  -----------

  distupgrade:            Do distribution upgrade as part of install process
  packages:               Install packages as part of install process
  updates:                Do updates as part of install process
  upgrades:               Do upgrades as part of install process
  all:                    Do all updates as part of install process
POSTINSTALL
}

print_examples () {
  cat <<-EXAMPLES
  
  Examples
  --------

  Create an ISO with a static IP configuration:

  ${0##*/} --action createiso --options verbose --ip 192.168.1.211 --cidr 24 --dns 8.8.8.8 --gateway 192.168.1.254
EXAMPLES
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
