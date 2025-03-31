#!/usr/bin/env bash

# shellcheck disable=SC2129
# shellcheck disable=SC2034

# Function: print_env
#
# Print environment

print_env () {
  handle_output "# Setting Variables" TEXT
  handle_output "# Codename:                  [ISO_CODENAME]                   $ISO_CODENAME"         "TEXT"
  handle_output "# Architecture:              [ISO_ARCH]                       $ISO_ARCH"             "TEXT"
  handle_output "# Work directory:            [ISO_WORKDIR]                       $ISO_WORKDIR"             "TEXT"
  if [ "$DO_DOCKER" = "true" ]; then
    handle_output "# Previous Work directory:   [ISO_WORKDIR]                       $ISO_WORKDIR"           "TEXT"
  fi
  if [ "$DO_OLD_INSTALLER" = "true" ]; then
    handle_output "# Old Work directory:        [OLD_ISO_WORKDIR]                   $OLD_ISO_WORKDIR"       "TEXT"
    handle_output "# Old ISO input file:        [OLD_ISO_INPUTFILE]             $OLD_ISO_INPUTFILE" "TEXT"
    handle_output "# Old ISO URL:               [OLD_ISO_URL]                    $OLD_ISO_URL"        "TEXT"
  fi
  handle_output "# ISO URL:                   [ISO_URL]                        $ISO_URL"                              "TEXT"
  handle_output "# Cloud Image URL:           [CI_URL]                         $CI_URL"                               "TEXT"
  handle_output "# ISO input file:            [ISO_INPUTFILE]                 $ISO_INPUTFILE"                       "TEXT"
  handle_output "# Cloud Image input file:    [ISO_INPUTCI]                  $ISO_INPUTCI"                        "TEXT"
  handle_output "# Required packages:         [REQUIRED_PACKAGES]              $REQUIRED_PACKAGES"                    "TEXT"
  handle_output "# ISO output file:           [ISO_OUTPUTFILE]                $ISO_OUTPUTFILE"                      "TEXT"
  handle_output "# Cloud Image output file:   [ISO_OUTPUTCI]                 $ISO_OUTPUTCI"                       "TEXT"
  handle_output "# SCP command:               [SCP_COMMAND]                    $ISO_BMCUSERNAME@$MY_IP:$ISO_OUTPUTFILE" "TEXT"
  handle_output "# ISO Release:               [ISO_RELEASE]                    $ISO_RELEASE"                          "TEXT"
  handle_output "# ISO Release (Major):       [ISO_MAJOR_RELEASE]              $ISO_MAJOR_RELEASE"                    "TEXT"
  handle_output "# ISO Release (Minor):       [ISO_MINOR_RELEASE]              $ISO_MINOR_RELEASE"                    "TEXT"
  handle_output "# ISO Build:                 [ISO_BUILDTYPE]                 $ISO_BUILDTYPE"                       "TEXT"
  handle_output "# ISO Volume ID:             [ISO_VOLID]                      $ISO_VOLID"                            "TEXT"
  handle_output "# ISO mount directory:       [ISO_MOUNT_DIR]                  $ISO_MOUNT_DIR"                        "TEXT"
  if [ "$DO_OLD_INSTALLER" = "true" ]; then
    handle_output "# Old ISO mount directory:   [OLD_ISO_MOUNT_DIR]              $OLD_ISO_MOUNT_DIR"              "TEXT"
    handle_output "# Old install squashfs file: [OLD_INSTALL_SQUASHFS_FILE]      $OLD_INSTALL_SQUASHFS_FILE"      "TEXT"
  fi
  handle_output "# ISO squashfs file:         [ISO_SQUASHFSFILE]              $ISO_SQUASHFSFILE"    "TEXT"
  handle_output "# Check latest ISO:          [DO_CHECK_ISO]                   $DO_CHECK_ISO"         "TEXT"
  handle_output "# Hostname:                  [ISO_HOSTNAME]                   $ISO_HOSTNAME"         "TEXT"
  handle_output "# Username:                  [ISO_USERNAME]                   $ISO_USERNAME"         "TEXT"
  handle_output "# Realname:                  [ISO_REALNAME]                   $ISO_REALNAME"         "TEXT"
  handle_output "# Password:                  [ISO_PASSWORD]                   $ISO_PASSWORD"         "TEXT"
  handle_output "# Password Hash:             [ISO_PASSWORD_CRYPT]             $ISO_PASSWORD_CRYPT"   "TEXT"
  if [ "$DO_ISO_SSHKEY" =  "true" ]; then
    handle_output "# SSH Key file:              [ISO_SSHKEYFILE]               $ISO_SSHKEYFILE"   "TEXT"
    handle_output "# SSH Key:                   [ISO_SSHKEY]                    $ISO_SSHKEY"        "TEXT"
  fi
  handle_output "# Timezone:                  [ISO_TIMEZONE]                   $ISO_TIMEZONE"         "TEXT"
  if [ -n "$ISO_SSHKEYFILE" ]; then
    handle_output "# SSH Key file:              [ISO_SSHKEYFILE]               $ISO_SSHKEYFILE"   "TEXT"
  fi
  handle_output "# NIC:                       [ISO_NIC]                        $ISO_NIC"              "TEXT"
  handle_output "# DHCP:                      [DO_ISO_DHCP]                        $DO_ISO_DHCP"              "TEXT"
  if [ "$DO_ISO_DHCP" = "false" ]; then
    handle_output "# IP:                        [ISO_IP]                         $ISO_IP"             "TEXT"
    handle_output "# CIDR:                      [ISO_CIDR]                       $ISO_CIDR"           "TEXT"
    handle_output "# Netmask:                   [ISO_NETMASK]                    $ISO_NETMASK"        "TEXT"
    handle_output "# Gateway:                   [ISO_GATEWAY]                    $ISO_GATEWAY"        "TEXT"
    handle_output "# Nameservers:               [ISO_DNS]                        $ISO_DNS"            "TEXT"
  fi
  handle_output "# Kernel:                    [ISO_KERNEL]                     $ISO_KERNEL"                     "TEXT"
  handle_output "# Kernel arguments:          [ISO_KERNELARGS]                $ISO_KERNELARGS"                "TEXT"
  handle_output "# Block kernel modules:      [ISO_BLOCKLIST]                  $ISO_BLOCKLIST"                  "TEXT"
  handle_output "# Allow kernel modules:      [ISO_ALLOWLIST]                  $ISO_ALLOWLIST"                  "TEXT"
  handle_output "# Allow password login:      [ISO_ALLOWPASSWORD]              $ISO_ALLOWPASSWORD"              "TEXT"
  handle_output "# Keyboard Layout:           [ISO_LAYOUT]                     $ISO_LAYOUT"                     "TEXT"
  handle_output "# Locale:                    [ISO_LOCALE]                     $ISO_LOCALE"                     "TEXT"
  handle_output "# LC_ALL:                    [ISO_LCALL]                     $ISO_LCALL"                     "TEXT"
  handle_output "# Root disk(s):              [ISO_DISK]                       $ISO_DISK"                       "TEXT"
  handle_output "# Volme Manager(s):          [ISO_VOLMGRS]                    $ISO_VOLMGRS"                    "TEXT"
  handle_output "# GRUB Menu:                 [ISO_GRUBMENU]                  $ISO_GRUBMENU"                  "TEXT"
  handle_output "# GRUB Timeout:              [ISO_GRUBTIMEOUT]               $ISO_GRUBTIMEOUT"               "TEXT"
  handle_output "# AI Directory:              [ISO_AUTOINSTALLDIR]             $ISO_AUTOINSTALLDIR"            "TEXT"
  handle_output "# Install mount:             [ISO_INSTALLMOUNT]              $ISO_INSTALLMOUNT"              "TEXT"
  handle_output "# Install target:            [ISO_TARGETMOUNT]               $ISO_TARGETMOUNT"               "TEXT"
  handle_output "# Recreate squashfs:         [DO_ISO_SQUASHFS_UPDATE]         $DO_ISO_SQUASHFS_UPDATE"         "TEXT"
  handle_output "# Run chroot script:         [DO_CHROOT]                      $DO_CHROOT"                      "TEXT"
  handle_output "# Squashfs packages:         [ISO_CHROOTPACKAGES]            $ISO_CHROOTPACKAGES"            "TEXT"
  handle_output "# Additional packages:       [ISO_PACKAGES]           $ISO_PACKAGES"           "TEXT"
  handle_output "# Network updates:           [DO_INSTALL_ISO_NETWORK_UPDATES] $DO_INSTALL_ISO_NETWORK_UPDATES" "TEXT"
  handle_output "# Install packages:          [DO_INSTALL_ISO_PACKAGES]        $DO_INSTALL_ISO_PACKAGES"        "TEXT"
  handle_output "# Install updates:           [DO_INSTALL_ISO_UPDATE]          $DO_INSTALL_ISO_UPDATE"          "TEXT"
  handle_output "# Install upgrades:          [DO_INSTALL_ISO_UPGRADE]         $DO_INSTALL_ISO_UPGRADE"         "TEXT"
  handle_output "# Dist upgrades:             [DO_INSTALL_ISO_DIST_UPGRADE]    $DO_INSTALL_ISO_DIST_UPGRADE"    "TEXT"
  handle_output "# Swap size:                 [ISO_SWAPSIZE]                  $ISO_SWAPSIZE"                  "TEXT"
  handle_output "# VM Memory size:            [ISO_VM_RAM]                     $ISO_VM_RAM"                     "TEXT"
  if [ "$DO_CREATE_EXPORT" = "true" ] || [ "$DO_CREATE_ANSIBLE" = "true" ]; then
    handle_output "# Bootserver IP:             [ISO_BOOTSERVERIP]                 $ISO_BOOTSERVERIP"     "TEXT"
    handle_output "# Bootserver file:           [ISO_BOOTSERVERFILE]               $ISO_BOOTSERVERFILE"   "TEXT"
  fi
  if [ "$DO_CREATE_ANSIBLE" = "true" ] ; then
    handle_output "# BMC IP:                    [ISO_BMCIP]                         $ISO_BMCIP"             "TEXT"
    handle_output "# BMC Username:              [ISO_BMCUSERNAME]                   $ISO_BMCUSERNAME"       "TEXT"
    handle_output "# BMC Password:              [ISO_BMCPASSWORD]                   $ISO_BMCPASSWORD"       "TEXT"
  fi
  if [ "$ISO_CODENAME" = "rocky" ]; then
    handle_output "# Install Mode:              [ISO_INSTALLMODE]               $ISO_INSTALLMODE"             "TEXT"
    handle_output "# Install Source:            [ISO_INSTALLSOURCE]             $ISO_INSTALLSOURCE"           "TEXT"
    handle_output "# Install Username:          [ISO_INSTALLUSERNAME]           $ISO_INSTALLUSERNAME"         "TEXT"
    handle_output "# Install Password:          [ISO_INSTALLPASSWORD]           $ISO_INSTALLPASSWORD"         "TEXT"
    handle_output "# Install Password Crypt:    [ISO_INSTALLPASSWORD_CRYPT]     $ISO_INSTALLPASSWORD_CRYPT"   "TEXT"
    handle_output "# Password Algorithm:        [ISO_PASSWORDALGORITHM]         $ISO_PASSWORDALGORITHM"       "TEXT"
    handle_output "# Bootloader Location:       [ISO_BOOTLOADER]       $ISO_BOOTLOADER"     "TEXT"
    handle_output "# SELinux Mode:              [ISO_SELINUX]                    $ISO_SELINUX"                  "TEXT"
    handle_output "# Firewall:                  [ISO_FIREWALL]                   $ISO_FIREWALL"                 "TEXT"
    handle_output "# Allow Services:            [ISO_ALLOWSERVICE]               $ISO_ALLOWSERVICE"            "TEXT"
    handle_output "# Enable Network on boot:    [ISO_ONBOOT]                     $ISO_ONBOOT"                   "TEXT"
    handle_output "# Network Boot Procol:       [ISO_BOOT_PROTO]                 $ISO_BOOT_PROTO"               "TEXT"
    handle_output "# Enable Services:           [ISO_ENABLESERVICE]             $ISO_ENABLESERVICE"           "TEXT"
    handle_output "# Disable Services:          [ISO_DISABLESERVICE]            $ISO_DISABLESERVICE"          "TEXT"
    handle_output "# User GECOS field:          [ISO_GECOS]                      $ISO_GECOS"                    "TEXT"
    handle_output "# User Groups:               [ISO_GROUPS]                     $ISO_GROUPS"                   "TEXT"
    handle_output "# Boot Partition Size:       [ISO_BOOTSIZE]                  $ISO_BOOTSIZE"                "TEXT"
    handle_output "# PE Size:                   [ISO_PESIZE]                    $ISO_PESIZE"                  "TEXT"
    handle_output "# Volume Group Name:         [ISO_VGNAME]                    $ISO_VGNAME"                  "TEXT"
    handle_output "# Install SSH User:          [ISO_SSH_USER]                   $ISO_SSH_USER"                 "TEXT"
    handle_output "# Install SSH Password:      [ISO_SSH_PASSWORD]               $ISO_SSH_PASSWORD"             "TEXT"
    handle_output "# Do setup on first boot:    [DO_ISO_FIRSTBOOT]               $DO_ISO_FIRSTBOOT"             "TEXT"
  else
    handle_output "# Fallback:                  [ISO_FALLBACK]                   $ISO_FALLBACK"       "TEXT"
  fi
  handle_output "# Serial Port:               [ISO_SERIALPORT0]               $ISO_SERIALPORT0"               "TEXT"
  handle_output "# Serial Port:               [ISO_SERIAL_PORT1]               $ISO_SERIAL_PORT1"               "TEXT"
  handle_output "# Serial Port Address:       [ISO_SERIALPORTADDRESS0]       $ISO_SERIALPORTADDRESS0"       "TEXT"
  handle_output "# Serial Port Address:       [ISO_SERIAL_PORT_ADDRESS1]       $ISO_SERIAL_PORT_ADDRESS1"       "TEXT"
  handle_output "# Serial Port Speed:         [ISO_SERIALPORTSPEED0]         $ISO_SERIALPORTSPEED0"         "TEXT"
  handle_output "# Serial Port Speed:         [ISO_SERIAL_PORT_SPEED1]         $ISO_SERIAL_PORT_SPEED1"         "TEXT"
  handle_output "# Use biosdevnames:          [ISO_USE_BIOSDEVNAME]            $ISO_USE_BIOSDEVNAME"            "TEXT"
  handle_output "# OEM Install:               [ISO_OEMINSTALL]                $ISO_OEMINSTALL"                "TEXT"
  handle_output "# Source ID:                 [ISO_SOURCEID]                  $ISO_SOURCEID"                  "TEXT"
  handle_output "# Search Drivers:            [DO_ISO_SEARCH_DRIVERS]          $DO_ISO_SEARCH_DRIVERS"          "TEXT"
  handle_output "# Preserve Sources:          [DO_ISO_PRESERVE_SOURCES]        $DO_ISO_PRESERVE_SOURCES"        "TEXT"
  if [ "$DO_ISO_AUTOINSTALL" = "true" ]; then
    handle_output "# Custom user-data:          [ISO_AUTOINSTALLFILE]               $ISO_AUTOINSTALLFILE" "TEXT"
  fi
  if [ "$DO_PRINT_ENV" = "true" ] || [ "$INTERACTIVE_MODE" = "true" ]; then
    TEMP_VERBOSE_MODE="false"
  fi
  if [ "$DO_PRINT_ENV" = "true" ]; then
    exit
  fi
}
