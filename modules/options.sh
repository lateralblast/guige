# Function: process_options
#
# Process option switch

process_options () {
  if [[ "$OPTIONS" = "firstboot" ]]; then
    DO_ISO_FIRSTBOOT="enabled"
  fi
  if [[ "$OPTIONS" = "user" ]]; then
    DO_INSTALL_USER="true"
  fi
  if [[ "$OPTIONS" =~ "static" ]]; then
    ISO_BOOT_PROTO="static"
    DO_DHCP="false"
  fi
  if [[ "$OPTIONS" =~ "dhcp" ]]; then
    ISO_BOOT_PROTO="dhcp"
    DO_DHCP="true"
  fi
  if [[ "$OPTIONS" =~ "mediacheck" ]]; then
    DO_MEDIA_CHECK="true"
  fi
  if [[ "$OPTIONS" =~ "ks" ]] || [[ "$OPTIONS" =~ "kick" ]]; then
    if [ "$ACTION" = "test" ]; then
      DO_KS_TEST="true"
    fi
  fi
  if [[ "$OPTIONS" =~ "nolockroot" ]]; then
    DO_LOCK_ROOT="false"
  fi
  if [[ "$OPTIONS" =~ "nodefroute" ]]; then
    DO_DEFROUTE="true"
  fi
  if [[ "$OPTIONS" =~ "noactivate" ]]; then
    DO_ACTIVATE="false"
  fi
  if [[ "$OPTIONS" =~ "nohwekernel" ]]; then
    DO_NO_HWE_KERNEL="true"
  else
    DO_NO_HWE_KERNEL="false"
  fi
  if [[ "$OPTIONS" =~ "noipv4" ]]; then
    DO_IPV4="false"
  fi
  if [[ "$OPTIONS" =~ "noipv6" ]]; then
    DO_IPV6="false"
  fi
  if [[ "$OPTIONS" =~ "plaintext" ]]; then
    DO_PLAIN_TEXT_PASSWORD="true"
  else
    DO_PLAIN_TEXT_PASSWORD="false"
  fi
  if [[ "$OPTIONS" =~ "searchdrivers" ]]; then
    DO_ISO_SEARCH_DRIVERS="true"
  fi
  if [[ "$OPTIONS" =~ "preservesourceslist" ]]; then
    DO_ISO_PRESERVE_SOURCES="true"
  fi
  if [[ "$OPTIONS" =~ "scp" ]]; then
    DO_SCP_HEADER="true"
  fi
  if [[ "$OPTIONS" =~ "confdef" ]] || [[ "$OPTIONS" =~ "confnew" ]]; then
    if [[ "$OPTIONS" =~ "confdef" ]]; then
      ISO_DPKG_CONF="--force-confdef"
    fi
    if [[ "$OPTIONS" =~ "confnew" ]]; then
      ISO_DPKG_CONF="--force-confnew"
    fi
  else
    ISO_DPKG_CONF="$DEFAULT_ISO_DPKG_CONF"
  fi
  if [[ "$OPTIONS" =~ "overwrite" ]]; then
    ISO_DPKG_OVERWRITE="--force-overwrite"
  else
    ISO_DPKG_OVERWRITE="$DEFAULT_ISO_DPKG_OVERWRITE"
  fi
  if [[ "$OPTIONS" =~ "depends" ]]; then
    ISO_DPKG_DEPENDS="--force-depends"
  else
    ISO_DPKG_DEPENDS="$DEFAULT_ISO_DPKG_DEPENDS"
  fi
  if [[ "$OPTIONS" =~ "latest" ]]; then
    DO_CHECK_ISO="true"
  fi
  if [[ "$OPTIONS" =~ "noserial" ]]; then
    DO_SERIAL="false"
  fi
  if [[ "$OPTIONS" =~ "nomultipath" ]]; then
    DO_NO_MULTIPATH="true"
    if [ "$ISO_BLOCKLIST" = "" ]; then
      ISO_BLOCKLIST="md_multipath"
    else
      ISO_BLOCKLIST="$ISO_BLOCKLIST,md_multipath"
    fi
  fi
  if [[ "$OPTIONS" =~ "cluster" ]]; then
    DO_CLUSTER_PACKAGES="true"
    DEFAULT_ISO_INSTALL_PACKAGES="$DEFAULT_ISO_INSTALL_PACKAGES pcs pacemaker cockpit cockpit-machines resource-agents-extra resource-agents-common resource-agents-base glusterfs-server"
  fi
  if [[ "$OPTIONS" =~ "kvm" ]]; then
    DO_CLUSTER_PACKAGES="true"
    DEFAULT_ISO_INSTALL_PACKAGES="$DEFAULT_ISO_INSTALL_PACKAGES cpu-checker qemu-kvm libvirt-daemon-system libvirt-clients bridge-utils virt-manager cloud-image-utils"
  fi
  if [[ "$OPTIONS" =~ "sshkey" ]]; then
    DO_ISO_SSH_KEY="true"
  fi
  if [[ "$OPTIONS" =~ "biosdevname" ]]; then
    ISO_USE_BIOSDEVNAME="true"
  else
    ISO_USE_BIOSDEVNAME="false"
  fi
  if [[ "$OPTIONS" =~ "nounmount" ]]; then
    DO_NO_UNMOUNT_ISO="true";
  else
    DO_NO_UNMOUNT_ISO="false";
  fi
  if [[ "$OPTIONS" =~ "testmode" ]]; then
    TEST_MODE="true";
  else
    TEST_MODE="false";
  fi
  if [[ "$OPTIONS" =~ "efi" ]]; then
    ISO_BOOT_TYPE="efi";
  fi
  if [[ "$OPTIONS" =~ "bios" ]]; then
    ISO_BOOT_TYPE="bios";
  fi
  if [[ "$OPTIONS" =~ "verbose" ]]; then
    VERBOSE_MODE="true";
  else
    VERBOSE_MODE="false";
  fi
  if [[ "$OPTIONS" =~ "autoupgrades" ]]; then
    DO_ISO_AUTO_UPGRADES="true";
  else
    DO_ISO_AUTO_UPGRADES="false";
  fi
  if [[ "$OPTIONS" =~ "interactive" ]]; then
    INTERACTIVE_MODE="true";
  else
    INTERACTIVE_MODE="false";
  fi
  if [[ "$OPTIONS" =~ "aptnews" ]]; then
    DO_ISO_APT_NEWS="true";
  else
    DO_ISO_APT_NEWS="false";
  fi
}
