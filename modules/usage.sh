# Function: print_usage
#
# Print script usage information

print_usage () {
  cat <<-USAGE

  action
  ------

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

  options
  -------

  cluster                 Install cluster related packages (pcs, gluster, etc)  (default: $DO_CLUSTER_PACKAGES)
  kvm                     Install KVM related packages (virt-manager, cloud-image-utils, etc) (def) ($DO_KVM_PACKAGES)
  sshkey                  Add SSH key from ~/.ssh if present (default $DO_ISO_SSH_KEY)
  biosdevname:            Enable biosdevname kernel parameters (default: $ISO_USE_BIOSDEVNAME)
  nounmount:              Don't unmount filesystems (useful for troubleshooting) (default: $DO_NO_UNMOUNT_ISO)
  testmode:               Don't execute commands (useful for testing and generating a script) (deafault: $TEST_MODE)
  efi:                    Create UEFI based ISO (default $ISO_BOOT_TYPE)
  bios:                   Create BIOS based ISO (default $ISO_BOOT_TYPE)
  verbose:                Verbose output (default: $VERBOSE_MODE)
  interactive:            Interactively ask questions (default: $INTERACTIVE_MODE)
  autoupgrades:           Allow autoupgrades
  nohwekernel:            Don't install HWE kernel packages (Ubuntu) (deafault: $DO_NO_HWE_KERNEL)
  nomultipath:            Don't load multipath kernel module (default: $DO_NO_MULTIPATH)
  plaintextpassword:      Use plaintext password (default: $DO_PLAIN_TEXT_PASSWORD)

  postinstall
  -----------

  distupgrade:            Do distribution upgrade as part of install process
  packages:               Install packages as part of install process
  updates:                Do updates as part of install process
  upgrades:               Do upgrades as part of install process
  all:                    Do all updates as part of install process

  Examples
  --------

  Create an ISO with a static IP configuration:

  ${0##*/} --action createiso --options verbose --ip 192.168.1.211 --cidr 24 --dns 8.8.8.8 --gateway 192.168.1.254

USAGE
  exit
}
