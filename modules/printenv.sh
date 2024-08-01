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
  handle_output "# Work directory:            [WORK_DIR]                       $WORK_DIR"             "TEXT"
  if [ "$DO_DOCKER" = "true" ]; then
    handle_output "# Previous Work directory:   [WORK_DIR]                       $WORK_DIR"           "TEXT"
  fi
  if [ "$DO_OLD_INSTALLER" = "true" ]; then
    handle_output "# Old Work directory:        [OLD_WORK_DIR]                   $OLD_WORK_DIR"       "TEXT"
    handle_output "# Old ISO input file:        [OLD_INPUT_FILE]                 $OLD_INPUT_FILE"     "TEXT"
    handle_output "# Old ISO URL:               [OLD_ISO_URL]                    $OLD_ISO_URL"        "TEXT"
  fi
  handle_output "# ISO URL:                   [ISO_URL]                        $ISO_URL"                          "TEXT"
  handle_output "# ISO input file:            [INPUT_FILE]                     $INPUT_FILE"                       "TEXT"
  handle_output "# Required packages:         [REQUIRED_PACKAGES]              $REQUIRED_PACKAGES"                "TEXT"
  handle_output "# ISO output file:           [OUTPUT_FILE]                    $OUTPUT_FILE"                      "TEXT"
  handle_output "# SCP command:               [SCP_COMMAND]                    $BMC_USERNAME@$MY_IP:$OUTPUT_FILE" "TEXT"
  handle_output "# ISO Release:               [ISO_RELEASE]                    $ISO_RELEASE"                      "TEXT"
  handle_output "# ISO Release (Major):       [ISO_MAJOR_RELEASE]              $ISO_MAJOR_RELEASE"                "TEXT"
  handle_output "# ISO Release (Minor):       [ISO_MINOR_RELEASE]              $ISO_MINOR_RELEASE"                "TEXT"
  handle_output "# ISO Build:                 [ISO_BUILD_TYPE]                 $ISO_BUILD_TYPE"                   "TEXT"
  handle_output "# ISO Volume ID:             [ISO_VOLID]                      $ISO_VOLID"                        "TEXT"
  handle_output "# ISO mount directory:       [ISO_MOUNT_DIR]                  $ISO_MOUNT_DIR"                    "TEXT"
  if [ "$DO_OLD_INSTALLER" = "true" ]; then
    handle_output "# Old ISO mount directory:   [OLD_ISO_MOUNT_DIR]              $OLD_ISO_MOUNT_DIR"              "TEXT"
    handle_output "# Old install squashfs file: [OLD_INSTALL_SQUASHFS_FILE]      $OLD_INSTALL_SQUASHFS_FILE"      "TEXT"
  fi
  handle_output "# ISO squashfs file:         [ISO_SQUASHFS_FILE]              $ISO_SQUASHFS_FILE"    "TEXT"
  handle_output "# Check latest ISO:          [DO_CHECK_ISO]                   $DO_CHECK_ISO"         "TEXT"
  handle_output "# Hostname:                  [ISO_HOSTNAME]                   $ISO_HOSTNAME"         "TEXT"
  handle_output "# Username:                  [ISO_USERNAME]                   $ISO_USERNAME"         "TEXT"
  handle_output "# Realname:                  [ISO_REALNAME]                   $ISO_REALNAME"         "TEXT"
  handle_output "# Password:                  [ISO_PASSWORD]                   $ISO_PASSWORD"         "TEXT"
  handle_output "# Password Hash:             [ISO_PASSWORD_CRYPT]             $ISO_PASSWORD_CRYPT"   "TEXT"
  if [ "$DO_ISO_SSH_KEY" =  "true" ]; then
    handle_output "# SSH Key file:              [ISO_SSH_KEY_FILE]               $ISO_SSH_KEY_FILE"   "TEXT"
    handle_output "# SSH Key:                   [ISO_SSH_KEY]                    $ISO_SSH_KEY"        "TEXT"
  fi
  handle_output "# Timezone:                  [ISO_TIMEZONE]                   $ISO_TIMEZONE"         "TEXT"
  if [ -n "$ISO_SSH_KEY_FILE" ]; then
    handle_output "# SSH Key file:              [ISO_SSH_KEY_FILE]               $ISO_SSH_KEY_FILE"   "TEXT"
  fi
  handle_output "# NIC:                       [ISO_NIC]                        $ISO_NIC"              "TEXT"
  handle_output "# DHCP:                      [DO_DHCP]                        $DO_DHCP"              "TEXT"
  if [ "$DO_DHCP" = "false" ]; then
    handle_output "# IP:                        [ISO_IP/ISO_CIDR]                $ISO_IP/$ISO_CIDR"   "TEXT"
    handle_output "# Gateway:                   [ISO_GATEWAY]                    $ISO_GATEWAY"        "TEXT"
    handle_output "# Nameservers:               [ISO_DNS]                        $ISO_DNS"            "TEXT"
  fi
  handle_output "# Kernel:                    [ISO_KERNEL]                     $ISO_KERNEL"                     "TEXT"
  handle_output "# Kernel arguments:          [ISO_KERNEL_ARGS]                $ISO_KERNEL_ARGS"                "TEXT"
  handle_output "# Block kernel modules:      [ISO_BLOCKLIST]                  $ISO_BLOCKLIST"                  "TEXT"
  handle_output "# Allow kernel modules:      [ISO_ALLOWLIST]                  $ISO_ALLOWLIST"                  "TEXT"
  handle_output "# Keyboard Layout:           [ISO_LAYOUT]                     $ISO_LAYOUT"                     "TEXT"
  handle_output "# Locale:                    [ISO_LOCALE]                     $ISO_LOCALE"                     "TEXT"
  handle_output "# LC_ALL:                    [ISO_LC_ALL]                     $ISO_LC_ALL"                     "TEXT"
  handle_output "# Root disk(s):              [ISO_DISK]                       $ISO_DISK"                       "TEXT"
  handle_output "# Volme Manager(s):          [ISO_VOLMGRS]                    $ISO_VOLMGRS"                    "TEXT"
  handle_output "# GRUB Menu:                 [ISO_GRUB_MENU]                  $ISO_GRUB_MENU"                  "TEXT"
  handle_output "# GRUB Timeout:              [ISO_GRUB_TIMEOUT]               $ISO_GRUB_TIMEOUT"               "TEXT"
  handle_output "# AI Directory:              [ISO_AUTOINSTALL_DIR]            $ISO_AUTOINSTALL_DIR"            "TEXT"
  handle_output "# Install mount:             [ISO_INSTALL_MOUNT]              $ISO_INSTALL_MOUNT"              "TEXT"
  handle_output "# Install target:            [ISO_TARGET_MOUNT]               $ISO_TARGET_MOUNT"               "TEXT"
  handle_output "# Recreate squashfs:         [DO_ISO_SQUASHFS_UPDATE]         $DO_ISO_SQUASHFS_UPDATE"         "TEXT"
  handle_output "# Run chroot script:         [DO_CHROOT]                      $DO_CHROOT"                      "TEXT"
  handle_output "# Squashfs packages:         [ISO_CHROOT_PACKAGES]            $ISO_CHROOT_PACKAGES"            "TEXT"
  handle_output "# Additional packages:       [ISO_INSTALL_PACKAGES]           $ISO_INSTALL_PACKAGES"           "TEXT"
  handle_output "# Network updates:           [DO_INSTALL_ISO_NETWORK_UPDATES] $DO_INSTALL_ISO_NETWORK_UPDATES" "TEXT"
  handle_output "# Install packages:          [DO_INSTALL_ISO_PACKAGES]        $DO_INSTALL_ISO_PACKAGES"        "TEXT"
  handle_output "# Install updates:           [DO_INSTALL_ISO_UPDATE]          $DO_INSTALL_ISO_UPDATE"          "TEXT"
  handle_output "# Install upgrades:          [DO_INSTALL_ISO_UPGRADE]         $DO_INSTALL_ISO_UPGRADE"         "TEXT"
  handle_output "# Dist upgrades:             [DO_INSTALL_ISO_DIST_UPGRADE]    $DO_INSTALL_ISO_DIST_UPGRADE"    "TEXT"
  handle_output "# Swap size:                 [ISO_SWAP_SIZE]                  $ISO_SWAP_SIZE"                  "TEXT"
  handle_output "# VM Memory size:            [ISO_VM_RAM]                     $ISO_VM_RAM"                     "TEXT"
  if [ "$DO_CREATE_EXPORT" = "true" ] || [ "$DO_CREATE_ANSIBLE" = "true" ]; then
    handle_output "# Bootserver IP:             [BOOT_SERVER_IP]                 $BOOT_SERVER_IP"     "TEXT"
    handle_output "# Bootserver file:           [BOOT_SERVER_FILE]               $BOOT_SERVER_FILE"   "TEXT"
  fi
  if [ "$DO_CREATE_ANSIBLE" = "true" ] ; then
    handle_output "# BMC IP:                    [BMC_IP]                         $BMC_IP"             "TEXT"
    handle_output "# BMC Username:              [BMC_USERNAME]                   $BMC_USERNAME"       "TEXT"
    handle_output "# BMC Password:              [BMC_PASSWORD]                   $BMC_PASSWORD"       "TEXT"
  fi
  if [ "$ISO_OS_NAME" = "rocky" ]; then
    handle_output "# Install Mode:              [ISO_INSTALL_MODE]               $ISO_INSTALL_MODE"             "TEXT"
    handle_output "# Install Source:            [ISO_INSTALL_SOURCE]             $ISO_INSTALL_SOURCE"           "TEXT"
    handle_output "# Install Username:          [ISO_INSTALL_USERNAME]           $ISO_INSTALL_USERNAME"         "TEXT"
    handle_output "# Install Password:          [ISO_INSTALL_PASSWORD]           $ISO_INSTALL_PASSWORD"         "TEXT"
    handle_output "# Install Password Crypt:    [ISO_INSTALL_PASSWORD_CRYPT]     $ISO_INSTALL_PASSWORD_CRYPT"   "TEXT"
    handle_output "# Password Algorithm:        [ISO_PASSWORD_ALGORITHM]         $ISO_PASSWORD_ALGORITHM"       "TEXT"
    handle_output "# Bootloader Location:       [ISO_BOOT_LOADER_LOCATION]       $ISO_BOOT_LOADER_LOCATION"     "TEXT"
    handle_output "# SELinux Mode:              [ISO_SELINUX]                    $ISO_SELINUX"                  "TEXT"
    handle_output "# Firewall:                  [ISO_FIREWALL]                   $ISO_FIREWALL"                 "TEXT"
    handle_output "# Allow Services:            [ISO_ALLOW_SERVICE]              $ISO_ALLOW_SERVICE"            "TEXT"
    handle_output "# Enable Network on boot:    [ISO_ONBOOT]                     $ISO_ONBOOT"                   "TEXT"
    handle_output "# Network Boot Procol:       [ISO_BOOT_PROTO]                 $ISO_BOOT_PROTO"               "TEXT"
    handle_output "# Enable Services:           [ISO_ENABLE_SERVICE]             $ISO_ENABLE_SERVICE"           "TEXT"
    handle_output "# Disable Services:          [ISO_DISABLE_SERVICE]            $ISO_DISABLE_SERVICE"          "TEXT"
    handle_output "# User GECOS field:          [ISO_GECOS]                      $ISO_GECOS"                    "TEXT"
    handle_output "# User Groups:               [ISO_GROUPS]                     $ISO_GROUPS"                   "TEXT"
    handle_output "# Boot Partition Size:       [ISO_BOOT_SIZE]                  $ISO_BOOT_SIZE"                "TEXT"
    handle_output "# PE Size:                   [ISO_PE_SIZE]                    $ISO_PE_SIZE"                  "TEXT"
    handle_output "# Volume Group Name:         [ISO_VG_NAME]                    $ISO_VG_NAME"                  "TEXT"
    handle_output "# Install SSH User:          [ISO_SSH_USER]                   $ISO_SSH_USER"                 "TEXT"
    handle_output "# Install SSH Password:      [ISO_SSH_PASSWORD]               $ISO_SSH_PASSWORD"             "TEXT"
    handle_output "# Do setup on first boot:    [DO_ISO_FIRSTBOOT]               $DO_ISO_FIRSTBOOT"             "TEXT"
  else
    handle_output "# Fallback:                  [ISO_FALLBACK]                   $ISO_FALLBACK"       "TEXT"
  fi
  handle_output "# Serial Port:               [ISO_SERIAL_PORT0]               $ISO_SERIAL_PORT0"               "TEXT"
  handle_output "# Serial Port:               [ISO_SERIAL_PORT1]               $ISO_SERIAL_PORT1"               "TEXT"
  handle_output "# Serial Port Address:       [ISO_SERIAL_PORT_ADDRESS0]       $ISO_SERIAL_PORT_ADDRESS0"       "TEXT"
  handle_output "# Serial Port Address:       [ISO_SERIAL_PORT_ADDRESS1]       $ISO_SERIAL_PORT_ADDRESS1"       "TEXT"
  handle_output "# Serial Port Speed:         [ISO_SERIAL_PORT_SPEED0]         $ISO_SERIAL_PORT_SPEED0"         "TEXT"
  handle_output "# Serial Port Speed:         [ISO_SERIAL_PORT_SPEED1]         $ISO_SERIAL_PORT_SPEED1"         "TEXT"
  handle_output "# Use biosdevnames:          [ISO_USE_BIOSDEVNAME]            $ISO_USE_BIOSDEVNAME"            "TEXT"
  handle_output "# OEM Install:               [ISO_OEM_INSTALL]                $ISO_OEM_INSTALL"                "TEXT"
  handle_output "# Source ID:                 [ISO_SOURCE_ID]                  $ISO_SOURCE_ID"                  "TEXT"
  handle_output "# Search Drivers:            [DO_ISO_SEARCH_DRIVERS]          $DO_ISO_SEARCH_DRIVERS"          "TEXT"
  handle_output "# Preserve Sources:          [DO_ISO_PRESERVE_SOURCES]        $DO_ISO_PRESERVE_SOURCES"        "TEXT"
  if [ "$DO_CUSTOM_AUTO_INSTALL" = "true" ]; then
    handle_output "# Custom user-data:          [AUTO_INSTALL_FILE]               $AUTO_INSTALL_FILE" "TEXT"
  fi
  if [ "$DO_PRINT_ENV" = "true" ] || [ "$INTERACTIVE_MODE" = "true" ]; then
    TEMP_VERBOSE_MODE="false"
  fi
  if [ "$DO_PRINT_ENV" = "true" ]; then
    exit
  fi
}
